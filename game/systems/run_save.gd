class_name RunSave
extends RefCounted

const SAVE_PATH := "user://roguelike_save.cfg"

static func load_best_depth() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return config.get_value("stats", "best_depth", 0)


static func load_best_run_money() -> int:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0
	return config.get_value("stats", "best_run_money", 0)


static func maybe_update_records(depth: int, run_money: int) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var best_depth: int = config.get_value("stats", "best_depth", 0)
	var best_money: int = config.get_value("stats", "best_run_money", 0)
	var changed := false
	if depth > best_depth:
		config.set_value("stats", "best_depth", depth)
		changed = true
	if run_money > best_money:
		config.set_value("stats", "best_run_money", run_money)
		changed = true
	if changed:
		config.save(SAVE_PATH)
