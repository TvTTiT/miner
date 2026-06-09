class_name GameConfig
extends RefCounted

const VIEWPORT_SIZE := Vector2(960, 640)
const DYNAMITE_RADIUS_BASE := 120.0
const DEFAULT_STUN := 1.5
const DEFAULT_TIME_PENALTY := 3.0
const SHOP_INTRO_DELAY := 1.35
const VAULT_INTRO_DELAY := 1.5

const UNDERGROUND_NORMAL := Color(0.42, 0.30, 0.18)
const UNDERGROUND_VAULT := Color(0.52, 0.38, 0.14)

const SCENE_ITEM := "res://game/scenes/items/item.tscn"
const SCENE_CHEST := "res://game/scenes/items/chest.tscn"
const SCENE_DRAGON := "res://game/scenes/hazards/dragon.tscn"
const SCENE_BAT := "res://game/scenes/hazards/bat.tscn"
const SCENE_MOLE := "res://game/scenes/hazards/mole.tscn"

static func spawn_rect() -> Rect2:
	return Rect2(60, 180, VIEWPORT_SIZE.x - 120, VIEWPORT_SIZE.y - 220)
