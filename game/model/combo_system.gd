class_name ComboSystem
extends RefCounted

const VALUABLE_IDS: Array[String] = [
	"gold_small", "gold_medium", "gold_large", "diamond",
]

const TIER_THRESHOLDS: Array[int] = [2, 3, 4, 5, 6, 8]
const TIER_NAMES: Array[String] = ["SPARK", "FLOW", "SURGE", "FURY", "JACKPOT", "GOLD RUSH"]
const TIER_MULTS: Array[float] = [1.15, 1.30, 1.50, 1.75, 2.0, 2.5]
const TIER_TAGLINES: Array[String] = [
	"Vein touched!",
	"Stack rolling!",
	"Gold fever!",
	"Unstoppable haul!",
	"Jackpot rhythm!",
	"LEGENDARY RUSH!",
]

const TIER_COLORS := {
	"SPARK": Color(0.55, 0.95, 0.72),
	"FLOW": Color(0.45, 0.85, 1.0),
	"SURGE": Color(0.95, 0.75, 0.35),
	"FURY": Color(1.0, 0.55, 0.28),
	"JACKPOT": Color(1.0, 0.42, 0.82),
	"GOLD RUSH": Color(1.0, 0.92, 0.35),
}

var streak: int = 0
var last_break_reason: String = ""
var peak_streak: int = 0

var _grace_charges: int = 0
var _combo_bonus: float = 0.0
var _last_valuable_id: String = ""
var _same_chain: int = 0
var _tier_up_pending: String = ""


func reset() -> void:
	streak = 0
	last_break_reason = ""
	peak_streak = 0
	_grace_charges = 0
	_combo_bonus = 0.0
	_last_valuable_id = ""
	_same_chain = 0
	_tier_up_pending = ""


func set_grace_charges(charges: int) -> void:
	_grace_charges = maxi(0, charges)


func set_combo_bonus(bonus: float) -> void:
	_combo_bonus = maxf(0.0, bonus)


func consume_tier_up() -> String:
	var pending := _tier_up_pending
	_tier_up_pending = ""
	return pending


func get_tier_index() -> int:
	for i in range(TIER_THRESHOLDS.size() - 1, -1, -1):
		if streak >= TIER_THRESHOLDS[i]:
			return i
	return -1


func get_tier_name() -> String:
	var idx := get_tier_index()
	if idx < 0:
		return ""
	return TIER_NAMES[idx]


func get_multiplier() -> float:
	if streak < 2:
		return 1.0

	var idx := get_tier_index()
	var base: float = TIER_MULTS[idx] if idx >= 0 else 1.0
	var same_bonus := clampf(float(_same_chain - 1) * 0.05, 0.0, 0.20)
	var diamond_bonus := 0.22 if _last_valuable_id == "diamond" and streak >= 3 else 0.0
	return (base + same_bonus + diamond_bonus) * (1.0 + _combo_bonus)


func get_heat() -> float:
	if streak <= 0:
		return 0.0
	return clampf(float(streak) / 8.0, 0.0, 1.0)


func get_display() -> Dictionary:
	var tier := get_tier_name()
	var mult := get_multiplier()
	var tagline := ""
	var idx := get_tier_index()
	if idx >= 0:
		tagline = TIER_TAGLINES[idx]
	elif streak == 1:
		tagline = "Build the chain..."
	return {
		"tier": tier,
		"streak": streak,
		"mult": mult,
		"heat": get_heat(),
		"color": TIER_COLORS.get(tier, Color(0.45, 0.5, 0.55)) if tier != "" else Color(0.45, 0.5, 0.55),
		"tagline": tagline,
		"same_chain": _same_chain,
		"peak": peak_streak,
	}


func get_rarity_bonus() -> int:
	if streak >= 8:
		return 3
	if streak >= 6:
		return 2
	if streak >= 4:
		return 1
	return 0


func register_hit(item_id: String) -> void:
	if not is_valuable(item_id):
		if is_junk(item_id):
			break_streak("junk")
		return

	var old_tier := get_tier_index()
	if item_id == _last_valuable_id:
		_same_chain += 1
	else:
		_same_chain = 1
	_last_valuable_id = item_id
	streak += 1
	peak_streak = maxi(peak_streak, streak)

	var new_tier := get_tier_index()
	if new_tier > old_tier and new_tier >= 0:
		_tier_up_pending = TIER_NAMES[new_tier]


func register_chest_hit() -> void:
	var old_tier := get_tier_index()
	streak += 1
	_same_chain = 0
	_last_valuable_id = "chest"
	peak_streak = maxi(peak_streak, streak)
	var new_tier := get_tier_index()
	if new_tier > old_tier and new_tier >= 0:
		_tier_up_pending = TIER_NAMES[new_tier]


func break_streak(reason: String = "") -> void:
	if _grace_charges > 0 and reason in ["junk", "miss"]:
		_grace_charges -= 1
		last_break_reason = "grace"
		return
	streak = 0
	_same_chain = 0
	_last_valuable_id = ""
	last_break_reason = reason


func is_valuable(item_id: String) -> bool:
	return item_id in VALUABLE_IDS


func is_junk(item_id: String) -> bool:
	return (
		item_id in ["rock", "bone", "dynamite"]
		or item_id.begins_with("cursed")
	)


func is_cursed(item_id: String) -> bool:
	return item_id.begins_with("cursed")
