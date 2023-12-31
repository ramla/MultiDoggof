#TODO: gettaa pelaajan ip jotta pääsee takasi: enet.get_peer(peer_id).get_remote_address()
#TODO: resetoi ready lobbyyn liittyessä, träkkää unready count, total hesitation time, who arrived early at a turning point/defining moment/crossroads, who made an uninformed decision, who made wrong decisions (ready before all arrived)??
#TODO: päivitä nimi kirjoittaessa kenttään (timer+ifchanged/signal(text_changed/text_set/focus_exited?)
#TODO: broadcast host selected game settings, constants & other gameplay variables

extends Control

var server = preload("res://server.tscn")
var serverinstance = server.instantiate()

var local_id = 0
var local_osid = OS.get_unique_id()
var local_playername: String
var local_ready = false
var local_team = 0

var playerbase = {}

var ticktimer: Timer = Timer.new()
var tick: int = -1

var game_settings = Overseer.game_settings
var port = game_settings["port"]
var default_team = 0
var hosting = false
var launched = false
var all_ready = false
var all_in_team = false
var team1_count = 0
var team2_count = 0

@onready var addressbox = $Menu/GridContainer2/GridContainer/AddressTextBox
@onready var infobox = $Menu/GridContainer2/RichTextLabel
@onready var namebox = $Menu/GridContainer2/GridContainer/NameTextBox

var peer = ENetMultiplayerPeer.new()
# A MultiplayerPeer implementation that should be passed to MultiplayerAPI.multiplayer_peer after being initialized as either a client, server, or mesh. Events can then be handled by connecting to MultiplayerAPI signals.
# ENet's purpose is to provide a relatively thin, simple and robust network communication layer on top of UDP (User Datagram Protocol).

func _ready():
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = peer
	$Game.hide()
	#TODO:connect game_over _on_game_over
	ticktimer.connect("timeout", _on_tick)
	ticktimer.wait_time = 5
	add_child(ticktimer)
	ticktimer.start()

func _process(delta):
	all_ready = true
	all_in_team = true
	team1_count = 0
	team2_count = 0
	for id in playerbase:
		var player = playerbase[id]
		if !player["is_ready"]:
			all_ready = false
		if player["team"] == -1:
			team1_count += 1
		elif player["team"] == 1:
			team2_count += 1
	$Menu/GridContainer2/GridContainer2/PlayerCount1.text = str(team1_count)
	$Menu/GridContainer2/GridContainer2/PlayerCount2.text = str(team2_count)
	if local_team == -1:
		$Menu/GridContainer2/GridContainer2/ProgressButton["theme_override_colors/font_color"] = game_settings["blue"]
		$Menu/GridContainer2/GridContainer2/FurtherButton["theme_override_colors/font_color"] = game_settings["red"]
	elif local_team == 1:
		$Menu/GridContainer2/GridContainer2/ProgressButton["theme_override_colors/font_color"] = game_settings["red"]
		$Menu/GridContainer2/GridContainer2/FurtherButton["theme_override_colors/font_color"] = game_settings["blue"]
	else:
		all_in_team = false
	if !launched && all_ready && all_in_team && team1_count >= 1 && team2_count >= 1:
		launch(game_settings, playerbase)
		launched = true

func _on_connection_failed():
	print("Connection failed")
	infobox.text = infobox.text + "\nConnection failed"

func _on_connected_to_server():
	if game_settings["quick_launch"]:
		local_team = 1
		local_ready = true
	announce_player.rpc_id(1, local_id, local_osid, namebox.text, local_ready, local_team)
	infobox.text += "\nJoined lobby"

func _on_server_disconnected():
	print("Disconnected from server")

func _on_host_buttonpress():
	if not hosting:
		if game_settings["quick_launch"]:
			local_ready = true
			local_team = -1
		add_child(serverinstance)
		multiplayer.multiplayer_peer = peer
		addressbox.text = "Lobby started!"
		infobox.text = "Server bound to all interfaces: " + str(IP.get_local_addresses())
		hosting = true
		local_playername = namebox.text
		if local_playername == null:
			local_playername = "Hostcuck"
		local_id = multiplayer.get_unique_id()
		update_player(local_id, local_osid, local_playername, local_ready, local_team)

	else:
		$Server.terminate()
		remove_child(serverinstance)
		addressbox.text = ""
		infobox.text = "Lobby closed"
		hosting = false
		local_id = 0

func _on_join_buttonpress():
	if addressbox.text == "":
		infobox.text = "Address field empty"
		return
	elif hosting == true:
		infobox.text += "\nStill hosting! Click \"Host\" to close lobby"
		return
	infobox.text = "Connecting to " + (addressbox.text) + ":" + str(port)
	peer.create_client(addressbox.text, port)
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	print("created client, multiplayer.is_server() returns ",multiplayer.is_server())
	
func _on_cause(selection):
	pass

func upnp_setup():
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(port)
	print("Server IP: " + upnp.query_external_address())

func launch(game_settings, playerbase):
	$Game.reset(game_settings, playerbase, local_team)
	$Menu.hide()
	$Game.show()
	
func _on_game_over(scoring):
	$Game.hide()
	$Menu.display_score(scoring)
	$Menu.show()
	
@rpc("any_peer")
func announce_player(multi_id, os_id, playername, is_ready: bool = false, team: int = get_team_least_players()):
	if game_settings["quick_launch"]:
		is_ready = true
	if playername == "":
		playername = "Landcuck " + str(multi_id)
	update_player(multi_id,os_id,playername.left(16),is_ready,team)

	if hosting:
		for pl_id in playerbase:
			var player = playerbase[pl_id]
			announce_player.rpc(pl_id, player["os_id"], player["playername"], player["is_ready"], player["team"])
			print("announced multi_id: ", multi_id, " == ", pl_id, " ", player["playername"], " ", player["os_id"], " ", player["is_ready"], " ", player["team"])

func update_player(multi_id, os_id, playername, is_ready = false, team = get_team_least_players()):
	if playername == "":
		playername = "Hostcuck"

	#tarvii for id in playerbase
	#if playerbase[os_id].get("playername",0) == playername:
		#var new = {"multi_id" = multi_id, "playername" = playername}
		#playerbase[os_id]["multi_id"] = multi_id
	#else:
		#var new = {"playername" = playername, "os_id" = os_id, "ready" = ready, "team" = team}
		#playerbase[multi_id].update(new)

	playerbase[multi_id] = {
		"os_id" = os_id,
		"playername" = playername,
		"is_ready" = is_ready,
		"team" = team
		}

@rpc("any_peer")
func announce_team(multi_id, team):
	pass
	
@rpc("any_peer")
func announce_message(multi_id, message):
	pass

func get_team_least_players():
	var teamdelta = 0
	for id in playerbase:
		var player = playerbase[id]
		teamdelta += player["team"]
	if teamdelta >= 0:
		default_team = -1
		print("default_team = ", default_team)
	else:
		default_team = 1
		print("default_team = ", default_team)
	return default_team

func _on_tick():
	tick += 1
	#print("tick ", tick)
	#print(": lobbyists @ ", local_id, ": ", playerbase)
	
func _on_ready_button_toggled(toggle_position):
	local_ready = !toggle_position
	if hosting:
		announce_player(local_id, local_osid, namebox.text, local_ready, local_team)
	else:
		announce_player.rpc_id(1, local_id, local_osid, namebox.text, local_ready, local_team)

func _on_team_select(team):
	local_team = team
	local_playername = namebox.text
	if hosting:
		announce_player(local_id, local_osid, local_playername, local_ready, local_team)
	else:
		announce_player.rpc_id(1, local_id, local_osid, local_playername, local_ready, local_team)
