extends Area2D
class_name Hurtbox

signal attack_mission_takeoff

var mission_range
var cooldown_ready = false
var attack_wings = Overseer.game_settings["admiral"]["attack_wings"]

#TODO
const READY_IN_HANGAR = 1
const READY_ON_DECK = 2
const TAKING_OFF = 3
const ON_MISSION = 4
const WAITING_TO_LAND = 5
const LANDING = 6
const REARMING = 7
var air_wing_state = {}
var air_wing_fuel = Overseer.game_settings["admiral"]["attack_fuel"]

@onready var cooldown_timer = get_node("CooldownTimer")
@onready var area = get_node("Area")
@onready var area_timer = get_node("AreaTimer")

func _ready():
	cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["attack_cooldown"]
	cooldown_timer.start()
	area_timer.connect("timeout", _on_area_timer_timeout)
	area_timer.one_shot = true
	area_timer.wait_time = 0.3
	print("attack_mission init ready!")
	for wings in air_wing_state:
		air_wing_state[str()] = 1

func _on_cooldown_timer_timeout():
	print("attack cooldownready")
	cooldown_ready = true

func plan_attack_mission():
	if cooldown_ready:
		visible = true
		area.disabled = true
		look_at(get_global_mouse_position())
	else:
		area.disabled = true

func order_attack_mission():
	if cooldown_ready == true:
		attack_mission_takeoff.emit(cooldown_timer.wait_time)
		cooldown_timer.start()
		cooldown_ready = false
		area.disabled = false
		area_timer.start()
		visible = false
		print("attack mission takes off")

func _on_area_timer_timeout():
	area.disabled = true

func is_ready():
	return cooldown_ready
