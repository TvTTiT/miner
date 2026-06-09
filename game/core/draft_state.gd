class_name DraftState
extends RefCounted

var offers: Array[Dictionary] = []
var after_action: String = ""
var header: String = ""
var subtitle: String = ""
var is_shop: bool = false
var shop_context: Dictionary = {}
var pending_loot: Dictionary = {}
var after_chest: String = ""


func reset() -> void:
	offers.clear()
	after_action = ""
	header = ""
	subtitle = ""
	is_shop = false
	shop_context.clear()
	pending_loot.clear()
	after_chest = ""
