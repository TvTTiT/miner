class_name Claw
extends Node2D

enum State { SWINGING, EXTENDING, RETRACTING }

signal item_delivered(item: MineItem)
signal state_changed(state: State)

const SWING_SPEED := 1.8
const SWING_AMPLITUDE := 1.1
const EXTEND_SPEED := 320.0
const RETRACT_SPEED_BASE := 280.0
const MAX_ROPE_LENGTH := 480.0
const CLAW_OPEN_ANGLE := 0.35

@export var swing_enabled := true

var state: State = State.SWINGING
var swing_time: float = 0.0
var rope_length: float = 40.0
var grabbed_item: MineItem = null
var base_angle: float = 0.0

@onready var rope: Line2D = $Rope
@onready var claw_head: Node2D = $ClawHead
@onready var claw_left: Line2D = $ClawHead/ClawLeft
@onready var claw_right: Line2D = $ClawHead/ClawRight
@onready var claw_area: Area2D = $ClawHead/ClawArea


func _ready() -> void:
	claw_area.collision_layer = 1
	claw_area.collision_mask = 2
	claw_area.area_entered.connect(_on_area_entered)
	_update_visuals()


func _process(delta: float) -> void:
	match state:
		State.SWINGING:
			_process_swing(delta)
		State.EXTENDING:
			_process_extend(delta)
		State.RETRACTING:
			_process_retract(delta)
	_update_visuals()


func _process_swing(delta: float) -> void:
	if not swing_enabled:
		return
	swing_time += delta * SWING_SPEED
	rotation = sin(swing_time) * SWING_AMPLITUDE


func _process_extend(delta: float) -> void:
	rope_length += EXTEND_SPEED * delta
	if rope_length >= MAX_ROPE_LENGTH:
		_start_retract()


func _process_retract(delta: float) -> void:
	var speed := RETRACT_SPEED_BASE
	if grabbed_item:
		speed /= grabbed_item.weight
	rope_length = maxf(40.0, rope_length - speed * delta)
	if grabbed_item:
		grabbed_item.global_position = claw_head.global_position
	if rope_length <= 40.0:
		_finish_retract()


func fire() -> void:
	if not swing_enabled or state != State.SWINGING:
		return
	base_angle = rotation
	state = State.EXTENDING
	state_changed.emit(state)


func _start_retract() -> void:
	state = State.RETRACTING
	state_changed.emit(state)


func _finish_retract() -> void:
	if grabbed_item:
		var item := grabbed_item
		grabbed_item = null
		item_delivered.emit(item)
	state = State.SWINGING
	swing_time = 0.0
	state_changed.emit(state)


func _on_area_entered(area: Area2D) -> void:
	if state != State.EXTENDING or grabbed_item:
		return
	if area is MineItem:
		var item := area as MineItem
		grabbed_item = item
		item.grab()
		item.call_deferred("reparent", claw_head)
		item.call_deferred("set", "position", Vector2.ZERO)
		call_deferred("_start_retract")


func get_claw_tip_global() -> Vector2:
	return claw_head.global_position


func _update_visuals() -> void:
	var tip := Vector2(0, rope_length)
	rope.points = PackedVector2Array([Vector2.ZERO, tip])
	claw_head.position = tip

	var open := CLAW_OPEN_ANGLE
	if grabbed_item:
		open = 0.1

	claw_left.points = PackedVector2Array([
		Vector2(-6, 0),
		Vector2(-14, 18),
	])
	claw_right.points = PackedVector2Array([
		Vector2(6, 0),
		Vector2(14, 18),
	])
	claw_left.rotation = -open
	claw_right.rotation = open
