extends CharacterBody2D

const HIT_FLASH_TIME := 0.1
const HIT_FX_FRAME_COUNT := 5
const HIT_FX_FRAME_SIZE := Vector2i(125, 87)
const HIT_FX_FRAME_TIME := 0.04
const HIT_FX_1_OFFSET := Vector2(-70.5, -43.5)
const HIT_FX_2_OFFSET := Vector2(-40.5, -30.5)
const MAX_HP := 300.0
const HEALTH_FILL_MAX_WIDTH := 426.0
const AGIS_FRAME_SIZE := Vector2i(320, 320)
const INTRO_TRIGGER_DISTANCE := 260.0
const INTRO_FRAME_COUNT := 30
const INTRO_FRAME_TIME := 0.05
const VISUAL_IDLE_POSITION := Vector2(-161.0, -327.0)
const VISUAL_INTRO_POSITION := VISUAL_IDLE_POSITION + Vector2(2.0, 3.0)
const DEATH_FRAME_COUNT := 65
const DEATH_FRAME_TIME := 4.0 / float(DEATH_FRAME_COUNT)
const DAMAGE_NUMBER_LIFETIME := 0.7
const DAMAGE_NUMBER_RISE := 34.0
const DAMAGE_NUMBER_OFFSET := Vector2(-12.0, -185.0)
const DAMAGE_NUMBER_NORMAL_COLOR := Color(0.282353, 0.752941, 0.690196, 1.0)
const DAMAGE_NUMBER_HEAVY_COLOR := Color(0.364706, 0.298039, 0.717647, 1.0)
const DAMAGE_NUMBER_HEAVY_THRESHOLD := 20

@onready var visual: AnimatedSprite2D = $Visual
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurt_box: Area2D = $HurtBox
@onready var upper_body_shape: CollisionShape2D = $HurtBox/UpperBodyShape
@onready var lower_body_shape: CollisionShape2D = $HurtBox/LowerBodyShape
@onready var upper_hit_point: Marker2D = $HitPoints/UpperHitPoint
@onready var lower_hit_point: Marker2D = $HitPoints/LowerHitPoint
@onready var hit_fx: AnimatedSprite2D = $HitFx
@onready var death_sfx: AudioStreamPlayer2D = $DeathSfx
@onready var health_bar: Control = get_node_or_null("../BossUI/AgisHealthBar")
@onready var health_fill: ColorRect = get_node_or_null("../BossUI/AgisHealthBar/Fill")
@onready var damage_numbers: CanvasLayer = get_node_or_null("../DamageNumbers")
@onready var damage_font: FontFile = load("res://assets/fonts/antiquity-print.ttf")
@onready var player: Node2D = get_node_or_null("../Player")

var hit_flash_timer := 0.0
var current_hp := MAX_HP
var is_dead := false
var has_intro_started := false
var is_intro_playing := false
var intro_timer := 0.0

func _ready() -> void:
	randomize()
	_setup_intro_animation()
	_setup_death_animation()
	_setup_hit_fx_animations()
	visual.animation_finished.connect(_on_visual_animation_finished)
	visual.position = VISUAL_IDLE_POSITION
	visual.play("idle")
	visual.visible = false
	hit_fx.visible = false
	_set_health_bar_visible(false)
	_set_health_bar_fill_width(0.0)

func _process(delta: float) -> void:
	if not has_intro_started:
		_try_start_intro()

	if is_intro_playing:
		_update_intro_health_bar(delta)

	if hit_flash_timer <= 0.0:
		return

	hit_flash_timer -= delta
	if hit_flash_timer <= 0.0:
		visual.modulate = Color.WHITE

func take_hit(_source_position: Vector2, _source_direction: int, damage := 1, hit_area: Area2D = null, attack_position := Vector2.ZERO) -> void:
	if is_dead or not has_intro_started or is_intro_playing:
		return

	current_hp = max(current_hp - float(damage), 0.0)
	_update_health_bar()
	_spawn_damage_number(damage)
	if current_hp <= 0.0:
		_die()
		return

	visual.modulate = Color(1.8, 1.8, 1.8, 1.0)
	hit_flash_timer = HIT_FLASH_TIME
	_play_random_hit_fx(_get_hit_point(hit_area, attack_position).global_position)

func _try_start_intro() -> void:
	if player == null:
		return

	if global_position.distance_to(player.global_position) > INTRO_TRIGGER_DISTANCE:
		return

	has_intro_started = true
	is_intro_playing = true
	intro_timer = 0.0
	_set_health_bar_visible(true)
	_set_health_bar_fill_width(0.0)
	visual.visible = true
	visual.position = VISUAL_INTRO_POSITION
	visual.play("intro")

func _update_intro_health_bar(delta: float) -> void:
	intro_timer += delta
	var intro_duration := INTRO_FRAME_COUNT * INTRO_FRAME_TIME
	var fill_ratio := clampf(intro_timer / intro_duration, 0.0, 1.0)
	_set_health_bar_fill_width(HEALTH_FILL_MAX_WIDTH * fill_ratio)

func _get_hit_point(hit_area: Area2D, attack_position: Vector2) -> Marker2D:
	if hit_area != hurt_box:
		return upper_hit_point

	var upper_distance := attack_position.distance_squared_to(upper_body_shape.global_position)
	var lower_distance := attack_position.distance_squared_to(lower_body_shape.global_position)
	if lower_distance < upper_distance:
		return lower_hit_point
	return upper_hit_point

func _die() -> void:
	is_dead = true
	hit_flash_timer = 0.0
	visual.modulate = Color.WHITE
	hit_fx.visible = false
	if health_bar != null:
		health_bar.hide()
	death_sfx.play()
	body_shape.set_deferred("disabled", true)
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	for child in hurt_box.get_children():
		var shape := child as CollisionShape2D
		if shape != null:
			shape.set_deferred("disabled", true)
	visual.position = VISUAL_IDLE_POSITION
	visual.play("death")

func _setup_death_animation() -> void:
	var frames := visual.sprite_frames
	if frames.has_animation("death"):
		frames.remove_animation("death")

	frames.add_animation("death")
	frames.set_animation_loop("death", false)
	frames.set_animation_speed("death", 1.0 / DEATH_FRAME_TIME)
	var texture := load("res://assets/enemies/agis/full/death.png")
	for frame_index in range(DEATH_FRAME_COUNT):
		frames.add_frame("death", _make_agis_atlas_texture(texture, frame_index))

func _setup_intro_animation() -> void:
	var frames := visual.sprite_frames
	if frames.has_animation("intro"):
		frames.remove_animation("intro")

	frames.add_animation("intro")
	frames.set_animation_loop("intro", false)
	frames.set_animation_speed("intro", 1.0 / INTRO_FRAME_TIME)
	var texture := load("res://assets/enemies/agis/full/teleport in.png")
	for frame_index in range(INTRO_FRAME_COUNT):
		frames.add_frame("intro", _make_agis_atlas_texture(texture, frame_index))

func _make_agis_atlas_texture(texture: Texture2D, frame_index: int) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = Rect2(frame_index * AGIS_FRAME_SIZE.x, 0, AGIS_FRAME_SIZE.x, AGIS_FRAME_SIZE.y)
	return atlas_texture

func _update_health_bar() -> void:
	var hp_ratio := clampf(current_hp / MAX_HP, 0.0, 1.0)
	_set_health_bar_fill_width(HEALTH_FILL_MAX_WIDTH * hp_ratio)

func _set_health_bar_fill_width(fill_width: float) -> void:
	if health_fill == null:
		return

	health_fill.custom_minimum_size.x = fill_width
	health_fill.size.x = fill_width

func _set_health_bar_visible(visible: bool) -> void:
	if health_bar != null:
		health_bar.visible = visible

func _spawn_damage_number(damage: int) -> void:
	if damage_numbers == null:
		return

	var label := Label.new()
	label.text = str(damage)
	label.z_index = 100
	label.global_position = get_global_transform_with_canvas().origin + DAMAGE_NUMBER_OFFSET + Vector2(randf_range(-8.0, 8.0), 0.0)
	label.add_theme_font_override("font", damage_font)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", DAMAGE_NUMBER_HEAVY_COLOR if damage >= DAMAGE_NUMBER_HEAVY_THRESHOLD else DAMAGE_NUMBER_NORMAL_COLOR)
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.0, 0.02, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	damage_numbers.add_child(label)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - DAMAGE_NUMBER_RISE, DAMAGE_NUMBER_LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, DAMAGE_NUMBER_LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func _setup_hit_fx_animations() -> void:
	var frames := SpriteFrames.new()
	_add_hit_fx_animation(frames, "hit_fx_1", "res://assets/characters/player_01/hit fx/hit fx_01.png")
	_add_hit_fx_animation(frames, "hit_fx_2", "res://assets/characters/player_01/hit fx/hit fx_02.png")
	hit_fx.sprite_frames = frames
	hit_fx.animation_finished.connect(_on_hit_fx_animation_finished)

func _add_hit_fx_animation(frames: SpriteFrames, animation_name: StringName, texture_path: String) -> void:
	var texture := load(texture_path)
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, false)
	frames.set_animation_speed(animation_name, 1.0 / HIT_FX_FRAME_TIME)
	for frame_index in range(HIT_FX_FRAME_COUNT):
		frames.add_frame(animation_name, _make_hit_fx_atlas_texture(texture, frame_index))

func _make_hit_fx_atlas_texture(texture: Texture2D, frame_index: int) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = Rect2(frame_index * HIT_FX_FRAME_SIZE.x, 0, HIT_FX_FRAME_SIZE.x, HIT_FX_FRAME_SIZE.y)
	return atlas_texture

func _play_random_hit_fx(hit_position: Vector2) -> void:
	var animation_name := "hit_fx_1" if randi() % 2 == 0 else "hit_fx_2"
	var fx_offset := HIT_FX_1_OFFSET if animation_name == "hit_fx_1" else HIT_FX_2_OFFSET
	hit_fx.global_position = hit_position + fx_offset
	hit_fx.visible = true
	hit_fx.play(animation_name)

func _on_hit_fx_animation_finished() -> void:
	hit_fx.visible = false

func _on_visual_animation_finished() -> void:
	if is_intro_playing and visual.animation == "intro":
		is_intro_playing = false
		current_hp = MAX_HP
		_set_health_bar_fill_width(HEALTH_FILL_MAX_WIDTH)
		visual.position = VISUAL_IDLE_POSITION
		visual.play("idle")
		return

	if is_dead and visual.animation == "death":
		hide()
