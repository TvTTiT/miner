class_name ShopFlow
extends RefCounted

var _session: RunSession
var _draft: DraftState


func setup(session: RunSession, draft: DraftState) -> void:
	_session = session
	_draft = draft


func build_shop_context() -> Dictionary:
	var mods := _session.loadout.get_modifiers()
	var ctx := LevelData.preview_next_floor(_session.floor_depth + 1, mods["extra_time"])
	ctx["run_money"] = _session.run_money
	return ctx


func begin_draft(
	after_action: String,
	header: String = "",
	subtitle: String = "",
	is_shop: bool = false,
	shop_context: Dictionary = {},
) -> void:
	_draft.after_action = after_action
	_draft.header = header
	_draft.subtitle = subtitle
	_draft.is_shop = is_shop
	_draft.shop_context = shop_context
	_draft.offers = _session.loadout.pick_draft_options(
		_session.rng,
		3,
		_session.chest_rarity_bonus(),
	)


func apply_pick(offer: Dictionary) -> Dictionary:
	var result := _session.loadout.apply_pick(offer["id"])
	var entry := ToolData.get_entry(offer["id"])
	var bonus_parts: PackedStringArray = []

	if result.get("fusion_triggered", false):
		bonus_parts.append("Parents fused into a stronger form!")
	if _session.combo.streak >= 4:
		bonus_parts.append("Hot streak active!")
	if _session.is_vault_floor:
		bonus_parts.append("Vault luck!")

	var reveal := {
		"id": offer["id"],
		"name": entry["name"],
		"desc": entry.get("desc", ""),
		"rarity": entry.get("rarity", "common"),
		"category": entry.get("category", "skill"),
		"bonus_text": " ".join(bonus_parts),
	}
	if result.get("kind") == "level_up":
		reveal["desc"] = "Level %d — %s" % [result.get("level", 1), entry.get("desc", "")]

	_draft.pending_loot = reveal
	return reveal
