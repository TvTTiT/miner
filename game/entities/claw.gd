class_name Claw
extends Node2D

enum State { SWINGING, EXTENDING, RETRACTING }

signal item_delivered(item: MineItem)
signal chest_delivered(chest: TreasureChest)
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
var grabbed: Node2D = null
var base_angle: float = 0.0

var retract_multiplier := 1.0
var extend_multiplier := 1.0
var swing_multiplier := 1.0
var weight_resistance_multiplier := 1.0
var max_rope_multiplier := 1.0

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


func apply_upgrades(upgrade_ids: Array[String]) -> void:
	retract_multiplier = 1.0
	extend_multiplier = 1.0
	swing_multiplier = 1.0
	weight_resistance_multiplier = 1.0
	max_rope_multiplier = 1.0

	for upgrade_id in upgrade_ids:
		match upgrade_id:
			"quick_reel":
				retract_multiplier += 0.3
			"long_rope":
				max_rope_multiplier += 0.2
			"fast_swing":
				swing_multiplier += 0.25
			"light_touch":
				weight_resistance_multiplier += 0.25
			"steady_hand":
				extend_multiplier += 0.2


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
	swing_time += delta * SWING_SPEED * swing_multiplier
	rotation = sin(swing_time) * SWING_AMPLITUDE


func _process_extend(delta: float) -> void:
	rope_length += EXTEND_SPEED * extend_multiplier * delta
	if rope_length >= MAX_ROPE_LENGTH * max_rope_multiplier:
		_start_retract()


func _process_retract(delta: float) -> void:
	var speed := RETRACT_SPEED_BASE * retract_multiplier
	if grabbed is MineItem or grabbed is TreasureChest:
		var weight_factor := maxf(0.35, grabbed.weight - weight_resistance_multiplier * 0.5)
		speed /= weight_factor
	rope_length = maxf(40.0, rope_length - speed * delta)
	if grabbed:
		grabbed.global_position = claw_head.global_position
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
	if grabbed:
		var payload := grabbed
		grabbed = null
		if payload is MineItem:
			item_delivered.emit(payload)
		elif payload is TreasureChest:
			chest_delivered.emit(payload)
	state = State.SWINGING
	swing_time = 0.0
	state_changed.emit(state)


func _on_area_entered(area: Area2D) -> void:
	if state != State.EXTENDING or grabbed:
		return
	if area is MineItem or area is TreasureChest:
		grabbed = area
		area.grab()
		area.call_deferred("reparent", claw_head)
		area.call_deferred("set", "position", Vector2.ZERO)
		call_deferred("_start_retract")


func get_claw_tip_global() -> Vector2:
	return claw_head.global_position


func _update_visuals() -> void:
	var tip := Vector2(0, rope_length)
	rope.points = PackedVector2Array([Vector2.ZERO, tip])
	claw_head.position = tip

	var open := CLAW_OPEN_ANGLE
	if grabbed:
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
