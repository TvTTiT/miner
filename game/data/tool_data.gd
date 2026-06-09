class_name ToolData
extends RefCounted

const MAX_LEVEL := 3

const ENTRIES: Array[Dictionary] = [
	# Tools (active gear)
	{
		"id": "iron_claw",
		"name": "Iron Claw",
		"category": "tool",
		"rarity": "common",
		"desc": "Reliable baseline hook. +10% reel speed per level.",
		"starter": true,
	},
	{
		"id": "magnet_hook",
		"name": "Magnet Hook",
		"category": "tool",
		"rarity": "uncommon",
		"hook_style": "magnetic",
		"hook_priority": 2,
		"hook_icon": "🧲",
		"desc": "Magnetic head pulls nuggets toward you while dropping. +12% grab radius per level.",
	},
	{
		"id": "long_hook",
		"name": "Long Hook",
		"category": "tool",
		"rarity": "uncommon",
		"hook_style": "long",
		"hook_priority": 3,
		"hook_icon": "📏",
		"desc": "Deep-reach harpoon. +18% rope length per level. Skims the deepest stacks.",
	},
	{
		"id": "electric_hook",
		"name": "Electric Hook",
		"category": "tool",
		"rarity": "rare",
		"hook_style": "electric",
		"hook_priority": 3,
		"hook_icon": "⚡",
		"desc": "Arc lightning on grab. Zaps 1–3 nearby gold per level for bonus loot.",
	},
	{
		"id": "blast_rig",
		"name": "Blast Rig",
		"category": "tool",
		"rarity": "rare",
		"desc": "Tamed dynamite. +25% blast radius, −40% dynamite penalty per level.",
	},
	{
		"id": "triple_claw",
		"name": "Triple Claw",
		"category": "tool",
		"rarity": "uncommon",
		"hook_style": "triple",
		"hook_priority": 3,
		"hook_icon": "🔱",
		"desc": "Three prongs drop together. Triple grab zones sweep the vein.",
	},
	{
		"id": "rotary_hook",
		"name": "Rotary Hook",
		"category": "tool",
		"rarity": "uncommon",
		"hook_style": "rotary",
		"hook_priority": 3,
		"hook_icon": "🌀",
		"desc": "Spinning drill head. Rotates while swinging and dropping for wider coverage.",
	},
	{
		"id": "twin_fork",
		"name": "Twin Fork",
		"category": "tool",
		"rarity": "rare",
		"hook_style": "twin",
		"hook_priority": 2,
		"hook_icon": "⑂",
		"desc": "Double forks side-by-side. Two lanes grabbed in one drop.",
	},
	{
		"id": "piercer_rig",
		"name": "Piercer Rig",
		"category": "tool",
		"rarity": "rare",
		"hook_style": "piercer",
		"hook_priority": 2,
		"hook_icon": "📌",
		"desc": "Needle hook punches through rocks & bones to snatch gold behind junk.",
	},
	# Skills (passives)
	{
		"id": "quick_reel",
		"name": "Quick Reel",
		"category": "skill",
		"rarity": "common",
		"desc": "Reel in faster. +12% retract speed per level.",
	},
	{
		"id": "long_rope",
		"name": "Long Rope",
		"category": "skill",
		"rarity": "common",
		"desc": "Reach deeper. +12% max rope per level.",
	},
	{
		"id": "fast_swing",
		"name": "Fast Swing",
		"category": "skill",
		"rarity": "common",
		"desc": "Swing faster. +12% swing speed per level.",
	},
	{
		"id": "steady_hand",
		"name": "Steady Hand",
		"category": "skill",
		"rarity": "uncommon",
		"desc": "Drop faster. +12% extend speed per level.",
	},
	{
		"id": "light_touch",
		"name": "Light Touch",
		"category": "skill",
		"rarity": "uncommon",
		"desc": "Beat weight. +12% weight resistance per level.",
	},
	{
		"id": "extra_time",
		"name": "Lucky Watch",
		"category": "skill",
		"rarity": "uncommon",
		"desc": "More time. +5 seconds each floor per level.",
	},
	{
		"id": "gold_rush",
		"name": "Gold Rush",
		"category": "skill",
		"rarity": "rare",
		"desc": "Richer floors. More gold spawns per level.",
	},
	{
		"id": "prospector",
		"name": "Prospector",
		"category": "skill",
		"rarity": "rare",
		"desc": "Gem hunter. Better diamond odds per level.",
	},
	{
		"id": "second_wind",
		"name": "Second Wind",
		"category": "skill",
		"rarity": "uncommon",
		"desc": "Gold rush adrenaline. +0.8s timer per valuable grab per level.",
	},
	{
		"id": "stone_smasher",
		"name": "Stone Smasher",
		"category": "skill",
		"rarity": "common",
		"desc": "Even rubble pays. Rocks worth +60% per level.",
	},
	{
		"id": "combo_ember",
		"name": "Combo Ember",
		"category": "skill",
		"rarity": "rare",
		"desc": "Streak insurance. 1 free combo slip per floor per level (junk/miss).",
	},
	{
		"id": "vein_radar",
		"name": "Vein Radar",
		"category": "skill",
		"rarity": "uncommon",
		"desc": "Reads the stack. +5% combo multiplier per level on chains.",
	},
	# Fusions (evolved forms — replace parents)
	{
		"id": "sky_drill",
		"name": "Sky Drill",
		"category": "fusion",
		"rarity": "epic",
		"desc": "Long Rope + Quick Reel fused. Massive reach and reel speed.",
		"parents": ["long_rope", "quick_reel"],
	},
	{
		"id": "snap_claw",
		"name": "Snap Claw",
		"category": "fusion",
		"rarity": "epic",
		"desc": "Fast Swing + Steady Hand fused. Lightning aim and drop.",
		"parents": ["fast_swing", "steady_hand"],
	},
	{
		"id": "treasure_sense",
		"name": "Treasure Sense",
		"category": "fusion",
		"rarity": "epic",
		"desc": "Magnet Hook + Prospector fused. Huge grab zone and gem luck.",
		"parents": ["magnet_hook", "prospector"],
	},
	{
		"id": "titan_grip",
		"name": "Titan Grip",
		"category": "fusion",
		"rarity": "epic",
		"desc": "Iron Claw + Light Touch fused. Unstoppable heavy hauls.",
		"parents": ["iron_claw", "light_touch"],
	},
	{
		"id": "gold_hour",
		"name": "Gold Hour",
		"category": "fusion",
		"rarity": "epic",
		"desc": "Gold Rush + Lucky Watch fused. Floods of gold and time.",
		"parents": ["gold_rush", "extra_time"],
	},
	{
		"id": "shatter_core",
		"name": "Shatter Core",
		"category": "fusion",
		"rarity": "epic",
		"desc": "Blast Rig + Quick Reel fused. Explosive speed demon.",
		"parents": ["blast_rig", "quick_reel"],
	},
	{
		"id": "trident_storm",
		"name": "Trident Storm",
		"category": "fusion",
		"rarity": "epic",
		"hook_style": "triple",
		"hook_priority": 5,
		"desc": "Triple Claw + Fast Swing fused. Three spinning prongs of chaos.",
		"parents": ["triple_claw", "fast_swing"],
	},
	{
		"id": "spiral_reaper",
		"name": "Spiral Reaper",
		"category": "fusion",
		"rarity": "epic",
		"hook_style": "rotary",
		"hook_priority": 5,
		"desc": "Rotary Hook + Quick Reel fused. Buzzsaw reel tears through lanes.",
		"parents": ["rotary_hook", "quick_reel"],
	},
	{
		"id": "gem_harpoon",
		"name": "Gem Harpoon",
		"category": "fusion",
		"rarity": "epic",
		"hook_style": "twin",
		"hook_priority": 4,
		"desc": "Twin Fork + Prospector fused. Twin gem-seeking harpoons.",
		"parents": ["twin_fork", "prospector"],
	},
	{
		"id": "thunder_lance",
		"name": "Thunder Lance",
		"category": "fusion",
		"rarity": "epic",
		"hook_style": "electric",
		"hook_priority": 5,
		"hook_icon": "⚡",
		"desc": "Electric Hook + Long Rope fused. Shocking deep strikes.",
		"parents": ["electric_hook", "long_rope"],
	},
	{
		"id": "polar_maw",
		"name": "Polar Maw",
		"category": "fusion",
		"rarity": "epic",
		"hook_style": "magnetic",
		"hook_priority": 4,
		"hook_icon": "🧲",
		"desc": "Magnet Hook + Long Hook fused. Magnetic deep dredge.",
		"parents": ["magnet_hook", "long_hook"],
	},
	{
		"id": "storm_trident",
		"name": "Storm Trident",
		"category": "fusion",
		"rarity": "epic",
		"hook_style": "triple",
		"hook_priority": 6,
		"hook_icon": "⚡",
		"desc": "Triple Claw + Electric Hook fused. Triple lightning harvest.",
		"parents": ["triple_claw", "electric_hook"],
	},
]


static func get_entry(id: String) -> Dictionary:
	for entry in ENTRIES:
		if entry["id"] == id:
			return entry.duplicate()
	return ENTRIES[0].duplicate()


static func is_fusion(id: String) -> bool:
	return get_entry(id).get("category") == "fusion"


static func get_parents(id: String) -> Array[String]:
	var parents: Array[String] = []
	var entry := get_entry(id)
	for parent in entry.get("parents", []):
		parents.append(parent)
	return parents


static func get_fusion_recipes() -> Array[Dictionary]:
	var recipes: Array[Dictionary] = []
	for entry in ENTRIES:
		if entry.get("category") == "fusion":
			recipes.append(entry.duplicate())
	return recipes


const HOOK_ICONS := {
	"single": "🪝",
	"triple": "🔱",
	"rotary": "🌀",
	"twin": "⑂",
	"piercer": "📌",
	"long": "📏",
	"electric": "⚡",
	"magnetic": "🧲",
}


static func hook_icon(style: String) -> String:
	return HOOK_ICONS.get(style, HOOK_ICONS["single"])


static func hook_icon_for_entry(entry: Dictionary) -> String:
	var hook_style: String = entry.get("hook_style", "")
	if hook_style != "":
		return hook_icon(hook_style)
	return entry.get("hook_icon", "✦")
