extends StaticBody2D
class_name Objective

signal score_objective(points, attributed_to)

var health
var hitpoints_lost = 0
var blue
var value
var local_team
var destroyed = false
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
	pass

func init(in_position, in_hitpoints, in_team, in_value, local_team, priority):
	position = in_position
	
	if in_team == local_team: 
		blue = true
	else:
		blue = false
	set_icon()
	
	health = in_hitpoints
	if health <= 0: 
		destroyed = true
	
	value = in_value

func set_icon():
	if blue:
		attack_icon.visible = false
		defend_icon.visible = true
	else:
		attack_icon.visible = true
		defend_icon.visible = false

func lose_health(damage, attacker_id):
	health -= damage
	if health <= 0:
		destroy(attacker_id)
		attribute_score(damage, attacker_id)
	else:
		attribute_score(damage, attacker_id)

func get_team_scores():
	var score_enemy = value * hitpoints_lost
	#if priority_objective_t1:
		#score_enemy = priority_multiplier * score_enemy
	
	var score_ally = 0
	#if priority_objective_t2:
		#score_ally = -value * hitpoints_lost * priority_multiplier

func destroy(attacker_id):
	effect.visible = true
	effect.emitting = true
	collision_node.disabled = true
	pass

func attribute_score(damage, attacker_id):
	pass
