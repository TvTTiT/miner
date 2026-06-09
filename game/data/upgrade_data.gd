class_name UpgradeData
extends RefCounted

# Legacy alias — loadout system lives in ToolData + RunLoadout.
static func get_upgrade(id: String) -> Dictionary:
	return ToolData.get_entry(id)


static func pick_random_loot(
	rng: RandomNumberGenerator,
	owned: Array[String],
	rarity_bonus: int = 0,
) -> Dictionary:
	var loadout := RunLoadout.new()
	for id in owned:
		loadout.levels[id] = 1
	var options := loadout.pick_draft_options(rng, 1, rarity_bonus)
	if options.is_empty():
		return ToolData.get_entry("quick_reel")
	return options[0]
