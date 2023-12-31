extends Node2D

signal game_over

var admirals = {}
var t1_color
var t2_color
var game_settings
var admiral_scene = preload("res://admiral.tscn")
var local_id
var local_team
var hosting
var running = false

#TODO:
#var pre_round_timer jtnjtn 
#var round_timer
#var post_round_timer

func _ready():
	self.local_id = get_tree().get_multiplayer().get_unique_id()
	self.hosting = get_tree().get_multiplayer().is_server()
	pass

func _process(_delta):
	pass

func reset(new_game_settings,new_admirals,new_local_team,in_local_id):
	for n in $Admirals.get_children():
		$Admirals.remove_child(n)
	game_settings = new_game_settings
	local_team = new_local_team
	local_id = in_local_id
	if local_team == -1:
		t1_color = game_settings["blue"]
		t2_color = game_settings["red"]
	else:
		t1_color = game_settings["red"]
		t2_color = game_settings["blue"]
	
	spawn(new_admirals)
	$HUD.show()
	running = true
	#start_round_timer_chain()
	return

func spawn(new_admirals):
	for id in new_admirals:
		var admiral = new_admirals[id]
		var admiral_instance = admiral_scene.instantiate()
		admiral_instance.init(id, admiral["playername"], admiral["team"], local_team, local_id, game_settings)
		$Admirals.add_child(admiral_instance)
		admirals[id] = admiral_instance
	return

func handle_disconnected_player(id):
	if running:
		$Admirals.remove_child(admirals[id])
	
func _on_postround_end():
	$HUD.hide()
	running = false
	#TODO:
#	$Scorekeeper.get_round_results(scoring)
#	game_over.emit(scoring)
	pass
