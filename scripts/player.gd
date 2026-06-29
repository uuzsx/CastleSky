extends CharacterBody2D

enum MoveState {
	IDLE,
	WALK,
	RUN_START,
	RUN,
	RUN_TO_WALK,
	RUN_STOP,
	CROUCH,
	SLIDE,
	BACK_DODGE,
	HURT,
	HEAL,
	JUMP,
	LAND,
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

const WALK_SPEED := 130.0
const RUN_SPEED := 300.0
const GRAVITY := 1200.0
const JUMP_VELOCITY := -430.0
const JUMP_HORIZONTAL_SPEED := 180.0
const JUMP_PREPARE_FRAME_TIME := 0.06
const JUMP_LOOP_FRAME_TIME := 0.08
const JUMP_LAND_FRAME_TIME := 0.06
const CROUCH_FRAME_TIME := 0.07
const SLIDE_FRAME_TIME := 0.03
const SLIDE_SPEED := 360.0
const BACK_DODGE_FRAME_TIME := 0.02
const BACK_DODGE_SPEED := 260.0
const BACK_DODGE_OFFSET_LEFT := Vector2(-108.0, -67.0)
const BACK_DODGE_OFFSET_RIGHT := Vector2(-33.0, -67.0)
const HURT_FRAME_TIME := 0.04
const HEAL_FRAME_TIME := 0.05
const ACCELERATION := 1200.0
const FRICTION := 1600.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var slide_fx: AnimatedSprite2D = $SlideFx
@onready var heal_sfx: AudioStreamPlayer2D = $HealSfx

const VISUAL_OFFSETS := {
	"idle": Vector2(-20.6, -61.0),
	"walk": Vector2(-18.9, -64.0),
	"run": Vector2(-29.9, -52.8),
	"run_start": Vector2(-29.2, -59.0),
	"run_stop": Vector2(-30.2, -59.0),
	"crouch": Vector2(-26.5, -56.0),
	"slide": Vector2(-48.0, -69.0),
	"slide_fx": Vector2(-48.0, -69.0),
	"hit": Vector2(-25.6, -62.0),
	"normal_hit": Vector2(-25.6, -66.0),
	"hard_hit": Vector2(-32.6, -66.0),
	"heal": Vector2(-43.0, -86.0),
	"jump": Vector2(-31.5, -80.0),
}

var move_state := MoveState.IDLE
var jump_phase := JumpPhase.NONE
var jump_timer := 0.0
var jump_frame := 0
var jump_direction := 0.0
var crouch_phase := CrouchPhase.NONE
var crouch_timer := 0.0
var crouch_frame := 0
var slide_timer := 0.0
var slide_frame := 0
var slide_direction := 0.0
var slide_input_locked := false
var back_dodge_timer := 0.0
var back_dodge_frame := 0
var back_dodge_direction := 0.0
var hurt_timer := 0.0
var hurt_frame := 0
var hurt_frame_count := 0
var hurt_animation := StringName()
var heal_timer := 0.0
var heal_frame := 0
var facing := 1
var last_pressed_direction := 0

func _ready() -> void:
	_setup_back_dodge_animations()
	_setup_hurt_animations()
	_setup_heal_animation()
	visual.animation_finished.connect(_on_animation_finished)
	slide_fx.visible = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction := _get_input_direction()
	var wants_run := Input.is_action_pressed("run") and direction != 0.0
	var wants_crouch := Input.is_action_pressed("move_down") and is_on_floor()
	if not wants_crouch and move_state != MoveState.SLIDE:
		slide_input_locked = false
	if _try_start_test_hurt():
		pass
	elif Input.is_action_just_pressed("heal") and is_on_floor() and _can_start_heal():
		_start_heal()
	elif Input.is_action_just_pressed("back_dodge") and is_on_floor() and _can_start_back_dodge():
		_start_back_dodge()
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		_start_jump()
	else:
		_update_move_state(direction, wants_run, wants_crouch)

	var speed := _get_current_speed()
	var movement_direction := _get_movement_direction(direction)
	var target_velocity_x := movement_direction * speed

	if movement_direction != 0.0:
		velocity.x = move_toward(velocity.x, target_velocity_x, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if movement_direction != 0.0 and move_state != MoveState.BACK_DODGE:
		facing = int(sign(movement_direction))

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

	if move_state == MoveState.LAND:
		_update_landing()
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
		move_state = MoveState.WALK
	else:
		move_state = MoveState.IDLE

func _update_animation() -> void:
	match move_state:
		MoveState.IDLE:
			_play_animation("idle")
		MoveState.WALK:
			_play_animation("walk")
		MoveState.RUN:
			_play_animation("run")
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
		MoveState.JUMP:
			pass
		_:
			pass

func _on_animation_finished() -> void:
	if move_state == MoveState.RUN_START:
		move_state = MoveState.RUN
		_play_animation("run")
	elif move_state == MoveState.RUN_STOP:
		move_state = MoveState.IDLE
		_play_animation("idle")
	elif move_state == MoveState.RUN_TO_WALK:
		move_state = MoveState.WALK
		_play_animation("walk")

func _uses_run_speed() -> bool:
	return move_state in [MoveState.RUN_START, MoveState.RUN]

func _get_current_speed() -> float:
	if move_state == MoveState.JUMP:
		return JUMP_HORIZONTAL_SPEED
	if move_state == MoveState.SLIDE:
		return SLIDE_SPEED
	if move_state == MoveState.BACK_DODGE:
		return BACK_DODGE_SPEED
	if move_state == MoveState.HURT:
		return 0.0
	if move_state == MoveState.HEAL:
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

func _setup_back_dodge_animations() -> void:
	var frames := visual.sprite_frames
	if not frames.has_animation("back_dodge"):
		frames.add_animation("back_dodge")
		frames.set_animation_loop("back_dodge", false)
		frames.set_animation_speed("back_dodge", 24.0)
		var texture := load("res://assets/characters/player_01/back dodge/sprite sheets/back dodge(fx included).png")
		for frame_index in range(24):
			frames.add_frame("back_dodge", _make_atlas_texture(texture, frame_index, 4, Vector2i(142, 61)))

func _setup_hurt_animations() -> void:
	var frames := visual.sprite_frames
	var normal_texture := load("res://assets/characters/player_01/hurt/sprite sheets/normal hit.png")
	var hard_texture := load("res://assets/characters/player_01/hurt/sprite sheets/hard hit.png")

	_rebuild_animation("hit")
	frames.set_animation_loop("hit", false)
	frames.set_animation_speed("hit", 24.0)
	for frame_index in range(10):
		frames.add_frame("hit", _make_atlas_texture(normal_texture, frame_index, 4, Vector2i(70, 60)))

	_rebuild_animation("normal_hit")
	frames.set_animation_loop("normal_hit", false)
	frames.set_animation_speed("normal_hit", 24.0)
	for frame_index in range(22):
		frames.add_frame("normal_hit", _make_atlas_texture(normal_texture, frame_index, 4, Vector2i(70, 60)))

	_rebuild_animation("hard_hit")
	frames.set_animation_loop("hard_hit", false)
	frames.set_animation_speed("hard_hit", 24.0)
	for frame_index in range(34):
		frames.add_frame("hard_hit", _make_atlas_texture(hard_texture, frame_index, 6, Vector2i(79, 60)))

func _setup_heal_animation() -> void:
	var frames := visual.sprite_frames
	var texture := load("res://assets/characters/player_01/healing/sprite sheets/healing_merged.png")
	_rebuild_animation("heal")
	frames.set_animation_loop("heal", false)
	frames.set_animation_speed("heal", 24.0)
	for frame_index in range(18):
		frames.add_frame("heal", _make_atlas_texture(texture, frame_index, 3, Vector2i(97, 81)))

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
		MoveState.WALK,
		MoveState.RUN_START,
		MoveState.RUN,
		MoveState.RUN_TO_WALK,
		MoveState.RUN_STOP,
	]

func _can_start_heal() -> bool:
	return move_state in [MoveState.IDLE, MoveState.WALK, MoveState.RUN_STOP]

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

func _get_movement_direction(direction: float) -> float:
	if move_state == MoveState.JUMP:
		return jump_direction
	if move_state == MoveState.CROUCH:
		return 0.0
	if move_state == MoveState.SLIDE:
		return slide_direction
	if move_state == MoveState.BACK_DODGE:
		return back_dodge_direction
	if move_state == MoveState.HURT:
		return 0.0
	if move_state == MoveState.HEAL:
		return 0.0

	return direction

func _start_jump() -> void:
	_clear_slide_visuals()
	_clear_back_dodge_visuals()
	move_state = MoveState.JUMP
	jump_phase = JumpPhase.PREPARE
	jump_timer = 0.0
	jump_frame = 0
	jump_direction = 0.0
	_force_play_animation("jump")
	_set_jump_frame(0)

func _update_jump(direction: float) -> void:
	if jump_phase != JumpPhase.LAND and jump_frame <= 19 and jump_direction == 0.0 and direction != 0.0:
		jump_direction = direction
		facing = int(sign(direction))

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
				jump_phase = JumpPhase.LAND
				jump_frame = 20
				jump_timer = 0.0
				jump_direction = 0.0
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
	_set_slide_frame(slide_frame)

func _update_slide() -> void:
	slide_timer += get_physics_process_delta_time()
	if slide_timer < SLIDE_FRAME_TIME:
		return

	slide_timer = 0.0
	slide_frame += 1
	if slide_frame > 16:
		slide_direction = 0.0
		_hide_slide_fx()
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

func _start_back_dodge() -> void:
	_clear_slide_visuals()
	move_state = MoveState.BACK_DODGE
	back_dodge_timer = 0.0
	back_dodge_frame = 0
	back_dodge_direction = -float(facing)
	_set_back_dodge_frame(back_dodge_frame)

func _update_back_dodge() -> void:
	back_dodge_timer += get_physics_process_delta_time()
	if back_dodge_timer < BACK_DODGE_FRAME_TIME:
		return

	back_dodge_timer = 0.0
	back_dodge_frame += 1
	if back_dodge_frame > 23:
		_clear_back_dodge_visuals()
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

func _update_landing() -> void:
	jump_timer += get_physics_process_delta_time()
	if jump_timer < JUMP_LAND_FRAME_TIME:
		return

	jump_timer = 0.0
	jump_frame += 1
	if jump_frame > 23:
		jump_phase = JumpPhase.NONE
		_return_to_ground_state()
		return

	_set_jump_frame(jump_frame)

func _return_to_ground_state() -> void:
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
