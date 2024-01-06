extends Area2D
class_name Spotbox

signal recon_mission_takeoff

var mission_range
var cooldown_ready = false
var recon_wings = Overseer.game_settings["admiral"]["recon_wings"]

#TODO: is_player -checkki, myös attack mission
#TODO: view_distance sprite, recon / attack spritet ja animaatiot

#TODO:{
#const READY_IN_HANGAR = 1
#const READY_ON_DECK = 2
#const TAKING_OFF = 3
#const ON_MISSION = 4
#const WAITING_TO_LAND = 5
#const LANDING = 6
#const REARMING = 7
var air_wing_state = {}
#var air_wing_fuel = Overseer.game_settings["admiral"]["recon_fuel"]
#}

@onready var animation_node = get_node("AnimationPlayer")
@onready var cooldown_timer = get_node("CooldownTimer")
@onready var area = get_node("Area")

func _ready():
	cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["recon_cooldown"]
	cooldown_timer.start()
	animation_node.connect("animation_finished", _on_animation_finished)
	animation_node["speed_scale"] = Overseer.game_settings["admiral"]["plane_speed_multiplier"]
	animation_node["current_animation"] = "recon"
	print("recon_mission init ready!")
	for wings in air_wing_state:
		air_wing_state[str()] = 1

func _on_cooldown_timer_timeout():
	print("recon cooldownready")
	cooldown_ready = true

func _on_animation_finished(anim_name):
	print("recon mission over")
	cooldown_timer.start()

func plan_recon_mission():
	if cooldown_ready:
		visible = true
		area.disabled = true
		look_at(get_global_mouse_position())
	else:
		area.disabled = true
		visible = false

func order_recon_mission():
	if cooldown_ready == true:
		animation_node.play("recon")
		cooldown_ready = false
		area.disabled = false
		visible = false
		print("recon mission takes off")
		recon_mission_takeoff.emit(cooldown_timer.wait_time + animation_node["speed_scale"]*animation_node.current_animation_length)

func is_ready():
	return cooldown_ready
