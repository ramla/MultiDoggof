extends Node
class_name MainScene

var server = preload("res://server.tscn")
var serverinstance = server.instantiate()
var lobby_player = preload("res://lobby_player.tscn")
var lobby_players = {}

var local_id = 0
var local_osid = OS.get_unique_id()
var local_playername: String
var local_ready = false
var local_team = 0
var start_timer = Timer.new()
var ticktimer = Timer.new()
var orientation_timer = Timer.new()

var playerbase = {}
var last_round_playerbase = {}

var game_settings = Overseer.game_settings
var settingsmanager = SettingsManager.new()

var port = game_settings["port"]
var default_team = 0
var upnp = false
var hosting = false
var launched = false
var all_ready = false
var all_in_team = false
var team1_count = 0
var team2_count = 0
var countdown: int

@onready var addressbox = %AddressTextBox
@onready var infobox = %Infobox
@onready var namebox = %NameTextBox

var peer = ENetMultiplayerPeer.new()
# A MultiplayerPeer implementation that should be passed to MultiplayerAPI.multiplayer_peer after being initialized as either a client, server, or mesh. Events can then be handled by connecting to MultiplayerAPI signals.
# ENet's purpose is to provide a relatively thin, simple and robust network communication layer on top of UDP (User Datagram Protocol).

func _ready():
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	serverinstance.connect("player_disconnected", _on_player_disconnected)
	serverinstance.connect("put_infoboxline", _on_put_infoboxline)
	
	$Game.connect("game_over", _on_game_over)
	#print(OS.get_unique_id())
	
	%UPnPButton.connect("toggled", _on_upnp_button_toggled)
	%ProgressButton.connect("button_down", _on_team_select_progress)
	%FurtherButton.connect("button_down", _on_team_select_further)
	%ScoreButton.connect("pressed", _on_score_button_pressed)
	
	add_child(start_timer)
	start_timer.one_shot = true
	start_timer.wait_time = game_settings["launch_timer"]
	start_timer.connect("timeout", _on_start_timer_timeout)
	add_child(ticktimer)
	ticktimer.wait_time = .5
	ticktimer.connect("timeout", _on_tick)
	ticktimer.start()
	add_child(orientation_timer)
	orientation_timer.one_shot = true
	orientation_timer.wait_time = 5
	orientation_timer.connect("timeout", _on_orientation_timer_timeout)
	
	namebox.text = settingsmanager.get_setting("user", "name", "")
	addressbox.text = settingsmanager.get_setting("user", "last_server", "127.0.0.1")
	
func _process(_delta):
	if start_timer.is_stopped():
		%MotivationalLabel["text"] = "Do not hesitate"
	else:
		countdown = start_timer.time_left
		%MotivationalLabel["text"] = "Starting in " + str(countdown+1)

func are_we_there_yet():
	all_ready = true
	#print("are we there yet?")
	for id in playerbase:
		var player = playerbase[id]
		#print(player)
		if !player["is_ready"]:
			all_ready = false

func team_count():
	team1_count = 0
	team2_count = 0
	all_in_team = true
	for id in playerbase:
		var player = playerbase[id]
		if player["team"] == -1:
			team1_count += 1
		elif player["team"] == 1:
			team2_count += 1
	if team1_count + team2_count != len(playerbase):
		all_in_team = false
	%PlayerCount1.text = str(team1_count)
	%PlayerCount2.text = str(team2_count)
	if local_team == -1:
		%ProgressButton["theme_override_colors/font_color"] = game_settings["blue"]
		%FurtherButton["theme_override_colors/font_color"] = game_settings["red"]
	elif local_team == 1:
		%ProgressButton["theme_override_colors/font_color"] = game_settings["red"]
		%FurtherButton["theme_override_colors/font_color"] = game_settings["blue"]

func _on_put_infoboxline(blurt):
	infobox.text += blurt

func _on_connection_failed():
	print("Connection failed")
	infobox.text += infobox.text + "\nConnection failed"

func _on_connected_to_server():
	if Overseer.debug["quick_launch"]:
		#commenting all team autoselect code
		#local_team = get_team_least_players()
		local_ready = true
	announce_player.rpc_id(1, local_id, local_osid, namebox["text"], local_ready, local_team)
	infobox.text += "\nJoined lobby"

func _on_server_disconnected():
	print("Disconnected from server")
	infobox.text += "Disconnected from server"
	
func _on_player_disconnected(id):
	infobox.text += "Player id " + str(id) + "disconnected from server"
	$Game.handle_disconnected_player(id)

func _on_host_buttonpress():
	if not hosting:
		if Overseer.debug["quick_launch"]:
			local_ready = true
		add_child(serverinstance)
		addressbox.text = "Lobby started!"
		infobox.text += "Server bound to all interfaces: " + str(IP.get_local_addresses())
		hosting = true
		local_playername = namebox["text"]
		if local_playername == null:
			local_playername = "Hostcuck"
		local_id = multiplayer.get_unique_id()
		update_player(local_id, local_osid, local_playername, local_ready, local_team)
	else:
		serverinstance.terminate()
		remove_child(serverinstance)
		addressbox.text = "127.0.0.1"
		infobox.text += "Lobby closed"
		hosting = false
		local_id = 0

func _on_join_buttonpress():
	if addressbox.text == "":
		infobox.text += "Address field empty!"
		return
	elif hosting == true:
		infobox.text += "\nStill hosting! Click \"Host\" to close lobby"
		return
	infobox.text += "Connecting to " + (addressbox.text) + ":" + str(port)
	peer.create_client(addressbox.text, port)
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	settingsmanager.set_setting("user", "last_server", addressbox.text)

func launch(new_playerbase):
	$Game.reset(new_playerbase, local_team)
	$ScoreTable.update_players(new_playerbase)
	$Menu.hide()
	$Game.show()

func _on_game_over():
	$ScoreTable.show()
	$ScoreTable.draw_scores()
	if hosting:
		unready.rpc()
	$Game.hide()
	$Menu.show()
	%ScoreButton.show()

@rpc("any_peer", "reliable")
#commenting all team autoselect code
func announce_player(in_multi_id, in_os_id, in_playername, in_is_ready: bool = false, in_team: int = 0): #get_team_least_players()):
	var playername
	if Overseer.debug["quick_launch"]:
		in_is_ready = true
	if in_playername == "":
		if in_multi_id != 1: playername = "Landcuck " + str(in_multi_id)
		else: playername = "Hostcuck"
	else: playername = in_playername
	playername = playername.left(16)
	if in_multi_id == local_id:
		local_team = in_team
	update_player(in_multi_id,in_os_id,playername,in_is_ready,in_team)
	#print(local_id, " updated player ", in_multi_id, " ", playername.left(16), " ", in_team)
	
	if hosting:
		for id in playerbase:
			var player = playerbase[id]
			announce_player.rpc(id, player["os_id"], player["playername"], player["is_ready"], player["team"])
			#print("announced multi_id: ", in_multi_id, " == ", pl_id, " ", player["playername"], " ", player["os_id"], " ", player["is_ready"], " ", player["team"])

#commenting all team autoselect code
func update_player(in_multi_id, in_os_id, in_playername, in_is_ready = false, in_team = 0): #get_team_least_players()):
	if in_playername == "" && hosting:
		in_playername = "Hostcuck"
	
	#commenting all team autoselect code
	#if hosting && in_team == 0: 
		#in_team = get_team_least_players()
		#local_team = in_team
	
	if not in_multi_id in playerbase:
		var new_lobby_player = lobby_player.instantiate()
		%PlayerList.add_child(new_lobby_player)
		lobby_players[in_multi_id] = new_lobby_player
	lobby_players[in_multi_id].update(in_playername, in_is_ready, in_team, local_team)
	for id in lobby_players:
		lobby_players[id].refresh_team_color(local_team)

	playerbase[in_multi_id] = {
		"os_id" = in_os_id,
		"playername" = in_playername,
		"is_ready" = in_is_ready,
		"team" = in_team
		}

@rpc("reliable")
func announce_game_settings():
	#TODO: pass host's game settings to clients
	pass

@rpc("call_local")
func announce_message(multi_id, message):
	infobox.text += playerbase[multi_id]["playername"] + ": " + str(message)

func get_team_least_players():
	var teamdelta = 0
	var randval = randi() % 2
	for id in playerbase:
		var player = playerbase[id]
		teamdelta += player["team"]
	print("random team value: ", randval, " teamdelta: ", teamdelta)
	if teamdelta > 0:
		default_team = -1
	elif teamdelta < 0:
		default_team = 1
	elif teamdelta == 0 && randval == 0:
		default_team = -1
	else: 
		default_team = 1
	return default_team

func _on_upnp_button_toggled(toggle_position):
	upnp = toggle_position

func _on_ready_button_toggled(toggle_position):
	local_ready = !toggle_position
	if hosting:
		announce_player(local_id, local_osid, namebox.text, local_ready, local_team)
	else:
		announce_player.rpc_id(1, local_id, local_osid, namebox.text, local_ready, local_team)
	settingsmanager.set_setting("user", "name", namebox.text)

func _on_score_button_pressed():
	$ScoreTable.show()

func _on_team_select_progress():
	if local_team == 1:
		%ReadyButton.set_pressed(true)
	local_team = -1
	local_playername = namebox.text
	if hosting:
		announce_player(local_id, local_osid, namebox.text, local_ready, local_team)
		#print(local_id, " announced player ", local_id, " ", namebox.text, " ", local_team, "progressbutton")
	else:
		announce_player.rpc_id(1, local_id, local_osid, namebox.text, local_ready, local_team)
		#print("host announced player ", local_id, " ", namebox.text, " ", local_team, "progressbutton")
		
func _on_team_select_further():
	if local_team == -1:
		%ReadyButton.set_pressed(true)
	local_team = 1
	local_playername = namebox.text
	if hosting:
		announce_player(local_id, local_osid, namebox.text, local_ready, local_team)
		#print(local_id, " announced player ", local_id, " ", namebox.text, " ", local_team, "furtherbutton")
	else:
		announce_player.rpc_id(1, local_id, local_osid, namebox.text, local_ready, local_team)
		#print("host announced player ", local_id, " ", namebox.text, " ", local_team, "furtherbutton")

func _on_start_timer_timeout():
	launch(playerbase)
	launched = true
	ticktimer.stop()

func _on_tick():
	are_we_there_yet()
	team_count()
	if !launched && all_ready && all_in_team && team1_count >= 1 && team2_count >= 1 && start_timer.is_stopped():
		start_timer.start()
	elif !start_timer.is_stopped() && all_ready:
		return
	else:
		start_timer.stop()

@rpc("call_local", "reliable")
func unready():
	%ReadyButton.set_pressed(true)
	local_ready = false
	all_ready = false
	all_in_team = false
	launched = false
	last_round_playerbase = playerbase
	playerbase.clear()
	lobby_players.clear()
	for lobbyist in %PlayerList.get_children():
		%PlayerList.remove_child(lobbyist)
	update_player(local_id, local_osid, local_playername, local_ready, local_team)
	if hosting:
		request_announce_player.rpc()
	orientation_timer.start()

@rpc("authority", "reliable")
func request_announce_player():
	announce_player.rpc_id(1, local_id, local_osid, namebox["text"], local_ready, local_team)

func _on_orientation_timer_timeout():
	#print("ticktimer starting")
	ticktimer.start()
	if hosting:
		$Game.ready_to_receive = false
