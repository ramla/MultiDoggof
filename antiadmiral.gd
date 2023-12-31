extends CharacterBody2D

@onready var view_distance = get_node("ViewDistance")

func _ready():
	view_distance.spotted.connect(_on_view_distance_spotted)
	connect("timeout",_on_timer_timeout)
	hide()
	pass

func _process(delta):
	pass

func _on_view_distance_spotted(spotter, target):
	print(target, " been spotted by ", spotter)
	if target == self:
		show()
		$Timer.start()
	else:
		pass

func _on_timer_timeout():
	hide()
	$Timer.stop()
	
