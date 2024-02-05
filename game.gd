extends Node2D

signal game_over
signal basic_init_ready

var admirals = {}

var t1_color
var t2_color

var game_settings
#kirjottasko nää vaa sinne overseeriin

var playerbase = {}

var admiral_scene = preload("res://admiral.tscn")
var objective_scene = preload("res://objective.tscn")
var local_id
var local_team
var local_objective_priorities
var objectives_received = false
@onready var hosting = false		#ALERT: why on earth is this @onready
var running = false
var client_state_checklist = {}
var client_state_queue = {}
var client_state_checklist_initialized = false
var checklist_queue = { "1" = true }
var clients_ready = false
var ready_to_receive = false
var status_successfully_sent = false
@export var tick: int = 0


enum ClientState { Lobby, Waiting4Spawn, Waiting4Objectives, Waiting4Round2Start }
var local_state = ClientState.Lobby
var expected_state = ClientState.Lobby

var pre_round_timer = Timer.new()
var round_timer = Timer.new()
var post_round_timer = Timer.new()
var fail_timer = Timer.new()
var client_state_check_timer = Timer.new()
var ticktimer = Timer.new()

func _ready():
	add_child(pre_round_timer)
	add_child(round_timer)
	add_child(post_round_timer)
	add_child(fail_timer)
	add_child(client_state_check_timer)
	add_child(ticktimer)
	
	pre_round_timer.connect("timeout", _on_pre_round_timer_timeout)
	round_timer.connect("timeout", _on_round_timer_timeout)
	post_round_timer.connect("timeout", _on_post_round_timer_timeout)
	
	fail_timer.connect("timeout", _on_fail_timer_timeout)
	fail_timer.wait_time = .2
	fail_timer.one_shot = true

	client_state_check_timer.connect("timeout", _on_client_state_check_timer_timeout)
	client_state_check_timer.wait_time = .2
	
	ticktimer.wait_time = .1
	ticktimer.connect("timeout", _on_tick)

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
	local_objective_priorities = in_objectives
	print(local_id, " received objectives ", in_objectives)
	objectives_received = true
	load_objectives()
	local_state = ClientState.Waiting4Round2Start
	update_client_state.rpc_id(1, local_id, local_state)
	fail_timer.start()
	print(local_id, " WAITING for round 2 start")

func load_objectives():
	var i = 0
	for n in $Level.get_children():
		$Level.remove_child(n)
	for spawnpoint in game_settings["objective"]["spawns"]:
		var objective_priority = local_objective_priorities[i]
		var obj_team
		if spawnpoint.contains("east"): obj_team = -1
		else: obj_team = 1
		var objective_instance = objective_scene.instantiate()
		objective_instance.init(i, game_settings["objective"]["spawns"][spawnpoint], game_settings["objective"]["hitpoints"], obj_team, game_settings["objective"]["value"], local_team, objective_priority)
		print(local_id, " objspawn ", spawnpoint, " obj_team ", obj_team, " local_team ", local_team)
		$Level.add_child(objective_instance)
		i += 1
	print(local_id, " loaded objectives")

func reset(new_game_settings,new_admirals,new_local_team):
	self.local_id = get_tree().get_multiplayer().get_unique_id()
	self.hosting = get_tree().get_multiplayer().is_server()
	
	for n in $Admirals.get_children():
		$Admirals.remove_child(n)
	
	playerbase = new_admirals
	game_settings = new_game_settings
	local_team = new_local_team
	
	if local_team == -1:
		t1_color = game_settings["blue"]
		t2_color = game_settings["red"]
	else:
		t1_color = game_settings["red"]
		t2_color = game_settings["blue"]
	
	if hosting:
		fail_timer.wait_time = 5
		init_client_state_checklist(new_admirals)
		#spawn(admirals)
		basic_init_ready.emit()
		expected_state = ClientState.Waiting4Spawn
		wait_for_clients_ready()
		print("HOST WAITING for clients ready to spawn, expected state: ", str(expected_state))
	else:
		local_state = ClientState.Waiting4Spawn
		fail_timer.one_shot = false
		fail_timer.start()
		update_client_state.rpc_id(1, local_id, local_state)
		print(local_id, " called update_client_state ", str(local_state), " (waiting 4 spawn)")
		
	start_round_timer_chain()

@rpc("reliable", "call_local")
func spawn():
	for id in playerbase:
		var admiral = playerbase[id]
		var admiral_instance = admiral_scene.instantiate()
		admiral_instance.init(id, admiral["playername"], admiral["team"], local_team, local_id, game_settings)
		$Admirals.add_child(admiral_instance)
		admirals[id] = admiral_instance
	print(local_id, " spawned admirals")
	if !hosting:
		local_state = ClientState.Waiting4Objectives
		fail_timer.start()
		update_client_state.rpc_id(1, local_id, local_state)
		print(local_id, " called update_client_state ", local_state, " (w/4objectives), fail timer started")

func init_client_state_checklist(in_admirals):
	for i in in_admirals:
		if i != 1:
			client_state_checklist[i] = null
	client_state_checklist_initialized = true
	print(local_id, " ClientState checklist initialized w/ false for each client id.")

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
		print("PRE ROUND over")
		print("Fail timer started")
		if clients_ready:
			print("HOST: clients ready, starting round timer")
			fail_timer.stop()
			start_round_timer.rpc()
		else: print("HOST: clients NOT READY, fail timer is our last chance!")

@rpc("call_local", "reliable")
func start_round_timer():
	if !running:
		ready_to_receive = true
		pre_round_timer.stop()
		running = true
		round_timer.start()
		clients_ready = false
		admirals[local_id].start_round()
		tick = 0
		ticktimer.start()
		print(local_id, " started round timer")

func _on_round_timer_timeout():
	if hosting:
		start_post_round_timer.rpc()

@rpc("call_local","reliable")
func start_post_round_timer():
	post_round_timer.start()
	admirals[local_id].start_post_round()

func _on_post_round_timer_timeout():
	running = false
	var hud = admirals[local_id].get_node("HUD")
	hud.visible = false
	local_state = ClientState.Lobby
	update_client_state.rpc_id(1, local_id, local_state)

	game_over.emit()

func _on_fail_timer_timeout():
	if hosting:
		#intent is to return to lobby instead, but for now let's just go ahead and start the round
		if clients_ready:
			print("FAIL TIMER TIMEOUT w/ clients_ready == true, starting round")
		else:
			print("LAUNCH FAILED")
			admirals[local_id].cprint("GAME LAUNCH FAILED")
	else:
		if !status_successfully_sent:
			update_client_state.rpc_id(1, local_id, local_state)

func _on_tick():
	tick += 1

func _on_ready_for_round():
	start_round_timer.rpc()

func is_all_clients_state(in_expected_state):
	client_state_check_timer.stop()
	var all_states_match = true
	print("HOST checking clients states match? checklist: ", client_state_checklist)
	for i in client_state_checklist:
		if client_state_checklist[i] != in_expected_state:
			all_states_match = false
	if all_states_match:
		proceed_to_next_phase(in_expected_state)
#		clients_ready = false
		client_state_checklist_initialized = false
	else: client_state_check_timer.start()

func wait_for_clients_ready():
	client_state_check_timer.start()
	ready_to_receive = true
	print("HOST started client state check timer, ready to receive = true")

func _on_client_state_check_timer_timeout():
	is_all_clients_state(expected_state)
	print("client_state_check_timer_timeout")

@rpc("any_peer", "reliable")
func update_client_state(in_client_id, in_client_state: ClientState):
	if ready_to_receive:
		print("HOST received & confirming ", in_client_id, " state ", in_client_state)
		client_state_checklist[in_client_id] = in_client_state
		confirm_received.rpc_id(in_client_id, in_client_state)

func proceed_to_next_phase(in_state):
	print("HOST proceeding to next phase, all states matched expected_state ", expected_state)
	match in_state:
		ClientState.Lobby:
			pass
		ClientState.Waiting4Spawn:
			ready_to_receive = false
			spawn.rpc()
			expected_state = ClientState.Waiting4Objectives
			print("HOST WAITING for clients to ready for objectives, expected state == ", expected_state)
			init_client_state_checklist(admirals)
			wait_for_clients_ready()
		ClientState.Waiting4Objectives:
			ready_to_receive = false
			local_objective_priorities = randomize_objectives()
			distribute_objectives.rpc(local_objective_priorities)
			load_objectives()
			expected_state = ClientState.Waiting4Round2Start
			print("HOST WAITING for clients to ready for round 2 start, expected state == ", expected_state)
			init_client_state_checklist(admirals)
			wait_for_clients_ready()
		ClientState.Waiting4Round2Start:
			#ready_to_receive = false
			init_client_state_checklist(admirals)
			print("HOST LAUNCHING ?")
			clients_ready = true

@rpc("reliable")
func confirm_received(received_state):
	print(local_id, " got host confirmation for state update, received state == ", received_state)
	if received_state == local_state:
		status_successfully_sent = true
		print(local_id, " got host confirmation for state update, fail timer stopped")
	else: print("received unexpected state confirmation")
