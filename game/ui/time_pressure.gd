class_name TimePressure
extends CanvasLayer

const URGENT_AT := 15.0
const CRITICAL_AT := 8.0
const PANIC_AT := 4.0

var _floor_time_max: float = 60.0
var _hurry_shown: bool = false
var _tick_accum: float = 0.0
var _pulse_time: float = 0.0

@onready var vignette: ColorRect = $Vignette
@onready var hurry_label: Label = $HurryLabel


func _ready() -> void:
	vignette.modulate.a = 0.0
	hurry_label.modulate.a = 0.0


func reset_for_floor(max_time: float) -> void:
	_floor_time_max = maxf(1.0, max_time)
	_hurry_shown = false
	_tick_accum = 0.0
	_pulse_time = 0.0
	vignette.modulate.a = 0.0
	hurry_label.modulate.a = 0.0
	hurry_label.scale = Vector2.ONE


func update(time_left: float, timer_label: Label, delta: float) -> void:
	_pulse_time += delta

	if time_left > URGENT_AT:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		vignette.modulate.a = 0.0
		timer_label.scale = Vector2.ONE
		return

	var urgency := clampf(1.0 - time_left / URGENT_AT, 0.0, 1.0)
	var pulse := 0.65 + 0.35 * sin(_pulse_time * 9.0)
	vignette.modulate.a = lerpf(0.0, 0.42, urgency) * pulse

	var timer_color := Color(1.0, 0.55 - urgency * 0.35, 0.25)
	if time_left <= CRITICAL_AT:
		timer_color = Color(1.0, 0.18 + 0.12 * sin(_pulse_time * 12.0), 0.12)
		var scale_boost := 1.0 + 0.06 * sin(_pulse_time * 14.0)
		timer_label.scale = Vector2(scale_boost, scale_boost)
	timer_label.add_theme_color_override("font_color", timer_color)

	if time_left <= PANIC_AT and not _hurry_shown:
		_hurry_shown = true
		_show_hurry()

	if time_left <= CRITICAL_AT:
		_tick_accum += delta
		if _tick_accum >= 1.0:
			_tick_accum = 0.0
			_pulse_hurry_once()


func _show_hurry() -> void:
	hurry_label.text = "HURRY!"
	hurry_label.modulate.a = 1.0
	hurry_label.scale = Vector2(1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(hurry_label, "scale", Vector2(1.45, 1.45), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(hurry_label, "modulate:a", 0.0, 0.55).set_delay(0.35)


func _pulse_hurry_once() -> void:
	hurry_label.text = "!"
	hurry_label.modulate.a = 0.85
	hurry_label.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(hurry_label, "modulate:a", 0.0, 0.25)
