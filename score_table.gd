extends Control
class_name ScoreTable

var score_sheet
var playerbase
@onready var event_tracker = get_parent().get_node("Game/EventTracker")
@onready var close_button = $CenterContainer/CloseButton

func _ready():
	print(close_button)
	%CloseButton.connect("pressed", _on_close_button_pressed)

func draw_scores(in_playerbase):
	playerbase = in_playerbase
	score_sheet = event_tracker.get_scores(playerbase)
	var title_label = Label.new()
	title_label.set_text("Team1")
	%NameContainer1.add_child(title_label)
	%TotalContainer1.add_child(title_label)
	%ObjectivesContainer1.add_child(title_label)
	%PvPContainer1.add_child(title_label)
	for admiral_score in score_sheet.individual_scores_array:
		#var admiral_score = score_sheet.individual_scores_array[i]
		var label = Label.new()
		label.text = playerbase[admiral_score[0]].playername
		%NameContainer1.add_child(label)
		label.text = str(admiral_score[1])
		%TotalContainer1.add_child(label)
		label.text = str(admiral_score[2])
		%ObjectivesContainer1.add_child(label)
		label.text = str(admiral_score[3])
		%PvPContainer1.add_child(label)

func _on_close_button_pressed():
	hide()
