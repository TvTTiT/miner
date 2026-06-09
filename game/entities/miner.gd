class_name Miner
extends Node2D

@onready var claw: Claw = $Claw
@onready var body_sprite: ColorRect = $Body
@onready var hat_sprite: ColorRect = $Hat
@onready var face_sprite: ColorRect = $Face


func _ready() -> void:
	claw.item_delivered.connect(_on_item_delivered)
	claw.chest_delivered.connect(_on_chest_delivered)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		claw.fire()


func _on_item_delivered(item: MineItem) -> void:
	get_parent().register_item_collected(item)


func _on_chest_delivered(chest: TreasureChest) -> void:
	get_parent().register_chest_collected(chest)
