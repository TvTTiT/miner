class_name GameController
extends Node2D

var session := RunSession.new()
var draft := DraftState.new()

var _spawner := FloorSpawner.new()
var _hazards := HazardSpawner.new()
var _loot := LootResolver.new()
var _shop := ShopFlow.new()
var _hud := HudView.new()
var _overlay := OverlayView.new()

@onready var miner: Miner = $Miner
@onready var items_container: Node2D = $Items
@onready var hud: CanvasLayer = $HUD
@onready var overlay: CanvasLayer = $Overlay
@onready var chest_cinematic: ChestCinematic = $ChestCinematic
@onready var loot_feedback: LootFeedback = $LootFeedback
@onready var loot_selector: LootSelector = $LootSelector
@onready var time_pressure: TimePressure = $TimePressure
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var underground: ColorRect = $Underground
@onready var title_label: Label = $Overlay/TitleLabel
@onready var subtitle_label: Label = $Overlay/SubtitleLabel
@onready var score_label: Label = $HUD/ScoreLabel
@onready var target_label: Label = $HUD/TargetLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var combo_label: Label = $HUD/ComboLabel
@onready var combo_tier_label: Label = $HUD/ComboTierLabel
@onready var combo_bar: ColorRect = $HUD/ComboBar
@onready var combo_bar_fill: ColorRect = $HUD/ComboBar/ComboBarFill
@onready var loadout_label: Label = $HUD/LoadoutLabel
@onready var hint_label: Label = $HUD/HintLabel
@onready var message_label: Label = $Overlay/MessageLabel
@onready var run_label: Label = $HUD/RunLabel


func _ready() -> void:
	add_to_group("game_controller")
	_setup_world()
	_bind_views()
	_wire_services()
	chest_cinematic.dismissed.connect(_on_chest_dismissed)
	loot_selector.offer_selected.connect(_on_draft_pick)
	_show_title()


func _process(delta: float) -> void:
	if session.phase != GamePhase.Id.PLAYING:
		return
	session.time_left -= delta
	_hud.refresh(session)
	time_pressure.update(session.time_left, timer_label, delta)
	if session.time_left <= 0.0:
		_end_floor()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		return

	if session.phase == GamePhase.Id.PAUSED:
		_handle_pause_input(event)
		return

	if session.phase == GamePhase.Id.CHEST_SELECT:
		return

	if session.phase == GamePhase.Id.CHEST_OPEN:
		if chest_cinematic.state == ChestCinematic.State.WAITING and event.is_action_pressed("grab"):
			chest_cinematic.dismiss()
		return

	if session.phase == GamePhase.Id.SHOP_INTRO:
		if event.is_action_pressed("grab"):
			_open_round_shop()
		return

	if session.phase == GamePhase.Id.VAULT_INTRO:
		if event.is_action_pressed("grab"):
			_finish_vault_intro()
		return

	if not event.is_action_pressed("grab"):
		return
	match session.phase:
		GamePhase.Id.TITLE:
			_start_run()
		GamePhase.Id.GAME_OVER:
			_show_title()


# --- Public API (called by Miner) ---

func register_item_collected(item: MineItem) -> void:
	_loot.resolve_item(item)
	_hud.refresh(session)
	call_deferred("_check_floor_complete")


func register_chest_collected(chest: TreasureChest) -> void:
	chest.open_and_vanish()
	_loot.resolve_chest_pick()
	_open_draft("resume", "TREASURE CHEST", "Pick one reward before you keep mining")


func register_empty_retract() -> void:
	_loot.resolve_miss()


func register_hazard_hit(payload: Dictionary) -> void:
	_loot.resolve_hazard(payload, self)
	_hud.refresh(session)


# --- Setup ---

func _setup_world() -> void:
	background.size = GameConfig.VIEWPORT_SIZE
	background.color = Color(0.55, 0.78, 0.95)
	ground.position = Vector2(0, 120)
	ground.size = Vector2(GameConfig.VIEWPORT_SIZE.x, 24)
	ground.color = Color(0.35, 0.55, 0.25)
	underground.position = Vector2(0, 144)
	underground.size = Vector2(GameConfig.VIEWPORT_SIZE.x, GameConfig.VIEWPORT_SIZE.y - 144)
	underground.color = GameConfig.UNDERGROUND_NORMAL
	miner.position = Vector2(GameConfig.VIEWPORT_SIZE.x * 0.5, 100)


func _bind_views() -> void:
	_hud.panel = hud
	_hud.score_label = score_label
	_hud.target_label = target_label
	_hud.timer_label = timer_label
	_hud.level_label = level_label
	_hud.run_label = run_label
	_hud.combo_label = combo_label
	_hud.combo_tier_label = combo_tier_label
	_hud.combo_bar = combo_bar
	_hud.combo_bar_fill = combo_bar_fill
	_hud.hud_panel = $HUD/Panel
	_hud.loadout_label = loadout_label
	_hud.hint_label = hint_label

	_overlay.root = overlay
	_overlay.title_label = title_label
	_overlay.subtitle_label = subtitle_label
	_overlay.message_label = message_label


func _wire_services() -> void:
	var spawn_rect := GameConfig.spawn_rect()
	_spawner.setup(items_container, spawn_rect)
	_hazards.setup(items_container, spawn_rect)
	_loot.setup(session, _spawner, loot_feedback, miner)
	_shop.setup(session, draft)


# --- Flow ---

func _show_title() -> void:
	session.phase = GamePhase.Id.TITLE
	_overlay.show_title()
	hud.visible = false
	hint_label.visible = false
	miner.claw.swing_enabled = false
	loot_selector.hide_selector()


func _start_run() -> void:
	session.start_new_run()
	_load_floor()


func _new_run() -> void:
	chest_cinematic.dismiss()
	_start_run()


func _load_floor() -> void:
	var mods := session.loadout.get_modifiers()
	var vault := LevelData.roll_is_vault(session.floor_depth + 1, session.rng)
	var time := LevelData.get_floor_time(session.floor_depth + 1, mods["extra_time"], vault)
	var layout := LevelData.generate_floor_layout(
		session.floor_depth + 1,
		session.rng,
		mods["gold_rush"],
		mods["prospector"],
		vault,
	)
	var goal := LevelData.compute_achievable_goal(layout, session.floor_depth + 1, vault)
	session.prepare_floor(vault, time, goal, layout)

	_spawner.clear()
	_spawner.spawn_layout(layout)
	_hazards.spawn_for_floor(session)
	_apply_loadout()

	time_pressure.reset_for_floor(session.floor_time_max)
	session.combo.set_grace_charges(mods.get("combo_grace", 0))
	session.combo.set_combo_bonus(mods.get("combo_bonus", 0.0))
	underground.color = GameConfig.UNDERGROUND_VAULT if vault else GameConfig.UNDERGROUND_NORMAL
	hud.visible = true
	hint_label.visible = true
	miner.claw.swing_enabled = false
	miner.claw.state = Claw.State.SWINGING
	_hud.refresh(session)

	if vault:
		_show_vault_intro()
	else:
		session.phase = GamePhase.Id.PLAYING
		_overlay.hide()
		miner.claw.swing_enabled = true


func _apply_loadout() -> void:
	var mods := session.loadout.get_modifiers()
	miner.claw.apply_modifiers(mods)
	session.combo.set_combo_bonus(mods.get("combo_bonus", 0.0))


func _show_vault_intro() -> void:
	session.phase = GamePhase.Id.VAULT_INTRO
	_overlay.show_vault_intro()


func _finish_vault_intro() -> void:
	if session.phase != GamePhase.Id.VAULT_INTRO:
		return
	session.phase = GamePhase.Id.PLAYING
	_overlay.hide()
	miner.claw.swing_enabled = true


func _check_floor_complete() -> void:
	if session.phase != GamePhase.Id.PLAYING:
		return
	if session.floor_earned >= session.target_money or _spawner.only_chests_remain():
		_end_floor()


func _end_floor() -> void:
	if session.phase != GamePhase.Id.PLAYING:
		return
	miner.claw.swing_enabled = false

	var cleared := session.floor_earned >= session.target_money or _spawner.only_chests_remain()
	if cleared:
		RunSave.maybe_update_records(session.floor_depth, session.run_money)
		_begin_shop_intro()
	else:
		session.phase = GamePhase.Id.GAME_OVER
		RunSave.maybe_update_records(session.floor_depth - 1, session.run_money)
		_overlay.show_game_over(
			session.floor_depth,
			session.floor_earned,
			session.target_money,
			session.run_money,
			session.run_seed,
		)


func _begin_shop_intro() -> void:
	session.phase = GamePhase.Id.SHOP_INTRO
	miner.claw.swing_enabled = false
	hud.visible = true
	hint_label.visible = false
	_overlay.show_shop_intro(
		session.floor_depth,
		session.floor_earned,
		session.target_money,
		session.run_money,
		session.loadout.get_display_summary(),
		session.loadout.get_recipe_hint(),
	)


func _open_round_shop() -> void:
	if session.phase != GamePhase.Id.SHOP_INTRO:
		return
	var ctx := _shop.build_shop_context()
	var sub := "Run banked $%d — spend your luck on one tool or skill" % session.run_money
	_open_draft("next_floor", "", sub, true, ctx)


func _open_draft(
	after: String,
	header: String = "",
	subtitle: String = "",
	is_shop: bool = false,
	shop_context: Dictionary = {},
) -> void:
	session.phase = GamePhase.Id.CHEST_SELECT
	_shop.begin_draft(after, header, subtitle, is_shop, shop_context)
	_overlay.hide()
	hud.visible = true
	hint_label.visible = false
	miner.claw.swing_enabled = false
	loot_selector.show_draft(
		draft.offers,
		session.loadout,
		draft.header,
		draft.subtitle,
		draft.is_shop,
		draft.shop_context,
	)


func _on_draft_pick(offer: Dictionary) -> void:
	var reveal := _shop.apply_pick(offer)
	_apply_loadout()
	loot_selector.hide_selector()
	draft.after_chest = draft.after_action

	var screen_pos := Vector2(GameConfig.VIEWPORT_SIZE.x * 0.5, GameConfig.VIEWPORT_SIZE.y * 0.52)
	session.phase = GamePhase.Id.CHEST_OPEN
	_overlay.hide()
	hint_label.visible = false
	miner.claw.swing_enabled = false
	chest_cinematic.play(reveal, self, screen_pos, reveal.get("bonus_text", ""))


func _on_chest_dismissed() -> void:
	draft.pending_loot.clear()
	_apply_loadout()

	if draft.after_chest == "next_floor":
		draft.after_chest = ""
		_load_floor()
	elif draft.after_chest == "resume":
		draft.after_chest = ""
		session.phase = GamePhase.Id.PLAYING
		hint_label.visible = true
		miner.claw.swing_enabled = true
		_hud.refresh(session)


# --- Pause ---

func _toggle_pause() -> void:
	if session.phase in [
		GamePhase.Id.PLAYING,
		GamePhase.Id.CHEST_OPEN,
		GamePhase.Id.CHEST_SELECT,
		GamePhase.Id.VAULT_INTRO,
		GamePhase.Id.SHOP_INTRO,
	]:
		_show_pause()
	elif session.phase == GamePhase.Id.PAUSED:
		_hide_pause()


func _show_pause() -> void:
	session.paused_from_phase = session.phase
	session.phase = GamePhase.Id.PAUSED
	miner.claw.swing_enabled = false
	if session.paused_from_phase == GamePhase.Id.CHEST_SELECT:
		loot_selector.hide_selector()
	_overlay.show_pause(session.loadout.get_recipe_hint())


func _hide_pause() -> void:
	session.phase = session.paused_from_phase
	match session.phase:
		GamePhase.Id.PLAYING:
			_overlay.hide()
			hud.visible = true
			hint_label.visible = true
			miner.claw.swing_enabled = true
		GamePhase.Id.CHEST_OPEN:
			_overlay.hide()
			hud.visible = true
			hint_label.visible = false
		GamePhase.Id.CHEST_SELECT:
			_overlay.hide()
			hud.visible = true
			hint_label.visible = false
			loot_selector.show_draft(
				draft.offers,
				session.loadout,
				draft.header,
				draft.subtitle,
				draft.is_shop,
				draft.shop_context,
			)
		GamePhase.Id.VAULT_INTRO, GamePhase.Id.SHOP_INTRO:
			overlay.visible = true
			hud.visible = true
			hint_label.visible = false
		_:
			overlay.visible = true


func _handle_pause_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("pause"):
		_hide_pause()
		return
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_N:
		_new_run()
