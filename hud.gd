extends CanvasLayer

var admiral_scene
var attack_mission
var attack_mission_timer
var recon_mission
var recon_mission_timer
var tex_attack_available = preload("res://Assets/item8BIT_bow.png")
var tex_attack_unavailable = preload("res://Assets/item8BIT_bow_desaturated.png")
var tex_recon_available = preload("res://Assets/item8BIT_mirror.png")
var tex_recon_unavailable = preload("res://Assets/item8BIT_mirror_desaturated.png")
var health = 0
var munitions = 0
var fuel_oil = 0
var aviation_fuel = 0
var fuel_oil_consumption = 0
var prepost_round_time_min: int = Overseer.game_settings["pre_round_length"] / 60
var prepost_round_time_sec: int = Overseer.game_settings["pre_round_length"] - (round_time_min * 60)
var round_time_min: int = Overseer.game_settings["round_length"] / 60
var round_time_sec: int = Overseer.game_settings["round_length"] - (round_time_min * 60)
var local_id
var init_done = false

var ticktimer = Timer.new()
var round_timer = Timer.new()
var prepost_timer = Timer.new()

@onready var recon_icon = %ReconIcon
@onready var recon_progbar = %ReconProgressBar
@onready var attack_icon = %AttackIcon
@onready var attack_progbar = %AttackProgressBar
@onready var munitions_animation_node = %MunitionsAnimationPlayer
@onready var recon_animation_node = %ReconAnimationPlayer
@onready var attack_animation_node = %AttackAnimationPlayer

func _ready():
	ticktimer.connect("timeout", _on_tick)
	ticktimer.wait_time = 0.5
	add_child(ticktimer)
	ticktimer.start()
	
	prepost_timer.connect("timeout", _on_prepost_round_timeout)
	prepost_timer.wait_time = Overseer.game_settings["pre_round_length"]
	prepost_timer.one_shot = true
	prepost_timer.autostart = true
	add_child(prepost_timer)
	
	round_timer.connect("timeout", _on_round_timeout)
	round_timer.wait_time = Overseer.game_settings["round_length"]
	round_timer.one_shot = true
	add_child(round_timer)

func init(in_health, in_munitions, in_fuel_oil, in_aviation_fuel, in_local_id):
	attack_mission = self.get_owner().attack_mission
	attack_mission.connect("attack_mission_takeoff", _on_attack_mission_cooldown_triggered)
	attack_mission.connect("no_munitions", _on_no_munitions)
	attack_mission.connect("aviation_fuel_used", _on_aviation_fuel_used)
	attack_mission_timer = attack_mission.get_node("CooldownTimer")
	attack_mission_timer.connect("timeout", _on_attack_mission_cooldown_over)
	recon_mission = self.get_owner().recon_mission
	recon_mission.connect("recon_mission_takeoff", _on_recon_mission_cooldown_triggered)
	recon_mission.connect("aviation_fuel_used", _on_aviation_fuel_used)
	recon_mission_timer = recon_mission.get_node("CooldownTimer")
	recon_mission_timer.connect("timeout", _on_recon_mission_cooldown_over)
	get_owner().connect("damage_taken", _on_damage_taken)
	get_owner().connect("cprint_signal", _on_cprint)
	health = in_health
	local_id = in_local_id
	%LocalID["text"] = str(local_id)
	#print("initialised health: ", health, " @local_id ", local_id)
	%ProgressBar["max_value"] = health
	%ProgressBar["value"] = health
	munitions = in_munitions
	%MunitionsAmount["text"] = str(munitions)
	fuel_oil = in_fuel_oil
	%FuelOilAmount["text"] = str(fuel_oil)
	aviation_fuel = in_aviation_fuel
	if aviation_fuel > 0:
		%AviationFuelAmount["text"] = str(aviation_fuel)
	else:
		%AviationFuelAmount["text"] = str(0)
	%FuelOilConsumptionAmount["text"] = str(fuel_oil_consumption)
	%RoundTime["text"] = str(round_time_min) + ":" + str(round_time_sec)
	init_done = true
	show()

func _process(_delta):
	update_timers()

func update_timers():
	if !get_owner().on_round_timer:
		prepost_round_time_min = prepost_timer.time_left / 60
		prepost_round_time_sec = prepost_timer.time_left - prepost_round_time_min * 60
		if prepost_round_time_sec < 10:
			%PrePostTime["text"] = str(prepost_round_time_min) + ":0" + str(prepost_round_time_sec)
		else:
			%PrePostTime["text"] = str(prepost_round_time_min) + ":" + str(prepost_round_time_sec)
	else:
		round_time_min = round_timer.time_left / 60
		round_time_sec = round_timer.time_left - round_time_min * 60
		if round_time_sec < 10:
			%RoundTime["text"] = str(round_time_min) + ":0" + str(round_time_sec)
		else:
			%RoundTime["text"] = str(round_time_min) + ":" + str(round_time_sec)
	if init_done:
		if !recon_mission_timer.is_stopped():
			recon_progbar.value = recon_mission_timer.time_left
		if !attack_mission_timer.is_stopped():
			attack_progbar.value = attack_mission_timer.time_left

func _on_prepost_round_timeout():
	%PrePostTime["visible"] = false
	%PrePostLabel["visible"] = false
	
func start_round():
	round_timer.start()
	%PrePostTime["visible"] = false
	%PrePostLabel["visible"] = false
	prepost_timer.wait_time = Overseer.game_settings["post_round_length"]

func _on_round_timeout():
	%PrePostTime["visible"] = true
	%PrePostLabel["visible"] = true

func start_post_round():
	%PrePostTime["visible"] = true
	%PrePostLabel["visible"] = true
	init_done = false
	prepost_timer.start()

func _on_cprint(in_text):
	%HudTextBox["text"] += "[right]" + in_text + "[/right]"

func _on_attack_mission_cooldown_triggered(duration):
	_on_cprint(str(duration) + "seconds to complete attack mission & rearm")
	attack_icon.texture = tex_attack_unavailable
	attack_progbar.max_value = duration
	attack_progbar.value = duration
	
func _on_attack_mission_cooldown_over():
	attack_icon.texture = tex_attack_available
	attack_animation_node.play("attack_icon_pop")

func _on_recon_mission_cooldown_triggered(duration):
	_on_cprint(str(duration) + "seconds to complete recon mission & rearm")
	recon_icon.texture = tex_recon_unavailable
	recon_progbar.max_value = duration
	recon_progbar.value = duration

func _on_recon_mission_cooldown_over():
	recon_icon.texture = tex_recon_available
	recon_animation_node.play("recon_icon_pop")

func _on_damage_taken():
	if get_owner().is_player:
		health = get_owner().health
		%ProgressBar["value"] = health
		#get_owner().cprint(local_id, "'s %HUD drawing damage taken @ ", local_id, "'s new health is ", health)

func munitions_used():
	munitions -= 1
	%MunitionsAmount["text"] = str(munitions)
	if munitions <= 2:
		%MunitionsAmount["theme_override_colors/font_color"] = "ff0900"

func _on_no_munitions():
	munitions_animation_node.play("no_munitions")
	get_parent().sfx.play_no_munitions()

func _on_tick():
	fuel_oil = get_owner().fuel_oil
	fuel_oil_consumption = get_owner().current_fuel_oil_consumption * 3600
	if fuel_oil <= 0:
		fuel_oil = 0
	%FuelOilAmount["text"] = str(fuel_oil)
	%FuelOilConsumptionAmount["text"] = str(fuel_oil_consumption)
	if fuel_oil <= 3000 && fuel_oil > 1500:
		%FuelOilAmount["theme_override_colors/font_color"] = "ffae00"
	elif fuel_oil <= 1500:
		%FuelOilAmount["theme_override_colors/font_color"] = "ff0900"
	if fuel_oil_consumption < 1000:
		%FuelOilConsumptionAmount["theme_override_colors/font_color"] = "ffffff"
	elif 1000 <= fuel_oil_consumption && fuel_oil_consumption <= 10000:
		%FuelOilConsumptionAmount["theme_override_colors/font_color"] = "00ff00"
	elif 10000 <= fuel_oil_consumption && fuel_oil_consumption  <= 14000:
		%FuelOilConsumptionAmount["theme_override_colors/font_color"] = "ffff00"
	elif 14000 <= fuel_oil_consumption && fuel_oil_consumption  <= 18000:
		%FuelOilConsumptionAmount["theme_override_colors/font_color"] = "ffae00"
	elif 18000 <= fuel_oil_consumption:
		%FuelOilConsumptionAmount["theme_override_colors/font_color"] = "ff0900"

func _on_aviation_fuel_used(amount):
	aviation_fuel -= amount
	get_parent().aviation_fuel -= amount
	%AviationFuelAmount["text"] = str(aviation_fuel)
	if aviation_fuel <= 200:
		%AviationFuelAmount["theme_override_colors/font_color"] = "ff0900"
