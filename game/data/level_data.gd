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
]

const LANES: Array[float] = [0.14, 0.30, 0.50, 0.70, 0.86]
const MIN_SEPARATION := 0.07
const GOAL_VALUE_RATIO := 0.55


static func get_item_type(id: String) -> Dictionary:
	for item_type in ITEM_TYPES:
		if item_type["id"] == id:
			return item_type
	return ITEM_TYPES[0]


static func get_floor_goal(depth: int) -> int:
	return 180 + depth * 90 + int(depth * depth * 4)


static func compute_achievable_goal(layout: Array[Dictionary], depth: int) -> int:
	var positive_value := layout_positive_value(layout)
	var from_spawn := int(positive_value * GOAL_VALUE_RATIO)
	var cap := get_floor_goal(depth)
	return clampi(mini(from_spawn, cap), 100, cap)


static func layout_positive_value(layout: Array[Dictionary]) -> int:
	var total := 0
	for entry in layout:
		if entry.get("id") == "chest":
			continue
		var value: int = get_item_type(entry["id"])["value"]
		if value > 0:
			total += value
	return total


static func get_floor_time(depth: int, extra_time_stacks: int) -> float:
	var base := maxf(42.0, 65.0 - depth * 1.2)
	return base + extra_time_stacks * 8.0


static func generate_floor_layout(
	depth: int,
	rng: RandomNumberGenerator,
	gold_rush_stacks: int,
	prospector_stacks: int,
) -> Array[Dictionary]:
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
	_ensure_minimum_treasure(layout, min_spawn_value)
	_maybe_spawn_chest(layout, depth, rng)

	return layout


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
		if entry.get("id") == "chest":
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
