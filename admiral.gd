extends CharacterBody2D

signal destroyed(destroyed_id)
signal damage_taken(int)
signal spotted(spotted_id)
signal munitions_used(amount)
signal cprint_signal(String)

var is_destroyed: bool = true

const MAX_ACCEL = 100
const MAX_DECEL = 50
const MAX_RATE = PI/10
var min_speed = Overseer.game_settings["admiral"]["min_speed"]
var max_speed = Overseer.game_settings["admiral"]["max_speed"]

var health = Overseer.game_settings["admiral"]["health"]
var fuel_oil = Overseer.game_settings["admiral"]["fuel_oil"]
var munitions = Overseer.game_settings["admiral"]["munitions"]
var aviation_fuel = Overseer.game_settings["admiral"]["aviation_fuel"]
var fuel_oil_consumption_multiplier = Overseer.game_settings["admiral"]["fuel_oil_consumption_multiplier"]
var fuel_oil_consumption_idle = Overseer.game_settings["admiral"]["fuel_oil_consumption_idle"]
var fuel_oil_consumption_base = Overseer.game_settings["admiral"]["fuel_oil_consumption_base"]
var fuel_oil_consumption_ineff = Overseer.game_settings["admiral"]["fuel_oil_consumption_ineff"]
var fuel_oil_consumption_divider = Overseer.game_settings["admiral"]["fuel_oil_consumption_divider"]
var current_fuel_oil_consumption = 0

var speed = min_speed
var previous_speed = min_speed
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
var in_line_of_sight = false

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
		if Input.is_action_pressed("recon_action") && recon_mission.is_ready() && !is_destroyed:
			recon_mission.plan_recon_mission()
			if Input.is_action_just_pressed("action_click"):
				recon_mission.order_recon_mission()
				get_window().set_input_as_handled()
			get_window().set_input_as_handled()
		else: recon_mission.visible = false
		if Input.is_action_pressed("attack_action") && attack_mission.is_ready() && !is_destroyed:
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
	speed_input = Input.get_axis("decelerate", "accelerate")
	return speed_input

func _physics_process(delta):
	#if !is_destroyed:
	if is_player:
		consume_fuel_oil(delta)
		do_moves(delta)

func do_moves(delta):
	if Input.is_action_pressed("move_click") && fuel_oil > 0:
		click_position = get_global_mouse_position()
		speed = previous_speed
	elif Input.is_action_just_pressed("stop"):
		click_position = position

	var target_position = (click_position - position).normalized()
	speed = get_speed(delta)
	
	if position.distance_to(click_position) > 3:
		velocity = target_position * speed
		move_and_slide()
		look_at(click_position)
		previous_speed = speed
	else: 
		speed = 0

func get_speed(delta):
	if speed_input == 0:
		return(speed)
	else: 
		if speed_input > 0:
			speed += (delta * speed_input * MAX_ACCEL)
		else:
			speed += (delta * speed_input * MAX_DECEL)

	speed = clamp(speed, min_speed, max_speed)
	return(speed)

func consume_fuel_oil(delta):
	if speed < min_speed - 1 :
		current_fuel_oil_consumption = fuel_oil_consumption_idle * delta
		#print("consuming ", current_fuel_oil_consumption, " /delta while idling (min_speed - speed = ", min_speed - speed)
	else:
		current_fuel_oil_consumption = ((fuel_oil_consumption_base * speed + fuel_oil_consumption_ineff * (speed - min_speed)) * delta) / fuel_oil_consumption_divider
		#print("consuming ", current_fuel_oil_consumption, " /delta @ speed ", speed)
	fuel_oil -= current_fuel_oil_consumption
	if fuel_oil <= 0:
		click_position = position

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
	if local_id == entity_id:
		blue = true
		is_player = true
		t_color = game_settings["blue"]
		self.collision_layer = 2
		view_distance.collision_mask = 12
		recon_mission.collision_mask = 12
		attack_mission.collision_mask = 12
		%HUD.init(health, munitions, fuel_oil, aviation_fuel, local_id)
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
		#$AttackMission.queue_free()
		#$ReconMission.queue_free()
		%HUD.queue_free()
		apply_fog_of_war()
	#cprint("Init done @ " + str(local_id) + ". Self: " + str(self) + ", team: " + str(team) + ", local_team: " + str(local_team))

func set_visual():
	cprint("setting visual on local_id ", local_id, " for entity_id ", entity_id)
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

func cprint(arg0, _arg1 = "", _arg2 = "", _arg3 = "", _arg4 = "", _arg5 = "", _arg6 = "", _arg7 = "", _arg8 = "", _arg9 = "", _arg10 = "", _arg11 = "", _arg12 = ""):
	if is_player:
		var x = [arg0, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6, _arg7, _arg8, _arg9, _arg10, _arg11, _arg12]
		var output = ""
		for arg in x:
			output += str(arg)
		cprint_signal.emit(output)

func apply_fog_of_war():
	#cprint("FOW active on "+ str(entity_id)+ " at "+ str(local_id))
	hide()
	if Overseer.debug["wallhack"]:
		view_distance.get_node("Sprite2D").show()

func ghost_last_known_admiral_location(spotted_entity_id):
	if entity_id != spotted_entity_id:
		admirals[spotted_entity_id].show()
		if !fog_of_war_timers.has(spotted_entity_id):
			add_child(fow_timer_instantiated)
			fog_of_war_timers[spotted_entity_id] = fow_timer_instantiated
			fog_of_war_timers[spotted_entity_id].init(spotted_entity_id)
			fog_of_war_timers[spotted_entity_id].connect("return_fog_of_war", _on_return_fog_of_war)
			#cprint("connected ", spotted_entity_id, " fog of war")
		fog_of_war_timers[spotted_entity_id].start()
		#cprint(spotted_entity_id, " fog of war timer started on ", entity_id, " @local_id ", local_id)

func _on_return_fog_of_war(seen_entity_id):
	#cprint(seen_entity_id, "'s FOW timer activation on ", entity_id, " at ", local_id)
	if admirals[seen_entity_id].in_line_of_sight:
		spotted.emit(seen_entity_id)
		return
	admirals[seen_entity_id].hide()
	if Overseer.debug["wallhack"]:
		admirals[seen_entity_id].show()
	var ghost_instantiated = ghost_scene.instantiate()
	ghost_instantiated.init(seen_entity_id, admirals[seen_entity_id].position, admirals[seen_entity_id].blue, true)
	get_parent().get_parent().get_node("Ghosts").add_child(ghost_instantiated)

func _on_view_distance_body_entered(body):
	var spotted_entity_id = body.entity_id
	if entity_id == spotted_entity_id:
		return
	spotted.emit(spotted_entity_id)
	#cprint(spotted_entity_id, " entered ", entity_id, "'s Line of Sight")
	if fog_of_war_timers.has(spotted_entity_id):
		fog_of_war_timers[spotted_entity_id].stop()
	admirals[spotted_entity_id].show()
	admirals[spotted_entity_id].in_line_of_sight = true
	#TODO: save direction & speed for ghost estimate?

func _on_view_distance_body_exited(body):
	var spotted_entity_id = body.entity_id
	#cprint(spotted_entity_id, " left line of sight of ", entity_id)
	admirals[spotted_entity_id].in_line_of_sight = false
	ghost_last_known_admiral_location(spotted_entity_id)

func _on_recon_body_entered(body):
	var spotted_entity_id = body.entity_id
	cprint(entity_id, "'s recon spotted ", spotted_entity_id)
	ghost_last_known_admiral_location(spotted_entity_id)
	spotted.emit(spotted_entity_id)

func _on_attack_body_entered(body):
	var spotted_entity_id = body.entity_id
	cprint(entity_id, "'s attacker spotted ", spotted_entity_id)
	ghost_last_known_admiral_location(spotted_entity_id)
	spotted.emit(spotted_entity_id)
	if !admirals[spotted_entity_id].blue:
		attack_mission.area.set_deferred("disabled", true) #call_deferred jtnjtn warn/err
		deal_damage.rpc(spotted_entity_id)
	#if !admirals[spotted_entity_id].blue:
		use_munitions()

func use_munitions():
	munitions -= 1
	munitions_used.emit()

@rpc("any_peer", "call_local")
func deal_damage(in_id):
	if in_id == local_id: 
		health -= 1 #tämä vie etäpäältä hiparia
		damage_taken.emit()
		if health <= 0:
			destroy(in_id) #tämä tappaa etämiehen
	else:
		admirals[in_id].health -= 1
		if admirals[in_id].health <= 0:
			admirals[in_id].destroy(in_id) #tämä tappaa lokaalin proxyn
	admirals[in_id].cprint("taking damage with in_id ", in_id, " @ local_id ", local_id, " from ", entity_id, ". Health is now ", health)

@rpc("any_peer", "call_local")
func destroy(destroyed_id):
	if destroyed_id == local_id: 
		admirals[destroyed_id].is_destroyed = true
		admirals[destroyed_id].set_visual()
		admirals[destroyed_id].max_speed = admirals[destroyed_id].min_speed
	else:
		is_destroyed = true
		set_visual()
		max_speed = min_speed
	cprint("!!!!! ", destroyed_id, " has been incapacitated!")
