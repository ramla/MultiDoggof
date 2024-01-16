extends Area2D
class_name Mission

enum MissionType { Recon, Attack }
var mission_type

func _ready():
	pass

func _init(new_mission_type: MissionType):
	mission_type = new_mission_type
	pass

func _process(_delta):
	pass

func cooldown_ready():
	pass

func mission_over():
	pass

func reserve_resources():
	pass

func plan_mission():
	pass

func cancel_plan_mission():
	pass

func order_mission():
	pass

func assign_effect_area():
	pass

func assign_effect_area_visualization():
	pass

func play_mission_effect():
	pass
