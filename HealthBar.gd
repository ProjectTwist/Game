extends Control 

signal pulse()

const FLASH_RATE = 0.07
const N_FLASHES = 3

onready var health_over = $HealthOver
onready var health_under = $HealthUnder
onready var update_tween = $UpdateTween
onready var pulse_tween = $PulseTween
onready var flash_tween = $FlashTween

export (Color) var healthy_color = Color.green
export (Color) var caution_color = Color.yellow
export (Color) var danger_color = Color.red
export (Color) var pulse_color = Color.darkred
export (Color) var flash_color = Color.orangered
export (float, 0, 1, 0.05) var caution_zone = 0.5
export (float, 0, 1, 0.05) var danger_zone = 0.25
export (bool) var will_pulse = true

func _on_health_bar_updated(health, amount = 0):
	health_over.value = health
	update_tween.interpolate_property(health_under, "value", health_under.value, health, 0.45, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.4)
	update_tween.start()
	
	_assign_color(health)
	if amount < 100:
		_flash_damage()

func _assign_color(health):
	var testA = health_over.max_value * danger_zone
	if health == 0:
		pulse_tween.set_active(false)
		
	elif health < health_over.max_value * danger_zone:
		if will_pulse:
			print("pulsed")
			if !pulse_tween.is_active():
				pulse_tween.interpolate_property(health_over, "tint_progress", pulse_color, danger_color, 1.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
				pulse_tween.interpolate_callback(self, 0.0, "emit_signal", "pulse")
				pulse_tween.start()
		else:
			health_over.tint_progress = danger_color
			print("color")
	else:
		pulse_tween.set_active(false)
		if health < health_over.max_value * caution_zone:
			health_over.tint_progress = caution_color
		else:
			health_over.tint_progress = healthy_color

func _flash_damage():
	for i in range(N_FLASHES * 2):
		var color = health_over.tint_progress if i % 2 == 1 else flash_color
		var time = FLASH_RATE * i + FLASH_RATE
		flash_tween.interpolate_callback(health_over, time, "set", "tint_progress", color)
	flash_tween.start() 

func _on_max_health_updated(max_health):
	health_over.max_value = max_health
	health_under.max_value = max_health

