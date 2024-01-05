extends Node

var port = Overseer.game_settings["port"]
var max_clients = Overseer.game_settings["max_clients"]
@onready var peer = ENetMultiplayerPeer.new()

signal put_infoboxline
signal player_disconnected

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	print("OS.get_name()", OS.get_name())
	print("OS.get_unique_id(): ", OS.get_unique_id())
	#TODO: palauta käyttöön tarvittaessa! toimii myös linux muttei kaikis bokseis. oletuksena pois päält?
	#upnp_setup() #toimiskoha

	peer.create_server(port, max_clients)
	multiplayer.multiplayer_peer = peer

func upnp_setup():
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(port)
	put_infoboxline.emit("Server IP: " + upnp.query_external_address())
	print("ok?")

func peer_connected(id):
	print("Client connected: ", id)
	put_infoboxline.emit("Client connected: ", id)

func peer_disconnected(id):
	player_disconnected.emit(id)
	#TODO: $Game.retire_admiral(id)
	print("Client disconnected: ", id)
	put_infoboxline.emit("Client disconnected: ", id)
	
func terminate():
	print("Terminating server")
	put_infoboxline.emit("Terminating server")
	#TODO: disconnect/inform clients before terminating
	
	peer.close()
