extends Area2D
class_name Hurtbox

signal attack_mission_takeoff

var mission_range
var mission_duration
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

@onready var animation_node = get_node("AnimationPlayer")
@onready var cooldown_timer = get_node("CooldownTimer")
@onready var area = get_node("Area")
@onready var mission_timer = get_node("MissionTimer")

func _ready():
	cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["attack_cooldown"]
	cooldown_timer.start()
	mission_duration = animation_node["speed_scale"] * animation_node.current_animation_length
	mission_timer.connect("timeout", _on_mission_timer_timeout)
	mission_timer.one_shot = true
	mission_timer.wait_time = mission_duration
	animation_node.connect("animation_finished", _on_animation_finished)
	animation_node["speed_scale"] = Overseer.game_settings["admiral"]["plane_speed_multiplier"]
	animation_node["current_animation"] = "attack"
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
		cooldown_timer.start()
		cooldown_ready = false
		area.disabled = false
		mission_timer.start()
		visible = true
		print("attack mission takes off")
		attack_mission_takeoff.emit(cooldown_timer.wait_time + mission_duration)

func _on_animation_finished(anim_name):
	print("recon mission over")
	cooldown_timer.start()


func _on_mission_timer_timeout():
	area.disabled = true

func is_ready():
	return cooldown_ready
