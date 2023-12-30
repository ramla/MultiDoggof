extends CharacterBody2D

signal destroyed

var is_destroyed: bool = true

#later get from instantiation call
const MAX_SPEED = 50
const MAX_ACCEL = 100
const MAX_DECEL = 50
const MAX_RATE = PI/10

var speed = 0
var speed_input = 0
var accel = 0
var click_position = Vector2.ZERO
#TODO make visible duration timer


func _ready():
	is_destroyed = false
	click_position = Vector2(position.x, position.y)
	
func _physics_process(delta):
	if Input.is_action_pressed("move_click"):
		click_position = get_global_mouse_position()
	
	var target_position = (click_position - position).normalized()
	speed = get_speed(delta)
	
	if position.distance_to(click_position) > 3:
		velocity = target_position * speed
		move_and_slide()
		look_at(click_position)
	
	if Input.is_action_pressed("recon"):
		#$Recon.monitorable = true
		#$Recon.monitoring = true
		$Recon.visible = true
		$Recon/Area.disabled = true
		#$Recon.position = Vector2.ZERO
		$Recon.look_at(get_global_mouse_position())
	else:
		if Input.is_action_just_released("recon"):
			$Recon/Area.disabled = false
		else:
			#$Recon.monitorable = false
			#$Recon.monitoring = false
			$Recon.visible = false
			$Recon/Area.disabled = true

func get_input():
	speed_input = Input.get_axis("down", "up")
	return speed_input

func get_speed(delta):
	speed_input = get_input()
	if speed_input == 0:
		return(speed)
	else: 
		if speed_input > 0:
			speed += (delta * speed_input * MAX_ACCEL)
		else:
			speed += (delta * speed_input * MAX_DECEL)

	speed = clamp(speed, 0, MAX_SPEED)
	return(speed)

func _on_damage(attack):
	pass	

func hide_self():
	$Admiral.hide()

func destroy_self():
	$Admiral.hide()
	$CollisionPhysical.disabled = true

func show_self(duration) -> void:
	$Admiral.show()
	#TODO visible duration
	$CollisionPhysical.disabled = false
