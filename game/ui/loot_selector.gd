class_name LootSelector
extends CanvasLayer

signal offer_selected(offer: Dictionary)

const VIEWPORT := Vector2(960, 640)
const CARD_SIZE := Vector2(272, 196)

const RARITY_COLORS := preload("res://game/ui/game_theme.gd").RARITY

const RARITY_BG := {
	"common": Color(0.14, 0.14, 0.18, 0.94),
	"uncommon": Color(0.10, 0.18, 0.13, 0.94),
	"rare": Color(0.10, 0.14, 0.22, 0.94),
	"epic": Color(0.16, 0.10, 0.22, 0.94),
	"fusion": Color(0.22, 0.16, 0.08, 0.96),
}

var _offers: Array[Dictionary] = []
var _cards: Array[PanelContainer] = []
var _hover_index: int = -1

@onready var dimmer: ColorRect = $Dimmer
@onready var root: Control = $Root
@onready var title_label: Label = $Root/TitleLabel
@onready var subtitle_label: Label = $Root/SubtitleLabel
@onready var owned_label: Label = $Root/OwnedLabel
@onready var preview_label: Label = $Root/PreviewLabel
@onready var cards_row: HBoxContainer = $Root/CardsRow

const MERCHANT_QUOTES: Array[String] = [
	"Fresh gear for the next dig — one pick only!",
	"Stack that gold high, stranger. What'll it be?",
	"Fusions don't fuse themselves. Choose wisely.",
	"The vein runs deeper. You'll want upgrades.",
]
@onready var recipe_label: Label = $Root/RecipeLabel
@onready var hint_label: Label = $Root/HintLabel


func _ready() -> void:
	visible = false


func show_draft(
	offers: Array[Dictionary],
	loadout: RunLoadout,
	header: String = "CHOOSE YOUR LOOT",
	subtitle: String = "",
	is_shop: bool = false,
	shop_context: Dictionary = {},
) -> void:
	_offers = offers
	_hover_index = -1
	_clear_cards()

	if is_shop:
		title_label.text = "MERCHANT'S WAGON"
		subtitle_label.text = subtitle if subtitle != "" else MERCHANT_QUOTES[randi() % MERCHANT_QUOTES.size()]
		_apply_shop_preview(shop_context)
	else:
		title_label.text = header
		subtitle_label.text = subtitle if subtitle != "" else "Treasure chest — grab one reward"
		preview_label.text = ""

	owned_label.text = "Equipped: %s" % loadout.get_display_summary()
	recipe_label.text = loadout.get_recipe_hint()
	if recipe_label.text == "":
		recipe_label.text = "Collect matching pairs to unlock ★ fusions"

	for i in offers.size():
		var card := _build_card(offers[i], i, loadout)
		cards_row.add_child(card)
		_cards.append(card)

	visible = true
	_animate_in()


func _apply_shop_preview(ctx: Dictionary) -> void:
	if ctx.is_empty():
		preview_label.text = ""
		return
	var parts: PackedStringArray = [
		"Next: Depth %d" % ctx.get("depth", 1),
		"Goal %s" % ctx.get("goal_hint", "?"),
		"%ds timer" % ctx.get("time_sec", 60),
		ctx.get("hazard_note", ""),
	]
	if ctx.get("vault_note", "") != "":
		parts.append(ctx.get("vault_note", ""))
	preview_label.text = "  ·  ".join(parts)


func hide_selector() -> void:
	visible = false
	_clear_cards()
	dimmer.modulate = Color.WHITE
	root.modulate = Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_pressed() or event.is_echo():
		return
	var choice := -1
	if event is InputEventKey:
		match (event as InputEventKey).keycode:
			KEY_1, KEY_KP_1:
				choice = 0
			KEY_2, KEY_KP_2:
				choice = 1
			KEY_3, KEY_KP_3:
				choice = 2
	if choice >= 0 and choice < _offers.size():
		_select_index(choice)


func _select_index(index: int) -> void:
	if index < 0 or index >= _offers.size():
		return
	_pulse_card(_cards[index])
	offer_selected.emit(_offers[index])


func _build_card(offer: Dictionary, index: int, loadout: RunLoadout) -> PanelContainer:
	var rarity: String = offer.get("rarity", "common")
	if offer.get("offer_kind") == "fusion":
		rarity = "fusion"

	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _make_card_style(rarity, false))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Top row: badges + key
	var top := HBoxContainer.new()
	vbox.add_child(top)

	var kind_badge := _make_badge(_kind_label(offer), _kind_color(offer))
	top.add_child(kind_badge)

	var cat_badge := _make_badge(_category_label(offer.get("category", "skill")), Color(0.25, 0.25, 0.32, 0.9))
	top.add_child(cat_badge)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	var key_badge := _make_badge("[%d]" % (index + 1), Color(0.18, 0.18, 0.24, 0.95), 22)
	key_badge.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))
	top.add_child(key_badge)

	# Rarity strip label
	var rarity_label := Label.new()
	rarity_label.text = rarity.to_upper()
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))
	vbox.add_child(rarity_label)

	# Name + hook icon
	var name_label := Label.new()
	var icon: String = offer.get("hook_icon", "")
	if icon == "" and offer.get("hook_style", "") != "":
		icon = ToolData.hook_icon(offer.get("hook_style", ""))
	var prefix := "%s " % icon if icon != "" and icon != "✦" else ""
	if offer.get("category") == "skill":
		prefix = "✦ " if prefix == "" else prefix
	name_label.text = prefix + offer.get("name", "Unknown")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82))
	vbox.add_child(name_label)

	# Level pips
	if offer.get("offer_kind") != "fusion":
		vbox.add_child(_build_level_row(offer, loadout))

	# Description
	var desc_label := Label.new()
	desc_label.text = offer.get("desc", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	vbox.add_child(desc_label)

	# Fusion parents
	if offer.get("offer_kind") == "fusion":
		var parents_label := Label.new()
		parents_label.text = _format_parents(offer, loadout)
		parents_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parents_label.add_theme_font_size_override("font_size", 12)
		parents_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
		vbox.add_child(parents_label)

	panel.gui_input.connect(_on_card_gui_input.bind(index))
	panel.mouse_entered.connect(_on_card_hover.bind(index))
	panel.mouse_exited.connect(_on_card_unhover.bind(index))

	return panel


func _build_level_row(offer: Dictionary, loadout: RunLoadout) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var kind: String = offer.get("offer_kind", "new")
	var preview: int = offer.get("preview_level", 1)
	var label := Label.new()
	if kind == "level_up":
		label.text = "LEVEL %d → %d" % [loadout.get_level(offer["id"]), preview]
	else:
		label.text = "NEW — LEVEL 1"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	row.add_child(label)

	for i in ToolData.MAX_LEVEL:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(10, 10)
		pip.color = RARITY_COLORS.get(offer.get("rarity", "common"), Color.WHITE) if i < preview else Color(0.3, 0.3, 0.35)
		row.add_child(pip)

	return row


func _format_parents(offer: Dictionary, loadout: RunLoadout) -> String:
	var parts: PackedStringArray = []
	for parent_id in offer.get("parents", []):
		var p := ToolData.get_entry(parent_id)
		var mark := "✓" if loadout.owns(parent_id) else "○"
		parts.append("%s %s" % [mark, p["name"]])
	return "Fuse: " + "  +  ".join(parts)


func _kind_label(offer: Dictionary) -> String:
	match offer.get("offer_kind", "new"):
		"fusion":
			return "★ FUSION"
		"level_up":
			return "LEVEL UP"
		_:
			return "NEW"


func _kind_color(offer: Dictionary) -> Color:
	match offer.get("offer_kind", "new"):
		"fusion":
			return Color(0.45, 0.32, 0.08, 0.95)
		"level_up":
			return Color(0.12, 0.28, 0.42, 0.95)
		_:
			return Color(0.18, 0.32, 0.18, 0.95)


func _category_label(category: String) -> String:
	match category:
		"tool":
			return "TOOL"
		"fusion":
			return "EVOLVED"
		_:
			return "SKILL"


func _make_badge(text: String, bg: Color, font_size: int = 11) -> PanelContainer:
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	badge.add_child(label)
	return badge


func _make_card_style(rarity: String, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = RARITY_BG.get(rarity, RARITY_BG["common"])
	style.border_color = RARITY_COLORS.get(rarity, Color.WHITE)
	style.border_width_top = 4
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	if hovered:
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.bg_color = style.bg_color.lightened(0.08)
	return style


func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(index)


func _on_card_hover(index: int) -> void:
	_hover_index = index
	_refresh_hover_styles()


func _on_card_unhover(_index: int) -> void:
	_hover_index = -1
	_refresh_hover_styles()


func _refresh_hover_styles() -> void:
	for i in _cards.size():
		var offer := _offers[i]
		var rarity: String = offer.get("rarity", "common")
		if offer.get("offer_kind") == "fusion":
			rarity = "fusion"
		_cards[i].add_theme_stylebox_override("panel", _make_card_style(rarity, i == _hover_index))


func _pulse_card(card: PanelContainer) -> void:
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2(1.06, 1.06), 0.08)
	tween.tween_property(card, "scale", Vector2.ONE, 0.12)


func _animate_in() -> void:
	dimmer.modulate.a = 0.0
	root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(root, "modulate:a", 1.0, 0.22)
	for i in _cards.size():
		var card := _cards[i]
		card.scale = Vector2(0.85, 0.85)
		card.modulate.a = 0.0
		var ct := create_tween()
		ct.tween_property(card, "scale", Vector2.ONE, 0.25).set_delay(0.06 * float(i)).set_trans(Tween.TRANS_BACK)
		ct.parallel().tween_property(card, "modulate:a", 1.0, 0.2).set_delay(0.06 * float(i))


func _clear_cards() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	for child in cards_row.get_children():
		child.queue_free()
