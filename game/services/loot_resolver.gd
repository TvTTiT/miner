class_name LootResolver
extends RefCounted

var _session: RunSession
var _spawner: FloorSpawner
var _feedback: LootFeedback
var _miner: Miner


func setup(session: RunSession, spawner: FloorSpawner, feedback: LootFeedback, miner: Miner) -> void:
	_session = session
	_spawner = spawner
	_feedback = feedback
	_miner = miner


func resolve_item(item: MineItem) -> Dictionary:
	var item_id: String = item.item_id
	var earned: int = item.value
	var mult: float = 1.0
	var mods := _session.loadout.get_modifiers()
	if item_id == "dynamite":
		_trigger_dynamite(item, mods["dynamite_radius_mult"])
		_session.combo.break_streak("dynamite")
		earned = int(item.value * mods["dynamite_penalty_mult"])
		_feedback.show_popup("BOOM!", item.global_position, Color(1.0, 0.45, 0.1))
	elif _session.combo.is_cursed(item_id):
		_session.combo.break_streak("cursed")
		_feedback.red_flash()
		_feedback.show_popup("CURSED!", _miner.global_position, Color(0.95, 0.2, 0.25))
	elif _session.combo.is_junk(item_id):
		_session.combo.break_streak("junk")
		if item_id == "rock":
			earned = int(item.value * mods.get("rock_value_mult", 1.0))
	elif _session.combo.is_valuable(item_id):
		mult = _session.combo.get_multiplier()
		earned = int(item.value * mult)
		_session.combo.register_hit(item_id)
		_session.time_left += mods.get("time_on_grab", 0.0)
		_show_value_popup(earned, mult)
		_show_combo_feedback()
		if mult >= 2.0:
			_feedback.screen_punch(_miner.get_parent(), 10.0)
			_feedback.gold_flash()
		if mods.get("electric_chain", 0) > 0:
			_trigger_electric_chain(item.global_position, int(mods["electric_chain"]), mult)

	_session.add_earnings(earned)
	item.collect()
	return {"earned": earned, "mult": mult}


func resolve_hazard(payload: Dictionary, screen_shake_target: Node2D) -> void:
	_session.combo.break_streak(payload.get("id", "hazard"))
	_session.apply_time_penalty(payload.get("time_penalty", GameConfig.DEFAULT_TIME_PENALTY))
	_miner.claw.stun(payload.get("stun", GameConfig.DEFAULT_STUN))
	_feedback.show_popup(
		payload.get("message", "OUCH!"),
		_miner.global_position,
		payload.get("color", Color(1.0, 0.35, 0.25)),
	)
	_feedback.screen_punch(screen_shake_target, 10.0)


func resolve_miss() -> void:
	_session.combo.break_streak("miss")


func resolve_chest_pick() -> void:
	_session.combo.register_chest_hit()
	_show_combo_feedback()


func _trigger_dynamite(item: MineItem, radius_mult: float) -> void:
	var radius := GameConfig.DYNAMITE_RADIUS_BASE * radius_mult
	for victim in _spawner.collect_mine_items_in_radius(item.global_position, radius, item):
		victim.collect()


func _trigger_electric_chain(origin: Vector2, chain_count: int, mult: float) -> void:
	var victims := _spawner.collect_mine_items_in_radius(origin, 110.0, null)
	var zapped := 0
	for victim in victims:
		if zapped >= chain_count:
			break
		if not _session.combo.is_valuable(victim.item_id):
			continue
		var bonus := int(victim.value * 0.42 * mult)
		_session.add_earnings(bonus)
		_feedback.show_popup("ZAP +$%d" % bonus, victim.global_position, Color(0.45, 0.9, 1.0))
		victim.collect()
		zapped += 1
	if zapped > 0:
		_feedback.electric_flash()


func _show_combo_feedback() -> void:
	var tier_up := _session.combo.consume_tier_up()
	if tier_up != "":
		_feedback.show_combo_burst(tier_up, _miner.global_position)
	var display := _session.combo.get_display()
	if display.get("tier", "") != "" and tier_up == "":
		_feedback.show_popup(
			"%s x%.2g" % [display["tier"], display["mult"]],
			_miner.global_position + Vector2(0, -36),
			display["color"],
		)


func _show_value_popup(earned: int, mult: float) -> void:
	var text := "+$%d" % earned
	if mult > 1.0:
		text += " x%.2g!" % mult
	var display := _session.combo.get_display()
	var color: Color = display["color"] if display.get("tier", "") != "" else Color(1.0, 0.9, 0.35)
	if mult < 1.25:
		color = Color(1.0, 0.9, 0.35)
	_feedback.show_popup(text, _miner.global_position, color)
