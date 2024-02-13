class_name ScoredEvent

var tick: int
var score: int
var player_id
var team: int
var source

enum ScoreSource { AdmiralDamaged, AdmiralDestroyed, ObjectiveDamaged, ObjectiveDestroyed }


func init(in_tick, in_score, in_player_id, in_team, in_source, in_priority = false):
	tick = in_tick
	score = in_score
	player_id = in_player_id
	team = in_team
	source = in_source
	if in_priority:
		score = score * Overseer.game_settings["scoring"]["priority_multiplier"]
		print("score multiplied")
