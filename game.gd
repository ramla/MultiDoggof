extends Node2D

signal game_over
signal got_them_objectives
signal ready_for_round
signal basic_init_ready

var admirals = {}
var t1_color
var t2_color

var game_settings
#kirjottasko nää vaa sinne overseeriin

var admiral_scene = preload("res://admiral.tscn")
var objective_scene = preload("res://objective.tscn")
var local_id
var local_team
var local_objective_priorities
var objectives_received = false
@onready var hosting = false		#ALERT: why on earth is this @onready
var running = false
var ready_for_round_checklist = {}
var checklist_initialized = false
var checklist_queue = { "1" = true }
var clients_ready = false

var pre_round_timer = Timer.new()
var round_timer = Timer.new()
var post_round_timer = Timer.new()
var fail_timer = Timer.new()

func _ready():
	add_child(pre_round_timer)
	add_child(round_timer)
	add_child(post_round_timer)
	add_child(fail_timer)
	pre_round_timer.connect("timeout", _on_pre_round_timer_timeout)
	round_timer.connect("timeout", _on_round_timer_timeout)
	post_round_timer.connect("timeout", _on_post_round_timer_timeout)
	
	fail_timer.connect("timeout", _on_fail_timer_timeout)
	fail_timer.wait_time = 10
	fail_timer.one_shot = true

func _process(_delta):
	pass

func randomize_objectives():
	#only host runs this
		
	#randomise 1 priority offensive & priority defensive objective for each team
	#west,east; base,island,outpost 
	var obj_set_1 = randomize_objective_set()
	var obj_set_2 = randomize_objective_set()
	var obj_set_3 = randomize_objective_set()
	var obj_set_4 = randomize_objective_set()
	#print(obj_set_1, " ", obj_set_2, " ", obj_set_3, " ", obj_set_4)
	obj_set_1.append_array(obj_set_2)
	obj_set_1.append_array(obj_set_3)
	obj_set_1.append_array(obj_set_4)
	#print(local_id, " objective priorities randomized: ", obj_set_1)
	return obj_set_1

func randomize_objective_set():
	var objective_set = [false,false,false]
	var prio_objective_in_set = randi() % 3
	for n in 3:
#		print("objective set iteartion ", n, ", prio_obj = ", prio_objective_in_set)
		if n == prio_objective_in_set:
			objective_set[n] = true
	return objective_set

@rpc("reliable")
func distribute_objectives(in_objectives):
	if local_id == null:
		print("null local_id AWAITING")
		await basic_init_ready
		print("basic_init_ready get @ ", local_id)
	local_objective_priorities = in_objectives
	print(local_id, " received objectives ", in_objectives)
	objectives_received = true
	got_them_objectives.emit()

@rpc("reliable", "any_peer")
func confirm_received_objectives(confirmant_id):
	print(local_id, " received objectives confirmation from ", confirmant_id)
	if checklist_initialized == false:
		checklist_queue[confirmant_id] = true
	else:
		ready_for_round_checklist[confirmant_id] = true
		are_clients_ready() 

func load_objectives():
	var i = 0
	for spawnpoint in game_settings["objective"]["spawns"]:
		var objective_priority = local_objective_priorities[i]
		var obj_team
		if spawnpoint.contains("east"): obj_team = -1
		else: obj_team = 1
		var objective_instance = objective_scene.instantiate()
		objective_instance.init(game_settings["objective"]["spawns"][spawnpoint], game_settings["objective"]["hitpoints"], obj_team, game_settings["objective"]["value"], local_team, objective_priority)
		print(local_id, " objspawn ", spawnpoint, " obj_team ", obj_team, " local_team ", local_team)
		$Level.add_child(objective_instance)
		i += 1
	print(local_id, " loaded objectives")

func reset(new_game_settings,new_admirals,new_local_team,in_local_id):
	self.local_id = get_tree().get_multiplayer().get_unique_id()
	print(local_id, " + in_local_id == ", in_local_id)
	self.hosting = get_tree().get_multiplayer().is_server()
	
	for n in $Admirals.get_children():
		$Admirals.remove_child(n)
	game_settings = new_game_settings
	local_team = new_local_team
	#local_id = in_local_id
	
	basic_init_ready.emit()
	
	if local_team == -1:
		t1_color = game_settings["blue"]
		t2_color = game_settings["red"]
	else:
		t1_color = game_settings["red"]
		t2_color = game_settings["blue"]
	
	spawn(new_admirals)
	start_round_timer_chain()

	print(local_id, " hosting = ", hosting)
	if hosting:
		init_ready_for_round_checklist(new_admirals)
		local_objective_priorities = randomize_objectives()
		distribute_objectives.rpc(local_objective_priorities)
		load_objectives()
		print("host waiting for clients to ready objectives")
		await ready_for_round
		print("READY FOR ROUND GOT! next up: what?")
	elif objectives_received:
		load_objectives()
	else:
		print(local_id, " waiting for host to send objectives data")
		get_owner().infobox.text += "Waiting for host to send objectives data"
		await got_them_objectives
		load_objectives()
		confirm_received_objectives.rpc_id(1, local_id)

func spawn(new_admirals):
	for id in new_admirals:
		var admiral = new_admirals[id]
		var admiral_instance = admiral_scene.instantiate()
		admiral_instance.init(id, admiral["playername"], admiral["team"], local_team, local_id, game_settings)
		$Admirals.add_child(admiral_instance)
		admirals[id] = admiral_instance
	print(local_id, " spawned admirals")

func init_ready_for_round_checklist(in_admirals):
	for i in in_admirals:
		if i != 1:
			ready_for_round_checklist[i] = false
	print(ready_for_round_checklist)
	checklist_initialized = true
	print(local_id, " rfr checklist initialized w/ false for each client id, list above")
	for i in checklist_queue:
		if i != "1":
			ready_for_round_checklist[i] = true
	
func start_round_timer_chain():
	pre_round_timer.wait_time = game_settings["pre_round_length"]
	round_timer.wait_time = game_settings["round_length"]
	post_round_timer.wait_time = game_settings["post_round_length"]

	pre_round_timer.one_shot = true
	round_timer.one_shot = true
	post_round_timer.one_shot = true
	pre_round_timer.start()
	print(local_id, " started pre_round_timer")

func handle_disconnected_player(id):
	if running:
		admirals[id].disconnect_admiral()
	get_owner().playerbase.erase(id)

func _on_pre_round_timer_timeout():
	if hosting:
		fail_timer.start()
		print("PRE ROUND OVER")
		print("FAIL TIMER START")
		if clients_ready:
			start_round_timer.rpc()
		
	else:
		print(local_id, " waiting for host to rpc start round")
		admirals[local_id].cprint("Waiting for clients")

@rpc("call_local", "reliable")
func start_round_timer():
	if !running:
		running = true
		round_timer.start()
		admirals[local_id].start_round()
		print(local_id, " started round timer")

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

func _on_fail_timer_timeout():
	#intent is to return to lobby instead, but for now let's just go ahead and start the round
	print("FAIL TIMER TIMEOUT")
	if clients_ready:
		ready_for_round.emit()
		start_round_timer.rpc()
	else:
		print("LAUNCH FAILED")
		admirals[local_id].cprint("GAME LAUNCH FAILED")

func are_clients_ready():
	if !clients_ready:
		clients_ready = true
		for i in ready_for_round_checklist:
			if ready_for_round_checklist[i] == false:
				clients_ready = false
	#			print(i, " is not ready")
	#		else: print(i, " is ready!")
	if clients_ready:
		ready_for_round.emit()
	print(local_id, " are_clients_ready says ", clients_ready)
	
