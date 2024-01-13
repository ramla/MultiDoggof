extends Area2D
class_name Spotbox

signal recon_mission_takeoff
signal aviation_fuel_used(amount)

var mission_range
var cooldown_ready = false
var recon_wings = Overseer.game_settings["admiral"]["recon_wings"]
var anim_timer = Timer.new()

#TODO:{
#const READY_IN_HANGAR = 1
#const READY_ON_DECK = 2
#const TAKING_OFF = 3
#const ON_MISSION = 4
#const WAITING_TO_LAND = 5
#const LANDING = 6
#const REARMING = 7
#var air_wing_state = {}
var aviation_fuel_consumption = Overseer.game_settings["admiral"]["recon_fuel"]
var effect_running = false
var planning = false

@onready var spotbox_animation_node = get_node("SpotboxPlayer")
#@onready var visual_animation_node = get_node("VisualPlayer")
#@onready var aiming_template_recon = get_node("AimingTemplate/PlaneEmitter")
@onready var effect_recon = get_node("EffectRecon/PlaneEmitter")
@onready var cooldown_timer = get_node("CooldownTimer")
@onready var area = get_node("Area")
@onready var recon_visual_area = get_node("Area/ReconVisualArea/Polygon2D")
#@onready var recon_visual_animation = get_node("ReconVisualArea/DummyboxPlayer")
@onready var recon_poly = area["polygon"]

func _ready():
	cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["recon_cooldown"]
	cooldown_timer.start()
	spotbox_animation_node.connect("animation_finished", _on_animation_finished)
	spotbox_animation_node["speed_scale"] = Overseer.game_settings["admiral"]["plane_speed_multiplier"]
	spotbox_animation_node["current_animation"] = "recon"
	spotbox_animation_node.stop()
	#visual_animation_node["speed_scale"] = Overseer.game_settings["admiral"]["plane_speed_multiplier"]
	#visual_animation_node["current_animation"] = "plan_recon"
	#visual_animation_node.stop()
#	aiming_template_recon.connect("finished", _on_aiming_template_recon_finished)
#	aiming_template_recon["one_shot"] = false
#	aiming_template_recon["emitting"] = false
	#add_child(anim_timer)
	#anim_timer["one_shot"] = true
	#anim_timer.wait_time = 2.67
	effect_recon.connect("finished", _on_effect_recon_finished)
	effect_recon["one_shot"] = true
	effect_recon["emitting"] = false
#	print("recon_mission init ready!")
	pass_the_poly()
	#for wings in air_wing_state:
		#air_wing_state[str()] = 1

func _process(_delta):
	if planning:
		look_at(get_global_mouse_position())
		$Icon.visible = true
	else:
		self.visible = false
		$Icon.visible = false

func pass_the_poly():
	recon_visual_area["polygon"] = recon_poly

func _on_cooldown_timer_timeout():
	#print("recon cooldownready")
	cooldown_ready = true

func _on_animation_finished(_anim_name):
	print(_anim_name, " mission over (animation finished)")
	area.disabled = true
	cooldown_timer.start()

func plan_recon_mission():
	if cooldown_ready:
		planning = true
		$Icon.visible = true
		self.visible = true
		area.disabled = true
		look_at(get_global_mouse_position())
		#aiming_template_recon.visible = true
		#aiming_template_recon["emitting"] = true
		spotbox_animation_node["speed_scale"] = 4
		spotbox_animation_node.play("recon")
		print("recon visible, icon visible")
	else:
		planning = false
		area.disabled = true
		$Icon.visible = false
		#print("Recon icon visible = false, disabled = true")
#		aiming_template_recon.restart()
		#visible = false
		#aiming_template_recon["emitting"] = false

func cancel_plan_recon_mission():
		planning = false
		area.disabled = true
		self.visible = false
		$Icon.visible = false
		#print("Recon icon visible = false, disabled = true")

#func visualize_plan_recon():
		#if anim_timer.is_stopped():
			#anim_timer.start()
			#aiming_template_recon["one_shot"] = false
			#aiming_template_recon["emitting"] = true
			#visual_animation_node.stop()
			#visual_animation_node.play("plan_recon")

func order_recon_mission():
	if cooldown_ready == true && get_parent().aviation_fuel >= aviation_fuel_consumption:
		area.disabled = false
		area.visible = false
		spotbox_animation_node["speed_scale"] = 1.5
		spotbox_animation_node.stop()
		spotbox_animation_node.play("recon")
		#aiming_template_recon["emitting"] = false
		#aiming_template_recon.visible = false
		#aiming_template_recon.restart()
		effect_recon.restart()
		effect_recon["emitting"] = true
		#visual_animation_node.stop()
		#visual_animation_node.play("plan_recon")
		cooldown_ready = false
		$Icon.visible = false
		effect_running = true
		print("recon mission takes off, mission duration ", str(cooldown_timer.wait_time + spotbox_animation_node["speed_scale"]*spotbox_animation_node.current_animation_length))
		print("also cooldown reyad = false, icon visible = false, area visible = false, effect running = true")
		recon_mission_takeoff.emit(cooldown_timer.wait_time + spotbox_animation_node["speed_scale"]*spotbox_animation_node.current_animation_length)
		aviation_fuel_used.emit(aviation_fuel_consumption)
		planning = false

func _on_aiming_template_recon_finished():
	#visual_animation_node.play("plan_recon")
	print("does this still play?")
	pass

func _on_effect_recon_finished():
	$Icon.visible = true
	self.visible = false
#	aiming_template_recon.visible = true
	effect_running = false
	print("effect_recon_finished: icon visible = true, self.visible = false, effect running = false")

func is_ready():
	return cooldown_ready
