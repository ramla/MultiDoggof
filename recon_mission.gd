extends Area2D
class_name Spotbox

signal recon_mission_takeoff

var mission_range
var cooldown_ready = true
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

func _on_ready():
	connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.oneshot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["recon_cooldown"]

func _on_cooldown_timer_timeout():
	cooldown_ready = true

func order_recon_mission():
	if cooldown_ready == true:
		recon_mission_takeoff.emit()
		cooldown_timer.start()
	else:
		print("recon mission on cooldown")

func is_ready():
	if cooldown_ready:
		return true
		
