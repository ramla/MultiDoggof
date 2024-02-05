class_name ScoreSheet

var team_scores = { "t1" = 0, "t2" = 0 }
var individual_scores = {}
var individual_scores_objective = {}
var individual_scores_pvp = {}
var individual_scores_array: Array
var playerbase
#EVENT SPECS
#var tick: int
#var score: int
#var player_id
#var team: int
#var source
#enum ScoreSource { AdmiralDamaged, AdmiralDestroyed, ObjectiveDamaged, ObjectiveDestroyed }
func init(in_playerbase):
	playerbase = in_playerbase
	for id in playerbase:
		individual_scores[id] = 0
		individual_scores_objective[id] = 0
		individual_scores_pvp[id] = 0

func process_event(event):
	if event.team == -1:
		team_scores["t1"] += event.score
	else:
		team_scores["t2"] += event.score
	if playerbase.has(event.player_id):
		individual_scores[event.player_id] += event.score
		if event.source == ScoredEvent.ScoreSource.ObjectiveDamaged or event.source == ScoredEvent.ScoreSource.ObjectiveDestroyed:
			individual_scores_objective[event.player_id] += event.score
		if event.source == ScoredEvent.ScoreSource.AdmiralDamaged or event.source == ScoredEvent.ScoreSource.AdmiralDestroyed:
			individual_scores_pvp[event.player_id] += event.score

func process_scores():
	create_array()
	individual_scores_array.sort_custom(sort_desc_by_total)

func create_array():
	var i = 0
	for id in individual_scores:
		individual_scores_array.insert(i,[id, individual_scores[id], individual_scores_objective[id], individual_scores_pvp[id]])

func sort_desc_by_total(a,b):
	#if a[0][1] > b[0][1]:
	if a[1] > b[1]:
		return true
	else: return false
#
#func get_individual_scores_array():
	#return individual_scores_array
#
#func get_team_scores():
	#return team_scores
