extends Area2D
class_name Hurtbox

signal attack_mission_takeoff(mission_duration)
signal no_munitions
signal munitions_used
signal aviation_fuel_used(amount)

var mission_range
var mission_duration
var mission_over = true
var cooldown_ready = false
var attack_wings = Overseer.game_settings["admiral"]["attack_wings"]
var ordered_position = Vector2.ZERO
var munitions_onboard = 0

#TODO
#const READY_IN_HANGAR = 1
#const READY_ON_DECK = 2
#const TAKING_OFF = 3
#const ON_MISSION = 4
#const WAITING_TO_LAND = 5
#const LANDING = 6
#const REARMING = 7
#var air_wing_state = {}
var aviation_fuel_consumption = Overseer.game_settings["admiral"]["attack_fuel"]
var effect_running = false

@onready var effect_attack = get_node("EffectAttack/PlaneEmitter")
@onready var hurtbox_animation_node = get_node("HurtboxPlayer")
@onready var cooldown_timer = get_node("CooldownTimer")
@onready var area = get_node("Area")
@onready var mission_timer = get_node("MissionTimer")
@onready var attack_visual_area = get_node("Area/AttackVisualArea/Polygon2D")
@onready var attack_poly = area["polygon"]

func _ready():
	cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["attack_cooldown"]
	cooldown_timer.start()
	hurtbox_animation_node.connect("animation_finished", _on_animation_finished)
	hurtbox_animation_node["speed_scale"] = Overseer.game_settings["admiral"]["plane_speed_multiplier"]
	hurtbox_animation_node["current_animation"] = "attack"
	mission_duration = hurtbox_animation_node["speed_scale"] * hurtbox_animation_node.current_animation_length
	hurtbox_animation_node.stop()
	mission_timer.connect("timeout", _on_mission_timer_timeout)
	mission_timer.one_shot = true
	mission_timer.wait_time = mission_duration
	
	effect_attack.connect("finished", _on_effect_attack_finished)
	effect_attack["one_shot"] = true
	effect_attack["emitting"] = false
	
#	print("attack_mission init ready!")
	#for wings in air_wing_state:
		#air_wing_state[str()] = 1
		
func _physics_process(_delta):
	if !mission_over:
		look_at(ordered_position)
	
func pass_the_poly():
	attack_visual_area["polygon"] = attack_poly
	
func _on_cooldown_timer_timeout():
	print("attack cooldownready")
	cooldown_ready = true

func plan_attack_mission():
	if cooldown_ready:
		self.visible = true
		area.visible = true
		area.disabled = true
		$Icon.visible = true
		look_at(get_global_mouse_position())
		hurtbox_animation_node["speed_scale"] = 4
		hurtbox_animation_node.play("attack")
	else:
		area.disabled = true
		$Icon.visible = false

func order_attack_mission(action_click_position):
	if cooldown_ready == true && get_parent().munitions > 0 && get_parent().aviation_fuel >= aviation_fuel_consumption:
		area.disabled = false
		area.visible = false
		
		ordered_position = action_click_position
		
		hurtbox_animation_node["speed_scale"] = 1
		hurtbox_animation_node.stop()
		hurtbox_animation_node.play("attack")
		
		effect_attack.get_owner().look_at(get_global_mouse_position())
		effect_attack.restart()
		effect_attack["emitting"] = true
		
		mission_timer.start()
		
		cooldown_ready = false
		$Icon.visible = false
		effect_running = true
		mission_over = false
		
		reserve_munitions()
		
		print("attack mission takes off, mission duration ", str(cooldown_timer.wait_time + mission_duration))
		attack_mission_takeoff.emit(cooldown_timer.wait_time + mission_duration)
		aviation_fuel_used.emit(aviation_fuel_consumption)
		
	elif get_parent().munitions <= 0:
		no_munitions.emit()

func _on_animation_finished(_anim_name):
	print(_anim_name, " mission over")
	cooldown_timer.start()

func _on_mission_timer_timeout():
	area.disabled = true
	effect_running = false #hack b/c couldn't get particle emitter to emit "finished"
	mission_over = true

func _on_effect_attack_finished():
	self.visible = false
	$Icon.visible = true
	#aiming_template_attack.visible = true
	effect_running = false
	print("effect finished")

func is_ready():
	return cooldown_ready

func reserve_munitions():
	munitions_onboard = 1

func spend_munitions():
	munitions_onboard -= 1
	munitions_used.emit()
