class_name Miner
extends Node2D

@onready var claw: Claw = $Claw
@onready var body_sprite: ColorRect = $Body
@onready var hat_sprite: ColorRect = $Hat
@onready var face_sprite: ColorRect = $Face


func _ready() -> void:
	claw.item_delivered.connect(_on_item_delivered)
	claw.chest_delivered.connect(_on_chest_delivered)
	claw.empty_retract.connect(_on_empty_retract)
	claw.hazard_hit.connect(_on_hazard_hit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		claw.fire()


func _game() -> GameController:
	return get_parent() as GameController


func _on_item_delivered(item: MineItem) -> void:
	_game().register_item_collected(item)


func _on_chest_delivered(chest: TreasureChest) -> void:
	_game().register_chest_collected(chest)


func _on_empty_retract() -> void:
	_game().register_empty_retract()


func _on_hazard_hit(payload: Dictionary) -> void:
	_game().register_hazard_hit(payload)
