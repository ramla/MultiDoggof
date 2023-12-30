#TODO: basic pistelasku

extends Node

#TODO: lataa tiedostosta
var game_settings = {
	"pre_round_length" = 5,
	"round_length" = 15,
	"post_round_length" = 5,
	"game_mode" = 0,
	"spawn_east" = Vector2(640,320),
	"spawn_west" = Vector2(450,320),
	"port" = 4868, #Total amount of warships and auxiliary military ships lost during WW2 by Australia, Canada, France, Free France, Germany, Greece, Italy, Empire of Japan, Netherlands, Norway, Soviet Union, United Kingdom, United States, Poland. Source: I made it the fuck up (aka Wikipedia) 
	"max_clients" = 12
	}
