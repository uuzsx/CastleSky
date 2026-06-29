extends Camera2D

@export var target_path: NodePath
@export var camera_offset := Vector2(0.0, -24.0)
@export var dead_zone := Vector2(90.0, 35.0)
@export var follow_speed := 6.0

@onready var target := get_node(target_path) as Node2D

func _ready() -> void:
	if target != null:
		global_position = target.global_position + camera_offset

func _process(delta: float) -> void:
	if target == null:
		return

	var target_position := target.global_position + camera_offset
	var distance := target_position - global_position
	var desired_position := global_position

	if abs(distance.x) > dead_zone.x:
		desired_position.x = target_position.x - sign(distance.x) * dead_zone.x

	if abs(distance.y) > dead_zone.y:
		desired_position.y = target_position.y - sign(distance.y) * dead_zone.y

	var smoothing := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired_position, smoothing)
