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

var local_id

var ticktimer: Timer = Timer.new()

@onready var recon_icon = $ReconIcon
@onready var attack_icon = $AttackIcon
@onready var animation_node = %AnimationPlayer

func _ready():
	ticktimer.connect("timeout", _on_tick)
	ticktimer.wait_time = 0.5
	add_child(ticktimer)
	ticktimer.start()
	pass
	
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
	get_owner().connect("munitions_used", _on_munitions_used)
	get_owner().connect("damage_taken", _on_damage_taken)
	get_owner().connect("cprint_signal", _on_cprint)
	health = in_health
	local_id = in_local_id
	%LocalID["text"] = str(local_id)
	print("initialised health: ", health, " @local_id ", local_id)
	%ProgressBar["max_value"] = health
	%ProgressBar["value"] = health
	munitions = in_munitions
	%MunitionsAmount["text"] = str(munitions)
	fuel_oil = in_fuel_oil
	%FuelOilAmount["text"] = str(fuel_oil)
	aviation_fuel = in_aviation_fuel
	%AviationFuelAmount["text"] = str(aviation_fuel)
	%FuelOilConsumptionAmount["text"] = str(fuel_oil_consumption)
	show()

func _on_cprint(in_text):
	%HudTextBox["text"] += "[right]" + in_text + "[/right]"

func _on_attack_mission_cooldown_triggered(duration):
	#print(duration)
	attack_icon.texture = tex_attack_unavailable

func _on_attack_mission_cooldown_over():
	attack_icon.texture = tex_attack_available

func _on_recon_mission_cooldown_triggered(duration):
	recon_icon.texture = tex_recon_unavailable

func _on_recon_mission_cooldown_over():
	recon_icon.texture = tex_recon_available

func _on_damage_taken(damage):
	print("damage taken @ ", damage)
	health -= damage
	%ProgressBar["value"] = health
	print(damage, "damage taken @local_id ", local_id, ". new health is ", health)

func _on_munitions_used(amount):
	munitions -= amount
	%MunitionsAmount["text"] = str(munitions)
	if munitions <= 2:
		%MunitionsAmount["theme_override_colors/font_color"] = "ff0900"

func _on_no_munitions():
	animation_node.play("no_munitions")

func _on_tick():
	fuel_oil = get_owner().fuel_oil
	fuel_oil_consumption = get_owner().current_fuel_oil_consumption * 3600
	#print(fuel_oil_consumption)
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
	%AviationFuelAmount["text"] = str(aviation_fuel)
	if aviation_fuel <= 200:
		%AviationFuelAmount["theme_override_colors/font_color"] = "ff0900"
