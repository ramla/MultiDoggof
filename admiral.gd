extends CharacterBody2D
class_name Admiral

signal destroyed(destroyed_id)
signal damage_taken(int)
signal spotted(spotted_id)
signal munitions_used(amount)
signal cprint_signal(String)

var is_destroyed: bool = true
var is_disconnected: bool = true
var on_round_timer = false

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
var team
var in_line_of_sight = false
#@onready var tick = get_parent().get_parent().tick #lol

var timer_scene = preload("res://fog_of_war_timer.tscn")
var fog_of_war_timers: Dictionary = {}
var ghost_scene = preload("res://ghost.tscn")
var sfx_scene = preload("res://sound.tscn")
var sfx
var fuel_oil_sfx_played = false

@onready var admirals = get_parent().get_parent().admirals
var view_distance: Area2D
var recon_mission: Area2D
var attack_mission: Area2D
@onready var attack_area = $AttackMission/Area
@onready var event_tracker = get_parent().get_parent().get_node("EventTracker")


func _ready():
	is_destroyed = false
	click_position = Vector2(position.x, position.y)
	

func _process(_delta):
	if is_player && on_round_timer: 
		#if Input.is_action_just_pressed("recon_action") && recon_mission.is_ready() && !is_destroyed:
			#recon_mission.plan_recon_mission()
			#get_window().set_input_as_handled()
		#if Input.is_action_just_pressed("action_click") or Input.is_action_pressed("action_click"):
			#if recon_mission.planning == true:
				#recon_mission.order_recon_mission()
				#get_window().set_input_as_handled()
		#if !Input.is_action_pressed("recon_action") && !recon_mission.effect_running:
			#print("cancel_plan_recon_mission(), effect runninig = ", recon_mission.effect_running)
			#recon_mission.cancel_plan_recon_mission()
		if Input.is_action_pressed("attack_action") && attack_mission.is_ready() && !is_destroyed:
			attack_mission.plan_attack_mission()
			if Input.is_action_just_pressed("action_click") or Input.is_action_just_released("action_click"):
				attack_mission.order_attack_mission(get_global_mouse_position())
				get_window().set_input_as_handled()
			get_window().set_input_as_handled()
		
		if !Input.is_action_pressed("attack_action") && !attack_mission.effect_running:
			attack_mission.visible = false
			
		if Input.is_action_pressed("recon_action") && recon_mission.is_ready() && !is_destroyed:
			recon_mission.plan_recon_mission()
			if Input.is_action_just_pressed("action_click") or Input.is_action_just_released("action_click"):
				recon_mission.order_recon_mission(get_global_mouse_position())
				get_window().set_input_as_handled()
			get_window().set_input_as_handled()
		
		if Input.is_action_just_released("recon_action"):
			recon_mission.cancel_plan_recon_mission()
	#if Input.is_action_just_released("action_click") && Input.is_action_pressed("recon_action"):
		#pass		
	#elif Input.is_action_just_released("action_click") && Input.is_action_pressed("attack_action"):
		#pass

func _physics_process(delta):
	#if !is_destroyed:
	if is_player && on_round_timer:
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
	speed_input = Input.get_axis("decelerate", "accelerate")
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
		if !fuel_oil_sfx_played:
			sfx.play_no_fuel()
			fuel_oil_sfx_played = true

func init(id, in_playername, in_team, local_team, in_local_id):
	game_settings = Overseer.game_settings
	entity_id = id
	local_id = in_local_id
	team = in_team
	entity_playername = in_playername
	set_multiplayer_authority(entity_id)
	is_destroyed = false
	is_disconnected = false
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
		attack_mission.connect("munitions_used", _on_munitions_used)
		%HUD.init(health, munitions, fuel_oil, aviation_fuel, local_id)
		$ViewDistance/CollisionVisual["shape"]["radius"] = game_settings["admiral"]["line_of_sight_radius"]
		$ViewDistance/LineOfSightVisualized["visible"] = true
		sfx = sfx_scene.instantiate()
		add_child(sfx)
		fuel_oil_sfx_played = false
		sfx.make_connections()
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
		spawn = game_settings["admiral"]["spawn_east"] + Vector2(0,0)#randf_range(-100,100))
	else:
		spawn = game_settings["admiral"]["spawn_west"] + Vector2(0,0)#randf_range(-100,100))
	global_position = spawn
	if !is_player:
		%HUD.queue_free()
		apply_fog_of_war()
		#$ViewDistance/LineOfSightVisualized["scale"] = 
	#cprint("Init done @ " + str(local_id) + ". Self: " + str(self) + ", team: " + str(team) + ", local_team: " + str(local_team))

func get_tick():
	return get_parent().get_parent().tick

func start_round():
	#HACK: re-applying fog of war b/c sometimes others are visible outside view distance after spawning
	for i in admirals:
		if i != local_id && position.distance_to(admirals[i].position) > $ViewDistance/CollisionVisual["shape"]["radius"] / 2:
			var admiral = admirals[i]
			admiral.apply_fog_of_war()
	
	on_round_timer = true
	%HUD.start_round()
	cprint("Round started!")
	
func start_post_round():
	cprint("Round over!")
	%HUD.start_post_round()
	on_round_timer = false

func set_visual():
	#cprint("setting visual on local_id ", local_id, " for entity_id ", entity_id)
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

func disconnect_admiral():
	is_disconnected = true

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

func ghost_last_known_admiral_location(spotted_entity_id):
	if entity_id != spotted_entity_id:
		admirals[spotted_entity_id].show()
		if !fog_of_war_timers.has(spotted_entity_id):
			var fow_timer_instantiated = timer_scene.instantiate()
			add_child(fow_timer_instantiated)
			fog_of_war_timers[spotted_entity_id] = fow_timer_instantiated
			fog_of_war_timers[spotted_entity_id].init(spotted_entity_id)
			fog_of_war_timers[spotted_entity_id].connect("return_fog_of_war", _on_return_fog_of_war)
			#cprint(get_playername(local_id), " connected ", get_playername(spotted_entity_id), " fog of war timer")
		fog_of_war_timers[spotted_entity_id].start()
		#cprint(spotted_entity_id, " fog of war timer started on ", entity_id, " @local_id ", local_id)

func _on_return_fog_of_war(seen_entity_id):
	#cprint(seen_entity_id, "'s FOW timer activation on ", entity_id, " at ", local_id)
	if admirals[seen_entity_id].in_line_of_sight:
		spotted.emit(seen_entity_id)
		return
	admirals[seen_entity_id].hide()
	var ghost_instantiated = ghost_scene.instantiate()
	ghost_instantiated.init(seen_entity_id, admirals[seen_entity_id].position, admirals[seen_entity_id].blue, true)
	get_parent().get_parent().get_node("Ghosts").add_child(ghost_instantiated)

func _on_view_distance_body_entered(body):
	if body is Admiral:
		var spotted_entity_id = body.entity_id
		if entity_id == spotted_entity_id:
			return
		spotted.emit(spotted_entity_id)
		cprint(get_playername(spotted_entity_id), " entered line of sight!")
		if fog_of_war_timers.has(spotted_entity_id):
			fog_of_war_timers[spotted_entity_id].stop()
		admirals[spotted_entity_id].show()
		admirals[spotted_entity_id].in_line_of_sight = true

func _on_view_distance_body_exited(body):
	if body is Admiral:
		var spotted_entity_id = body.entity_id
		#cprint(spotted_entity_id, " left line of sight of ", entity_id)
		admirals[spotted_entity_id].in_line_of_sight = false
		ghost_last_known_admiral_location(spotted_entity_id)

func _on_recon_body_entered(body):
	if body is Admiral:
		var spotted_entity_id = body.entity_id
		cprint("Your recon spotted ", get_playername(spotted_entity_id))
		ghost_last_known_admiral_location(spotted_entity_id)
		spotted.emit(spotted_entity_id)
		recon_mission.spotted_someone = true
		if admirals[spotted_entity_id].blue:
			sfx.play_friendly_spotted()
		else:
			sfx.play_enemy_spotted()

func _on_attack_body_entered(body):
	if body is Admiral:
		var spotted_entity_id = body.entity_id
		if !admirals[spotted_entity_id].blue && attack_mission.munitions_onboard > 0:
			attack_mission.area.set_deferred("disabled", true)
			deal_damage.rpc(spotted_entity_id)
			attack_mission.spend_munitions()
			cprint("Your attackers struck ", get_playername(spotted_entity_id), "!")
			sfx.play_got_em()
		elif attack_mission.munitions_onboard <= 0:
			sfx.play_enemy_spotted()
		else:
			cprint("Your attackers spotted ", get_playername(spotted_entity_id))
			sfx.play_friendly_spotted()
		ghost_last_known_admiral_location(spotted_entity_id)
		spotted.emit(spotted_entity_id)

	if body is Objective && !body.blue && attack_mission.munitions_onboard > 0:
		var damage = 1
		attack_mission.area.set_deferred("disabled", true)
		var objective_id = body.objective_id
		cprint("Attackers struck ", get_parent().get_parent().objectives[objective_id].codename, "!")
		body.lose_health.rpc(damage)
		attack_mission.spend_munitions()
		sfx.play_got_em()
		for id in admirals:
			if !admirals[id].blue:
				transmit_objective_struck.rpc_id(id, objective_id)

func _on_munitions_used():
	munitions -= 1
	%HUD.munitions_used()

@rpc("any_peer", "call_local", "reliable")
func deal_damage(in_id):
	var attacker_id = multiplayer.get_remote_sender_id()
	print(self.entity_id, " running deal_damage()") 
	admirals[in_id].health -= 1 #tämä vie etäpäältä hiparia
	admirals[in_id].damage_taken.emit()
	admirals[in_id].cprint("Taking damage! Health is now ", admirals[in_id].health)
	if is_instance_valid(sfx):
		sfx.play_bombhit()
	if admirals[in_id].health <= 0:
		destroy(in_id)
		if local_id == attacker_id:
			score(ScoredEvent.ScoreSource.AdmiralDestroyed)
	else:
		if local_id == attacker_id:
			score(ScoredEvent.ScoreSource.AdmiralDamaged)

func destroy(destroyed_id):
	#if destroyed_id == local_id: 
	admirals[destroyed_id].is_destroyed = true
	admirals[destroyed_id].set_visual()
	admirals[destroyed_id].max_speed = admirals[destroyed_id].min_speed
	#dirty to print on both attacker and attackee
	cprint(get_playername(destroyed_id), " has been incapacitated!")
	admirals[destroyed_id].cprint("You have been incapacitated! Limp back to safety if you can")

func get_playername(in_entity_id):
	return admirals[in_entity_id].entity_playername

func score(source, in_id = local_id, in_team = team):
	var scored_event = ScoredEvent.new()
	var points
	match source:
		ScoredEvent.ScoreSource.AdmiralDamaged:
			points = game_settings["scoring"]["admiral_damaged"]
		ScoredEvent.ScoreSource.AdmiralDestroyed:
			points = game_settings["scoring"]["admiral_destroyed"]
		ScoredEvent.ScoreSource.ObjectiveDamaged:
			points = game_settings["scoring"]["objective_damaged"]
		ScoredEvent.ScoreSource.ObjectiveDestroyed:
			points = game_settings["scoring"]["objective_destroyed"]
	scored_event.init(get_tick(), points, in_id, in_team, source)
	event_tracker.store_event(scored_event)

@rpc("any_peer")
func transmit_objective_struck(objective_id):
	var message = "Objective " + get_parent().get_parent().objectives[objective_id].codename + " has been struck by enemy task force!"
	admirals[local_id].cprint(message)
	if is_instance_valid(admirals[local_id].sfx):
		admirals[local_id].sfx.play_friendly_objective_struck()
