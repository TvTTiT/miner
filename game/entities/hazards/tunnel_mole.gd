class_name TunnelMole
extends FloorHazard

const EXPOSE_TIME := 1.6
const HIDE_TIME := 2.4

var _state: String = "hidden"
var _timer: float = 0.0

@onready var mound: Polygon2D = $Mound
@onready var head: Polygon2D = $Head
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	super._ready()
	_draw_mole()
	_set_exposed(false)


func setup(x_pos: float, y_pos: float) -> void:
	position = Vector2(x_pos, y_pos)
	_timer = randf_range(0.0, HIDE_TIME * 0.5)


func get_hit_payload() -> Dictionary:
	return {
		"id": "mole",
		"stun": 1.8,
		"time_penalty": 2.5,
		"message": "MOLE BITE!",
		"color": Color(0.55, 0.38, 0.22),
	}


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return

	if _state == "hidden":
		_set_exposed(true)
		_state = "exposed"
		_timer = EXPOSE_TIME
	else:
		_set_exposed(false)
		_state = "hidden"
		_timer = HIDE_TIME + randf_range(-0.4, 0.6)


func _set_exposed(exposed: bool) -> void:
	collision.disabled = not exposed
	head.visible = exposed
	mound.modulate.a = 0.45 if exposed else 0.85
	head.position.y = -6.0 if exposed else 4.0


func _draw_mole() -> void:
	mound.polygon = PackedVector2Array([
		Vector2(-22, 8),
		Vector2(22, 8),
		Vector2(16, 18),
		Vector2(-16, 18),
	])
	mound.color = Color(0.38, 0.28, 0.18)

	head.polygon = PackedVector2Array([
		Vector2(-12, -4),
		Vector2(12, -4),
		Vector2(10, 10),
		Vector2(-10, 10),
	])
	head.color = Color(0.52, 0.36, 0.24)
