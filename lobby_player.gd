extends HBoxContainer
class_name LobbyPlayer

var blue = Color(1,1,1,1)
var red = Color(1,1,1,1)
var game_settings = Overseer.game_settings
var team = 0

func _ready():
	game_settings = Overseer.game_settings
	blue = game_settings["blue"]
	red = game_settings["red"]

func update(in_playername, in_ready, in_team, in_local_team):
	$Playername.text = str(in_playername)
	team = in_team
	if in_ready:
		$Hesitating.text = ""
	else:
		$Hesitating.text = "Yes"
	if team == 0:
		$Team.text = "Centrist"
		$Team["theme_override_colors/font_color"] = Color(1,1,1,1)
	elif team == -1:
		$Team.text = "Progress"
		if in_local_team == -1:
			$Team["theme_override_colors/font_color"] = blue
		if in_local_team == 1:
			$Team["theme_override_colors/font_color"] = red
	elif team == 1:
		$Team.text = "Further"
		if in_local_team == -1:
			$Team["theme_override_colors/font_color"] = blue
		if in_local_team == 1:
			$Team["theme_override_colors/font_color"] = red
	else: 
		$Team.text = "WTF"
	refresh_team_color(in_local_team)

func refresh_team_color(in_local_team):
	if in_local_team == 0:
		$Team.text = "Centrist"
		$Team["theme_override_colors/font_color"] = Color(1,1,1,1)
	elif team == -1:
		$Team.text = "Progress"
		if in_local_team == -1:
			$Team["theme_override_colors/font_color"] = blue
		if in_local_team == 1:
			$Team["theme_override_colors/font_color"] = red
	elif team == 1:
		$Team.text = "Further"
		if in_local_team == -1:
			$Team["theme_override_colors/font_color"] = blue
		if in_local_team == 1:
			$Team["theme_override_colors/font_color"] = red
	else: 
		$Team.text = "WTF"

func _process(_delta):
	pass
