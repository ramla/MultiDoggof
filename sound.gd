extends Node2D

func _ready():
	pass

func make_connections():
	get_parent().recon_mission.connect("no_aviation_fuel", play_no_gasoline)
	get_parent().attack_mission.connect("no_aviation_fuel", play_no_gasoline)

func play_bombhit():
	$BombHit.play()

func play_takeoff():
	$Takeoff.play()

func play_attack_not_found():
	$AttackNotFound.play()

func play_recon_not_found():
	$ReconNotFound.play()

func play_no_munitions():
	$NoMunitions.play()

func play_no_fuel():
	$NoFuel.play()

func play_no_gasoline():
	$NoGasoline.play()

func play_got_em():
	$GotEm.play()

func play_enemy_spotted():
	$EnemySpotted.play()

func play_friendly_spotted():
	$FriendlySpotted.play()

func play_friendly_objective_struck():
	$FriendlyObjectiveStruck.play()
