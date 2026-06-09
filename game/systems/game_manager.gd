extends Node2D

enum GamePhase { TITLE, PLAYING, PAUSED, CHEST_OPEN, GAME_OVER }

const VIEWPORT_SIZE := Vector2(960, 640)

var phase: GamePhase = GamePhase.TITLE
var floor_depth: int = 0
var floor_earned: int = 0
var run_money: int = 0
var time_left: float = 60.0
var target_money: int = 650
var run_seed: int = 0
var upgrades: Array[String] = []
var _paused_from_phase: GamePhase = GamePhase.PLAYING
var _after_chest: String = ""
var _pending_loot: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _current_layout: Array[Dictionary] = []

@onready var miner: Miner = $Miner
@onready var items_container: Node2D = $Items
@onready var hud: CanvasLayer = $HUD
@onready var overlay: CanvasLayer = $Overlay
@onready var chest_cinematic: ChestCinematic = $ChestCinematic
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var underground: ColorRect = $Underground
@onready var title_label: Label = $Overlay/TitleLabel
@onready var subtitle_label: Label = $Overlay/SubtitleLabel
@onready var score_label: Label = $HUD/ScoreLabel
@onready var target_label: Label = $HUD/TargetLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var hint_label: Label = $HUD/HintLabel
@onready var message_label: Label = $Overlay/MessageLabel
@onready var run_label: Label = $HUD/RunLabel


func _ready() -> void:
	_setup_layout()
	chest_cinematic.dismissed.connect(_on_chest_dismissed)
	_show_title()


func _process(delta: float) -> void:
	if phase != GamePhase.PLAYING:
		return
	time_left -= delta
	_update_hud()
	if time_left <= 0.0:
		_end_floor()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_handle_pause(event)
		return

	if phase == GamePhase.PAUSED:
		_handle_pause_menu_input(event)
		return

	if phase == GamePhase.CHEST_OPEN:
		if (
			chest_cinematic.state == ChestCinematic.State.WAITING
			and event.is_action_pressed("grab")
		):
			chest_cinematic.dismiss()
		return

	if not event.is_action_pressed("grab"):
		return
	match phase:
		GamePhase.TITLE:
			_start_run()
		GamePhase.GAME_OVER:
			_show_title()


func _handle_pause(event: InputEvent) -> void:
	if phase == GamePhase.PLAYING or phase == GamePhase.CHEST_OPEN:
		_show_pause()
	elif phase == GamePhase.PAUSED:
		_hide_pause()


func _handle_pause_menu_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("pause"):
		_hide_pause()
		return
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_N:
		_new_run()


func _setup_layout() -> void:
	background.size = VIEWPORT_SIZE
	background.color = Color(0.55, 0.78, 0.95)

	ground.position = Vector2(0, 120)
	ground.size = Vector2(VIEWPORT_SIZE.x, 24)
	ground.color = Color(0.35, 0.55, 0.25)

	underground.position = Vector2(0, 144)
	underground.size = Vector2(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y - 144)
	underground.color = Color(0.42, 0.30, 0.18)

	miner.position = Vector2(VIEWPORT_SIZE.x * 0.5, 100)


func _show_title() -> void:
	phase = GamePhase.TITLE
	overlay.visible = true
	hud.visible = false
	hint_label.visible = false
	miner.claw.swing_enabled = false

	var best_depth := RunSave.load_best_depth()
	var best_money := RunSave.load_best_run_money()
	title_label.text = "GOLD MINER ROGUELIKE"
	subtitle_label.text = "Press SPACE or Click to Descend"
	if best_depth > 0:
		message_label.text = "Best Depth: Floor %d  |  Best Run: $%d" % [best_depth, best_money]
	else:
		message_label.text = "Hook treasure chests for random stats. Clear floors for bonus loot."


func _show_pause() -> void:
	_paused_from_phase = phase
	phase = GamePhase.PAUSED
	miner.claw.swing_enabled = false
	overlay.visible = true
	title_label.text = "PAUSED"
	subtitle_label.text = "ESC — Resume"
	message_label.text = "N — New Run"


func _hide_pause() -> void:
	phase = _paused_from_phase
	if phase == GamePhase.PLAYING:
		overlay.visible = false
		hud.visible = true
		hint_label.visible = true
		miner.claw.swing_enabled = true
	elif phase == GamePhase.CHEST_OPEN:
		overlay.visible = false
		hud.visible = true
		hint_label.visible = false
	else:
		overlay.visible = true


func _new_run() -> void:
	chest_cinematic.dismiss()
	_start_run()


func _start_run() -> void:
	run_seed = randi()
	_rng.seed = run_seed
	floor_depth = 0
	floor_earned = 0
	run_money = 0
	upgrades.clear()
	_load_floor()


func _load_floor() -> void:
	floor_depth += 1
	floor_earned = 0
	time_left = LevelData.get_floor_time(floor_depth, _count_upgrade("extra_time"))

	_clear_items()
	_current_layout = LevelData.generate_floor_layout(
		floor_depth,
		_rng,
		_count_upgrade("gold_rush"),
		_count_upgrade("prospector"),
	)
	target_money = LevelData.compute_achievable_goal(_current_layout, floor_depth)
	_spawn_floor_items(_current_layout)
	miner.claw.apply_upgrades(upgrades)

	phase = GamePhase.PLAYING
	overlay.visible = false
	hud.visible = true
	hint_label.visible = true
	miner.claw.swing_enabled = true
	miner.claw.state = Claw.State.SWINGING
	_update_hud()


func _clear_items() -> void:
	for child in items_container.get_children():
		child.queue_free()


func _spawn_floor_items(layout: Array[Dictionary]) -> void:
	var item_scene: PackedScene = preload("res://game/scenes/item.tscn")
	var chest_scene: PackedScene = preload("res://game/scenes/chest.tscn")
	var spawn_rect := Rect2(60, 180, VIEWPORT_SIZE.x - 120, VIEWPORT_SIZE.y - 220)

	for entry in layout:
		var pos := Vector2(
			spawn_rect.position.x + spawn_rect.size.x * entry["x"],
			spawn_rect.position.y + spawn_rect.size.y * entry["y"],
		)
		if entry.get("id") == "chest":
			var chest: TreasureChest = chest_scene.instantiate()
			chest.global_position = pos
			items_container.add_child(chest)
			continue

		var item: MineItem = item_scene.instantiate()
		item.setup(entry["id"])
		item.global_position = pos
		items_container.add_child(item)


func register_item_collected(item: MineItem) -> void:
	floor_earned += item.value
	run_money += item.value
	item.collect()
	_update_hud()
	call_deferred("_check_floor_complete")


func register_chest_collected(chest: TreasureChest) -> void:
	var screen_pos := chest.global_position
	chest.open_and_vanish()
	_begin_chest_open(UpgradeData.pick_random_loot(_rng, upgrades), screen_pos, "resume")


func _check_floor_complete() -> void:
	if phase != GamePhase.PLAYING:
		return
	if floor_earned >= target_money or _only_chests_remain():
		_end_floor()


func _only_chests_remain() -> bool:
	for child in items_container.get_children():
		if child is MineItem:
			return false
	return items_container.get_child_count() == 0


func _end_floor() -> void:
	if phase != GamePhase.PLAYING:
		return
	miner.claw.swing_enabled = false

	var floor_cleared := floor_earned >= target_money or _only_chests_remain()
	if floor_cleared:
		RunSave.maybe_update_records(floor_depth, run_money)
		overlay.visible = true
		title_label.text = "FLOOR %d CLEARED!" % floor_depth
		subtitle_label.text = "Earned $%d / $%d  |  Run Total: $%d" % [floor_earned, target_money, run_money]
		message_label.text = "Opening reward chest..."
		_begin_chest_open(
			UpgradeData.pick_random_loot(_rng, upgrades),
			Vector2(VIEWPORT_SIZE.x * 0.5, VIEWPORT_SIZE.y * 0.52),
			"next_floor",
		)
	else:
		phase = GamePhase.GAME_OVER
		overlay.visible = true
		RunSave.maybe_update_records(floor_depth - 1, run_money)
		title_label.text = "RUN OVER"
		subtitle_label.text = "Floor %d failed — earned $%d / $%d" % [floor_depth, floor_earned, target_money]
		message_label.text = "Run Total: $%d  |  Seed: %d\nPress SPACE to Try Again" % [run_money, run_seed]


func _begin_chest_open(loot: Dictionary, screen_pos: Vector2, after: String) -> void:
	phase = GamePhase.CHEST_OPEN
	_after_chest = after
	_pending_loot = loot
	overlay.visible = false
	hint_label.visible = false
	miner.claw.swing_enabled = false
	chest_cinematic.play(loot, self, screen_pos)


func _on_chest_dismissed() -> void:
	if _pending_loot.is_empty():
		return

	var loot_id: String = _pending_loot.get("id", "")
	if loot_id != "" and loot_id not in upgrades:
		upgrades.append(loot_id)
	_pending_loot = {}
	miner.claw.apply_upgrades(upgrades)

	if _after_chest == "next_floor":
		_after_chest = ""
		_load_floor()
	elif _after_chest == "resume":
		_after_chest = ""
		phase = GamePhase.PLAYING
		hint_label.visible = true
		miner.claw.swing_enabled = true
		_update_hud()


func _count_upgrade(upgrade_id: String) -> int:
	var count := 0
	for id in upgrades:
		if id == upgrade_id:
			count += 1
	return count


func _update_hud() -> void:
	score_label.text = "Floor: $%d" % floor_earned
	target_label.text = "Goal: $%d" % target_money
	timer_label.text = "Time: %d" % ceili(time_left)
	level_label.text = "Depth %d" % floor_depth
	run_label.text = "Run: $%d" % run_money
