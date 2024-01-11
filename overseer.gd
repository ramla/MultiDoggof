
extends Node

var debug = {
	"quick_launch" = false, #to quickly launch a game from two instances. second round is also immediately launched as players are readied automatically
	"wallhack" = false, #not tested since fixing most of fog of war and is acshually maphack
	"pace_up" = false, #doubles some speeds, not very useful maybe DELETE
	}

var game_settings = {
	"launch_timer" = 3,
	"pre_round_length" = 2,
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
		"admiral" = {
			"spawn_east" = Vector2(640,320),
			"spawn_west" = Vector2(450,320), #test spawn positions atm, move to bases maybe
			"min_speed" = 10,
			"max_speed" = 25,
			"game_speed_multiplier" = 1,
			"plane_speed_multiplier" = 1,
			"line_of_sight_radius" = 46,
			"fog_of_war_speed" = 1,
			"recon_cooldown" = 1,
			"recon_wings" = 2,
			"recon_fuel" = 25,
			"attack_cooldown" = 1, #4
			"attack_wings" = 2,
			"attack_fuel" = 100,
			"health" = 3,
			"fuel_oil" = 20000,
			"munitions" = 10,
			"aviation_fuel" = 1500,
			"fuel_oil_consumption_multiplier" = 1,
			"fuel_oil_consumption_idle" = 10,
			"fuel_oil_consumption_base" = 100,
			"fuel_oil_consumption_ineff" = 55,
			"fuel_oil_consumption_divider" = 10,
		},
	}
