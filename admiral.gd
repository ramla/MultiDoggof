extends CharacterBody2D

signal destroyed(destroyed_id)
signal damage_taken(int)
signal spotted(spotted_id)

var is_destroyed: bool = true

#later get from instantiation call
var max_speed = 50
const MAX_ACCEL = 100
const MAX_DECEL = 50
const MAX_RATE = PI/10
var health = 3

var speed = 10
var speed_input = 0
var accel = 0
var click_position = Vector2.ZERO
var spawn = Vector2.ZERO
var game_settings
var t_color
var blue: bool #aka is_blue aka is_player_or_ally
var entity_playername = "How'd this happen"
var local_id
var entity_id
var is_player
var is_ally
var is_enemy

var timer_scene = preload("res://fog_of_war_timer.tscn")
var fow_timer_instantiated = timer_scene.instantiate()
var fog_of_war_timers: Dictionary = {}
var ghost_scene = preload("res://ghost.tscn")

@onready var admirals = get_parent().get_parent().admirals
var view_distance: Area2D
var recon_mission: Area2D
var attack_mission: Area2D
@onready var attack_area = $AttackMission/Area

func _ready():
	is_destroyed = false
	click_position = Vector2(position.x, position.y)

func _unhandled_input(_event):
	if is_player: 
		if Input.is_action_pressed("recon_action") && recon_mission.is_ready():
			recon_mission.plan_recon_mission()
			if Input.is_action_just_pressed("action_click"):
				recon_mission.order_recon_mission()
				get_window().set_input_as_handled()
			get_window().set_input_as_handled()
		else: recon_mission.visible = false
		if Input.is_action_pressed("attack_action"):
			attack_mission.plan_attack_mission()
			if Input.is_action_just_pressed("action_click"):
				attack_mission.order_attack_mission()
				get_window().set_input_as_handled()
			get_window().set_input_as_handled()
		else: attack_mission.visible = false
		if Input.is_action_just_released("action_click") && Input.is_action_pressed("recon_action"):
			pass		
		elif Input.is_action_just_released("action_click") && Input.is_action_pressed("attack_action"):
			pass
	#koska ei rpc, ei tu kuvii toisille clienteille?
	speed_input = Input.get_axis("down", "up")
	return speed_input

func _physics_process(delta):
	if !is_destroyed:
		do_moves(delta)

func do_moves(delta):
	if Input.is_action_pressed("move_click"):
		click_position = get_global_mouse_position()

	var target_position = (click_position - position).normalized()
	speed = get_speed(delta)
	
	if position.distance_to(click_position) > 3:
		velocity = target_position * speed
		move_and_slide()
		look_at(click_position)

func get_speed(delta):
	if speed_input == 0:
		return(speed)
	else: 
		if speed_input > 0:
			speed += (delta * speed_input * MAX_ACCEL)
		else:
			speed += (delta * speed_input * MAX_DECEL)

	speed = clamp(speed, 10, max_speed)
	return(speed)

func init(id, in_playername, team, local_team, in_local_id, in_settings):
	game_settings = in_settings
	entity_id = id
	local_id = in_local_id
	entity_playername = in_playername
	set_multiplayer_authority(entity_id)
	is_destroyed = false
	view_distance = $ViewDistance
	recon_mission = $ReconMission
	attack_mission = $AttackMission
	recon_mission.visible = false
	attack_mission.visible = false
	if Overseer.debug["pace_up"]:
		max_speed = max_speed * 2
	recon_mission.connect("body_entered", _on_recon_body_entered)
	attack_mission.connect("body_entered", _on_attack_body_entered)
	view_distance.connect("body_entered", _on_view_distance_body_entered)
	view_distance.connect("body_exited", _on_view_distance_body_exited)
	print(view_distance)
	if local_id == entity_id:
		blue = true
		is_player = true
		t_color = game_settings["blue"]
		self.collision_layer = 2
		view_distance.collision_mask = 12
		recon_mission.collision_mask = 12
		attack_mission.collision_mask = 12
	elif local_team == team:
		blue = true
		is_ally = true
		t_color = game_settings["blue"]
		self.collision_layer = 4
		view_distance.collision_mask = 8
		recon_mission.collision_mask = 8
		attack_mission.collision_mask = 8
	else:
		blue = false
		is_enemy = true
		t_color = game_settings["red"]
		self.collision_layer = 8
		view_distance.collision_mask = 16
		recon_mission.collision_mask = 16
		attack_mission.collision_mask = 16
	set_visual()
	if team == -1:
		spawn = game_settings["admiral"]["spawn_east"] + Vector2(0,randf_range(-100,100))
	else:
		spawn = game_settings["admiral"]["spawn_west"] + Vector2(0,randf_range(-100,100))
	global_position = spawn
	if !is_player:
		apply_fog_of_war()
	print("Init done @ ", local_id, ". Self: ", self, ", team: ", team, ", local_team: ", local_team)

func set_visual():
	var blue_texture = load("res://Assets/ENEMIES8bit_NegaBlob Idle.png")
	var nonblue_texture = load("res://Assets/ENEMIES8bit_Blob Idle.png")
	var destroyed_blue_texture = load("res://Assets/item8BIT_skull_blue.png")
	var destroyed_nonblue_texture = load("res://Assets/item8BIT_skull_nonblue.png")
	
	if !is_destroyed:
		if blue:
			$Sprite2D["texture"] = blue_texture
		else:
			$Sprite2D["texture"] = nonblue_texture
	else:
		if blue:
			$Sprite2D["texture"] = destroyed_blue_texture
		else:
			$Sprite2D["texture"] = destroyed_nonblue_texture

func apply_fog_of_war():
	#print("FOW active on ", entity_id, " at ", local_id)
	hide()
	if Overseer.debug["wallhack"]:
		view_distance.get_node("Sprite2D").show()

func ghost_last_known_admiral_location(spotted_entity_id):
	if entity_id != spotted_entity_id:
		admirals[spotted_entity_id].show()
		if !fog_of_war_timers.has(spotted_entity_id):
			self.add_child(fow_timer_instantiated)
			fog_of_war_timers[spotted_entity_id] = fow_timer_instantiated
			fog_of_war_timers[spotted_entity_id].init(spotted_entity_id)
			fog_of_war_timers[spotted_entity_id].connect("return_fog_of_war", _on_return_fog_of_war)
			print("connected ", spotted_entity_id, " fog of war")
		fog_of_war_timers[spotted_entity_id].start()
		print(spotted_entity_id, " fog of war timer started on ", entity_id, " @local_id ", local_id)
	else: print("should this really happen? (reveal_admiral_location)")

func _on_return_fog_of_war(seen_entity_id):
	print("FOW timer activation on ", entity_id, " at ", local_id)
	admirals[seen_entity_id].hide()
	if Overseer.debug["wallhack"]:
		admirals[seen_entity_id].show()
	var ghost_instantiated = ghost_scene.instantiate()
	ghost_instantiated.init(seen_entity_id, admirals[seen_entity_id].position, admirals[seen_entity_id].blue, true)
	get_parent().get_parent().get_node("Ghosts").add_child(ghost_instantiated)

func _on_view_distance_body_entered(body):
	var spotted_entity_id = body.entity_id
	spotted.emit(spotted_entity_id)
	print(spotted_entity_id, " been spotted by ", entity_id, " (body= ", body, "), body.get_owner() = ", body.get_owner())
	if entity_id != spotted_entity_id:
		admirals[spotted_entity_id].show()
	else: print("should this really happen? (view_distacne)")
		#TODO: save direction & speed for ghost estimate?
		#BUG: FoW menee päälle vaikka LOS pysyy
		
func _on_view_distance_body_exited(body):
	var spotted_entity_id = body.entity_id
	print(spotted_entity_id, " left line of sight of ", entity_id)
	ghost_last_known_admiral_location(spotted_entity_id)

func _on_recon_body_entered(body):
	var spotted_entity_id = body.entity_id
	print(spotted_entity_id, "'s recon spotted ", entity_id)
	ghost_last_known_admiral_location(spotted_entity_id)
	spotted.emit(spotted_entity_id)

func _on_attack_body_entered(body):
	var spotted_entity_id = body.entity_id
	print(spotted_entity_id, "'s attacker spotted ", entity_id)
	ghost_last_known_admiral_location(spotted_entity_id)
	spotted.emit(spotted_entity_id)
	if !admirals[spotted_entity_id].blue:
		take_damage.rpc_id(spotted_entity_id, spotted_entity_id)
	else: print("should this really happen? (attack)")

@rpc("call_local")
func take_damage(in_id):
	health -= 1
	if in_id == local_id: damage_taken.emit(1)
	if health <= 0:
		destroy.rpc(in_id)
		#TODO:next up
			#delay on recon/attack effect
			#finish destroyed effect
			#
			#get to the ghosts
@rpc("call_local")
func destroy(destroyed_id):
	admirals[destroyed_id].is_destroyed = true
	admirals[destroyed_id].set_visual()
	print("!!!!! ", destroyed_id, " has been destroyed!")
