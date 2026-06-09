class_name LevelData
extends RefCounted

const LEVELS: Array[Dictionary] = [
	{"target": 650, "time": 60, "name": "Level 1"},
	{"target": 1150, "time": 60, "name": "Level 2"},
	{"target": 2000, "time": 55, "name": "Level 3"},
	{"target": 3200, "time": 55, "name": "Level 4"},
	{"target": 5000, "time": 50, "name": "Level 5"},
]

const ITEM_TYPES: Array[Dictionary] = [
	{"id": "gold_small", "value": 50, "weight": 1.0, "radius": 14, "color": Color(1.0, 0.84, 0.0)},
	{"id": "gold_medium", "value": 100, "weight": 2.0, "radius": 22, "color": Color(0.95, 0.75, 0.0)},
	{"id": "gold_large", "value": 250, "weight": 4.0, "radius": 32, "color": Color(0.85, 0.65, 0.0)},
	{"id": "diamond", "value": 500, "weight": 0.8, "radius": 12, "color": Color(0.6, 0.9, 1.0)},
	{"id": "rock", "value": 11, "weight": 6.0, "radius": 26, "color": Color(0.45, 0.42, 0.38)},
	{"id": "bone", "value": 3, "weight": 2.5, "radius": 18, "color": Color(0.92, 0.88, 0.78)},
]

static func get_level(index: int) -> Dictionary:
	return LEVELS[clampi(index, 0, LEVELS.size() - 1)]

static func get_item_type(id: String) -> Dictionary:
	for item_type in ITEM_TYPES:
		if item_type["id"] == id:
			return item_type
	return ITEM_TYPES[0]

static func get_spawn_layout(level_index: int) -> Array[Dictionary]:
	var layouts: Array[Array] = [
		[
			{"id": "gold_small", "x": 0.18, "y": 0.72},
			{"id": "gold_small", "x": 0.35, "y": 0.85},
			{"id": "gold_medium", "x": 0.55, "y": 0.78},
			{"id": "gold_large", "x": 0.75, "y": 0.88},
			{"id": "rock", "x": 0.42, "y": 0.68},
			{"id": "bone", "x": 0.62, "y": 0.65},
			{"id": "diamond", "x": 0.85, "y": 0.70},
		],
		[
			{"id": "gold_small", "x": 0.15, "y": 0.80},
			{"id": "gold_medium", "x": 0.28, "y": 0.72},
			{"id": "gold_large", "x": 0.45, "y": 0.88},
			{"id": "rock", "x": 0.38, "y": 0.62},
			{"id": "rock", "x": 0.58, "y": 0.75},
			{"id": "diamond", "x": 0.72, "y": 0.68},
			{"id": "gold_small", "x": 0.88, "y": 0.82},
			{"id": "bone", "x": 0.52, "y": 0.58},
		],
		[
			{"id": "gold_large", "x": 0.20, "y": 0.85},
			{"id": "rock", "x": 0.32, "y": 0.70},
			{"id": "gold_medium", "x": 0.48, "y": 0.78},
			{"id": "diamond", "x": 0.60, "y": 0.62},
			{"id": "rock", "x": 0.55, "y": 0.90},
			{"id": "gold_small", "x": 0.70, "y": 0.72},
			{"id": "gold_large", "x": 0.82, "y": 0.85},
			{"id": "bone", "x": 0.40, "y": 0.58},
			{"id": "diamond", "x": 0.90, "y": 0.65},
		],
		[
			{"id": "rock", "x": 0.18, "y": 0.68},
			{"id": "gold_large", "x": 0.30, "y": 0.82},
			{"id": "rock", "x": 0.42, "y": 0.75},
			{"id": "diamond", "x": 0.50, "y": 0.60},
			{"id": "gold_medium", "x": 0.58, "y": 0.88},
			{"id": "rock", "x": 0.65, "y": 0.70},
			{"id": "gold_small", "x": 0.75, "y": 0.78},
			{"id": "diamond", "x": 0.85, "y": 0.58},
			{"id": "bone", "x": 0.48, "y": 0.92},
			{"id": "gold_large", "x": 0.92, "y": 0.85},
		],
		[
			{"id": "rock", "x": 0.15, "y": 0.75},
			{"id": "rock", "x": 0.25, "y": 0.62},
			{"id": "gold_large", "x": 0.35, "y": 0.88},
			{"id": "diamond", "x": 0.45, "y": 0.65},
			{"id": "rock", "x": 0.52, "y": 0.78},
			{"id": "gold_medium", "x": 0.60, "y": 0.58},
			{"id": "diamond", "x": 0.68, "y": 0.90},
			{"id": "rock", "x": 0.75, "y": 0.68},
			{"id": "gold_large", "x": 0.82, "y": 0.78},
			{"id": "bone", "x": 0.88, "y": 0.62},
			{"id": "diamond", "x": 0.92, "y": 0.85},
		],
	]
	var layout: Array = layouts[clampi(level_index, 0, layouts.size() - 1)]
	var result: Array[Dictionary] = []
	for entry in layout:
		result.append(entry)
	return result
