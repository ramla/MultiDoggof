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
var health

@onready var recon = $ReconIcon
@onready var attack = $AttackIcon

func _ready():
	#attack_mission = self.get_owner().get_node("AttackMission")
	#attack_mission.connect("", _on_attack_mission_cooldown_triggered)
	#attack_mission = self.get_owner().get_node("CooldownTimer")
	#attack_mission.connect("timeout", _on_attack_mission_cooldown_over)
	recon_mission = self.get_owner().get_node("ReconMission")
	recon_mission.connect("recon_mission_takeoff", _on_recon_mission_cooldown_triggered)
	recon_mission_timer = self.get_owner().get_node("ReconMission").get_node("CooldownTimer")
	recon_mission_timer.connect("timeout", _on_recon_mission_cooldown_over)

func _on_attack_mission_cooldown_triggered(wait_time):
	attack.texture = tex_attack_unavailable

func _on_attack_mission_cooldown_over():
	attack.texture = tex_attack_available

func _on_recon_mission_cooldown_triggered(wait_time):
	recon.texture = tex_recon_unavailable

func _on_recon_mission_cooldown_over():
	recon.texture = tex_recon_available
