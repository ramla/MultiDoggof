extends Node
class_name EventTracker

var scored_events = {}
var n = 0

func _ready():
	pass

func store_event(new_event: ScoredEvent):
	scored_events[n] = new_event
	n += 1

func get_scores(playerbase):
	var score_sheet = ScoreSheet.new()
	score_sheet.init(playerbase)
	for event in scored_events:
		score_sheet.process_event(scored_events[event])
	score_sheet.process_scores()
	return score_sheet
