class_name OverlayView
extends RefCounted

var root: CanvasLayer
var title_label: Label
var subtitle_label: Label
var message_label: Label


func show_title() -> void:
	root.visible = true
	title_label.text = "GOLD MINER ROGUELIKE"
	title_label.add_theme_color_override("font_color", GameTheme.OVERLAY_TITLE)
	subtitle_label.text = "Press SPACE or Click to Descend"
	subtitle_label.add_theme_color_override("font_color", GameTheme.OVERLAY_SUB)
	message_label.text = (
		"Stack gold veins old-school.\n"
		+ "Chain grabs → SPARK → FLOW → SURGE → JACKPOT.\n"
		+ "Shop hooks: Long, Electric, Magnetic, Triple, Rotary..."
	)
	message_label.add_theme_color_override("font_color", GameTheme.OVERLAY_BODY)


func show_pause(recipe_hint: String) -> void:
	root.visible = true
	title_label.text = "PAUSED"
	subtitle_label.text = "ESC — Resume"
	message_label.text = "N — New Run\n\n%s" % recipe_hint


func show_game_over(floor_depth: int, floor_earned: int, target: int, run_money: int, seed: int) -> void:
	root.visible = true
	title_label.text = "RUN OVER"
	subtitle_label.text = "Floor %d failed — earned $%d / $%d" % [floor_depth, floor_earned, target]
	message_label.text = "Run Total: $%d  |  Seed: %d\nPress SPACE to Try Again" % [run_money, seed]


func show_shop_intro(
	floor_depth: int,
	floor_earned: int,
	target: int,
	run_money: int,
	loadout_summary: String = "",
	recipe_hint: String = "",
) -> void:
	root.visible = true
	title_label.text = "ROUND %d — NICE HAUL!" % floor_depth
	subtitle_label.text = "Earned $%d / $%d  ·  Run total $%d" % [floor_earned, target, run_money]
	var body := "The merchant's wagon creaks into camp...\nTake your time — read your gear and fusion paths."
	if loadout_summary != "":
		body += "\n\nEquipped: %s" % loadout_summary
	if recipe_hint != "":
		body += "\n\n%s" % recipe_hint
	body += "\n\nPress SPACE or Click when ready to browse wares"
	message_label.text = body


func show_vault_intro() -> void:
	root.visible = true
	title_label.text = "VAULT FLOOR!"
	subtitle_label.text = "Grab fast — dragon awake!"
	message_label.text = (
		"Dense stacked gold. Tighter timer. Dragon + bats guard the vault.\n\n"
		+ "Press SPACE or Click when ready"
	)


func hide() -> void:
	root.visible = false
