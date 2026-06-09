class_name RunLoadout
extends RefCounted

var levels: Dictionary = {}


func reset() -> void:
	levels.clear()
	levels["iron_claw"] = 1


func owns(id: String) -> bool:
	return levels.has(id) and levels[id] > 0


func get_level(id: String) -> int:
	return levels.get(id, 0)


func get_owned_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in levels.keys():
		if levels[id] > 0:
			ids.append(id)
	return ids


func get_available_fusions() -> Array[Dictionary]:
	var ready: Array[Dictionary] = []
	for recipe in ToolData.get_fusion_recipes():
		var fusion_id: String = recipe["id"]
		if owns(fusion_id):
			continue
		var parents: Array[String] = ToolData.get_parents(fusion_id)
		var has_all := true
		for parent_id in parents:
			if not owns(parent_id):
				has_all = false
				break
		if has_all:
			ready.append(recipe.duplicate())
	return ready


func apply_pick(id: String) -> Dictionary:
	var entry := ToolData.get_entry(id)
	var result := {
		"id": id,
		"name": entry["name"],
		"category": entry.get("category", "skill"),
		"kind": "new",
		"level": 1,
		"fusion_triggered": false,
	}

	if entry.get("category") == "fusion":
		_apply_fusion(id)
		result["kind"] = "fusion"
		result["fusion_triggered"] = true
		result["level"] = 1
		return result

	if owns(id):
		var old_level: int = get_level(id)
		var next_level := mini(old_level + 1, ToolData.MAX_LEVEL)
		levels[id] = next_level
		result["kind"] = "level_up" if next_level > old_level else "maxed"
		result["level"] = next_level
	else:
		levels[id] = 1
		result["kind"] = "new"

	return result


func _apply_fusion(fusion_id: String) -> void:
	for parent_id in ToolData.get_parents(fusion_id):
		levels.erase(parent_id)
	levels[fusion_id] = 1


func pick_draft_options(rng: RandomNumberGenerator, count: int, rarity_bonus: int = 0) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var fusions := get_available_fusions()
	if not fusions.is_empty() and rng.randf() < clampf(0.55 + rarity_bonus * 0.08, 0.55, 0.92):
		options.append(_make_offer(fusions[rng.randi_range(0, fusions.size() - 1)], "fusion"))

	var attempts := 0
	while options.size() < count and attempts < 60:
		attempts += 1
		var candidate := _roll_candidate(rng, rarity_bonus)
		if candidate.is_empty():
			continue
		if _offer_exists(options, candidate["id"], candidate.get("offer_kind", "new")):
			continue
		options.append(candidate)

	while options.size() < count:
		var fallback := _roll_candidate(rng, 0)
		if fallback.is_empty():
			break
		if not _offer_exists(options, fallback["id"], fallback.get("offer_kind", "new")):
			options.append(fallback)

	if options.is_empty():
		options.append(_make_offer(ToolData.get_entry("quick_reel"), "new"))
	return options


func _roll_candidate(rng: RandomNumberGenerator, rarity_bonus: int) -> Dictionary:
	var tier := _roll_tier(rng, rarity_bonus)
	var pool: Array[Dictionary] = []

	for entry in ToolData.ENTRIES:
		var category: String = entry.get("category", "skill")
		if category == "fusion":
			continue
		var id: String = entry["id"]
		if owns(id) and get_level(id) >= ToolData.MAX_LEVEL:
			continue
		if entry.get("starter", false) and owns(id) and get_level(id) < ToolData.MAX_LEVEL:
			pool.append(entry)
			continue
		if entry.get("starter", false):
			continue
		pool.append(entry)

	pool.shuffle()
	for entry in pool:
		if entry.get("rarity", "common") == tier:
			var kind := "level_up" if owns(entry["id"]) else "new"
			return _make_offer(entry, kind)

	if not pool.is_empty():
		var fallback: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var kind := "level_up" if owns(fallback["id"]) else "new"
		return _make_offer(fallback, kind)
	return {}


func _make_offer(entry: Dictionary, kind: String) -> Dictionary:
	var id: String = entry["id"]
	var level := get_level(id) + 1 if kind == "level_up" else 1
	if kind == "fusion":
		level = 1
	return {
		"id": id,
		"name": entry["name"],
		"category": entry.get("category", "skill"),
		"rarity": entry.get("rarity", "common"),
		"desc": entry.get("desc", ""),
		"hook_style": entry.get("hook_style", ""),
		"hook_icon": ToolData.hook_icon_for_entry(entry),
		"offer_kind": kind,
		"preview_level": clampi(level, 1, ToolData.MAX_LEVEL),
		"parents": ToolData.get_parents(id),
	}


func _offer_exists(options: Array[Dictionary], id: String, kind: String) -> bool:
	for offer in options:
		if offer["id"] == id and offer.get("offer_kind") == kind:
			return true
	return false


func _roll_tier(rng: RandomNumberGenerator, rarity_bonus: int) -> String:
	var roll := rng.randi_range(1, 100)
	var epic := maxi(1, 7 + rarity_bonus * 3)
	var rare := epic + 18 + rarity_bonus * 5
	var uncommon := rare + 30 + rarity_bonus * 8
	if roll <= epic:
		return "epic"
	if roll <= rare:
		return "rare"
	if roll <= uncommon:
		return "uncommon"
	return "common"


func get_modifiers() -> Dictionary:
	var mods := {
		"retract_mult": 1.0,
		"extend_mult": 1.0,
		"swing_mult": 1.0,
		"weight_resist": 1.0,
		"rope_mult": 1.0,
		"grab_radius_mult": 1.0,
		"extra_time": 0,
		"gold_rush": 0,
		"prospector": 0,
		"dynamite_radius_mult": 1.0,
		"dynamite_penalty_mult": 1.0,
		"hook_style": "single",
		"rotary_speed": 0.0,
		"pierce_junk": false,
		"combo_grace": 0,
		"time_on_grab": 0.0,
		"rock_value_mult": 1.0,
		"combo_bonus": 0.0,
		"electric_chain": 0,
		"magnet_pull": 0.0,
	}

	for id in levels.keys():
		var lvl: int = levels[id]
		if lvl <= 0:
			continue
		match id:
			"iron_claw":
				mods["retract_mult"] += 0.10 * lvl
			"magnet_hook":
				mods["grab_radius_mult"] += 0.12 * lvl
				mods["magnet_pull"] += 0.14 * lvl
			"long_hook":
				mods["rope_mult"] += 0.18 * lvl
				mods["extend_mult"] += 0.06 * lvl
			"electric_hook":
				mods["electric_chain"] += lvl
			"blast_rig":
				mods["dynamite_radius_mult"] += 0.25 * lvl
				mods["dynamite_penalty_mult"] -= 0.40 * lvl
			"triple_claw":
				mods["grab_radius_mult"] += 0.08 * lvl
			"rotary_hook":
				mods["rotary_speed"] += 4.5 + 1.2 * float(lvl - 1)
			"twin_fork":
				mods["extend_mult"] += 0.10 * lvl
				mods["grab_radius_mult"] += 0.06 * lvl
			"piercer_rig":
				mods["extend_mult"] += 0.15 * lvl
				mods["pierce_junk"] = true
			"quick_reel":
				mods["retract_mult"] += 0.12 * lvl
			"long_rope":
				mods["rope_mult"] += 0.12 * lvl
			"fast_swing":
				mods["swing_mult"] += 0.12 * lvl
			"steady_hand":
				mods["extend_mult"] += 0.12 * lvl
			"light_touch":
				mods["weight_resist"] += 0.12 * lvl
			"extra_time":
				mods["extra_time"] += lvl
			"gold_rush":
				mods["gold_rush"] += lvl
			"prospector":
				mods["prospector"] += lvl
			"second_wind":
				mods["time_on_grab"] += 0.8 * lvl
			"stone_smasher":
				mods["rock_value_mult"] += 0.60 * lvl
			"combo_ember":
				mods["combo_grace"] += lvl
			"vein_radar":
				mods["combo_bonus"] += 0.05 * lvl
			"sky_drill":
				mods["retract_mult"] += 0.50
				mods["rope_mult"] += 0.35
			"snap_claw":
				mods["swing_mult"] += 0.40
				mods["extend_mult"] += 0.40
			"treasure_sense":
				mods["grab_radius_mult"] += 0.25
				mods["prospector"] += 2
			"titan_grip":
				mods["retract_mult"] += 0.30
				mods["weight_resist"] += 0.40
			"gold_hour":
				mods["gold_rush"] += 2
				mods["extra_time"] += 3
			"shatter_core":
				mods["dynamite_radius_mult"] += 0.60
				mods["retract_mult"] += 0.30
				mods["dynamite_penalty_mult"] -= 0.50
			"trident_storm":
				mods["swing_mult"] += 0.35
				mods["grab_radius_mult"] += 0.20
				mods["rotary_speed"] += 3.0
			"spiral_reaper":
				mods["retract_mult"] += 0.45
				mods["rotary_speed"] += 7.0
			"gem_harpoon":
				mods["prospector"] += 2
				mods["extend_mult"] += 0.25
			"thunder_lance":
				mods["rope_mult"] += 0.30
				mods["electric_chain"] += 2
				mods["extend_mult"] += 0.20
			"polar_maw":
				mods["rope_mult"] += 0.25
				mods["magnet_pull"] += 0.35
				mods["grab_radius_mult"] += 0.15
			"storm_trident":
				mods["electric_chain"] += 3
				mods["grab_radius_mult"] += 0.18
				mods["swing_mult"] += 0.20

	_apply_active_hook_style(mods)
	mods["dynamite_penalty_mult"] = maxf(0.1, mods["dynamite_penalty_mult"])
	return mods


func _apply_active_hook_style(mods: Dictionary) -> void:
	var best_score := -1
	var best_style := "single"
	for id in levels.keys():
		var lvl: int = levels[id]
		if lvl <= 0:
			continue
		var entry := ToolData.get_entry(id)
		var style: String = entry.get("hook_style", "")
		if style == "":
			continue
		var score: int = lvl * int(entry.get("hook_priority", 1))
		if score > best_score:
			best_score = score
			best_style = style
	mods["hook_style"] = best_style


func get_display_summary() -> String:
	var parts: PackedStringArray = []
	for id in levels.keys():
		if levels[id] <= 0:
			continue
		var entry := ToolData.get_entry(id)
		var tag := "F" if entry.get("category") == "fusion" else "T" if entry.get("category") == "tool" else "S"
		var lvl_text := "" if entry.get("category") == "fusion" else " %d" % levels[id]
		parts.append("%s %s%s" % [tag, entry["name"], lvl_text])
	return " | ".join(parts) if not parts.is_empty() else "Iron Claw 1"


func get_recipe_hint() -> String:
	var hints: PackedStringArray = []
	for recipe in ToolData.get_fusion_recipes():
		if owns(recipe["id"]):
			continue
		var parents: Array[String] = ToolData.get_parents(recipe["id"])
		var owned_count := 0
		for parent_id in parents:
			if owns(parent_id):
				owned_count += 1
		if owned_count == 0:
			continue
		var parent_names: PackedStringArray = []
		for parent_id in parents:
			var p := ToolData.get_entry(parent_id)
			var mark := "✓" if owns(parent_id) else "○"
			parent_names.append("%s %s" % [mark, p["name"]])
		hints.append("%s: %s" % [recipe["name"], " + ".join(parent_names)])
	return "\n".join(hints)
