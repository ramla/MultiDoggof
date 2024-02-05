extends Control
#class_name ScoreTable

var score_sheet
var playerbase
@onready var event_tracker = get_parent().get_node("Game/EventTracker")

func _ready():
	%CloseButton.connect("pressed", _on_close_button_pressed)

#playerbase[in_multi_id] = {
		#"os_id" = in_os_id,
		#"playername" = in_playername,
		#"is_ready" = in_is_ready,
		#"team" = in_team
		#}

func update_players(in_playerbase):
	playerbase = in_playerbase

func draw_scores():
	score_sheet = event_tracker.get_scores(playerbase)
	put_label("Progress", %NameContainer1)
	put_label("All Admirals", %NameContainer1)
	put_label("Total", %TotalContainer1)
	put_label("Objectives", %ObjectivesContainer1)
	put_label("", %ObjectivesContainer1)
	put_label("PvP", %PvPContainer1)
	put_label("", %PvPContainer1)
	put_label("Further", %NameContainer2)
	put_label("All Admirals", %NameContainer2)
	put_label("Total", %TotalContainer2)
	put_label("Objectives", %ObjectivesContainer2)
	put_label("", %ObjectivesContainer2)
	put_label("PvP", %PvPContainer2)
	put_label("", %PvPContainer2)
	put_label(str(score_sheet.team_scores["t1"]), %TotalContainer1)
	put_label(str(score_sheet.team_scores["t2"]), %TotalContainer2)
	for admiral_score in score_sheet.individual_scores_array:
		if playerbase[admiral_score[0]].team == -1:
			put_label(playerbase[admiral_score[0]].playername, %NameContainer1)
			put_label(str(admiral_score[1]), %TotalContainer1)
			put_label(str(admiral_score[2]), %ObjectivesContainer1)
			put_label(str(admiral_score[3]), %PvPContainer1)
		else:
			put_label(playerbase[admiral_score[0]].playername, %NameContainer2)
			put_label(str(admiral_score[1]), %TotalContainer2)
			put_label(str(admiral_score[2]), %ObjectivesContainer2)
			put_label(str(admiral_score[3]), %PvPContainer2)

func _on_close_button_pressed():
	hide()

func put_label(text,target):
	var label = Label.new()
	label.text = text
	target.add_child(label)
