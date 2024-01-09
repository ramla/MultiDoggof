extends Node

var port = Overseer.game_settings["port"]
var max_clients = Overseer.game_settings["max_clients"]
@onready var peer = ENetMultiplayerPeer.new()

signal put_infoboxline
signal player_disconnected

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)

	upnp_setup()

	peer.create_server(port, max_clients)
	multiplayer.multiplayer_peer = peer

func upnp_setup():
	if get_parent().upnp:
		var upnp = UPNP.new()
		upnp.discover()
		upnp.add_port_mapping(port)
		put_infoboxline.emit("External IP: " + upnp.query_external_address())

func peer_connected(id):
	print("Client connected: ", id)
	put_infoboxline.emit("Client connected: " + str(id))

func peer_disconnected(id):
	player_disconnected.emit(id)
	print("Client disconnected: ", id)
	put_infoboxline.emit("Client disconnected: " + str(id))
	
func terminate():
	print("Terminating server")
	put_infoboxline.emit("Terminating server")
	peer.close()
