
extends Node

#TODO: lataa tiedostosta
#TODO: tallenna tiedostoon jos serveri

var debug = {
	"quick_launch" = true, #to quickly launch a game from two instances
	"wallhack" = false,
	"pace_up" = true,
	}
var game_settings = {
	"pre_round_length" = 5,
	"round_length" = 15,
	"post_round_length" = 5,
	"game_mode" = 0,
	"port" = 4868, #Total amount of warships and auxiliary military ships lost during WW2 by Australia, Canada, France, Free France, Germany, Greece, Italy, Empire of Japan, Netherlands, Norway, Soviet Union, United Kingdom, United States, Poland. Source: I made it the fuck up (aka Wikipedia) 
	"max_clients" = 12,
	"red" = Color(1,0,0,1),
	"blue" = Color(0,0,1,1),
		"admiral" = {
			"spawn_east" = Vector2(640,320),
			"spawn_west" = Vector2(450,320),
			"max_speed" = 50,
			"game_speed_multiplier" = 1,
			"plane_speed_multiplier" = 1,
			"fog_of_war_speed" = 2,
			"recon_cooldown" = 1,
			"recon_wings" = 2,
			"recon_fuel" = 12,
			"attack_cooldown" = 3,
			"attack_wings" = 2,
			"attack_fuel" = 10,
		},
	}
