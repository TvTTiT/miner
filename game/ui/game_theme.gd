class_name GameTheme
extends RefCounted

const HUD_BG := Color(0.08, 0.06, 0.12, 0.88)
const HUD_ACCENT := Color(0.95, 0.72, 0.22, 0.9)
const HUD_TEXT := Color(0.92, 0.94, 0.98)
const GOLD := Color(1.0, 0.85, 0.28)
const GOAL := Color(0.82, 0.88, 0.95)
const DEPTH := Color(0.55, 0.82, 1.0)
const RUN := Color(0.78, 0.68, 1.0)
const TIMER := Color(1.0, 0.52, 0.42)
const TIMER_URGENT := Color(1.0, 0.28, 0.22)

const OVERLAY_TITLE := Color(1.0, 0.82, 0.22)
const OVERLAY_SUB := Color(0.95, 0.96, 1.0)
const OVERLAY_BODY := Color(0.78, 0.84, 0.95)

const RARITY := {
	"common": Color(0.72, 0.72, 0.78),
	"uncommon": Color(0.38, 0.92, 0.52),
	"rare": Color(0.42, 0.68, 1.0),
	"epic": Color(0.78, 0.45, 0.98),
	"fusion": Color(1.0, 0.78, 0.28),
}

const COMBO_TIER_COLORS := {
	"SPARK": Color(0.55, 0.95, 0.72),
	"FLOW": Color(0.45, 0.85, 1.0),
	"SURGE": Color(0.95, 0.75, 0.35),
	"FURY": Color(1.0, 0.55, 0.28),
	"JACKPOT": Color(1.0, 0.42, 0.82),
	"GOLD RUSH": Color(1.0, 0.92, 0.35),
}

static func rarity_color(rarity: String) -> Color:
	return RARITY.get(rarity, RARITY["common"])


static func combo_color(tier_name: String) -> Color:
	return COMBO_TIER_COLORS.get(tier_name, Color(0.5, 0.55, 0.6))


static func hook_icon(style: String) -> String:
	return ToolData.hook_icon(style)


static func hook_icon_for_entry(entry: Dictionary) -> String:
	return ToolData.hook_icon_for_entry(entry)
