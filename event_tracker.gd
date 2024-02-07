extends Node
class_name EventTracker

var scored_events = {}
var n = 0


func _ready():
	pass

func store_event(new_event: ScoredEvent):
	scored_events[n] = new_event
	n += 1

func transmit_events():
	var local_id = get_parent().local_id
	var dict_scored_events = {}
	for i in scored_events:
		var event = scored_events[i]
		if event.player_id == local_id:
			dict_scored_events[i] = { 	"tick" = event.tick, 
										"score" = event.score, 
										"player_id" = event.player_id, 
										"team" = event.team, 
										"source" = event.source }
	receive_events.rpc(dict_scored_events)
	print("sent ", dict_scored_events)

@rpc("any_peer", "reliable")
func receive_events(dict_scored_events):
	for i in dict_scored_events:
		var dict_event = dict_scored_events[i]
		var event = ScoredEvent.new()
		event.init(dict_event["tick"], dict_event["score"], dict_event["player_id"], dict_event["team"], dict_event["source"])
		store_event(event)
		print("stored event ", event)

func get_scores(playerbase):
	var score_sheet = ScoreSheet.new()
	score_sheet.init(playerbase)
	for event in scored_events:
		score_sheet.process_event(scored_events[event])
	score_sheet.process_scores()
	return score_sheet
