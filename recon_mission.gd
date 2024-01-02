extends Area2D
class_name Spotbox

signal recon_mission_takeoff

var mission_range
var cooldown_ready = false
var recon_squads = Overseer.game_settings["admiral"]["recon_squads"]
var ready_in_hangar = true
var ready_on_deck = false
var taking_off = false
var on_mission = false
var waiting_to_land = false
var landing = false
var rearming = false

@onready var cooldown_timer = get_node("CooldownTimer")
@onready var area = get_node("Area")

func _ready():
	cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["recon_cooldown"]
	cooldown_timer.start()
	print("recon_mission init ready!")

func _on_cooldown_timer_timeout():
	print("recon cooldownready")
	cooldown_ready = true

func order_recon_mission():
	if cooldown_ready == true:
		recon_mission_takeoff.emit(cooldown_timer.wait_time)
		cooldown_timer.start()
		cooldown_ready = false
		area.disabled = false
		print("recon mission takes off")

func is_ready():
	return cooldown_ready

#TODO: jotain järkee tähä himmeliin puolet koodista admiral scenes
