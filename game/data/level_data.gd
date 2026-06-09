class_name LevelData
extends RefCounted

const ITEM_TYPES: Array[Dictionary] = [
	{"id": "gold_small", "value": 50, "weight": 1.0, "radius": 14, "color": Color(1.0, 0.84, 0.0)},
	{"id": "gold_medium", "value": 100, "weight": 2.0, "radius": 22, "color": Color(0.95, 0.75, 0.0)},
	{"id": "gold_large", "value": 250, "weight": 4.0, "radius": 32, "color": Color(0.85, 0.65, 0.0)},
	{"id": "diamond", "value": 500, "weight": 0.8, "radius": 12, "color": Color(0.6, 0.9, 1.0)},
	{"id": "rock", "value": 11, "weight": 6.0, "radius": 26, "color": Color(0.45, 0.42, 0.38)},
	{"id": "bone", "value": 3, "weight": 2.5, "radius": 18, "color": Color(0.92, 0.88, 0.78)},
	{"id": "dynamite", "value": -150, "weight": 1.2, "radius": 16, "color": Color(0.92, 0.18, 0.12)},
	{"id": "cursed_idol", "value": -120, "weight": 1.8, "radius": 14, "color": Color(0.78, 0.55, 0.95)},
	{"id": "cursed_coin", "value": -60, "weight": 1.0, "radius": 14, "color": Color(0.95, 0.72, 0.15)},
]

const LANES: Array[float] = [0.14, 0.30, 0.50, 0.70, 0.86]
const MIN_SEPARATION := 0.07
const GOAL_VALUE_RATIO := 0.55
const VAULT_GOAL_RATIO := 0.65
const VAULT_TIME_PENALTY := 15.0


static func get_item_type(id: String) -> Dictionary:
	for item_type in ITEM_TYPES:
		if item_type["id"] == id:
			return item_type
	return ITEM_TYPES[0]


static func get_floor_goal(depth: int) -> int:
	return 180 + depth * 90 + int(depth * depth * 4)


static func roll_is_vault(depth: int, rng: RandomNumberGenerator) -> bool:
	return depth > 1 and rng.randf() < 0.07


static func compute_achievable_goal(layout: Array[Dictionary], depth: int, is_vault: bool = false) -> int:
	var positive_value := layout_positive_value(layout)
	var ratio := VAULT_GOAL_RATIO if is_vault else GOAL_VALUE_RATIO
	var from_spawn := int(positive_value * ratio)
	var cap := get_floor_goal(depth)
	return clampi(mini(from_spawn, cap), 100, cap)


static func layout_positive_value(layout: Array[Dictionary]) -> int:
	var total := 0
	for entry in layout:
		var id: String = entry.get("id", "")
		if id in ["chest", "dragon"]:
			continue
		var value: int = get_item_type(id)["value"]
		if value > 0:
			total += value
	return total


static func get_floor_time(depth: int, extra_time_stacks: int, is_vault: bool = false) -> float:
	var base := maxf(42.0, 65.0 - depth * 1.2)
	base += extra_time_stacks * 5.0
	if is_vault:
		base -= VAULT_TIME_PENALTY
	return maxf(30.0, base)


static func generate_floor_layout(
	depth: int,
	rng: RandomNumberGenerator,
	gold_rush_stacks: int,
	prospector_stacks: int,
	is_vault: bool = false,
) -> Array[Dictionary]:
	if is_vault:
		return generate_vault_layout(depth, rng, prospector_stacks)

	var layout: Array[Dictionary] = []
	var min_spawn_value := int(get_floor_goal(depth) * 1.35)

	var lanes := LANES.duplicate()
	_shuffle_array(lanes, rng)
	var lane_count := clampi(4 + depth / 4, 4, lanes.size())
	var items_per_lane := clampi(2 + depth / 3 + gold_rush_stacks, 2, 4)

	for lane_slot in lane_count:
		var lane_x: float = lanes[lane_slot]
		var lane_x_jitter := rng.randf_range(-0.03, 0.03)
		var start_y := rng.randf_range(0.56, 0.64)
		for stack_index in items_per_lane:
			var y := start_y + stack_index * rng.randf_range(0.11, 0.15)
			y = clampf(y, 0.55, 0.93)
			var pos := Vector2(clampf(lane_x + lane_x_jitter, 0.08, 0.92), y)
			if not _is_position_clear(pos, layout):
				pos.y = clampf(pos.y + MIN_SEPARATION, 0.55, 0.93)
				if not _is_position_clear(pos, layout):
					continue
			var item_id := _pick_vein_item(stack_index, items_per_lane - 1, depth, rng, prospector_stacks)
			layout.append({"id": item_id, "x": pos.x, "y": pos.y})

	_fill_spawn_value(layout, min_spawn_value, rng)
	_add_sparse_obstacles(layout, depth, rng)
	_maybe_spawn_cursed(layout, depth, rng)
	_ensure_minimum_treasure(layout, min_spawn_value)
	_maybe_spawn_chest(layout, depth, rng)

	return layout


static func generate_vault_layout(depth: int, rng: RandomNumberGenerator, prospector_stacks: int) -> Array[Dictionary]:
	var layout: Array[Dictionary] = []
	var lanes := LANES.duplicate()
	_shuffle_array(lanes, rng)

	for i in lanes.size():
		var lane_x: float = lanes[i]
		var start_y := 0.58 + float(i % 3) * 0.04
		for stack_index in 3:
			var y := start_y + stack_index * 0.13
			var item_id := "gold_medium"
			if stack_index == 2:
				item_id = "diamond" if rng.randf() < 0.35 + prospector_stacks * 0.1 else "gold_large"
			elif stack_index == 1:
				item_id = "gold_large" if rng.randf() < 0.5 else "gold_medium"
			else:
				item_id = "gold_small"
			layout.append({"id": item_id, "x": lane_x, "y": y})

	_fill_spawn_value(layout, int(get_floor_goal(depth) * 1.8), rng)

	var cursed_count := rng.randi_range(0, 2)
	for _j in cursed_count:
		_try_append_cursed(layout, depth, rng)

	_maybe_spawn_chest(layout, depth, rng)
	return layout


static func roll_floor_hazards(depth: int, is_vault: bool, rng: RandomNumberGenerator) -> Array[String]:
	var hazards: Array[String] = []
	if is_vault:
		hazards.append("dragon")
		if rng.randf() < 0.55:
			hazards.append("bat")
		return hazards

	var rolls: Array[Dictionary] = [
		{"id": "dragon", "min_depth": 3, "chance": 0.30},
		{"id": "bat", "min_depth": 2, "chance": 0.32},
		{"id": "mole", "min_depth": 4, "chance": 0.24},
	]
	for roll in rolls:
		if depth >= roll["min_depth"] and rng.randf() < roll["chance"]:
			hazards.append(roll["id"])

	var cap := 2 if depth < 7 else 3
	while hazards.size() > cap:
		hazards.pop_back()
	return hazards


static func get_hazard_spawn(
	hazard_id: String,
	layout: Array[Dictionary],
	spawn_rect: Rect2,
	rng: RandomNumberGenerator,
	used_positions: Array[Vector2] = [],
) -> Dictionary:
	match hazard_id:
		"dragon":
			return get_dragon_spawn(layout, spawn_rect, rng)
		"bat":
			var bat := get_dragon_spawn(layout, spawn_rect, rng)
			bat["y"] -= 50.0
			bat["patrol_left"] -= 40.0
			bat["patrol_right"] += 40.0
			return bat
		"mole":
			return _get_mole_spawn(layout, spawn_rect, rng, used_positions)
		_:
			return get_dragon_spawn(layout, spawn_rect, rng)


static func preview_next_floor(depth: int, extra_time_stacks: int) -> Dictionary:
	var hazard_parts: PackedStringArray = []
	if depth >= 2:
		hazard_parts.append("bats")
	if depth >= 3:
		hazard_parts.append("dragons")
	if depth >= 4:
		hazard_parts.append("moles")
	var hazard_note := "Calm tunnels" if hazard_parts.is_empty() else "Watch for " + ", ".join(hazard_parts)
	return {
		"depth": depth,
		"goal_hint": "~$%d" % int(get_floor_goal(depth) * GOAL_VALUE_RATIO),
		"time_sec": int(get_floor_time(depth, extra_time_stacks, false)),
		"hazard_note": hazard_note,
		"vault_note": "7% vault jackpot" if depth > 1 else "",
	}


static func should_spawn_dragon(depth: int, is_vault: bool, rng: RandomNumberGenerator) -> bool:
	return "dragon" in roll_floor_hazards(depth, is_vault, rng)


static func get_dragon_spawn(
	layout: Array[Dictionary],
	spawn_rect: Rect2,
	rng: RandomNumberGenerator,
) -> Dictionary:
	var richest_x := 0.5
	var richest_y := 0.78
	var best_value := 0

	for entry in layout:
		var id: String = entry.get("id", "")
		if id in ["chest", "dragon"]:
			continue
		var value: int = get_item_type(id)["value"]
		if value > best_value:
			best_value = value
			richest_x = entry["x"]
			richest_y = entry["y"]

	var lane_width := spawn_rect.size.x * 0.14
	var center_x := spawn_rect.position.x + spawn_rect.size.x * richest_x
	var y_pos := spawn_rect.position.y + spawn_rect.size.y * richest_y
	var jitter := rng.randf_range(-lane_width * 0.2, lane_width * 0.2)

	return {
		"patrol_left": center_x - lane_width + jitter,
		"patrol_right": center_x + lane_width + jitter,
		"y": y_pos,
	}


static func _get_mole_spawn(
	layout: Array[Dictionary],
	spawn_rect: Rect2,
	rng: RandomNumberGenerator,
	used_positions: Array[Vector2],
) -> Dictionary:
	var attempts := 0
	while attempts < 32:
		attempts += 1
		var norm := Vector2(rng.randf_range(0.18, 0.82), rng.randf_range(0.74, 0.90))
		if not _is_position_clear(norm, layout):
			continue
		var world := Vector2(
			spawn_rect.position.x + spawn_rect.size.x * norm.x,
			spawn_rect.position.y + spawn_rect.size.y * norm.y,
		)
		var too_close := false
		for other in used_positions:
			if world.distance_to(other) < 90.0:
				too_close = true
				break
		if too_close:
			continue
		return {"x": world.x, "y": world.y}

	return {
		"x": spawn_rect.position.x + spawn_rect.size.x * 0.5,
		"y": spawn_rect.position.y + spawn_rect.size.y * 0.82,
	}


static func _maybe_spawn_chest(layout: Array[Dictionary], depth: int, rng: RandomNumberGenerator) -> void:
	var chance := clampf(0.18 + depth * 0.05, 0.18, 0.45)
	if rng.randf() > chance:
		return
	var attempts := 0
	while attempts < 24:
		attempts += 1
		var pos := Vector2(rng.randf_range(0.18, 0.82), rng.randf_range(0.70, 0.90))
		if _is_position_clear(pos, layout):
			layout.append({"id": "chest", "x": pos.x, "y": pos.y})
			return


static func _maybe_spawn_cursed(layout: Array[Dictionary], depth: int, rng: RandomNumberGenerator) -> void:
	var chance := clampf(0.02 + depth * 0.008, 0.02, 0.08)
	if rng.randf() > chance:
		return
	_try_append_cursed(layout, depth, rng)


static func _try_append_cursed(layout: Array[Dictionary], depth: int, rng: RandomNumberGenerator) -> void:
	var attempts := 0
	while attempts < 20:
		attempts += 1
		var pos := Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.60, 0.88))
		if not _is_position_clear(pos, layout):
			continue
		if _nearest_item_is_valuable(pos, layout):
			var cursed_id := "cursed_idol" if rng.randf() < 0.45 else "cursed_coin"
			layout.append({"id": cursed_id, "x": pos.x, "y": pos.y})
			return


static func _pick_vein_item(
	stack_index: int,
	max_stack_index: int,
	depth: int,
	rng: RandomNumberGenerator,
	prospector_stacks: int,
) -> String:
	if stack_index == max_stack_index:
		var diamond_roll := clampf(0.08 + depth * 0.02 + prospector_stacks * 0.06, 0.08, 0.3)
		if rng.randf() < diamond_roll:
			return "diamond"
		return "gold_large" if depth >= 2 or rng.randf() < 0.55 else "gold_medium"
	if stack_index == 0:
		return "gold_small"
	return "gold_medium" if rng.randf() < 0.65 else "gold_small"


static func _fill_spawn_value(layout: Array[Dictionary], min_value: int, rng: RandomNumberGenerator) -> void:
	var grid_ys: Array[float] = [0.58, 0.68, 0.78, 0.88]
	var grid_xs: Array[float] = [0.10, 0.22, 0.34, 0.46, 0.58, 0.70, 0.82, 0.90]
	for y in grid_ys:
		for x in grid_xs:
			if layout_positive_value(layout) >= min_value:
				return
			var pos := Vector2(x, y)
			if not _is_position_clear(pos, layout):
				continue
			var filler_id := "gold_medium" if rng.randf() < 0.4 else "gold_small"
			layout.append({"id": filler_id, "x": pos.x, "y": pos.y})


static func _ensure_minimum_treasure(layout: Array[Dictionary], min_value: int) -> void:
	var guard := 0
	while layout_positive_value(layout) < min_value and guard < 12:
		guard += 1
		layout.append({
			"id": "gold_medium",
			"x": 0.08 + 0.07 * float(guard),
			"y": 0.56 + 0.03 * float(guard),
		})


static func _add_sparse_obstacles(layout: Array[Dictionary], depth: int, rng: RandomNumberGenerator) -> void:
	var max_rocks := clampi(1 + depth / 4, 1, 3)
	var rocks_added := 0
	var attempts := 0
	while rocks_added < max_rocks and attempts < 30:
		attempts += 1
		var pos := Vector2(rng.randf_range(0.12, 0.88), rng.randf_range(0.60, 0.88))
		if not _is_position_clear(pos, layout):
			continue
		if _nearest_item_is_valuable(pos, layout):
			continue
		layout.append({"id": "rock", "x": pos.x, "y": pos.y})
		rocks_added += 1

	if depth >= 4 and rng.randf() < clampf(0.08 + depth * 0.02, 0.08, 0.2):
		var dyn_attempts := 0
		while dyn_attempts < 20:
			dyn_attempts += 1
			var pos := Vector2(rng.randf_range(0.20, 0.80), rng.randf_range(0.78, 0.92))
			if _is_position_clear(pos, layout) and not _nearest_item_is_valuable(pos, layout):
				layout.append({"id": "dynamite", "x": pos.x, "y": pos.y})
				break

	if depth >= 3 and rng.randf() < 0.25:
		var bone_pos := Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.55, 0.68))
		if _is_position_clear(bone_pos, layout):
			layout.append({"id": "bone", "x": bone_pos.x, "y": bone_pos.y})


static func _nearest_item_is_valuable(pos: Vector2, layout: Array[Dictionary]) -> bool:
	for entry in layout:
		if entry.get("id") in ["chest", "dragon"]:
			continue
		var other := Vector2(entry["x"], entry["y"])
		if pos.distance_to(other) > 0.18:
			continue
		var value: int = get_item_type(entry["id"])["value"]
		if value >= 100:
			return true
	return false


static func _is_position_clear(pos: Vector2, layout: Array[Dictionary]) -> bool:
	for entry in layout:
		var other := Vector2(entry["x"], entry["y"])
		if pos.distance_to(other) < MIN_SEPARATION:
			return false
	return true


static func _shuffle_array(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = values[i]
		values[i] = values[j]
		values[j] = tmp
