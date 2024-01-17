extends Node2D

signal game_over

var admirals = {}
var t1_color
var t2_color

var game_settings
#kirjottasko nää vaa sinne overseeriin

var admiral_scene = preload("res://admiral.tscn")
var objective_scene = preload("res://objective.tscn")
var local_id
var local_team
var local_objectives
@onready var hosting = false
var running = false
var pre_round_timer = Timer.new()
var round_timer = Timer.new()
var post_round_timer = Timer.new()


func _ready():
	add_child(pre_round_timer)
	add_child(round_timer)
	add_child(post_round_timer)
	pre_round_timer.connect("timeout", _on_pre_round_timer_timeout)
	round_timer.connect("timeout", _on_round_timer_timeout)
	post_round_timer.connect("timeout", _on_post_round_timer_timeout)

func _process(_delta):
	pass

func randomize_objectives():
	#only host runs this
		
	#randomise 1 priority offensive & priority defensive objective for each team
	#west,east; base,island,outpost 
	var t1_objectives = randomize_objective_set().append_array(randomize_objective_set())
	print("t1 objectives = ", t1_objectives)
	var t2_objectives = randomize_objective_set().append_array(randomize_objective_set())
	print("t2 objectives = ", t2_objectives)
	

func randomize_objective_set():
	var objective_set = [false,false,false]
	var prio_objective_in_set = randi() % 3
	for i in objective_set:
		print("objective set iteartion ", i, ", prio_obj = ", prio_objective_in_set)
		if i == prio_objective_in_set:
			objective_set[i] = true
	return objective_set

@rpc
func distribute_objectives(in_objectives):
	local_objectives = in_objectives
	pass

func load_objectives():
	for i in game_settings["level"]["objective_spawns"]:
		var spawn = game_settings["level"]["spawns"][i]
		objective_scene.init(spawn, game_settings["level"]["hitpoints"], game_settings["level"]["value"])
		#func init(in_position, in_hitpoints, in_team, in_value, local_team, priority):
		$Level.add_child(objective_scene)
	pass

func reset(new_game_settings,new_admirals,new_local_team,in_local_id):
	for n in $Admirals.get_children():
		$Admirals.remove_child(n)
	game_settings = new_game_settings
	local_team = new_local_team
	local_id = in_local_id
	
	if hosting:
		randomize_objectives()
	
	if local_team == -1:
		t1_color = game_settings["blue"]
		t2_color = game_settings["red"]
	else:
		t1_color = game_settings["red"]
		t2_color = game_settings["blue"]
	
	self.local_id = get_tree().get_multiplayer().get_unique_id()
	self.hosting = get_tree().get_multiplayer().is_server()
	running = true
	start_round_timer_chain()
	spawn(new_admirals)

func spawn(new_admirals):
	for id in new_admirals:
		var admiral = new_admirals[id]
		var admiral_instance = admiral_scene.instantiate()
		print("admiral_scene instantiated")
		admiral_instance.init(id, admiral["playername"], admiral["team"], local_team, local_id, game_settings)
		$Admirals.add_child(admiral_instance)
		admirals[id] = admiral_instance

func start_round_timer_chain():
	pre_round_timer.wait_time = game_settings["pre_round_length"]
	round_timer.wait_time = game_settings["round_length"]
	post_round_timer.wait_time = game_settings["post_round_length"]

	if hosting: print("täälä ollaan!!!!!!!!!!!!!!!!!!!!")
	pre_round_timer.one_shot = true
	round_timer.one_shot = true
	post_round_timer.one_shot = true
	pre_round_timer.start()
	
func handle_disconnected_player(id):
	if running:
		admirals[id].disconnect_admiral()
	get_owner().playerbase.erase(id)

func _on_pre_round_timer_timeout():
	if hosting:
		start_round_timer.rpc()
	pass

@rpc("call_local", "reliable")
func start_round_timer():
	round_timer.start()
	admirals[local_id].start_round()

func _on_round_timer_timeout():
	start_post_round_timer.rpc()

@rpc("call_local","reliable")
func start_post_round_timer():
	post_round_timer.start()
	admirals[local_id].start_post_round()

func _on_post_round_timer_timeout():
	running = false
	var hud = admirals[local_id].get_node("HUD")
	hud.visible = false

	game_over.emit()
#	game_over.emit(scoring)

	#TODO:
#	$Scorekeeper.get_round_results(scoring)

