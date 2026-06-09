class_name MineItem
extends Area2D

signal collected(item: MineItem)

@export var item_id: String = "gold_small"

var value: int = 50
var weight: float = 1.0
var radius: float = 14.0
var item_color: Color = Color.GOLD
var is_grabbed: bool = false

@onready var sprite: Polygon2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_type(item_id)
	_draw_shape()
	collision_layer = 2
	collision_mask = 0
	body_entered.connect(_on_body_entered)


func setup(id: String) -> void:
	item_id = id
	if is_inside_tree():
		_apply_type(id)
		_draw_shape()


func _apply_type(id: String) -> void:
	var data := LevelData.get_item_type(id)
	value = data["value"]
	weight = data["weight"]
	radius = data["radius"]
	item_color = data["color"]


func _draw_shape() -> void:
	var points: PackedVector2Array = []
	var sides := 12
	for i in sides:
		var angle := TAU * float(i) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	if item_id == "diamond":
		points = PackedVector2Array([
			Vector2(0, -radius),
			Vector2(radius * 0.7, 0),
			Vector2(0, radius),
			Vector2(-radius * 0.7, 0),
		])
	elif item_id == "bone":
		points = PackedVector2Array([
			Vector2(-radius, -radius * 0.3),
			Vector2(-radius * 0.4, -radius * 0.3),
			Vector2(-radius * 0.4, radius * 0.3),
			Vector2(-radius, radius * 0.3),
			Vector2(-radius * 0.6, 0),
			Vector2(radius * 0.6, 0),
			Vector2(radius, -radius * 0.3),
			Vector2(radius * 0.4, -radius * 0.3),
			Vector2(radius * 0.4, radius * 0.3),
			Vector2(radius, radius * 0.3),
		])
	elif item_id == "dynamite":
		points = PackedVector2Array([
			Vector2(-radius * 0.35, -radius),
			Vector2(radius * 0.35, -radius),
			Vector2(radius * 0.35, radius * 0.5),
			Vector2(radius * 0.15, radius),
			Vector2(-radius * 0.15, radius),
			Vector2(-radius * 0.35, radius * 0.5),
		])

	sprite.polygon = points
	sprite.color = item_color

	if collision.shape is CircleShape2D:
		(collision.shape as CircleShape2D).radius = radius


func grab() -> void:
	is_grabbed = true
	set_deferred("collision_layer", 0)
	set_deferred("monitoring", false)


func release_at(pos: Vector2) -> void:
	global_position = pos
	is_grabbed = false
	collision_layer = 2
	monitoring = true


func collect() -> void:
	collected.emit(self)
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	pass
