class_name FloorHazard
extends Area2D

func _ready() -> void:
	add_to_group("floor_hazard")
	collision_layer = 4
	collision_mask = 0


func get_hit_payload() -> Dictionary:
	return {
		"id": "hazard",
		"stun": 1.5,
		"time_penalty": 3.0,
		"message": "OUCH!",
		"color": Color(1.0, 0.35, 0.25),
	}
