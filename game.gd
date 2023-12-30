extends Node2D

signal game_over

var t1_admirals = {}
var t2_admirals = {}

var admiral_scene = preload("res://admiral.tscn")
var admiral_entity = admiral_scene.instantiate()

#TODO:
#var pre_round_timer jtnjtn 
#var round_timer
#var post_round_timer

func _ready():
	#TODO:
	# connect successful attack
	# connect successful recon
	pass
	
func _process(delta):
	pass

func reset(game_settings,admirals):
	for t1_admirals in $Team1.get_children():
		$Team1.remove_child(admiral_entity)
	for t2_admirals in $Team2.get_children():
		$Team2.remove_child(admiral_entity)
	
	team_up_new(admirals)
		#$Team1.add_child(admiral_entity)
		#$Team2.add_child(admiral_entity)
	$HUD.show()
	
func team_up_new(admirals):
	t1_admirals = {}
	t2_admirals = {}
	for id in admirals:
		var admiral = admirals[id]
		if admiral["team"] == -1:
			t1_admirals[id] = admiral
		if admiral["team"] == 1:
			t2_admirals[id] = admiral
		#TODO: if no team kick or spectate (game setting)

func _on_successful_attack(attack):
	pass

func _on_successful_recon(information):
	pass
	
func _on_postround_end():
	$HUD.hide()
	#TODO:
#	$Scorekeeper.get_round_results(scoring)
#	game_over.emit(scoring)
	pass
