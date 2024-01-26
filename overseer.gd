
extends Node

var debug = {
	"quick_launch" = false, #to quickly launch a game from two instances. second round is also immediately launched as players are readied automatically
	"wallhack" = false, #not tested since fixing most of fog of war and is acshually maphack
	"pace_up" = false, #doubles some speeds, not very useful maybe DELETE
	}

var game_settings = {
	"launch_timer" = 3, 
	"pre_round_length" = 5, #5? 10?
	"round_length" = 180,
	"post_round_length" = 5,
	"game_mode" = 0,
	"port" = 4868, #Total amount of warships and auxiliary military ships lost during WW2 
				#by Australia, Canada, France, Free France, Germany, Greece, Italy, Empire of Japan, 
				#Netherlands, Norway, Soviet Union, United Kingdom, United States, Poland. 
				#Source: I made it the fuck up (aka Wikipedia) 
	"max_clients" = 12,
	"red" = Color(1,0,0,1),
	"blue" = Color(0,0,1,1),
	"objective" = {
		"spawns" = {
			"west_base_loc" = Vector2(40,168),
			"west_island_loc" = Vector2(352,400),
			"west_outpost_loc" = Vector2(440,8),
			"east_base_loc" = Vector2(1080,472),
			"east_island_loc" = Vector2(760,192),
			"east_outpost_loc" = Vector2(728,632), 
		},
		"value" = 15,
		"hitpoints" = 5,
		"priority_multiplier" = 4
	},
	"admiral" = {
		"spawn_east" = Vector2(640,320),
		"spawn_west" = Vector2(450,320), #test spawn positions atm, move to bases maybe
		"min_speed" = 10,
		"max_speed" = 25,
		"game_speed_multiplier" = 1,
		"plane_speed_multiplier" = 1,
		"line_of_sight_radius" = 46,
		"fog_of_war_speed" = 1,
		"recon_cooldown" = 2,
		"recon_wings" = 2,
		"recon_fuel" = 25,
		"attack_cooldown" = 4,
		"attack_wings" = 2,
		"attack_fuel" = 100,
		"health" = 4,
		"fuel_oil" = 20000,
		"munitions" = 10,
		"aviation_fuel" = 1500,
		"fuel_oil_consumption_multiplier" = 1,
		"fuel_oil_consumption_idle" = 10,
		"fuel_oil_consumption_base" = 100,
		"fuel_oil_consumption_ineff" = 55,
		"fuel_oil_consumption_divider" = 10,
		"value_damage" = 5,
		"value_destroyed" = 25,
	},
	"scoring" = {
		"priority_multiplier" = 3,
	},
	}

#multiplayer debug features. rpc receives printed

#func _enter_tree():
	#get_tree().set_multiplayer(LogMultiplayer.new())
