extends CharacterBody2D

enum MoveState {
	IDLE,
	WALK_START,
	WALK,
	RUN_START,
	RUN,
	RUN_TURN,
	RUN_TO_WALK,
	RUN_STOP,
	CROUCH,
	SLIDE,
	BACK_DODGE,
	HURT,
	HEAL,
	LIGHT_ATTACK_1,
	LIGHT_ATTACK_2,
	LIGHT_ATTACK_3,
	LIGHT_ATTACK_4,
	LIGHT_ATTACK_5,
	JUMP_ATTACK_1,
	JUMP_ATTACK_2,
	JUMP,
	DOUBLE_JUMP,
	AIR_DASH,
	LAND,
	ROLL_LAND,
}

enum JumpPhase {
	NONE,
	PREPARE,
	UP,
	AIR,
	FALL,
	LAND,
}

enum CrouchPhase {
	NONE,
	ENTER,
	IDLE,
	EXIT,
}

const WALK_SPEED := 125.0
const RUN_SPEED := 300.0
const GRAVITY := 1200.0
const JUMP_VELOCITY := -430.0
const DOUBLE_JUMP_VELOCITY := -390.0
const JUMP_PREPARE_FRAME_TIME := 0.06
const JUMP_LOOP_FRAME_TIME := 0.06
const JUMP_LAND_FRAME_TIME := 0.045
const DOUBLE_JUMP_FRAME_TIME := 0.07
const AIR_DASH_FRAME_TIME := 0.07
const AIR_DASH_WALK_SPEED := 250.0
const AIR_DASH_RUN_SPEED := 360.0
const AIR_DASH_SMOKE_FRAME_WIDTH := 443.0
const AIR_DASH_SMOKE_CENTER_OFFSET := Vector2(0.0, -35.0)
const ROLL_LAND_FRAME_TIME := 0.045
const CROUCH_FRAME_TIME := 0.07
const SLIDE_FRAME_TIME := 0.04
const SLIDE_SPEED := 360.0
const BACK_DODGE_FRAME_TIME := 0.035
const BACK_DODGE_SPEED := 260.0
const BACK_DODGE_OFFSET_LEFT := Vector2(-108.0, -67.0)
const BACK_DODGE_OFFSET_RIGHT := Vector2(-33.0, -67.0)
const LIGHT_ATTACK_1_OFFSET_LEFT := Vector2(-137.0, -69.0)
const LIGHT_ATTACK_1_OFFSET_RIGHT := Vector2(-22.0, -69.0)
const LIGHT_ATTACK_2_OFFSET_LEFT := Vector2(-137.0, -69.0)
const LIGHT_ATTACK_2_OFFSET_RIGHT := Vector2(-54.0, -69.0)
const LIGHT_ATTACK_3_OFFSET_LEFT := Vector2(-109.0, -81.0)
const LIGHT_ATTACK_3_OFFSET_RIGHT := Vector2(-29.0, -81.0)
const LIGHT_ATTACK_4_OFFSET_LEFT := LIGHT_ATTACK_3_OFFSET_LEFT
const LIGHT_ATTACK_4_OFFSET_RIGHT := LIGHT_ATTACK_3_OFFSET_RIGHT
const LIGHT_ATTACK_5_OFFSET_LEFT := Vector2(-181.75, -97.0)
const LIGHT_ATTACK_5_OFFSET_RIGHT := Vector2(-39.25, -97.0)
const JUMP_ATTACK_1_OFFSET_LEFT := Vector2(-99.5, -74.0)
const JUMP_ATTACK_1_OFFSET_RIGHT := Vector2(-28.5, -74.0)
const JUMP_ATTACK_2_OFFSET_LEFT := Vector2(-85.5, -95.5)
const JUMP_ATTACK_2_OFFSET_RIGHT := Vector2(-14.5, -95.5)
const HURT_FRAME_TIME := 0.04
const HEAL_FRAME_TIME := 0.06
const LIGHT_ATTACK_1_FRAME_TIME := 0.04
const LIGHT_ATTACK_2_FRAME_TIME := 0.04
const LIGHT_ATTACK_3_FRAME_TIME := 0.04
const LIGHT_ATTACK_4_FRAME_TIME := 0.04
const LIGHT_ATTACK_5_FRAME_TIME := 0.035
const JUMP_ATTACK_1_FRAME_TIME := 0.04
const JUMP_ATTACK_2_FRAME_TIME := 0.1
const LIGHT_ATTACK_COMBO_WINDOW := 0.3
const LIGHT_ATTACK_1_LUNGE_SPEED := 15.0
const LIGHT_ATTACK_2_LUNGE_SPEED := 15.0
const LIGHT_ATTACK_3_LUNGE_SPEED := 0.0
const LIGHT_ATTACK_4_LUNGE_SPEED := 0.0
const LIGHT_ATTACK_5_LUNGE_SPEED := 30.0
const ATTACK_HITBOX_OFFSETS_RIGHT := {
	1: Vector2(80.0, -36.0),
	2: Vector2(70.0, -36.0),
	3: Vector2(62.0, -46.0),
	4: Vector2(66.0, -43.0),
	5: Vector2(104.0, -53.0),
	6: Vector2(76.0, -50.0),
	7: Vector2(76.0, -58.0),
}
const ATTACK_HITBOX_OFFSETS_LEFT := {
	1: Vector2(-80.0, -36.0),
	2: Vector2(-70.0, -36.0),
	3: Vector2(-62.0, -46.0),
	4: Vector2(-66.0, -43.0),
	5: Vector2(-104.0, -53.0),
	6: Vector2(-76.0, -50.0),
	7: Vector2(-76.0, -58.0),
}
const ATTACK_HITBOX_SIZES := {
	1: Vector2(124.0, 56.0),
	2: Vector2(100.0, 56.0),
	3: Vector2(88.0, 76.0),
	4: Vector2(96.0, 70.0),
	5: Vector2(160.0, 96.0),
	6: Vector2(112.0, 64.0),
	7: Vector2(112.0, 72.0),
}
const ATTACK_HITBOX_TRIGGER_FRAMES := {
	1: 6,
	2: 6,
	3: 3,
	4: 3,
	5: 12,
	6: 3,
	7: 3,
}
const LIGHT_ATTACK_DAMAGE := {
	1: 8,
	2: 10,
	3: 6,
	4: 12,
	5: 25,
	6: 10,
	7: 12,
}
const PLAYER_MAX_HP := 100.0
const PLAYER_TEST_DAMAGE := 10.0
const PLAYER_HEALTH_FILL_WIDTH := 111.0
const ACCELERATION := 1200.0
const FRICTION := 1600.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var slide_fx: AnimatedSprite2D = $SlideFx
@onready var heal_sfx: AudioStreamPlayer2D = $HealSfx
@onready var attack_hit_box: Area2D = $AttackHitBox
@onready var attack_hit_shape: CollisionShape2D = $AttackHitBox/CollisionShape2D
@onready var player_health_fill: TextureRect = get_node_or_null("../PlayerUI/HealthFill")

const VISUAL_OFFSETS := {
	"idle": Vector2(-20.6, -61.0),
	"walk_start": Vector2(-18.9, -64.0),
	"walk": Vector2(-18.9, -64.0),
	"run": Vector2(-29.9, -52.8),
	"run_start": Vector2(-29.2, -59.0),
	"run_turn": Vector2(-29.9, -52.8),
	"run_stop": Vector2(-30.2, -59.0),
	"crouch": Vector2(-26.5, -56.0),
	"slide": Vector2(-48.0, -69.0),
	"slide_fx": Vector2(-48.0, -69.0),
	"hit": Vector2(-25.6, -62.0),
	"normal_hit": Vector2(-25.6, -66.0),
	"hard_hit": Vector2(-32.6, -66.0),
	"heal": Vector2(-43.0, -86.0),
	"jump": Vector2(-31.5, -80.0),
	"double_jump_vertical": Vector2(-39.5, -80.0),
	"double_jump_forward": Vector2(-39.5, -80.0),
	"air_dash": Vector2(-51.5, -60.0),
	"air_dash_smoke": Vector2(-40.0, -78.0),
	"roll_landing": Vector2(-45.45, -68.91),
}

var move_state := MoveState.IDLE
var jump_phase := JumpPhase.NONE
var jump_timer := 0.0
var jump_frame := 0
var jump_direction := 0.0
var jump_horizontal_speed := WALK_SPEED
var double_jump_frame := 0
var double_jump_timer := 0.0
var double_jump_animation := StringName("double_jump_vertical")
var can_double_jump := false
var used_double_jump := false
var used_forward_double_jump := false
var used_jump_attack := false
var can_air_dash := false
var air_dash_frame := 0
var air_dash_timer := 0.0
var air_dash_direction := 0.0
var air_dash_speed := AIR_DASH_WALK_SPEED
var air_dash_jump_buffered := false
var air_dash_smoke: AnimatedSprite2D = null
var air_dash_smoke_origin := Vector2.ZERO
var air_dash_smoke_frame := 0
var air_dash_smoke_timer := 0.0
var air_dash_fx: AnimatedSprite2D = null
var air_dash_fx_origin := Vector2.ZERO
var air_dash_fx_frame := 0
var air_dash_fx_timer := 0.0
var roll_landing_direction := 0.0
var roll_landing_frame := 0
var roll_landing_timer := 0.0
var crouch_phase := CrouchPhase.NONE
var crouch_timer := 0.0
var crouch_frame := 0
var slide_timer := 0.0
var slide_frame := 0
var slide_direction := 0.0
var slide_input_locked := false
var run_turn_target_direction := 0
var back_dodge_timer := 0.0
var back_dodge_frame := 0
var back_dodge_direction := 0.0
var hurt_timer := 0.0
var hurt_frame := 0
var hurt_frame_count := 0
var hurt_animation := StringName()
var heal_timer := 0.0
var heal_frame := 0
var light_attack_1_timer := 0.0
var light_attack_1_frame := 0
var light_attack_2_timer := 0.0
var light_attack_2_frame := 0
var light_attack_2_queued := false
var light_attack_3_timer := 0.0
var light_attack_3_frame := 0
var light_attack_3_queued := false
var light_attack_4_timer := 0.0
var light_attack_4_frame := 0
var light_attack_5_timer := 0.0
var light_attack_5_frame := 0
var light_attack_5_queued := false
var jump_attack_1_timer := 0.0
var jump_attack_1_frame := 0
var jump_attack_1_direction := 0.0
var jump_attack_1_speed := 0.0
var jump_attack_2_timer := 0.0
var jump_attack_2_frame := 0
var jump_attack_count := 0
var light_attack_combo_timer := 0.0
var light_attack_combo_step := 0
var light_attack_direction := 1
var light_attack_active_step := 0
var light_attack_hit_targets: Array[Node] = []
var dodge_collision_exceptions: Array[PhysicsBody2D] = []
var current_hp := PLAYER_MAX_HP
var facing := 1
var last_pressed_direction := 0

func _ready() -> void:
	_setup_idle_animation()
	_setup_walk_animations()
	_setup_run_animation()
	_setup_jump_animation()
	_setup_air_dash_animation()
	_setup_crouch_animation()
	_setup_slide_animation()
	_setup_back_dodge_animations()
	_setup_hurt_animations()
	_setup_heal_animation()
	_setup_light_attack_animations()
	visual.animation_finished.connect(_on_animation_finished)
	attack_hit_box.area_entered.connect(_on_attack_hit_box_area_entered)
	_set_attack_hitbox_enabled(false)
	slide_fx.visible = false
	_update_player_health_ui()

func take_damage(damage: float) -> void:
	current_hp = max(current_hp - damage, 0.0)
	_update_player_health_ui()

func _update_player_health_ui() -> void:
	if player_health_fill == null:
		return

	var hp_ratio := clampf(current_hp / PLAYER_MAX_HP, 0.0, 1.0)
	var fill_width := roundf(PLAYER_HEALTH_FILL_WIDTH * hp_ratio)
	player_health_fill.size.x = fill_width

	var atlas_texture := player_health_fill.texture as AtlasTexture
	if atlas_texture != null:
		atlas_texture.region.size.x = fill_width

func _physics_process(delta: float) -> void:
	_update_air_dash_smoke(delta)
	_update_air_dash_fx(delta)
	if not is_on_floor() and move_state not in [MoveState.AIR_DASH, MoveState.JUMP_ATTACK_1, MoveState.JUMP_ATTACK_2]:
		velocity.y += GRAVITY * delta

	var direction := _get_input_direction()
	var wants_run := Input.is_action_pressed("run") and direction != 0.0
	var wants_crouch := Input.is_action_pressed("move_down") and is_on_floor()
	var action_locked := move_state in [MoveState.ROLL_LAND, MoveState.AIR_DASH]
	_update_light_attack_combo_timer(delta)
	if Input.is_action_just_pressed("test_player_damage"):
		take_damage(PLAYER_TEST_DAMAGE)
	if not wants_crouch and move_state != MoveState.SLIDE:
		slide_input_locked = false
	if move_state == MoveState.AIR_DASH and Input.is_action_just_pressed("light_attack") and _handle_light_attack_input():
		pass
	elif not action_locked and _try_start_test_hurt():
		pass
	elif not action_locked and Input.is_action_just_pressed("light_attack") and _handle_light_attack_input():
		pass
	elif not action_locked and Input.is_action_just_pressed("heal") and is_on_floor() and _can_start_heal():
		_start_heal()
	elif not action_locked and Input.is_action_just_pressed("back_dodge") and is_on_floor() and _can_start_back_dodge():
		_start_back_dodge()
	elif not action_locked and Input.is_action_just_pressed("air_dash") and not is_on_floor() and can_air_dash and _can_start_air_dash():
		_start_air_dash(direction)
	elif not action_locked and Input.is_action_just_pressed("jump") and not is_on_floor() and can_double_jump and _can_start_double_jump():
		_start_double_jump(direction)
	elif not action_locked and Input.is_action_just_pressed("jump") and is_on_floor():
		_start_jump()
	else:
		_update_move_state(direction, wants_run, wants_crouch)

	var speed := _get_current_speed()
	var movement_direction := _get_movement_direction(direction)
	var target_velocity_x := movement_direction * speed

	if _is_light_attack_state():
		velocity.x = target_velocity_x
	elif movement_direction != 0.0:
		velocity.x = move_toward(velocity.x, target_velocity_x, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if movement_direction != 0.0 and move_state not in [
		MoveState.BACK_DODGE,
		MoveState.RUN_TURN,
		MoveState.LIGHT_ATTACK_1,
		MoveState.LIGHT_ATTACK_2,
		MoveState.LIGHT_ATTACK_3,
		MoveState.LIGHT_ATTACK_4,
		MoveState.LIGHT_ATTACK_5,
		MoveState.JUMP_ATTACK_1,
		MoveState.JUMP_ATTACK_2,
		MoveState.AIR_DASH,
	]:
		facing = int(sign(movement_direction))

	if move_state != MoveState.RUN_TURN:
		visual.flip_h = facing > 0
	slide_fx.flip_h = visual.flip_h
	_update_animation()
	if move_state not in [MoveState.SLIDE, MoveState.BACK_DODGE] and slide_fx.visible:
		_hide_slide_fx()

	move_and_slide()

func _play_animation(animation_name: StringName) -> void:
	if visual.animation != animation_name:
		_force_play_animation(animation_name)

func _play_animation_backwards(animation_name: StringName) -> void:
	_set_visual_offset(animation_name)
	visual.animation = animation_name
	visual.frame = visual.sprite_frames.get_frame_count(animation_name) - 1
	visual.frame_progress = 1.0
	visual.speed_scale = -1.0
	visual.play()

func _update_move_state(direction: float, wants_run: bool, wants_crouch: bool) -> void:
	if move_state == MoveState.JUMP:
		_update_jump(direction)
		return

	if move_state == MoveState.DOUBLE_JUMP:
		_update_double_jump()
		return

	if move_state == MoveState.AIR_DASH:
		_update_air_dash()
		return

	if move_state == MoveState.LAND:
		_update_landing()
		return

	if move_state == MoveState.ROLL_LAND:
		_update_roll_landing()
		return

	if move_state == MoveState.CROUCH:
		_update_crouch(wants_crouch)
		return

	if move_state == MoveState.SLIDE:
		_update_slide()
		return

	if move_state == MoveState.BACK_DODGE:
		_update_back_dodge()
		return

	if move_state == MoveState.HURT:
		_update_hurt()
		return

	if move_state == MoveState.HEAL:
		_update_heal()
		return

	if move_state == MoveState.LIGHT_ATTACK_1:
		_update_light_attack_1()
		return

	if move_state == MoveState.LIGHT_ATTACK_2:
		_update_light_attack_2()
		return

	if move_state == MoveState.LIGHT_ATTACK_3:
		_update_light_attack_3()
		return

	if move_state == MoveState.LIGHT_ATTACK_4:
		_update_light_attack_4()
		return

	if move_state == MoveState.LIGHT_ATTACK_5:
		_update_light_attack_5()
		return

	if move_state == MoveState.JUMP_ATTACK_1:
		_update_jump_attack_1()
		return

	if move_state == MoveState.JUMP_ATTACK_2:
		_update_jump_attack_2()
		return

	if move_state == MoveState.RUN_TURN:
		return

	if move_state == MoveState.WALK_START:
		if wants_run:
			move_state = MoveState.RUN_START
			_play_animation("run_start")
		elif direction == 0.0:
			move_state = MoveState.IDLE
			_play_animation("idle")
		return

	if wants_crouch and not slide_input_locked and move_state in [MoveState.RUN_START, MoveState.RUN]:
		_start_slide()
		return

	if wants_crouch and not slide_input_locked:
		_start_crouch()
		return

	if move_state == MoveState.RUN_START:
		if not Input.is_action_pressed("run"):
			move_state = MoveState.WALK if direction != 0.0 else MoveState.RUN_STOP
			_play_animation("walk" if direction != 0.0 else "run_stop")
		elif direction == 0.0:
			move_state = MoveState.RUN_STOP
			_play_animation("run_stop")
		return

	if move_state == MoveState.RUN_STOP:
		if wants_run:
			move_state = MoveState.RUN_START
			_play_animation("run_start")
		return

	if move_state == MoveState.RUN_TO_WALK:
		if wants_run:
			move_state = MoveState.RUN_START
			_play_animation("run_start")
		elif direction == 0.0:
			move_state = MoveState.RUN_STOP
			_play_animation("run_stop")
		return

	var run_turn_direction := _get_run_turn_direction(direction, wants_run)
	if move_state == MoveState.RUN and run_turn_direction != 0:
		_start_run_turn(run_turn_direction)
		return

	if wants_run:
		if move_state != MoveState.RUN:
			move_state = MoveState.RUN_START
			_play_animation("run_start")
	elif move_state == MoveState.RUN and direction == 0.0:
		move_state = MoveState.RUN_STOP
		_play_animation("run_stop")
	elif move_state == MoveState.RUN and direction != 0.0:
		move_state = MoveState.RUN_TO_WALK
		_play_animation_backwards("run_start")
	elif direction != 0.0:
		if move_state != MoveState.WALK:
			move_state = MoveState.WALK_START
			_play_animation("walk_start")
	else:
		move_state = MoveState.IDLE

func _update_animation() -> void:
	match move_state:
		MoveState.IDLE:
			_play_animation("idle")
		MoveState.WALK_START:
			pass
		MoveState.WALK:
			_play_animation("walk")
		MoveState.RUN:
			_play_animation("run")
		MoveState.RUN_TURN:
			pass
		MoveState.CROUCH:
			pass
		MoveState.SLIDE:
			pass
		MoveState.BACK_DODGE:
			pass
		MoveState.HURT:
			pass
		MoveState.HEAL:
			pass
		MoveState.LIGHT_ATTACK_1:
			pass
		MoveState.LIGHT_ATTACK_2:
			pass
		MoveState.LIGHT_ATTACK_3:
			pass
		MoveState.LIGHT_ATTACK_4:
			pass
		MoveState.LIGHT_ATTACK_5:
			pass
		MoveState.JUMP_ATTACK_1:
			pass
		MoveState.JUMP_ATTACK_2:
			pass
		MoveState.DOUBLE_JUMP:
			pass
		MoveState.AIR_DASH:
			pass
		MoveState.JUMP:
			pass
		MoveState.ROLL_LAND:
			pass
		_:
			pass

func _on_animation_finished() -> void:
	if move_state == MoveState.RUN_START:
		move_state = MoveState.RUN
		_play_animation("run")
	elif move_state == MoveState.RUN_TURN:
		_finish_run_turn()
	elif move_state == MoveState.RUN_STOP:
		move_state = MoveState.IDLE
		_play_animation("idle")
	elif move_state == MoveState.RUN_TO_WALK:
		move_state = MoveState.WALK
		_play_animation("walk")
	elif move_state == MoveState.WALK_START:
		move_state = MoveState.WALK
		_play_animation("walk")

func _uses_run_speed() -> bool:
	return move_state in [MoveState.RUN_START, MoveState.RUN, MoveState.RUN_TURN]

func _is_light_attack_state() -> bool:
	return move_state in [
		MoveState.LIGHT_ATTACK_1,
		MoveState.LIGHT_ATTACK_2,
		MoveState.LIGHT_ATTACK_3,
		MoveState.LIGHT_ATTACK_4,
		MoveState.LIGHT_ATTACK_5,
		MoveState.JUMP_ATTACK_1,
		MoveState.JUMP_ATTACK_2,
	]

func _can_start_double_jump() -> bool:
	return move_state in [MoveState.JUMP, MoveState.JUMP_ATTACK_1, MoveState.JUMP_ATTACK_2]

func _can_start_air_dash() -> bool:
	return move_state in [MoveState.JUMP, MoveState.DOUBLE_JUMP, MoveState.JUMP_ATTACK_1, MoveState.JUMP_ATTACK_2]

func _get_current_speed() -> float:
	if move_state in [MoveState.JUMP, MoveState.DOUBLE_JUMP]:
		return jump_horizontal_speed
	if move_state == MoveState.AIR_DASH:
		return air_dash_speed
	if move_state == MoveState.SLIDE:
		return SLIDE_SPEED
	if move_state == MoveState.BACK_DODGE:
		return BACK_DODGE_SPEED
	if move_state == MoveState.HURT:
		return 0.0
	if move_state == MoveState.HEAL:
		return 0.0
	if move_state == MoveState.ROLL_LAND:
		return RUN_SPEED
	if move_state == MoveState.LIGHT_ATTACK_1:
		return LIGHT_ATTACK_1_LUNGE_SPEED
	if move_state == MoveState.LIGHT_ATTACK_2:
		return LIGHT_ATTACK_2_LUNGE_SPEED
	if move_state == MoveState.LIGHT_ATTACK_3:
		return LIGHT_ATTACK_3_LUNGE_SPEED
	if move_state == MoveState.LIGHT_ATTACK_4:
		return LIGHT_ATTACK_4_LUNGE_SPEED
	if move_state == MoveState.LIGHT_ATTACK_5:
		return LIGHT_ATTACK_5_LUNGE_SPEED
	if move_state == MoveState.JUMP_ATTACK_1:
		return jump_attack_1_speed
	if move_state == MoveState.JUMP_ATTACK_2:
		return 0.0
	if _uses_run_speed():
		return RUN_SPEED
	return WALK_SPEED

func _set_visual_offset(animation_name: StringName) -> void:
	if VISUAL_OFFSETS.has(animation_name):
		visual.position = VISUAL_OFFSETS[animation_name]

func _force_play_animation(animation_name: StringName) -> void:
	_set_visual_offset(animation_name)
	visual.stop()
	visual.animation = animation_name
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.speed_scale = 1.0
	visual.play()

func _setup_idle_animation() -> void:
	var frames := visual.sprite_frames
	if frames.has_animation("idle"):
		frames.set_animation_loop("idle", true)
		frames.set_animation_speed("idle", 1000.0 / 60.0)

func _setup_walk_animations() -> void:
	var frames := visual.sprite_frames
	var texture := load("res://assets/characters/player_01/walk/sprite sheets/from idle.png")
	_rebuild_animation("walk_start")
	frames.set_animation_loop("walk_start", false)
	frames.set_animation_speed("walk_start", 20.0)
	for frame_index in range(2):
		frames.add_frame("walk_start", _make_atlas_texture(texture, frame_index, 2, Vector2i(45, 58)))

	if frames.has_animation("walk"):
		frames.set_animation_loop("walk", true)
		frames.set_animation_speed("walk", 20.0)

func _setup_run_animation() -> void:
	var frames := visual.sprite_frames
	if frames.has_animation("run"):
		frames.set_animation_loop("run", true)
		frames.set_animation_speed("run", 1000.0 / 35.0)
	if frames.has_animation("run_start"):
		frames.set_animation_loop("run_start", false)
		frames.set_animation_speed("run_start", 10.0)

	var run_stop_texture := load("res://assets/characters/player_01/run/sprite sheets/run_stop.png")
	_rebuild_animation("run_stop")
	frames.set_animation_loop("run_stop", false)
	frames.set_animation_speed("run_stop", 25.0)
	for frame_index in range(15):
		frames.add_frame("run_stop", _make_atlas_texture(run_stop_texture, frame_index, 4, Vector2i(63, 53)))

	var run_turn_texture := load("res://assets/characters/player_01/run/sprite sheets/run_turn.png")
	_rebuild_animation("run_turn")
	frames.set_animation_loop("run_turn", false)
	frames.set_animation_speed("run_turn", 25.0)
	for frame_index in range(8):
		frames.add_frame("run_turn", _make_atlas_texture(run_turn_texture, frame_index, 4, Vector2i(59, 51)))

func _setup_jump_animation() -> void:
	var frames := visual.sprite_frames
	if frames.has_animation("jump"):
		frames.set_animation_loop("jump", false)
		frames.set_animation_speed("jump", 1000.0 / 60.0)

	var double_jump_texture := load("res://assets/characters/player_01/jump/sprite sheets/double jump_vertical.png")
	_rebuild_animation("double_jump_vertical")
	frames.set_animation_loop("double_jump_vertical", false)
	frames.set_animation_speed("double_jump_vertical", 1.0 / DOUBLE_JUMP_FRAME_TIME)
	for frame_index in range(7):
		frames.add_frame("double_jump_vertical", _make_atlas_texture(double_jump_texture, frame_index, 7, Vector2i(80, 80)))

	var double_jump_forward_texture := load("res://assets/characters/player_01/jump/sprite sheets/double jump_forward.png")
	_rebuild_animation("double_jump_forward")
	frames.set_animation_loop("double_jump_forward", false)
	frames.set_animation_speed("double_jump_forward", 1.0 / DOUBLE_JUMP_FRAME_TIME)
	for frame_index in range(7):
		frames.add_frame("double_jump_forward", _make_atlas_texture(double_jump_forward_texture, frame_index, 7, Vector2i(80, 80)))

	var roll_landing_texture := load("res://assets/characters/player_01/jump/sprite sheets/roll landing.png")
	_rebuild_animation("roll_landing")
	frames.set_animation_loop("roll_landing", false)
	frames.set_animation_speed("roll_landing", 1.0 / ROLL_LAND_FRAME_TIME)
	for frame_index in range(9):
		frames.add_frame("roll_landing", _make_atlas_texture(roll_landing_texture, frame_index, 9, Vector2i(79, 64)))

func _setup_air_dash_animation() -> void:
	var frames := visual.sprite_frames
	var dash_texture := load("res://assets/characters/player_01/aerial dash/sprite sheets/aerial dash.png")
	_rebuild_animation("air_dash")
	frames.set_animation_loop("air_dash", false)
	frames.set_animation_speed("air_dash", 1.0 / AIR_DASH_FRAME_TIME)
	for frame_index in range(6):
		frames.add_frame("air_dash", _make_atlas_texture(dash_texture, frame_index, 6, Vector2i(104, 50)))

	var smoke_texture := load("res://assets/characters/player_01/aerial dash/sprite sheets/aerial dash_smoke.png")
	_rebuild_animation("air_dash_smoke")
	frames.set_animation_loop("air_dash_smoke", false)
	frames.set_animation_speed("air_dash_smoke", 1.0 / AIR_DASH_FRAME_TIME)
	for frame_index in range(6):
		frames.add_frame("air_dash_smoke", _make_atlas_texture(smoke_texture, frame_index, 6, Vector2i(443, 160)))

	var fx_texture := load("res://assets/characters/player_01/aerial dash/sprite sheets/aerial dash_fx.png")
	_rebuild_animation("air_dash_fx")
	frames.set_animation_loop("air_dash_fx", false)
	frames.set_animation_speed("air_dash_fx", 1.0 / AIR_DASH_FRAME_TIME)
	for frame_index in range(5):
		frames.add_frame("air_dash_fx", _make_atlas_texture(fx_texture, frame_index, 5, Vector2i(61, 47)))

func _setup_crouch_animation() -> void:
	var frames := visual.sprite_frames
	var texture := load("res://assets/characters/player_01/crouching/sprite sheets/crouching.png")
	_rebuild_animation("crouch")
	frames.set_animation_loop("crouch", false)
	frames.set_animation_speed("crouch", 1000.0 / 70.0)
	for frame_index in range(13):
		frames.add_frame("crouch", _make_atlas_texture(texture, frame_index, 3, Vector2i(53, 50)))

func _setup_slide_animation() -> void:
	var frames := visual.sprite_frames
	if frames.has_animation("slide"):
		frames.set_animation_loop("slide", false)
		frames.set_animation_speed("slide", 25.0)
	if frames.has_animation("slide_fx"):
		frames.set_animation_loop("slide_fx", false)
		frames.set_animation_speed("slide_fx", 25.0)

func _start_run_turn(direction: float) -> void:
	run_turn_target_direction = int(sign(direction))
	move_state = MoveState.RUN_TURN
	_set_visual_offset("run_turn")
	visual.stop()
	visual.animation = "run_turn"
	visual.frame = 0
	visual.frame_progress = 0.0
	visual.speed_scale = 1.0
	visual.flip_h = facing > 0
	visual.play()

func _finish_run_turn() -> void:
	facing = run_turn_target_direction
	run_turn_target_direction = 0
	move_state = MoveState.RUN
	visual.flip_h = facing > 0
	_play_animation("run")

func _setup_back_dodge_animations() -> void:
	var frames := visual.sprite_frames
	var texture := load("res://assets/characters/player_01/back dodge/sprite sheets/back dodge(fx included).png")
	_rebuild_animation("back_dodge")
	frames.set_animation_loop("back_dodge", false)
	frames.set_animation_speed("back_dodge", 1000.0 / 35.0)
	for frame_index in range(24):
		frames.add_frame("back_dodge", _make_atlas_texture(texture, frame_index, 4, Vector2i(142, 61)))

func _setup_hurt_animations() -> void:
	var frames := visual.sprite_frames
	var normal_texture := load("res://assets/characters/player_01/hurt/sprite sheets/normal hit.png")
	var hard_texture := load("res://assets/characters/player_01/hurt/sprite sheets/hard hit.png")

	_rebuild_animation("hit")
	frames.set_animation_loop("hit", false)
	frames.set_animation_speed("hit", 25.0)
	for frame_index in range(10):
		frames.add_frame("hit", _make_atlas_texture(normal_texture, frame_index, 4, Vector2i(70, 60)))

	_rebuild_animation("normal_hit")
	frames.set_animation_loop("normal_hit", false)
	frames.set_animation_speed("normal_hit", 25.0)
	for frame_index in range(22):
		frames.add_frame("normal_hit", _make_atlas_texture(normal_texture, frame_index, 4, Vector2i(70, 60)))

	_rebuild_animation("hard_hit")
	frames.set_animation_loop("hard_hit", false)
	frames.set_animation_speed("hard_hit", 25.0)
	for frame_index in range(34):
		frames.add_frame("hard_hit", _make_atlas_texture(hard_texture, frame_index, 6, Vector2i(79, 60)))

func _setup_heal_animation() -> void:
	var frames := visual.sprite_frames
	var texture := load("res://assets/characters/player_01/healing/sprite sheets/healing_merged.png")
	_rebuild_animation("heal")
	frames.set_animation_loop("heal", false)
	frames.set_animation_speed("heal", 1000.0 / 60.0)
	for frame_index in range(18):
		frames.add_frame("heal", _make_atlas_texture(texture, frame_index, 3, Vector2i(97, 81)))

func _setup_light_attack_animations() -> void:
	var frames := visual.sprite_frames
	var attack_1_texture := load("res://assets/characters/player_01/atk/1x atk/sprite sheets/1x atk_merged.png")
	_rebuild_animation("light_attack_1")
	frames.set_animation_loop("light_attack_1", false)
	frames.set_animation_speed("light_attack_1", 25.0)
	for frame_index in range(17):
		frames.add_frame("light_attack_1", _make_atlas_texture(attack_1_texture, frame_index, 4, Vector2i(160, 64)))

	var attack_2_texture := load("res://assets/characters/player_01/atk/2x atk/sprite sheets/2x atk_merged(short).png")
	_rebuild_animation("light_attack_2")
	frames.set_animation_loop("light_attack_2", false)
	frames.set_animation_speed("light_attack_2", 25.0)
	for frame_index in range(19):
		frames.add_frame("light_attack_2", _make_atlas_texture(attack_2_texture, frame_index, 4, Vector2i(192, 64)))

	var attack_3_texture := load("res://assets/characters/player_01/atk/2x-1 atk/sprite sheets/2x-1 atk_merged.png")
	_rebuild_animation("light_attack_3")
	frames.set_animation_loop("light_attack_3", false)
	frames.set_animation_speed("light_attack_3", 25.0)
	for frame_index in range(6):
		frames.add_frame("light_attack_3", _make_atlas_texture(attack_3_texture, frame_index, 3, Vector2i(139, 75)))

	var attack_4_texture := load("res://assets/characters/player_01/atk/2x-2 atk/sprite sheets/2x-2 atk_merged.png")
	_rebuild_animation("light_attack_4")
	frames.set_animation_loop("light_attack_4", false)
	frames.set_animation_speed("light_attack_4", 25.0)
	for frame_index in range(10):
		frames.add_frame("light_attack_4", _make_atlas_texture(attack_4_texture, frame_index, 3, Vector2i(139, 75)))

	var attack_5_texture := load("res://assets/characters/player_01/atk/3x atk/sprite sheets/3x atk_merged.png")
	_rebuild_animation("light_attack_5")
	frames.set_animation_loop("light_attack_5", false)
	frames.set_animation_speed("light_attack_5", 1000.0 / 35.0)
	for frame_index in range(34):
		frames.add_frame("light_attack_5", _make_atlas_texture(attack_5_texture, frame_index, 4, Vector2i(222, 94)))

	var jump_attack_1_texture := load("res://assets/characters/player_01/jump attack/jump atk 1x/sprite sheets/jump attack 1x_merged.png")
	_rebuild_animation("jump_attack_1")
	frames.set_animation_loop("jump_attack_1", false)
	frames.set_animation_speed("jump_attack_1", 1.0 / JUMP_ATTACK_1_FRAME_TIME)
	for frame_index in range(9):
		frames.add_frame("jump_attack_1", _make_atlas_texture(jump_attack_1_texture, frame_index, 4, Vector2i(128, 69)))

	var jump_attack_2_texture := load("res://assets/characters/player_01/jump attack/jump atk 2x/sprite sheets/jump atk 2x_merged.png")
	_rebuild_animation("jump_attack_2")
	frames.set_animation_loop("jump_attack_2", false)
	frames.set_animation_speed("jump_attack_2", 1.0 / JUMP_ATTACK_2_FRAME_TIME)
	for frame_index in range(8):
		frames.add_frame("jump_attack_2", _make_atlas_texture(jump_attack_2_texture, frame_index, 4, Vector2i(100, 112)))

func _rebuild_animation(animation_name: StringName) -> void:
	var frames := visual.sprite_frames
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)

func _make_atlas_texture(texture: Texture2D, frame_index: int, columns: int, frame_size: Vector2i) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	var column := frame_index % columns
	var row := frame_index / columns
	atlas_texture.atlas = texture
	atlas_texture.region = Rect2(column * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
	return atlas_texture

func _can_start_back_dodge() -> bool:
	return move_state in [
		MoveState.IDLE,
		MoveState.WALK_START,
		MoveState.WALK,
		MoveState.RUN_START,
		MoveState.RUN,
		MoveState.RUN_TO_WALK,
		MoveState.RUN_STOP,
	]

func _can_start_heal() -> bool:
	return move_state in [MoveState.IDLE, MoveState.WALK, MoveState.RUN_STOP]

func _can_start_light_attack_1() -> bool:
	return move_state in [
		MoveState.IDLE,
		MoveState.WALK_START,
		MoveState.WALK,
		MoveState.RUN_START,
		MoveState.RUN,
		MoveState.RUN_STOP,
	]

func _handle_light_attack_input() -> bool:
	if not is_on_floor():
		if Input.is_action_pressed("move_up") and _can_start_jump_attack_2():
			_start_jump_attack_2()
			return true
		if _can_start_jump_attack_1():
			_start_jump_attack_1()
			return true
		return false

	if move_state == MoveState.LIGHT_ATTACK_1:
		light_attack_2_queued = true
		return true

	if move_state == MoveState.LIGHT_ATTACK_2:
		light_attack_3_queued = true
		return true

	if move_state == MoveState.LIGHT_ATTACK_3:
		light_attack_5_queued = true
		return true

	if move_state == MoveState.LIGHT_ATTACK_4:
		light_attack_5_queued = true
		return true

	if light_attack_combo_step == 3 and light_attack_combo_timer > 0.0 and _can_start_light_attack_1():
		_start_light_attack_5()
		return true

	if light_attack_combo_step == 2 and light_attack_combo_timer > 0.0 and _can_start_light_attack_1():
		_start_light_attack_3()
		return true

	if light_attack_combo_step == 1 and light_attack_combo_timer > 0.0 and _can_start_light_attack_1():
		_start_light_attack_2()
		return true

	if _can_start_light_attack_1():
		_start_light_attack_1()
		return true

	return false

func _update_light_attack_combo_timer(delta: float) -> void:
	if light_attack_combo_timer <= 0.0:
		light_attack_combo_timer = 0.0
		return

	light_attack_combo_timer -= delta
	if light_attack_combo_timer <= 0.0:
		light_attack_combo_timer = 0.0
		light_attack_combo_step = 0

func _lock_light_attack_direction(use_input_direction := false) -> void:
	if use_input_direction:
		var direction := _get_input_direction()
		if direction != 0.0:
			facing = int(sign(direction))

	light_attack_direction = facing
	if light_attack_direction == 0:
		light_attack_direction = 1

func _set_attack_hitbox_enabled(enabled: bool, attack_step := 0) -> void:
	attack_hit_box.monitoring = enabled
	attack_hit_box.monitorable = enabled
	if not enabled:
		light_attack_hit_targets.clear()
		return

	var offsets := ATTACK_HITBOX_OFFSETS_RIGHT if light_attack_direction > 0 else ATTACK_HITBOX_OFFSETS_LEFT
	if offsets.has(attack_step):
		attack_hit_shape.position = offsets[attack_step]
	var shape := attack_hit_shape.shape as RectangleShape2D
	if shape != null and ATTACK_HITBOX_SIZES.has(attack_step):
		shape.size = ATTACK_HITBOX_SIZES[attack_step]
	call_deferred("_process_attack_hitbox_overlaps")

func _refresh_attack_hitbox(attack_step: int, active: bool) -> void:
	if active:
		_set_attack_hitbox_enabled(true, attack_step)
	else:
		_set_attack_hitbox_enabled(false)

func _on_attack_hit_box_area_entered(area: Area2D) -> void:
	_try_hit_area(area)

func _process_attack_hitbox_overlaps() -> void:
	if not attack_hit_box.monitoring:
		return

	for area in attack_hit_box.get_overlapping_areas():
		_try_hit_area(area)

func _try_hit_area(area: Area2D) -> void:
	var target := _find_hit_target(area)
	if target == null or light_attack_hit_targets.has(target):
		return

	if target.has_method("take_hit"):
		light_attack_hit_targets.append(target)
		target.take_hit(global_position, light_attack_direction, _get_light_attack_damage(), area, attack_hit_shape.global_position)

func _get_light_attack_damage() -> int:
	if LIGHT_ATTACK_DAMAGE.has(light_attack_active_step):
		return LIGHT_ATTACK_DAMAGE[light_attack_active_step]
	return 1

func _find_hit_target(area: Area2D) -> Node:
	var node: Node = area
	while node != null:
		if node.has_method("take_hit"):
			return node
		node = node.get_parent()
	return null

func _enable_dodge_passthrough() -> void:
	_clear_dodge_passthrough()
	for node in get_tree().get_nodes_in_group("dodge_passthrough"):
		var body := node as PhysicsBody2D
		if body == null:
			continue

		add_collision_exception_with(body)
		dodge_collision_exceptions.append(body)

func _clear_dodge_passthrough() -> void:
	for body in dodge_collision_exceptions:
		if is_instance_valid(body):
			remove_collision_exception_with(body)
	dodge_collision_exceptions.clear()

func _get_input_direction() -> float:
	var left_pressed := Input.is_action_pressed("move_left")
	var right_pressed := Input.is_action_pressed("move_right")

	if left_pressed and right_pressed:
		return float(last_pressed_direction)
	if left_pressed:
		last_pressed_direction = -1
		return -1.0
	if right_pressed:
		last_pressed_direction = 1
		return 1.0

	last_pressed_direction = 0
	return 0.0

func _get_run_turn_direction(direction: float, wants_run: bool) -> int:
	if not wants_run:
		return 0
	if facing > 0 and Input.is_action_just_pressed("move_left"):
		return -1
	if facing < 0 and Input.is_action_just_pressed("move_right"):
		return 1
	if direction != 0.0 and int(sign(direction)) != facing:
		return int(sign(direction))
	return 0

func _get_ground_attack_lunge_direction(direction: float) -> float:
	if not _is_ground_attack_lunge_frame():
		return 0.0
	if direction != 0.0 and int(sign(direction)) == light_attack_direction:
		return float(light_attack_direction)
	return 0.0

func _is_ground_attack_lunge_frame() -> bool:
	if move_state == MoveState.LIGHT_ATTACK_1:
		return light_attack_1_frame <= 9
	if move_state == MoveState.LIGHT_ATTACK_2:
		return light_attack_2_frame <= 9
	if move_state == MoveState.LIGHT_ATTACK_5:
		return light_attack_5_frame <= 17
	return false

func _get_movement_direction(direction: float) -> float:
	if move_state in [MoveState.JUMP, MoveState.DOUBLE_JUMP]:
		return jump_direction
	if move_state == MoveState.AIR_DASH:
		return air_dash_direction
	if move_state == MoveState.CROUCH:
		return 0.0
	if move_state == MoveState.SLIDE:
		return slide_direction
	if move_state == MoveState.RUN_TURN:
		return float(run_turn_target_direction)
	if move_state == MoveState.BACK_DODGE:
		return back_dodge_direction
	if move_state == MoveState.HURT:
		return 0.0
	if move_state == MoveState.HEAL:
		return 0.0
	if move_state == MoveState.ROLL_LAND:
		return roll_landing_direction
	if move_state == MoveState.LIGHT_ATTACK_1:
		return _get_ground_attack_lunge_direction(direction)
	if move_state == MoveState.LIGHT_ATTACK_2:
		return _get_ground_attack_lunge_direction(direction)
	if move_state == MoveState.LIGHT_ATTACK_3:
		return _get_ground_attack_lunge_direction(direction)
	if move_state == MoveState.LIGHT_ATTACK_4:
		return _get_ground_attack_lunge_direction(direction)
	if move_state == MoveState.LIGHT_ATTACK_5:
		return _get_ground_attack_lunge_direction(direction)
	if move_state == MoveState.JUMP_ATTACK_1:
		return jump_attack_1_direction
	if move_state == MoveState.JUMP_ATTACK_2:
		return 0.0

	return direction

func _start_jump() -> void:
	_clear_slide_visuals()
	_clear_back_dodge_visuals()
	_clear_dodge_passthrough()
	var direction := _get_input_direction()
	move_state = MoveState.JUMP
	jump_phase = JumpPhase.PREPARE
	jump_timer = 0.0
	jump_frame = 0
	jump_direction = direction
	if jump_direction != 0.0:
		facing = int(sign(jump_direction))
	jump_horizontal_speed = RUN_SPEED if Input.is_action_pressed("run") and direction != 0.0 else WALK_SPEED
	can_double_jump = true
	can_air_dash = true
	used_double_jump = false
	used_forward_double_jump = false
	used_jump_attack = false
	jump_attack_count = 0
	jump_attack_1_direction = 0.0
	jump_attack_1_speed = 0.0
	_force_play_animation("jump")
	_set_jump_frame(0)

func _start_double_jump(direction: float) -> void:
	_set_attack_hitbox_enabled(false)
	move_state = MoveState.DOUBLE_JUMP
	can_double_jump = false
	used_double_jump = true
	used_jump_attack = false
	jump_attack_count = 0
	jump_attack_1_direction = 0.0
	jump_attack_1_speed = 0.0
	var wants_forward_double_jump := Input.is_action_pressed("run") and direction != 0.0
	used_forward_double_jump = wants_forward_double_jump
	if direction != 0.0:
		jump_horizontal_speed = RUN_SPEED if wants_forward_double_jump else WALK_SPEED
	double_jump_timer = 0.0
	double_jump_frame = 0
	if direction != 0.0:
		double_jump_animation = "double_jump_forward"
		jump_direction = direction
		facing = int(sign(direction))
	else:
		double_jump_animation = "double_jump_vertical"
		jump_direction = 0.0
	velocity.y = DOUBLE_JUMP_VELOCITY
	_force_play_animation(double_jump_animation)
	_set_double_jump_frame(double_jump_frame)

func _update_double_jump() -> void:
	double_jump_timer += get_physics_process_delta_time()
	if double_jump_timer < DOUBLE_JUMP_FRAME_TIME:
		return

	double_jump_timer = 0.0
	double_jump_frame += 1
	if double_jump_frame >= 7:
		move_state = MoveState.JUMP
		jump_phase = JumpPhase.UP
		jump_frame = 4
		jump_timer = 0.0
		_set_jump_frame(jump_frame)
		return

	_set_double_jump_frame(double_jump_frame)

func _set_double_jump_frame(frame_index: int) -> void:
	_set_visual_offset(double_jump_animation)
	visual.animation = double_jump_animation
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

func _start_air_dash(direction: float) -> void:
	_set_attack_hitbox_enabled(false)
	move_state = MoveState.AIR_DASH
	can_air_dash = false
	used_jump_attack = false
	jump_attack_count = 0
	jump_attack_1_direction = 0.0
	jump_attack_1_speed = 0.0
	air_dash_timer = 0.0
	air_dash_frame = 0
	air_dash_jump_buffered = false
	air_dash_direction = direction if direction != 0.0 else float(facing)
	air_dash_speed = AIR_DASH_RUN_SPEED if jump_horizontal_speed >= RUN_SPEED else AIR_DASH_WALK_SPEED
	facing = int(sign(air_dash_direction))
	jump_direction = air_dash_direction
	velocity.y = 0.0
	_enable_dodge_passthrough()
	_spawn_air_dash_smoke(global_position)
	_spawn_air_dash_fx(global_position)
	_set_air_dash_frame(air_dash_frame)

func _update_air_dash() -> void:
	if Input.is_action_just_pressed("jump") and not used_double_jump:
		air_dash_jump_buffered = true

	air_dash_timer += get_physics_process_delta_time()
	if air_dash_timer < AIR_DASH_FRAME_TIME:
		return

	air_dash_timer = 0.0
	air_dash_frame += 1
	if air_dash_frame >= 6:
		air_dash_direction = 0.0
		can_double_jump = not used_double_jump
		if air_dash_jump_buffered and can_double_jump:
			air_dash_jump_buffered = false
			_clear_dodge_passthrough()
			_start_double_jump(_get_input_direction())
			return
		air_dash_jump_buffered = false
		_clear_dodge_passthrough()
		move_state = MoveState.JUMP
		if velocity.y >= 0.0:
			jump_phase = JumpPhase.FALL
			jump_frame = 15
		else:
			jump_phase = JumpPhase.UP
			jump_frame = 4
		jump_timer = 0.0
		_set_jump_frame(jump_frame)
		return

	_set_air_dash_frame(air_dash_frame)

func _set_air_dash_frame(frame_index: int) -> void:
	_set_visual_offset("air_dash")
	visual.animation = "air_dash"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

func _spawn_air_dash_smoke(origin: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return

	if air_dash_smoke != null and is_instance_valid(air_dash_smoke):
		air_dash_smoke.queue_free()

	var smoke := AnimatedSprite2D.new()
	smoke.sprite_frames = visual.sprite_frames
	smoke.animation = "air_dash_smoke"
	smoke.centered = false
	smoke.top_level = true
	smoke.flip_h = facing > 0
	smoke.z_index = z_index - 1
	parent.add_child(smoke)
	air_dash_smoke = smoke
	air_dash_smoke_origin = origin
	air_dash_smoke_frame = 0
	air_dash_smoke_timer = 0.0
	_set_air_dash_smoke_frame(air_dash_smoke_frame)

func _update_air_dash_smoke(delta: float) -> void:
	if air_dash_smoke == null or not is_instance_valid(air_dash_smoke):
		return

	air_dash_smoke_timer += delta
	if air_dash_smoke_timer < AIR_DASH_FRAME_TIME:
		return

	air_dash_smoke_timer = 0.0
	air_dash_smoke_frame += 1
	if air_dash_smoke_frame >= 6:
		air_dash_smoke.queue_free()
		air_dash_smoke = null
		return

	_set_air_dash_smoke_frame(air_dash_smoke_frame)

func _set_air_dash_smoke_frame(frame_index: int) -> void:
	if air_dash_smoke == null or not is_instance_valid(air_dash_smoke):
		return

	air_dash_smoke.animation = "air_dash_smoke"
	air_dash_smoke.speed_scale = 0.0
	air_dash_smoke.frame = frame_index
	air_dash_smoke.frame_progress = 0.0
	air_dash_smoke.global_position = air_dash_smoke_origin + AIR_DASH_SMOKE_CENTER_OFFSET - _get_air_dash_smoke_anchor(frame_index, air_dash_smoke.flip_h)

func _get_air_dash_smoke_anchor(frame_index: int, flipped: bool) -> Vector2:
	var anchor := Vector2(289.12, 91.08)
	match frame_index:
		0:
			anchor = Vector2(289.12, 91.08)
		1:
			anchor = Vector2(284.81, 77.45)
		2:
			anchor = Vector2(281.48, 68.70)
		3:
			anchor = Vector2(283.74, 71.03)
		4:
			anchor = Vector2(287.98, 79.75)
		5:
			anchor = Vector2(291.85, 89.71)

	if flipped:
		anchor.x = AIR_DASH_SMOKE_FRAME_WIDTH - anchor.x

	return anchor

func _spawn_air_dash_fx(origin: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return

	if air_dash_fx != null and is_instance_valid(air_dash_fx):
		air_dash_fx.queue_free()

	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = visual.sprite_frames
	fx.animation = "air_dash_fx"
	fx.centered = false
	fx.top_level = true
	fx.flip_h = facing > 0
	fx.z_index = z_index - 1
	parent.add_child(fx)
	air_dash_fx = fx
	air_dash_fx_origin = origin
	air_dash_fx_frame = 0
	air_dash_fx_timer = 0.0
	_set_air_dash_fx_frame(air_dash_fx_frame)

func _update_air_dash_fx(delta: float) -> void:
	if air_dash_fx == null or not is_instance_valid(air_dash_fx):
		return

	air_dash_fx_timer += delta
	if air_dash_fx_timer < AIR_DASH_FRAME_TIME:
		return

	air_dash_fx_timer = 0.0
	air_dash_fx_frame += 1
	if air_dash_fx_frame >= 5:
		air_dash_fx.queue_free()
		air_dash_fx = null
		return

	_set_air_dash_fx_frame(air_dash_fx_frame)

func _set_air_dash_fx_frame(frame_index: int) -> void:
	if air_dash_fx == null or not is_instance_valid(air_dash_fx):
		return

	air_dash_fx.animation = "air_dash_fx"
	air_dash_fx.speed_scale = 0.0
	air_dash_fx.frame = frame_index
	air_dash_fx.frame_progress = 0.0
	air_dash_fx.global_position = air_dash_fx_origin + _get_air_dash_fx_offset(frame_index, air_dash_fx.flip_h)

func _get_air_dash_fx_offset(frame_index: int, flipped: bool) -> Vector2:
	if flipped:
		match frame_index:
			0:
				return Vector2(-10.5, -60.0)
			1:
				return Vector2(-9.5, -62.0)
			2:
				return Vector2(-8.5, -59.0)
			3:
				return Vector2(-10.5, -56.0)
			4:
				return Vector2(-11.5, -56.0)
			_:
				return Vector2(-10.5, -60.0)

	match frame_index:
		0:
			return Vector2(-49.5, -60.0)
		1:
			return Vector2(-50.5, -62.0)
		2:
			return Vector2(-51.5, -59.0)
		3:
			return Vector2(-49.5, -56.0)
		4:
			return Vector2(-48.5, -56.0)
		_:
			return Vector2(-49.5, -60.0)

func _update_jump(direction: float) -> void:
	if jump_phase != JumpPhase.LAND and jump_frame <= 19 and jump_direction == 0.0 and direction != 0.0:
		jump_direction = direction
		facing = int(sign(direction))
		jump_horizontal_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED

	match jump_phase:
		JumpPhase.PREPARE:
			_advance_jump_frames(0, 3, JUMP_PREPARE_FRAME_TIME)
			if jump_frame >= 3:
				velocity.y = JUMP_VELOCITY
				jump_phase = JumpPhase.UP
				jump_frame = 4
				jump_timer = 0.0
				_set_jump_frame(jump_frame)
		JumpPhase.UP:
			_advance_jump_loop(4, 9, JUMP_LOOP_FRAME_TIME)
			if velocity.y >= -80.0:
				jump_phase = JumpPhase.AIR
				jump_frame = 10
				jump_timer = 0.0
				_set_jump_frame(jump_frame)
		JumpPhase.AIR:
			_advance_jump_loop(10, 15, JUMP_LOOP_FRAME_TIME)
			if velocity.y > 80.0:
				jump_phase = JumpPhase.FALL
				jump_frame = 15
				jump_timer = 0.0
				_set_jump_frame(jump_frame)
		JumpPhase.FALL:
			_advance_jump_loop(15, 19, JUMP_LOOP_FRAME_TIME)
			if is_on_floor() and velocity.y >= 0.0:
				var landing_direction := jump_direction
				can_double_jump = false
				if used_double_jump and used_forward_double_jump:
					_start_roll_landing(landing_direction)
				else:
					jump_direction = 0.0
					jump_phase = JumpPhase.LAND
					jump_frame = 20
					jump_timer = 0.0
					move_state = MoveState.LAND
					_set_jump_frame(jump_frame)
		JumpPhase.LAND:
			pass

func _advance_jump_frames(start_frame: int, end_frame: int, frame_time: float) -> void:
	jump_timer += get_physics_process_delta_time()
	if jump_timer < frame_time:
		return

	jump_timer = 0.0
	jump_frame = min(jump_frame + 1, end_frame)
	_set_jump_frame(jump_frame)

func _advance_jump_loop(start_frame: int, end_frame: int, frame_time: float) -> void:
	jump_timer += get_physics_process_delta_time()
	if jump_timer < frame_time:
		return

	jump_timer = 0.0
	jump_frame += 1
	if jump_frame > end_frame:
		jump_frame = start_frame
	_set_jump_frame(jump_frame)

func _set_jump_frame(frame_index: int) -> void:
	_set_visual_offset("jump")
	visual.animation = "jump"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

func _start_roll_landing(landing_direction: float) -> void:
	move_state = MoveState.ROLL_LAND
	jump_phase = JumpPhase.LAND
	roll_landing_timer = 0.0
	roll_landing_frame = 0
	roll_landing_direction = landing_direction
	jump_direction = 0.0
	if roll_landing_direction != 0.0:
		facing = int(sign(roll_landing_direction))
	_set_roll_landing_frame(roll_landing_frame)

func _update_roll_landing() -> void:
	roll_landing_timer += get_physics_process_delta_time()
	if roll_landing_timer < ROLL_LAND_FRAME_TIME:
		return

	roll_landing_timer = 0.0
	roll_landing_frame += 1
	if roll_landing_frame >= 9:
		used_double_jump = false
		used_forward_double_jump = false
		roll_landing_direction = 0.0
		jump_phase = JumpPhase.NONE
		var direction := _get_input_direction()
		if Input.is_action_pressed("run") and direction != 0.0:
			move_state = MoveState.RUN
			_play_animation("run")
		else:
			_return_to_ground_state()
		return

	_set_roll_landing_frame(roll_landing_frame)

func _set_roll_landing_frame(frame_index: int) -> void:
	_set_visual_offset("roll_landing")
	visual.animation = "roll_landing"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

func _start_crouch() -> void:
	move_state = MoveState.CROUCH
	crouch_phase = CrouchPhase.ENTER
	crouch_timer = 0.0
	crouch_frame = 0
	_set_crouch_frame(crouch_frame)

func _update_crouch(wants_crouch: bool) -> void:
	if wants_crouch:
		if crouch_phase == CrouchPhase.EXIT:
			crouch_phase = CrouchPhase.ENTER
			crouch_frame = 0
			crouch_timer = 0.0
			_set_crouch_frame(crouch_frame)

		if crouch_phase == CrouchPhase.ENTER:
			_advance_crouch_enter()
		elif crouch_phase == CrouchPhase.IDLE:
			_advance_crouch_idle()
		return

	if crouch_phase != CrouchPhase.EXIT:
		crouch_phase = CrouchPhase.EXIT
		crouch_frame = 9
		crouch_timer = 0.0
		_set_crouch_frame(crouch_frame)
		return

	_advance_crouch_exit()

func _advance_crouch_enter() -> void:
	crouch_timer += get_physics_process_delta_time()
	if crouch_timer < CROUCH_FRAME_TIME:
		return

	crouch_timer = 0.0
	crouch_frame += 1
	if crouch_frame > 5:
		crouch_phase = CrouchPhase.IDLE
		crouch_frame = 6
	_set_crouch_frame(crouch_frame)

func _advance_crouch_idle() -> void:
	crouch_timer += get_physics_process_delta_time()
	if crouch_timer < CROUCH_FRAME_TIME:
		return

	crouch_timer = 0.0
	crouch_frame += 1
	if crouch_frame > 8:
		crouch_frame = 6
	_set_crouch_frame(crouch_frame)

func _advance_crouch_exit() -> void:
	crouch_timer += get_physics_process_delta_time()
	if crouch_timer < CROUCH_FRAME_TIME:
		return

	crouch_timer = 0.0
	crouch_frame += 1
	if crouch_frame > 12:
		crouch_phase = CrouchPhase.NONE
		_return_to_ground_state()
		return

	_set_crouch_frame(crouch_frame)

func _set_crouch_frame(frame_index: int) -> void:
	_set_visual_offset("crouch")
	visual.animation = "crouch"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

func _start_slide() -> void:
	move_state = MoveState.SLIDE
	slide_timer = 0.0
	slide_frame = 0
	slide_direction = float(facing)
	slide_input_locked = true
	_enable_dodge_passthrough()
	_set_slide_frame(slide_frame)

func _update_slide() -> void:
	slide_timer += get_physics_process_delta_time()
	if slide_timer < SLIDE_FRAME_TIME:
		return

	slide_timer = 0.0
	slide_frame += 1
	if slide_frame > 16:
		var direction := _get_input_direction()
		var wants_run := Input.is_action_pressed("run") and direction != 0.0
		slide_direction = 0.0
		velocity.x = direction * RUN_SPEED if wants_run else 0.0
		_hide_slide_fx()
		_clear_dodge_passthrough()
		_return_to_ground_state()
		return

	_set_slide_frame(slide_frame)

func _set_slide_frame(frame_index: int) -> void:
	_set_visual_offset("slide")
	visual.animation = "slide"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

	if frame_index >= 4 and frame_index <= 12:
		_set_slide_fx_frame(frame_index)
	else:
		_hide_slide_fx()

func _set_slide_fx_frame(frame_index: int) -> void:
	if VISUAL_OFFSETS.has("slide_fx"):
		slide_fx.position = VISUAL_OFFSETS["slide_fx"]
	slide_fx.visible = true
	slide_fx.animation = "slide_fx"
	slide_fx.speed_scale = 0.0
	slide_fx.frame = frame_index
	slide_fx.frame_progress = 0.0

func _hide_slide_fx() -> void:
	slide_fx.visible = false

func _clear_slide_visuals() -> void:
	slide_direction = 0.0
	_hide_slide_fx()
	_clear_dodge_passthrough()

func _start_back_dodge() -> void:
	_clear_slide_visuals()
	move_state = MoveState.BACK_DODGE
	back_dodge_timer = 0.0
	back_dodge_frame = 0
	back_dodge_direction = -float(facing)
	_enable_dodge_passthrough()
	_set_back_dodge_frame(back_dodge_frame)

func _update_back_dodge() -> void:
	back_dodge_timer += get_physics_process_delta_time()
	if back_dodge_timer < BACK_DODGE_FRAME_TIME:
		return

	back_dodge_timer = 0.0
	back_dodge_frame += 1
	if back_dodge_frame > 23:
		_clear_back_dodge_visuals()
		velocity.x = 0.0
		_clear_dodge_passthrough()
		_return_to_ground_state()
		return

	_set_back_dodge_frame(back_dodge_frame)

func _set_back_dodge_frame(frame_index: int) -> void:
	visual.position = BACK_DODGE_OFFSET_RIGHT if facing > 0 else BACK_DODGE_OFFSET_LEFT
	visual.animation = "back_dodge"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_hide_slide_fx()

func _clear_back_dodge_visuals() -> void:
	back_dodge_direction = 0.0
	_hide_slide_fx()
	_clear_dodge_passthrough()

func _try_start_test_hurt() -> bool:
	if not Input.is_action_pressed("hurt_modifier"):
		return false
	if Input.is_action_just_pressed("hurt_1"):
		_start_hurt("hit", 10)
		return true
	if Input.is_action_just_pressed("hurt_2"):
		_start_hurt("normal_hit", 22)
		return true
	if Input.is_action_just_pressed("hurt_3"):
		_start_hurt("hard_hit", 34)
		return true
	return false

func _start_hurt(animation_name: StringName, frame_count: int) -> void:
	_clear_slide_visuals()
	_clear_back_dodge_visuals()
	move_state = MoveState.HURT
	hurt_animation = animation_name
	hurt_frame_count = frame_count
	hurt_timer = 0.0
	hurt_frame = 0
	velocity.x = 0.0
	_set_hurt_frame(hurt_frame)

func _update_hurt() -> void:
	hurt_timer += get_physics_process_delta_time()
	if hurt_timer < HURT_FRAME_TIME:
		return

	hurt_timer = 0.0
	hurt_frame += 1
	if hurt_frame >= hurt_frame_count:
		hurt_animation = StringName()
		hurt_frame_count = 0
		_return_to_ground_state()
		return

	_set_hurt_frame(hurt_frame)

func _set_hurt_frame(frame_index: int) -> void:
	_set_visual_offset(hurt_animation)
	visual.animation = hurt_animation
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

func _start_heal() -> void:
	_clear_slide_visuals()
	_clear_back_dodge_visuals()
	move_state = MoveState.HEAL
	heal_timer = 0.0
	heal_frame = 0
	velocity.x = 0.0
	heal_sfx.stop()
	heal_sfx.play()
	_set_heal_frame(heal_frame)

func _update_heal() -> void:
	heal_timer += get_physics_process_delta_time()
	if heal_timer < HEAL_FRAME_TIME:
		return

	heal_timer = 0.0
	heal_frame += 1
	if heal_frame >= 18:
		_return_to_ground_state()
		return

	_set_heal_frame(heal_frame)

func _set_heal_frame(frame_index: int) -> void:
	_set_visual_offset("heal")
	visual.animation = "heal"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0

func _start_light_attack_1() -> void:
	_clear_slide_visuals()
	_clear_back_dodge_visuals()
	move_state = MoveState.LIGHT_ATTACK_1
	light_attack_1_timer = 0.0
	light_attack_1_frame = 0
	light_attack_2_queued = false
	light_attack_combo_timer = 0.0
	light_attack_combo_step = 0
	_lock_light_attack_direction(true)
	light_attack_active_step = 1
	velocity.x = 0.0
	light_attack_hit_targets.clear()
	_set_light_attack_1_frame(light_attack_1_frame)

func _update_light_attack_1() -> void:
	light_attack_1_timer += get_physics_process_delta_time()
	if light_attack_1_timer < LIGHT_ATTACK_1_FRAME_TIME:
		return

	light_attack_1_timer = 0.0
	light_attack_1_frame += 1
	if light_attack_1_frame >= 17:
		_set_attack_hitbox_enabled(false)
		if light_attack_2_queued:
			_start_light_attack_2()
			return
		light_attack_combo_step = 1
		light_attack_combo_timer = LIGHT_ATTACK_COMBO_WINDOW
		_return_to_ground_state()
		return

	_set_light_attack_1_frame(light_attack_1_frame)

func _set_light_attack_1_frame(frame_index: int) -> void:
	visual.position = LIGHT_ATTACK_1_OFFSET_RIGHT if facing > 0 else LIGHT_ATTACK_1_OFFSET_LEFT
	visual.animation = "light_attack_1"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_refresh_attack_hitbox(1, _is_light_attack_1_active_frame())

func _is_light_attack_1_active_frame() -> bool:
	return light_attack_1_frame == ATTACK_HITBOX_TRIGGER_FRAMES[1]

func _start_light_attack_2() -> void:
	move_state = MoveState.LIGHT_ATTACK_2
	light_attack_2_timer = 0.0
	light_attack_2_frame = 0
	light_attack_2_queued = false
	light_attack_3_queued = false
	light_attack_combo_timer = 0.0
	light_attack_combo_step = 0
	_lock_light_attack_direction()
	light_attack_active_step = 2
	velocity.x = 0.0
	light_attack_hit_targets.clear()
	_set_light_attack_2_frame(light_attack_2_frame)

func _update_light_attack_2() -> void:
	light_attack_2_timer += get_physics_process_delta_time()
	if light_attack_2_timer < LIGHT_ATTACK_2_FRAME_TIME:
		return

	light_attack_2_timer = 0.0
	light_attack_2_frame += 1
	if light_attack_2_frame >= 19:
		_set_attack_hitbox_enabled(false)
		if light_attack_3_queued:
			_start_light_attack_3()
			return
		light_attack_combo_step = 2
		light_attack_combo_timer = LIGHT_ATTACK_COMBO_WINDOW
		_return_to_ground_state()
		return

	_set_light_attack_2_frame(light_attack_2_frame)

func _set_light_attack_2_frame(frame_index: int) -> void:
	visual.position = LIGHT_ATTACK_2_OFFSET_RIGHT if facing > 0 else LIGHT_ATTACK_2_OFFSET_LEFT
	visual.animation = "light_attack_2"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_refresh_attack_hitbox(2, _is_light_attack_2_active_frame())

func _is_light_attack_2_active_frame() -> bool:
	return light_attack_2_frame == ATTACK_HITBOX_TRIGGER_FRAMES[2]

func _start_light_attack_3() -> void:
	move_state = MoveState.LIGHT_ATTACK_3
	light_attack_3_timer = 0.0
	light_attack_3_frame = 0
	light_attack_3_queued = false
	light_attack_5_queued = false
	light_attack_combo_timer = 0.0
	light_attack_combo_step = 0
	_lock_light_attack_direction()
	light_attack_active_step = 3
	velocity.x = 0.0
	light_attack_hit_targets.clear()
	_set_light_attack_3_frame(light_attack_3_frame)

func _update_light_attack_3() -> void:
	light_attack_3_timer += get_physics_process_delta_time()
	if light_attack_3_timer < LIGHT_ATTACK_3_FRAME_TIME:
		return

	light_attack_3_timer = 0.0
	light_attack_3_frame += 1
	if light_attack_3_frame >= 6:
		_set_attack_hitbox_enabled(false)
		_start_light_attack_4()
		return

	_set_light_attack_3_frame(light_attack_3_frame)

func _set_light_attack_3_frame(frame_index: int) -> void:
	visual.position = LIGHT_ATTACK_3_OFFSET_RIGHT if facing > 0 else LIGHT_ATTACK_3_OFFSET_LEFT
	visual.animation = "light_attack_3"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_refresh_attack_hitbox(3, _is_light_attack_3_active_frame())

func _is_light_attack_3_active_frame() -> bool:
	return light_attack_3_frame == ATTACK_HITBOX_TRIGGER_FRAMES[3]

func _start_light_attack_4() -> void:
	move_state = MoveState.LIGHT_ATTACK_4
	light_attack_4_timer = 0.0
	light_attack_4_frame = 0
	light_attack_combo_timer = 0.0
	light_attack_combo_step = 0
	_lock_light_attack_direction()
	light_attack_active_step = 4
	velocity.x = 0.0
	light_attack_hit_targets.clear()
	_set_light_attack_4_frame(light_attack_4_frame)

func _update_light_attack_4() -> void:
	light_attack_4_timer += get_physics_process_delta_time()
	if light_attack_4_timer < LIGHT_ATTACK_4_FRAME_TIME:
		return

	light_attack_4_timer = 0.0
	light_attack_4_frame += 1
	if light_attack_4_frame >= 10:
		_set_attack_hitbox_enabled(false)
		if light_attack_5_queued:
			_start_light_attack_5()
			return
		light_attack_combo_step = 3
		light_attack_combo_timer = LIGHT_ATTACK_COMBO_WINDOW
		_return_to_ground_state()
		return

	_set_light_attack_4_frame(light_attack_4_frame)

func _set_light_attack_4_frame(frame_index: int) -> void:
	visual.position = LIGHT_ATTACK_4_OFFSET_RIGHT if facing > 0 else LIGHT_ATTACK_4_OFFSET_LEFT
	visual.animation = "light_attack_4"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_refresh_attack_hitbox(4, _is_light_attack_4_active_frame())

func _is_light_attack_4_active_frame() -> bool:
	return light_attack_4_frame == ATTACK_HITBOX_TRIGGER_FRAMES[4]

func _start_light_attack_5() -> void:
	move_state = MoveState.LIGHT_ATTACK_5
	light_attack_5_timer = 0.0
	light_attack_5_frame = 0
	light_attack_5_queued = false
	light_attack_combo_timer = 0.0
	light_attack_combo_step = 0
	_lock_light_attack_direction()
	light_attack_active_step = 5
	velocity.x = 0.0
	light_attack_hit_targets.clear()
	_set_light_attack_5_frame(light_attack_5_frame)

func _update_light_attack_5() -> void:
	light_attack_5_timer += get_physics_process_delta_time()
	if light_attack_5_timer < LIGHT_ATTACK_5_FRAME_TIME:
		return

	light_attack_5_timer = 0.0
	light_attack_5_frame += 1
	if light_attack_5_frame >= 34:
		_set_attack_hitbox_enabled(false)
		light_attack_combo_timer = 0.0
		light_attack_combo_step = 0
		_return_to_ground_state()
		return

	_set_light_attack_5_frame(light_attack_5_frame)

func _set_light_attack_5_frame(frame_index: int) -> void:
	visual.position = LIGHT_ATTACK_5_OFFSET_RIGHT if facing > 0 else LIGHT_ATTACK_5_OFFSET_LEFT
	visual.animation = "light_attack_5"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_refresh_attack_hitbox(5, _is_light_attack_5_active_frame())

func _is_light_attack_5_active_frame() -> bool:
	return light_attack_5_frame == ATTACK_HITBOX_TRIGGER_FRAMES[5]

func _can_start_jump_attack_1() -> bool:
	return move_state in [MoveState.JUMP, MoveState.DOUBLE_JUMP, MoveState.AIR_DASH] and jump_attack_count in [0, 2]

func _capture_jump_attack_1_momentum() -> void:
	if jump_attack_count == 2:
		jump_attack_1_direction = 0.0
		jump_attack_1_speed = 0.0
		return

	if move_state == MoveState.AIR_DASH:
		jump_attack_1_direction = air_dash_direction
		jump_attack_1_speed = air_dash_speed
		return

	if move_state in [MoveState.JUMP, MoveState.DOUBLE_JUMP]:
		jump_attack_1_direction = jump_direction
		jump_attack_1_speed = jump_horizontal_speed
		return

	jump_attack_1_direction = 0.0
	jump_attack_1_speed = 0.0

func _start_jump_attack_1() -> void:
	_capture_jump_attack_1_momentum()
	if move_state == MoveState.AIR_DASH:
		air_dash_direction = 0.0
		air_dash_jump_buffered = false
		_clear_dodge_passthrough()
	move_state = MoveState.JUMP_ATTACK_1
	used_jump_attack = true
	jump_attack_count = 3 if jump_attack_count == 2 else 1
	jump_attack_1_timer = 0.0
	jump_attack_1_frame = 0
	_lock_light_attack_direction()
	light_attack_active_step = 6
	light_attack_hit_targets.clear()
	velocity.y = 0.0
	_set_attack_hitbox_enabled(false)
	_set_jump_attack_1_frame(jump_attack_1_frame)

func _update_jump_attack_1() -> void:
	jump_attack_1_timer += get_physics_process_delta_time()
	if jump_attack_1_timer < JUMP_ATTACK_1_FRAME_TIME:
		return

	jump_attack_1_timer = 0.0
	jump_attack_1_frame += 1
	if jump_attack_1_frame >= 9:
		_set_attack_hitbox_enabled(false)
		if is_on_floor():
			jump_phase = JumpPhase.LAND
			jump_frame = 20
			jump_timer = 0.0
			move_state = MoveState.LAND
			_set_jump_frame(jump_frame)
		else:
			move_state = MoveState.JUMP
			jump_phase = JumpPhase.FALL
			jump_frame = 15
			jump_timer = 0.0
			_set_jump_frame(jump_frame)
		return

	_set_jump_attack_1_frame(jump_attack_1_frame)

func _set_jump_attack_1_frame(frame_index: int) -> void:
	visual.position = JUMP_ATTACK_1_OFFSET_RIGHT if facing > 0 else JUMP_ATTACK_1_OFFSET_LEFT
	visual.animation = "jump_attack_1"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_refresh_attack_hitbox(6, _is_jump_attack_1_active_frame())

func _is_jump_attack_1_active_frame() -> bool:
	return jump_attack_1_frame == ATTACK_HITBOX_TRIGGER_FRAMES[6]

func _can_start_jump_attack_2() -> bool:
	return move_state in [MoveState.JUMP, MoveState.DOUBLE_JUMP, MoveState.AIR_DASH, MoveState.JUMP_ATTACK_1] and jump_attack_count == 1

func _start_jump_attack_2() -> void:
	if move_state == MoveState.AIR_DASH:
		air_dash_direction = 0.0
		air_dash_jump_buffered = false
		_clear_dodge_passthrough()
	_set_attack_hitbox_enabled(false)
	move_state = MoveState.JUMP_ATTACK_2
	used_jump_attack = true
	jump_attack_count = 2
	jump_attack_1_direction = 0.0
	jump_attack_1_speed = 0.0
	jump_attack_2_timer = 0.0
	jump_attack_2_frame = 0
	_lock_light_attack_direction()
	light_attack_active_step = 7
	light_attack_hit_targets.clear()
	velocity.y = 0.0
	_set_jump_attack_2_frame(jump_attack_2_frame)

func _update_jump_attack_2() -> void:
	jump_attack_2_timer += get_physics_process_delta_time()
	if jump_attack_2_timer < JUMP_ATTACK_2_FRAME_TIME:
		return

	jump_attack_2_timer = 0.0
	jump_attack_2_frame += 1
	if jump_attack_2_frame >= 8:
		_set_attack_hitbox_enabled(false)
		if is_on_floor():
			jump_phase = JumpPhase.LAND
			jump_frame = 20
			jump_timer = 0.0
			move_state = MoveState.LAND
			_set_jump_frame(jump_frame)
		else:
			move_state = MoveState.JUMP
			jump_phase = JumpPhase.FALL
			jump_frame = 15
			jump_timer = 0.0
			_set_jump_frame(jump_frame)
		return

	_set_jump_attack_2_frame(jump_attack_2_frame)

func _set_jump_attack_2_frame(frame_index: int) -> void:
	visual.position = JUMP_ATTACK_2_OFFSET_RIGHT if facing > 0 else JUMP_ATTACK_2_OFFSET_LEFT
	visual.animation = "jump_attack_2"
	visual.speed_scale = 0.0
	visual.frame = frame_index
	visual.frame_progress = 0.0
	_refresh_attack_hitbox(7, _is_jump_attack_2_active_frame())

func _is_jump_attack_2_active_frame() -> bool:
	return jump_attack_2_frame == ATTACK_HITBOX_TRIGGER_FRAMES[7]

func _update_landing() -> void:
	jump_timer += get_physics_process_delta_time()
	if jump_timer < JUMP_LAND_FRAME_TIME:
		return

	jump_timer = 0.0
	jump_frame += 1
	if jump_frame > 23:
		jump_phase = JumpPhase.NONE
		can_double_jump = false
		can_air_dash = false
		used_double_jump = false
		used_forward_double_jump = false
		used_jump_attack = false
		jump_attack_count = 0
		jump_attack_1_direction = 0.0
		jump_attack_1_speed = 0.0
		_return_to_ground_state()
		return

	_set_jump_frame(jump_frame)

func _return_to_ground_state() -> void:
	_set_attack_hitbox_enabled(false)
	_clear_dodge_passthrough()
	light_attack_active_step = 0
	var direction := _get_input_direction()
	var wants_run := Input.is_action_pressed("run") and direction != 0.0

	if wants_run:
		move_state = MoveState.RUN_START
		_play_animation("run_start")
	elif direction != 0.0:
		move_state = MoveState.WALK
		_play_animation("walk")
	else:
		move_state = MoveState.IDLE
		_play_animation("idle")
