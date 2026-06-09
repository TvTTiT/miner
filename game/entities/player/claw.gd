class_name Claw
extends Node2D

enum State { SWINGING, EXTENDING, RETRACTING, STUNNED }

signal item_delivered(item: MineItem)
signal chest_delivered(chest: TreasureChest)
signal empty_retract
signal hazard_hit(payload: Dictionary)
signal state_changed(state: State)

const SWING_SPEED := 1.8
const SWING_AMPLITUDE := 1.1
const EXTEND_SPEED := 320.0
const RETRACT_SPEED_BASE := 280.0
const MAX_ROPE_LENGTH := 480.0
const CLAW_OPEN_ANGLE := 0.35
const PIERCE_JUNK_IDS: Array[String] = ["rock", "bone"]

@export var swing_enabled := true

var state: State = State.SWINGING
var swing_time: float = 0.0
var rope_length: float = 40.0
var grabbed: Node2D = null
var base_angle: float = 0.0
var stun_timer: float = 0.0

var retract_multiplier := 1.0
var extend_multiplier := 1.0
var swing_multiplier := 1.0
var weight_resistance_multiplier := 1.0
var max_rope_multiplier := 1.0

var _hook_style := "single"
var _rotary_speed := 0.0
var _pierce_junk := false
var _head_spin := 0.0
var _grab_radius_mult := 1.0
var _magnet_pull := 0.0
var _electric_pulse := 0.0
var _extra_areas: Array[Area2D] = []
var _extra_prongs: Array[Line2D] = []

@onready var rope: Line2D = $Rope
@onready var claw_head: Node2D = $ClawHead
@onready var claw_left: Line2D = $ClawHead/ClawLeft
@onready var claw_right: Line2D = $ClawHead/ClawRight
@onready var claw_area: Area2D = $ClawHead/ClawArea
@onready var claw_collision: CollisionShape2D = $ClawHead/ClawArea/CollisionShape2D


func _ready() -> void:
	claw_area.collision_layer = 1
	claw_area.collision_mask = 6
	claw_area.area_entered.connect(_on_area_entered)
	_update_visuals()


func apply_modifiers(mods: Dictionary) -> void:
	retract_multiplier = mods.get("retract_mult", 1.0)
	extend_multiplier = mods.get("extend_mult", 1.0)
	swing_multiplier = mods.get("swing_mult", 1.0)
	weight_resistance_multiplier = mods.get("weight_resist", 1.0)
	max_rope_multiplier = mods.get("rope_mult", 1.0)
	_hook_style = mods.get("hook_style", "single")
	_rotary_speed = mods.get("rotary_speed", 0.0)
	_pierce_junk = mods.get("pierce_junk", false)
	_grab_radius_mult = mods.get("grab_radius_mult", 1.0)
	_magnet_pull = mods.get("magnet_pull", 0.0)
	if _hook_style == "rotary" and _rotary_speed <= 0.0:
		_rotary_speed = 4.5
	if _hook_style == "electric":
		_electric_pulse = 0.0
	_rebuild_hook_layout()


func stun(duration: float) -> void:
	state = State.STUNNED
	stun_timer = duration
	state_changed.emit(state)


func _process(delta: float) -> void:
	match state:
		State.SWINGING:
			_process_swing(delta)
		State.EXTENDING:
			_process_extend(delta)
		State.RETRACTING:
			_process_retract(delta)
		State.STUNNED:
			stun_timer -= delta
			if stun_timer <= 0.0:
				state = State.SWINGING
				swing_time = 0.0
				state_changed.emit(state)

	if _rotary_speed > 0.0 and state != State.STUNNED:
		_head_spin += delta * _rotary_speed
		claw_head.rotation = _head_spin
	elif claw_head.rotation != 0.0:
		claw_head.rotation = move_toward(claw_head.rotation, 0.0, delta * 6.0)

	if _hook_style == "electric" and state != State.STUNNED:
		_electric_pulse += delta * 10.0

	if state == State.EXTENDING and _magnet_pull > 0.0:
		_apply_magnet_pull(delta)

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
	else:
		empty_retract.emit()
	state = State.SWINGING
	swing_time = 0.0
	state_changed.emit(state)


func _on_area_entered(area: Area2D) -> void:
	if state != State.EXTENDING or grabbed:
		return
	if _is_hazard(area):
		call_deferred("_handle_hazard_hit", area)
		return
	if area is MineItem and _should_pierce(area as MineItem):
		return
	if area is MineItem or area is TreasureChest:
		grabbed = area
		area.grab()
		area.call_deferred("reparent", claw_head)
		area.call_deferred("set", "position", Vector2.ZERO)
		call_deferred("_start_retract")


func _should_pierce(item: MineItem) -> bool:
	return _pierce_junk and item.item_id in PIERCE_JUNK_IDS


func _is_hazard(area: Area2D) -> bool:
	return area.is_in_group("floor_hazard")


func _handle_hazard_hit(area: Area2D) -> void:
	if state != State.EXTENDING:
		return
	_start_retract()
	var payload := {"id": "hazard", "stun": 1.5, "time_penalty": 3.0, "message": "OUCH!", "color": Color(1, 0.35, 0.25)}
	if area is FloorHazard:
		payload = (area as FloorHazard).get_hit_payload()
	elif area.has_method("get_hit_payload"):
		payload = area.get_hit_payload()
	hazard_hit.emit(payload)


func get_claw_tip_global() -> Vector2:
	return claw_head.global_position


func _rebuild_hook_layout() -> void:
	_clear_extra_hook_parts()
	_set_grab_radius(_grab_radius_mult)

	match _hook_style:
		"triple":
			_add_grab_area(Vector2(-20, 8), 0.85)
			_add_grab_area(Vector2(20, 8), 0.85)
			_add_prong(Vector2(-16, 0), -0.45)
			_add_prong(Vector2(16, 0), 0.45)
		"twin":
			_add_grab_area(Vector2(-26, 4), 0.9)
			_add_grab_area(Vector2(26, 4), 0.9)
			_add_prong(Vector2(-20, 0), -0.3)
			_add_prong(Vector2(20, 0), 0.3)
		"rotary":
			claw_left.default_color = Color(0.75, 0.55, 0.2)
			claw_right.default_color = Color(0.75, 0.55, 0.2)
		"piercer":
			claw_left.default_color = Color(0.85, 0.9, 0.95)
			claw_right.default_color = Color(0.85, 0.9, 0.95)
		"long":
			claw_left.default_color = Color(0.72, 0.58, 0.38)
			claw_right.default_color = Color(0.72, 0.58, 0.38)
			rope.width = 4.0
		"electric":
			claw_left.default_color = Color(0.35, 0.85, 1.0)
			claw_right.default_color = Color(0.55, 0.95, 1.0)
		"magnetic":
			claw_left.default_color = Color(0.55, 0.35, 0.85)
			claw_right.default_color = Color(0.75, 0.45, 0.95)
		_:
			claw_left.default_color = Color(0.55, 0.55, 0.6)
			claw_right.default_color = Color(0.55, 0.55, 0.6)
			rope.width = 3.0


func _clear_extra_hook_parts() -> void:
	for area in _extra_areas:
		area.queue_free()
	_extra_areas.clear()
	for prong in _extra_prongs:
		prong.queue_free()
	_extra_prongs.clear()


func _add_grab_area(offset: Vector2, radius_scale: float) -> void:
	var area := Area2D.new()
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0 * _grab_radius_mult * radius_scale
	shape_node.shape = circle
	area.position = offset
	area.collision_layer = 1
	area.collision_mask = 6
	area.add_child(shape_node)
	area.area_entered.connect(_on_area_entered)
	claw_head.add_child(area)
	_extra_areas.append(area)


func _add_prong(offset: Vector2, angle: float) -> void:
	var prong := Line2D.new()
	prong.width = 3.0
	prong.default_color = Color(0.6, 0.6, 0.65)
	prong.position = offset
	prong.rotation = angle
	prong.points = PackedVector2Array([Vector2(-4, 0), Vector2(-12, 16)])
	claw_head.add_child(prong)
	_extra_prongs.append(prong)


func _set_grab_radius(multiplier: float) -> void:
	if claw_collision and claw_collision.shape is CircleShape2D:
		(claw_collision.shape as CircleShape2D).radius = 12.0 * multiplier


func _update_visuals() -> void:
	var tip := Vector2(0, rope_length)
	rope.points = PackedVector2Array([Vector2.ZERO, tip])
	claw_head.position = tip

	var open := CLAW_OPEN_ANGLE
	if grabbed:
		open = 0.1
	if _hook_style == "piercer":
		open *= 0.55

	var prong_len := 18.0
	match _hook_style:
		"triple":
			prong_len = 14.0
		"long":
			prong_len = 28.0
		"electric":
			prong_len = 20.0
		"magnetic":
			prong_len = 19.0

	claw_left.points = PackedVector2Array([Vector2(-6, 0), Vector2(-14, prong_len)])
	claw_right.points = PackedVector2Array([Vector2(6, 0), Vector2(14, prong_len)])
	claw_left.rotation = -open
	claw_right.rotation = open

	if _hook_style == "electric":
		var glow := 0.65 + sin(_electric_pulse) * 0.35
		claw_left.default_color = Color(0.3, 0.75 + glow * 0.2, 1.0)
		claw_right.default_color = Color(0.5, 0.9, 1.0)


func _apply_magnet_pull(delta: float) -> void:
	var tip := claw_head.global_position
	var radius := 75.0 * _grab_radius_mult
	for node in get_tree().get_nodes_in_group("mine_item"):
		if not node is MineItem:
			continue
		var item := node as MineItem
		if item.is_grabbed:
			continue
		var dist := tip.distance_to(item.global_position)
		if dist > radius or dist < 4.0:
			continue
		var pull := _magnet_pull * 220.0 * delta
		item.global_position = item.global_position.move_toward(tip, pull)
