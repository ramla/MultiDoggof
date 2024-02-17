extends Area2D
class_name Spotbox

signal recon_mission_takeoff
signal aviation_fuel_used(amount)
signal no_aviation_fuel

var mission_range
var cooldown_ready = false
var recon_wings = Overseer.game_settings["admiral"]["recon_wings"]
var anim_timer = Timer.new()
var ordered_position = Vector2.ZERO
var mission_duration

var aviation_fuel_consumption = Overseer.game_settings["admiral"]["recon_fuel"]
var effect_running = false
var planning = false
var spotted_someone = false

@onready var spotbox_animation_node = get_node("SpotboxPlayer")
@onready var effect_recon = get_node("EffectRecon/PlaneEmitter")
@onready var cooldown_timer = get_node("CooldownTimer")
@onready var mission_timer = get_node("MissionTimer")
@onready var area = get_node("Area")
@onready var recon_visual_area = get_node("Area/ReconVisualArea/Polygon2D")
@onready var recon_poly = area["polygon"]

func _ready():
	cooldown_timer.connect("timeout", _on_cooldown_timer_timeout)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = Overseer.game_settings["admiral"]["recon_cooldown"]
	cooldown_timer.start()
	
	spotbox_animation_node.connect("animation_finished", _on_animation_finished)
	spotbox_animation_node["speed_scale"] = Overseer.game_settings["admiral"]["plane_speed_multiplier"]
	spotbox_animation_node["current_animation"] = "recon"
	mission_duration = spotbox_animation_node["speed_scale"] * spotbox_animation_node.current_animation_length
	spotbox_animation_node.stop()
	
	mission_timer.connect("timeout", _on_mission_timer_timeout)
	mission_timer.one_shot = true
	mission_timer.wait_time = mission_duration
		
	effect_recon.connect("finished", _on_effect_recon_finished)
	effect_recon["one_shot"] = true
	effect_recon["emitting"] = false
	
	pass_the_poly()
	
	cooldown_ready = true
	
func _process(_delta):
	if planning:
		look_at(get_global_mouse_position())
		$Icon.visible = true
	else:
		$Icon.visible = false
	
func _physics_process(_delta):
	if !cooldown_ready:
		look_at(ordered_position)

func pass_the_poly():
	recon_visual_area["polygon"] = recon_poly

func _on_cooldown_timer_timeout():
	#print("recon cooldownready")
	cooldown_ready = true

func _on_animation_finished(_anim_name):
	#print(_anim_name, " animation finished")
	if !area.disabled:
		area.disabled = true
		cooldown_timer.start()

func plan_recon_mission():
	if cooldown_ready:
		planning = true
		$Icon.visible = true
		self.visible = true
		#print("recon visible, icon visible")
		area.visible = true
		look_at(get_global_mouse_position())
		spotbox_animation_node["speed_scale"] = 4
		if spotbox_animation_node.is_playing():
			#print("animation already running")
			return
		else:
			spotbox_animation_node.stop()
			spotbox_animation_node.play("recon")
			#print("starting recon animation")
			
	else:
		planning = false
		area.visible = false
		$Icon.visible = false

func cancel_plan_recon_mission():
		#print("cancelling plan rrecon")
		planning = false
		area.visible = false
		$Icon.visible = false

func order_recon_mission(action_click_position):
	if cooldown_ready == true && get_parent().aviation_fuel >= aviation_fuel_consumption:
		print(get_parent().aviation_fuel)
		get_parent().sfx.play_takeoff()
		
		ordered_position = action_click_position
		area.look_at(action_click_position)
		area.disabled = false
		area.visible = false
		spotted_someone = false
		
		spotbox_animation_node["speed_scale"] = 1.5
		spotbox_animation_node.stop()
		spotbox_animation_node.play("recon")

		effect_recon.restart()
		effect_recon["emitting"] = true

		cooldown_ready = false
		$Icon.visible = false
		effect_running = true
		mission_timer.start()
		
		#print("recon mission takes off, mission duration ", str(cooldown_timer.wait_time + spotbox_animation_node["speed_scale"]*spotbox_animation_node.current_animation_length))
		#print("also cooldown reyad = false, icon visible = false, area visible = false, effect running = true")
		recon_mission_takeoff.emit(cooldown_timer.wait_time + spotbox_animation_node["speed_scale"]*spotbox_animation_node.current_animation_length)
		aviation_fuel_used.emit(aviation_fuel_consumption)
		planning = false
	elif get_parent().aviation_fuel < aviation_fuel_consumption:
		print("no aviation fuel")
		no_aviation_fuel.emit()

func _on_mission_timer_timeout():
	area.disabled = true
	effect_running = false #hack b/c couldn't get particle emitter to emit "finished"
	if !spotted_someone:
		get_parent().sfx.play_recon_not_found()
	print("recon mission timer timeout")

func _on_effect_recon_finished():
	$Icon.visible = true
	self.visible = false
	effect_running = false
	print("effect_recon_finished: icon visible = true, self.visible = false, effect running = false")

func is_ready():
	return cooldown_ready
