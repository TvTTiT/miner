extends Node2D

enum GamePhase { TITLE, PLAYING, LEVEL_COMPLETE, GAME_OVER, VICTORY }

const VIEWPORT_SIZE := Vector2(960, 640)

var phase: GamePhase = GamePhase.TITLE
var current_level: int = 0
var score: int = 0
var time_left: float = 60.0
var target_money: int = 650

@onready var miner: Miner = $Miner
@onready var items_container: Node2D = $Items
@onready var hud: CanvasLayer = $HUD
@onready var overlay: CanvasLayer = $Overlay
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


func _ready() -> void:
	_setup_layout()
	_show_title()


func _process(delta: float) -> void:
	if phase != GamePhase.PLAYING:
		return
	time_left -= delta
	_update_hud()
	if time_left <= 0.0:
		_end_level()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("grab"):
		return
	match phase:
		GamePhase.TITLE:
			_start_game()
		GamePhase.LEVEL_COMPLETE:
			_next_level()
		GamePhase.GAME_OVER, GamePhase.VICTORY:
			_restart_game()


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
	title_label.text = "GOLD MINER"
	subtitle_label.text = "Press SPACE or Click to Start"
	message_label.text = ""


func _start_game() -> void:
	current_level = 0
	score = 0
	_load_level(0)


func _restart_game() -> void:
	_start_game()


func _load_level(level_index: int) -> void:
	current_level = level_index
	var level_data := LevelData.get_level(level_index)
	target_money = level_data["target"]
	time_left = level_data["time"]

	_clear_items()
	_spawn_items(level_index)

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


func _spawn_items(level_index: int) -> void:
	var layout := LevelData.get_spawn_layout(level_index)
	var item_scene: PackedScene = preload("res://scenes/item.tscn")
	var spawn_rect := Rect2(60, 180, VIEWPORT_SIZE.x - 120, VIEWPORT_SIZE.y - 220)

	for entry in layout:
		var item: MineItem = item_scene.instantiate()
		var id: String = entry["id"]
		var pos := Vector2(
			spawn_rect.position.x + spawn_rect.size.x * entry["x"],
			spawn_rect.position.y + spawn_rect.size.y * entry["y"],
		)
		item.setup(id)
		item.global_position = pos
		items_container.add_child(item)


func register_item_collected(item: MineItem) -> void:
	score += item.value
	item.collect()
	_update_hud()
	if score >= target_money:
		_end_level()


func _end_level() -> void:
	miner.claw.swing_enabled = false
	overlay.visible = true

	if score >= target_money:
		if current_level >= LevelData.LEVELS.size() - 1:
			phase = GamePhase.VICTORY
			title_label.text = "YOU WIN!"
			subtitle_label.text = "Final Score: $%d" % score
			message_label.text = "Press SPACE to Play Again"
		else:
			phase = GamePhase.LEVEL_COMPLETE
			var level_data := LevelData.get_level(current_level)
			title_label.text = "LEVEL CLEAR!"
			subtitle_label.text = "Earned $%d / $%d" % [score, target_money]
			message_label.text = "Press SPACE for %s" % LevelData.get_level(current_level + 1)["name"]
	else:
		phase = GamePhase.GAME_OVER
		title_label.text = "GAME OVER"
		subtitle_label.text = "Needed $%d — You had $%d" % [target_money, score]
		message_label.text = "Press SPACE to Retry"


func _next_level() -> void:
	_load_level(current_level + 1)


func _update_hud() -> void:
	score_label.text = "Money: $%d" % score
	target_label.text = "Goal: $%d" % target_money
	timer_label.text = "Time: %d" % ceili(time_left)
	level_label.text = LevelData.get_level(current_level)["name"]
