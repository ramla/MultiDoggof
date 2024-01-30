extends StaticBody2D
class_name Objective

signal score_objective(points, attributed_to)
signal objective_destroyed(objective_id)

var health
var hitpoints_lost = 0
var blue
var value
var local_team
var destroyed = false
var objective_id

var priority
#var priority_objective_enemy = false
#var priority_objective_ally = false
var priority_multiplier = Overseer.game_settings["scoring"]["priority_multiplier"]
var scoring = {}

@onready var effect = $Smoke
@onready var defend_icon = $Defend
@onready var attack_icon = $Attack
@onready var collision_node = $Collision

func _ready():
	effect.visible = false
	effect.emitting = false
	set_icon()

func init(in_objective_id, in_position, in_hitpoints, in_team, in_value, in_local_team, in_priority):
	position = in_position
	objective_id = in_objective_id
	local_team = in_local_team
	value = in_value
	
	health = in_hitpoints
	if health <= 0: 
		destroyed = true	
	
	if in_team == local_team: 
		blue = true
		priority = in_priority
		collision_layer = 4
		collision_mask = 8
	else:
		blue = false
		collision_layer = 8
		collision_mask = 16
	
func set_icon():
	if blue:
		attack_icon.visible = false
		defend_icon.visible = true
		if priority:
			defend_icon.scale = 1.5 * defend_icon.scale
	else:
		attack_icon.visible = true
		defend_icon.visible = false

@rpc("any_peer", "call_local")
func lose_health(damage, attacker_id):
	health -= damage
	if health <= 0:
		destroy(attacker_id)
		attribute_score(damage, attacker_id)
	else:
		attribute_score(damage, attacker_id)

func get_team_scores():
	#var score_enemy = value * hitpoints_lost
	#if priority_objective_t1:
		#score_enemy = priority_multiplier * score_enemy
	
	#var score_ally = 0
	#if priority_objective_t2:
		#score_ally = -value * hitpoints_lost * priority_multiplier
	pass

func destroy(attacker_id):
	effect.visible = true
	effect.emitting = true
	collision_layer = 4
	collision_mask = 8
	
	objective_destroyed.emit(objective_id)
	print(attacker_id, " destroyed objective ", objective_id)

func attribute_score(damage, attacker_id):
	print(attacker_id, damage)
	pass
