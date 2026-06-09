class_name TreasureChest
extends Area2D

signal opened(chest: TreasureChest)

var weight: float = 2.2
var radius: float = 22.0
var is_grabbed: bool = false
var is_floor_reward: bool = false
var pulse_time: float = 0.0

@onready var body_sprite: Polygon2D = $Body
@onready var lid_sprite: Polygon2D = $Lid
@onready var lock_sprite: Polygon2D = $Lock
@onready var glow_sprite: Polygon2D = $Glow
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_draw_chest()
	if is_floor_reward:
		glow_sprite.color = Color(1.0, 0.85, 0.2, 0.45)


func _process(delta: float) -> void:
	if is_grabbed or is_floor_reward:
		return
	pulse_time += delta * 3.5
	var pulse := 0.85 + sin(pulse_time) * 0.15
	glow_sprite.scale = Vector2(pulse, pulse)
	glow_sprite.modulate.a = 0.25 + sin(pulse_time * 1.5) * 0.15


func setup_floor_reward() -> void:
	is_floor_reward = true
	if is_inside_tree():
		glow_sprite.color = Color(1.0, 0.85, 0.2, 0.45)


func grab() -> void:
	is_grabbed = true
	set_deferred("collision_layer", 0)
	set_deferred("monitoring", false)


func open_and_vanish() -> void:
	opened.emit(self)
	queue_free()


func _draw_chest() -> void:
	var w := radius * 1.1
	var h := radius * 0.95
	body_sprite.polygon = PackedVector2Array([
		Vector2(-w, -h * 0.2),
		Vector2(w, -h * 0.2),
		Vector2(w, h),
		Vector2(-w, h),
	])
	body_sprite.color = Color(0.55, 0.32, 0.12)

	lid_sprite.polygon = PackedVector2Array([
		Vector2(-w, -h * 0.55),
		Vector2(w, -h * 0.55),
		Vector2(w, -h * 0.2),
		Vector2(-w, -h * 0.2),
	])
	lid_sprite.color = Color(0.72, 0.45, 0.14)

	lock_sprite.polygon = PackedVector2Array([
		Vector2(-5, -h * 0.35),
		Vector2(5, -h * 0.35),
		Vector2(5, -h * 0.05),
		Vector2(-5, -h * 0.05),
	])
	lock_sprite.color = Color(0.95, 0.78, 0.2)

	glow_sprite.polygon = PackedVector2Array([
		Vector2(-w * 1.3, -h),
		Vector2(w * 1.3, -h),
		Vector2(w * 1.3, h * 1.2),
		Vector2(-w * 1.3, h * 1.2),
	])
	glow_sprite.color = Color(1.0, 0.75, 0.1, 0.3)

	if collision.shape is CircleShape2D:
		(collision.shape as CircleShape2D).radius = radius
