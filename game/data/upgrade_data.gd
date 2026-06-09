class_name UpgradeData
extends RefCounted

const UPGRADES: Array[Dictionary] = [
	{"id": "quick_reel", "name": "Quick Reel", "desc": "Claw reels in 30% faster", "rarity": "common"},
	{"id": "long_rope", "name": "Long Rope", "desc": "Claw reaches 20% farther", "rarity": "common"},
	{"id": "fast_swing", "name": "Fast Swing", "desc": "Claw swings 25% faster", "rarity": "common"},
	{"id": "light_touch", "name": "Light Touch", "desc": "Heavy items slow you 25% less", "rarity": "uncommon"},
	{"id": "extra_time", "name": "Lucky Watch", "desc": "+8 seconds each floor", "rarity": "uncommon"},
	{"id": "gold_rush", "name": "Gold Rush", "desc": "More gold spawns next floor", "rarity": "rare"},
	{"id": "prospector", "name": "Prospector", "desc": "Better diamond odds next floor", "rarity": "rare"},
	{"id": "steady_hand", "name": "Steady Hand", "desc": "Claw extends 20% faster", "rarity": "epic"},
]

const RARITY_WEIGHTS := {
	"common": 45,
	"uncommon": 30,
	"rare": 18,
	"epic": 7,
}


static func get_upgrade(id: String) -> Dictionary:
	for upgrade in UPGRADES:
		if upgrade["id"] == id:
			return upgrade
	return UPGRADES[0]


static func pick_random_loot(rng: RandomNumberGenerator, owned: Array[String]) -> Dictionary:
	var pool: Array[Dictionary] = []
	for upgrade in UPGRADES:
		if upgrade["id"] not in owned:
			pool.append(upgrade)

	if pool.is_empty():
		return UPGRADES[rng.randi_range(0, UPGRADES.size() - 1)].duplicate()

	var roll := rng.randi_range(1, 100)
	var tier := "common"
	if roll <= RARITY_WEIGHTS["epic"]:
		tier = "epic"
	elif roll <= RARITY_WEIGHTS["epic"] + RARITY_WEIGHTS["rare"]:
		tier = "rare"
	elif roll <= RARITY_WEIGHTS["epic"] + RARITY_WEIGHTS["rare"] + RARITY_WEIGHTS["uncommon"]:
		tier = "uncommon"

	var tier_pool: Array[Dictionary] = []
	for upgrade in pool:
		if upgrade.get("rarity", "common") == tier:
			tier_pool.append(upgrade)

	if tier_pool.is_empty():
		return pool[rng.randi_range(0, pool.size() - 1)].duplicate()
	return tier_pool[rng.randi_range(0, tier_pool.size() - 1)].duplicate()
