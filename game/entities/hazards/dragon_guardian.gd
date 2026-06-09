class_name DragonGuardian
extends FloorHazard

const PATROL_SPEED := 90.0

var patrol_left: float = 0.0
var patrol_right: float = 0.0
var _direction: float = 1.0
var _wing_time: float = 0.0

@onready var body: Polygon2D = $Body
@onready var wing_left: Polygon2D = $WingLeft
@onready var wing_right: Polygon2D = $WingRight
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	super._ready()
	add_to_group("dragon_guardian")
	_draw_dragon()


func get_hit_payload() -> Dictionary:
	return {
		"id": "dragon",
		"stun": 1.5,
		"time_penalty": 3.0,
		"message": "DRAGON SLAP!",
		"color": Color(1.0, 0.35, 0.25),
	}


func setup(patrol_left_x: float, patrol_right_x: float, y_pos: float) -> void:
	patrol_left = patrol_left_x
	patrol_right = patrol_right_x
	position = Vector2(patrol_left_x, y_pos)
	_direction = 1.0


func _process(delta: float) -> void:
	position.x += _direction * PATROL_SPEED * delta
	if position.x >= patrol_right:
		position.x = patrol_right
		_direction = -1.0
	elif position.x <= patrol_left:
		position.x = patrol_left
		_direction = 1.0

	_wing_time += delta * 8.0
	var flap := sin(_wing_time) * 0.35
	wing_left.rotation = -0.4 + flap
	wing_right.rotation = 0.4 - flap


func _draw_dragon() -> void:
	body.polygon = PackedVector2Array([
		Vector2(-28, -8),
		Vector2(28, -8),
		Vector2(36, 12),
		Vector2(10, 20),
		Vector2(-10, 20),
		Vector2(-36, 12),
	])
	body.color = Color(0.82, 0.18, 0.14)

	wing_left.polygon = PackedVector2Array([
		Vector2(-8, -4),
		Vector2(-38, -22),
		Vector2(-30, 4),
	])
	wing_left.color = Color(0.65, 0.12, 0.1)

	wing_right.polygon = PackedVector2Array([
		Vector2(8, -4),
		Vector2(38, -22),
		Vector2(30, 4),
	])
	wing_right.color = Color(0.65, 0.12, 0.1)
