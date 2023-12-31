extends CharacterBody2D

signal destroyed

var is_destroyed: bool = true

#later get from instantiation call
const MAX_SPEED = 50
const MAX_ACCEL = 100
const MAX_DECEL = 50
const MAX_RATE = PI/10

var speed = 0
var speed_input = 0
var accel = 0
var click_position = Vector2.ZERO
var spawn = Vector2.ZERO
var game_settings
var t_color
var blue: bool #aka is_blue aka is_player_or_ally
var local_id
var entity_id
var is_player
var is_ally
var is_enemy

@onready var admirals = get_parent().get_parent().admirals
@onready var fog_of_war_timer = get_node("FogOfWarTimer")
@onready var view_distance = get_node("ViewDistance")

#TODO make visible duration timer 
# -- off scene or on scene uninheritiung?? --
#var last_seen_timer = $SeenTimer

func _ready():
	is_destroyed = false
	click_position = Vector2(position.x, position.y)
	print(get_parent())

func _physics_process(delta):
	do_moves(delta)

func do_moves(delta):
	#set_multiplayer_authority(local_id)
	if Input.is_action_pressed("move_click"):
		click_position = get_global_mouse_position()
	
	var target_position = (click_position - position).normalized()
	speed = get_speed(delta)
	
	if position.distance_to(click_position) > 3:
		velocity = target_position * speed
		move_and_slide()
		look_at(click_position)
	
	recon_action()

func recon_action():
	if Input.is_action_pressed("recon"):
		$Recon.visible = true
		$Recon/Area.disabled = true
		#$Recon.position = Vector2.ZERO
		$Recon.look_at(get_global_mouse_position())
	else:
		if Input.is_action_just_released("recon"):
			$Recon/Area.disabled = false
		else:
			#$Recon.monitorable = false
			#$Recon.monitoring = false
			$Recon.visible = false
			$Recon/Area.disabled = true

func get_input():
	speed_input = Input.get_axis("down", "up")
	return speed_input

func get_speed(delta):
	speed_input = get_input()
	if speed_input == 0:
		return(speed)
	else: 
		if speed_input > 0:
			speed += (delta * speed_input * MAX_ACCEL)
		else:
			speed += (delta * speed_input * MAX_DECEL)

	speed = clamp(speed, 0, MAX_SPEED)
	return(speed)

func init(id, playername, team, local_team, in_local_id, in_settings):
	set_multiplayer_authority(id)
	game_settings = in_settings
	entity_id = id
	local_id = in_local_id
	if local_id == entity_id:
		blue = true
		is_player = true
		t_color = game_settings["blue"]
		self.collision_layer = 2
		$ViewDistance.collision_mask = 12
	elif local_team == team:
		blue = true
		is_ally = true
		t_color = game_settings["blue"]
		self.collision_layer = 4
		$ViewDistance.collision_mask = 8
	else:
		blue = false
		is_enemy = true
		t_color = game_settings["red"]
		self.collision_layer = 8
		$ViewDistance.collision_mask = 16
	set_visual(blue)
	if team == -1:
		spawn = game_settings["admiral"]["spawn_east"] + Vector2(0,randf_range(-100,100))
	else:
		spawn = game_settings["admiral"]["spawn_west"] + Vector2(0,randf_range(-100,100))
	global_position = spawn
	if !is_player:
		apply_fog_of_war()
	print("Init done @ ", local_id, ". Self: ", self, ", team: ", team, ", local_team: ", local_team)
	pass

func set_visual(blue: bool):
	var blue_texture = load("res://Assets/ENEMIES8bit_NegaBlob Idle.png")
	var nonblue_texture = load("res://Assets/ENEMIES8bit_Blob Idle.png")
	
	if blue:
		$Sprite2D["texture"] = blue_texture
	else:
		$Sprite2D["texture"] = nonblue_texture
#BUG:	-CLIENT näkee vaan vihollisen (kontrollit oikein)
#		-HOST näkee itsensä, mutta kun recon-skannaa, vihollinen näkyy alueen ulkopuolella
#			jonka jälkeen molemmat hidee
#		-myös CLIENT näkee molemmat recon-skannauksella ja timer hidee molemmat
#		-timeri jää rullaamaan (missä pitäs stoppaa?)

func apply_fog_of_war():
	#print("FOW active on ", entity_id, " at ", local_id)
	hide()
	if Overseer.debug["wallhack"]:
		$ViewDistance/Sprite2D.show()
	return

func _on_fog_of_war_timer_timeout(spotted_entity_id):
	print("FOW timer activation on ", entity_id, " at ", local_id)
	fog_of_war_timer.stop
	admirals[spotted_entity_id].hide()
	if Overseer.debug["wallhack"]:
		admirals[spotted_entity_id].show()

func _on_view_distance_body_entered(body):
	var spotted_entity_id = body.entity_id
	print(spotted_entity_id, " been spotted by ", entity_id)
	if !body.is_player:
		admirals[spotted_entity_id].show()
	else: print("should this really happen?")
		#TODO: save direction & speed for ghost estimate?

func _on_view_distance_body_exited(body):
	var spotted_entity_id = body.entity_id
	fog_of_war_timer.start(spotted_entity_id)
	return
