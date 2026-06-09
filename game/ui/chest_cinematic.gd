class_name ChestCinematic
extends CanvasLayer

signal reveal_complete
signal dismissed

enum State { IDLE, PLAYING, WAITING }

const RARITY_COLORS := {
	"common": Color(0.85, 0.85, 0.85),
	"uncommon": Color(0.45, 0.95, 0.55),
	"rare": Color(0.45, 0.75, 1.0),
	"epic": Color(0.85, 0.45, 1.0),
	"fusion": Color(1.0, 0.82, 0.25),
}

var state: State = State.IDLE
var _upgrade: Dictionary = {}
var _shake_strength: float = 0.0
var _shake_target: Node2D = null

@onready var dimmer: ColorRect = $Dimmer
@onready var flash: ColorRect = $Flash
@onready var vignette: ColorRect = $Vignette
@onready var chest_root: Node2D = $ChestRoot
@onready var chest_body: Polygon2D = $ChestRoot/Body
@onready var chest_lid: Polygon2D = $ChestRoot/Lid
@onready var chest_lock: Polygon2D = $ChestRoot/Lock
@onready var chest_glow: Polygon2D = $ChestRoot/Glow
@onready var loot_ray: Polygon2D = $ChestRoot/LootRay
@onready var particles: CPUParticles2D = $ChestRoot/Particles
@onready var rarity_label: Label = $RarityLabel
@onready var name_label: Label = $NameLabel
@onready var desc_label: Label = $DescLabel
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	visible = false
	flash.modulate.a = 0.0
	dimmer.modulate.a = 0.0
	vignette.modulate.a = 0.0
	rarity_label.modulate.a = 0.0
	name_label.modulate.a = 0.0
	desc_label.modulate.a = 0.0
	prompt_label.modulate.a = 0.0
	loot_ray.modulate.a = 0.0
	particles.emitting = false
	_setup_chest_mesh()


func _process(delta: float) -> void:
	if _shake_strength > 0.0 and _shake_target:
		_shake_target.position = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength),
		)


func play(
	upgrade: Dictionary,
	shake_target: Node2D,
	screen_pos: Vector2 = Vector2(480, 360),
	bonus_text: String = "",
) -> void:
	if state != State.IDLE:
		return
	_upgrade = upgrade
	_upgrade["bonus_text"] = bonus_text
	_shake_target = shake_target
	state = State.PLAYING
	visible = true
	_reset_visuals()
	chest_root.position = screen_pos
	_run_sequence()


func _reset_visuals() -> void:
	chest_root.scale = Vector2.ONE
	chest_root.rotation = 0.0
	chest_lid.rotation = 0.0
	chest_lid.position = Vector2.ZERO
	chest_lock.modulate.a = 1.0
	chest_glow.modulate.a = 0.0
	flash.modulate.a = 0.0
	dimmer.modulate.a = 0.0
	vignette.modulate.a = 0.0
	rarity_label.modulate.a = 0.0
	name_label.modulate.a = 0.0
	name_label.scale = Vector2(0.4, 0.4)
	desc_label.modulate.a = 0.0
	prompt_label.modulate.a = 0.0
	loot_ray.modulate.a = 0.0
	particles.emitting = false


func _run_sequence() -> void:
	var category: String = _upgrade.get("category", "")
	var rarity: String = _upgrade.get("rarity", "common")
	if category == "fusion":
		rarity = "fusion"
	var rarity_color: Color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	particles.color = rarity_color

	var tween := create_tween()
	tween.set_parallel(false)

	# Dramatic dim + vignette
	tween.tween_property(dimmer, "modulate:a", 0.72, 0.35)
	tween.parallel().tween_property(vignette, "modulate:a", 0.55, 0.45)

	# Chest entrance bounce
	chest_root.scale = Vector2(0.2, 0.2)
	tween.tween_property(chest_root, "scale", Vector2(1.15, 1.15), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(chest_root, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD)

	# Anticipation shake
	tween.tween_callback(_start_shake.bind(6.0))
	tween.tween_interval(0.35)
	tween.tween_callback(_start_shake.bind(10.0))
	tween.tween_interval(0.25)

	# Lock pop + lid burst
	tween.tween_property(chest_lock, "modulate:a", 0.0, 0.12)
	tween.parallel().tween_property(chest_lid, "rotation", -1.35, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(chest_lid, "position", Vector2(-18, -28), 0.35)

	# Flash + particles + loot ray
	tween.tween_callback(_burst_open.bind(rarity_color))
	tween.tween_property(flash, "modulate:a", 0.85, 0.08)
	tween.tween_property(flash, "modulate:a", 0.0, 0.35)
	tween.parallel().tween_property(chest_glow, "modulate:a", 0.9, 0.2)
	tween.parallel().tween_property(loot_ray, "modulate:a", 0.75, 0.15)
	tween.tween_property(loot_ray, "modulate:a", 0.25, 0.4)

	# Stat reveal
	tween.tween_callback(_stop_shake)
	tween.tween_callback(_show_loot_text.bind(rarity, rarity_color))
	tween.tween_interval(0.15)
	tween.tween_property(rarity_label, "modulate:a", 1.0, 0.25)
	tween.tween_property(name_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(name_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(desc_label, "modulate:a", 1.0, 0.25)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_on_reveal_done)


func _show_loot_text(rarity: String, rarity_color: Color) -> void:
	rarity_label.text = rarity.to_upper()
	rarity_label.add_theme_color_override("font_color", rarity_color)
	name_label.text = _upgrade.get("name", "Mystery Buff")
	name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	var desc: String = _upgrade.get("desc", "")
	var bonus: String = _upgrade.get("bonus_text", "")
	if bonus != "":
		desc = "%s\n%s" % [desc, bonus]
	desc_label.text = desc
	prompt_label.text = "SPACE / Click — Continue"


func _burst_open(rarity_color: Color) -> void:
	particles.color = rarity_color
	particles.emitting = true
	particles.restart()
	chest_glow.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.55)


func _start_shake(strength: float) -> void:
	_shake_strength = strength


func _stop_shake() -> void:
	_shake_strength = 0.0
	if _shake_target:
		_shake_target.position = Vector2.ZERO


func _on_reveal_done() -> void:
	state = State.WAITING
	reveal_complete.emit()


func dismiss() -> void:
	if state != State.WAITING:
		return
	state = State.IDLE
	_stop_shake()
	var tween := create_tween()
	tween.tween_property(dimmer, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(vignette, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(chest_root, "scale", Vector2(0.6, 0.6), 0.25)
	tween.parallel().tween_property(rarity_label, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(name_label, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(desc_label, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(prompt_label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_finish_dismiss)


func _finish_dismiss() -> void:
	visible = false
	particles.emitting = false
	dismissed.emit()


func _setup_chest_mesh() -> void:
	var w := 52.0
	var h := 42.0
	chest_body.polygon = PackedVector2Array([
		Vector2(-w, -8),
		Vector2(w, -8),
		Vector2(w, h),
		Vector2(-w, h),
	])
	chest_body.color = Color(0.5, 0.28, 0.1)

	chest_lid.polygon = PackedVector2Array([
		Vector2(-w, -h * 0.65),
		Vector2(w, -h * 0.65),
		Vector2(w, -8),
		Vector2(-w, -8),
	])
	chest_lid.color = Color(0.68, 0.4, 0.12)

	chest_lock.polygon = PackedVector2Array([
		Vector2(-7, -28),
		Vector2(7, -28),
		Vector2(7, -10),
		Vector2(-7, -10),
	])
	chest_lock.color = Color(0.95, 0.78, 0.2)

	chest_glow.polygon = PackedVector2Array([
		Vector2(-w * 1.4, -h),
		Vector2(w * 1.4, -h),
		Vector2(w * 1.4, h * 1.3),
		Vector2(-w * 1.4, h * 1.3),
	])
	chest_glow.color = Color(1.0, 0.8, 0.2, 0.5)

	loot_ray.polygon = PackedVector2Array([
		Vector2(-16, -90),
		Vector2(16, -90),
		Vector2(48, 40),
		Vector2(-48, 40),
	])
	loot_ray.color = Color(1.0, 0.9, 0.45, 0.6)

	particles.amount = 48
	particles.lifetime = 0.9
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.direction = Vector2(0, -1)
	particles.spread = 75.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 280.0
	particles.gravity = Vector2(0, 180)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
