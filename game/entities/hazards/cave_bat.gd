class_name CaveBat
extends FloorHazard

const PATROL_SPEED := 140.0

var patrol_left: float = 0.0
var patrol_right: float = 0.0
var _direction: float = 1.0
var _flap_time: float = 0.0

@onready var body: Polygon2D = $Body
@onready var wing_left: Polygon2D = $WingLeft
@onready var wing_right: Polygon2D = $WingRight


func _ready() -> void:
	super._ready()
	_draw_bat()


func setup(patrol_left_x: float, patrol_right_x: float, y_pos: float) -> void:
	patrol_left = patrol_left_x
	patrol_right = patrol_right_x
	position = Vector2(patrol_left_x, y_pos)
	_direction = 1.0 if rng_rand_sign() > 0 else -1.0


func get_hit_payload() -> Dictionary:
	return {
		"id": "bat",
		"stun": 1.0,
		"time_penalty": 2.0,
		"message": "BAT SWARM!",
		"color": Color(0.75, 0.55, 1.0),
	}


func _process(delta: float) -> void:
	position.x += _direction * PATROL_SPEED * delta
	if position.x >= patrol_right:
		position.x = patrol_right
		_direction = -1.0
	elif position.x <= patrol_left:
		position.x = patrol_left
		_direction = 1.0

	_flap_time += delta * 14.0
	var flap := sin(_flap_time) * 0.5
	wing_left.rotation = -0.6 + flap
	wing_right.rotation = 0.6 - flap
	body.position.y = sin(_flap_time * 0.5) * 3.0


func _draw_bat() -> void:
	body.polygon = PackedVector2Array([
		Vector2(0, -6),
		Vector2(8, 2),
		Vector2(0, 10),
		Vector2(-8, 2),
	])
	body.color = Color(0.35, 0.28, 0.45)

	wing_left.polygon = PackedVector2Array([
		Vector2(-4, 0),
		Vector2(-26, -14),
		Vector2(-18, 6),
	])
	wing_left.color = Color(0.28, 0.22, 0.38)

	wing_right.polygon = PackedVector2Array([
		Vector2(4, 0),
		Vector2(26, -14),
		Vector2(18, 6),
	])
	wing_right.color = Color(0.28, 0.22, 0.38)


func rng_rand_sign() -> float:
	return 1.0 if randf() > 0.5 else -1.0
