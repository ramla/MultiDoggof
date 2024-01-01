extends Timer

signal return_fog_of_war(entity_id)

var entity_id

func _ready():
	print(entity_id, " new fog of war timer ready")
	pass
	
func init(id):
	entity_id = id
	wait_time = Overseer.game_settings["admiral"]["fog_of_war_speed"]
	print(wait_time)
	one_shot = true
	print(entity_id, " fog of war timer initiated")
	self.connect("timeout", on_timeout)

func on_timeout():
	print(entity_id, " fog of war timer timeout")
	return_fog_of_war.emit(entity_id)
