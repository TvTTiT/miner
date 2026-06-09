class_name LootFeedback
extends CanvasLayer

const POPUP_LIFETIME := 1.1

@onready var flash: ColorRect = $Flash


func _ready() -> void:
	flash.modulate.a = 0.0


func show_popup(text: String, world_pos: Vector2, color: Color = Color(1.0, 0.9, 0.3)) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.position = world_pos + Vector2(-80, -20)
	label.size = Vector2(160, 32)
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 48.0, POPUP_LIFETIME)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_LIFETIME).set_delay(0.35)
	tween.chain().tween_callback(label.queue_free)


func show_combo_burst(tier_name: String, world_pos: Vector2) -> void:
	var label := Label.new()
	label.text = "▲ %s ▲" % tier_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", GameTheme.combo_color(tier_name))
	label.position = world_pos + Vector2(-120, -60)
	label.size = Vector2(240, 40)
	label.scale = Vector2(0.6, 0.6)
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(label, "position:y", label.position.y - 56.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)


func screen_punch(target: Node2D, strength: float = 8.0) -> void:
	if target == null:
		return
	var origin := Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(target, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.04)
	tween.tween_property(target, "position", origin, 0.12)


func red_flash() -> void:
	flash.color = Color(0.9, 0.1, 0.1, 1.0)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.55, 0.06)
	tween.tween_property(flash, "modulate:a", 0.0, 0.35)


func gold_flash() -> void:
	flash.color = Color(1.0, 0.85, 0.2, 1.0)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.35, 0.05)
	tween.tween_property(flash, "modulate:a", 0.0, 0.25)


func electric_flash() -> void:
	flash.color = Color(0.35, 0.85, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.28, 0.04)
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
