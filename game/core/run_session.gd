class_name RunSession
extends RefCounted

var phase: GamePhase.Id = GamePhase.Id.TITLE
var floor_depth: int = 0
var floor_earned: int = 0
var run_money: int = 0
var time_left: float = 60.0
var floor_time_max: float = 60.0
var target_money: int = 650
var run_seed: int = 0
var is_vault_floor: bool = false
var paused_from_phase: GamePhase.Id = GamePhase.Id.PLAYING
var current_layout: Array[Dictionary] = []

var rng := RandomNumberGenerator.new()
var combo := ComboSystem.new()
var loadout := RunLoadout.new()


func start_new_run(seed: int = -1) -> void:
	run_seed = seed if seed >= 0 else randi()
	rng.seed = run_seed
	floor_depth = 0
	floor_earned = 0
	run_money = 0
	loadout = RunLoadout.new()
	loadout.reset()
	combo.reset()


func prepare_floor(vault: bool, time: float, goal: int, layout: Array[Dictionary]) -> void:
	floor_depth += 1
	floor_earned = 0
	is_vault_floor = vault
	time_left = time
	floor_time_max = time
	target_money = goal
	current_layout = layout


func add_earnings(amount: int) -> void:
	floor_earned += amount
	run_money += amount


func apply_time_penalty(seconds: float) -> void:
	time_left = maxf(0.0, time_left - seconds)


func chest_rarity_bonus() -> int:
	var bonus := combo.get_rarity_bonus()
	if is_vault_floor:
		bonus += 1
	return bonus
