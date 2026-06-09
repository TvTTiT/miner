class_name HudView
extends RefCounted

var score_label: Label
var target_label: Label
var timer_label: Label
var level_label: Label
var run_label: Label
var combo_label: Label
var combo_tier_label: Label
var combo_bar: ColorRect
var combo_bar_fill: ColorRect
var loadout_label: Label
var hint_label: Label
var panel: CanvasLayer
var hud_panel: ColorRect


func refresh(session: RunSession) -> void:
	if score_label:
		score_label.text = "⛏ $%d" % session.floor_earned
		score_label.add_theme_color_override("font_color", GameTheme.GOLD)
	if target_label:
		var pct := clampf(float(session.floor_earned) / float(maxi(1, session.target_money)), 0.0, 1.0)
		target_label.text = "Goal $%d (%.0f%%)" % [session.target_money, pct * 100.0]
		target_label.add_theme_color_override("font_color", GameTheme.GOAL)
	if timer_label:
		timer_label.text = "⏱ %ds" % ceili(session.time_left)
		var urgent := session.time_left <= 15.0
		timer_label.add_theme_color_override(
			"font_color",
			GameTheme.TIMER_URGENT if urgent else GameTheme.TIMER,
		)
	if level_label:
		var depth_text := "Depth %d" % session.floor_depth
		if session.is_vault_floor:
			depth_text = "★ VAULT %d" % session.floor_depth
		level_label.text = depth_text
		level_label.add_theme_color_override("font_color", GameTheme.DEPTH)
	if run_label:
		run_label.text = "Run $%d" % session.run_money
		run_label.add_theme_color_override("font_color", GameTheme.RUN)
	if loadout_label:
		loadout_label.text = session.loadout.get_display_summary()

	_refresh_combo(session)


func _refresh_combo(session: RunSession) -> void:
	var display := session.combo.get_display()
	var tier: String = display.get("tier", "")
	var streak: int = display.get("streak", 0)
	var heat: float = display.get("heat", 0.0)
	var color: Color = display.get("color", Color(0.45, 0.5, 0.55))
	var mult: float = display.get("mult", 1.0)

	if combo_tier_label:
		if tier != "":
			combo_tier_label.text = "%s  x%.2g" % [tier, mult]
			combo_tier_label.add_theme_color_override("font_color", color)
		elif streak == 1:
			combo_tier_label.text = "CHAIN START"
			combo_tier_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.72))
		else:
			combo_tier_label.text = ""

	if combo_label:
		if streak >= 1:
			var tagline: String = display.get("tagline", "")
			var same: int = display.get("same_chain", 0)
			var extra := ""
			if same >= 2:
				extra = "  ·  stack x%d" % same
			combo_label.text = "Combo %d%s  %s" % [streak, extra, tagline]
			combo_label.add_theme_color_override("font_color", color)
		else:
			combo_label.text = ""

	if combo_bar_fill and combo_bar:
		var bar_width := combo_bar.size.x * heat
		combo_bar_fill.size.x = bar_width
		combo_bar_fill.color = color
		combo_bar.visible = streak > 0
		combo_bar_fill.visible = streak > 0
