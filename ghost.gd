extends GPUParticles2D

var blue_texture = preload("res://Assets/question_mark_blue.png")
var nonblue_texture = preload("res://Assets/question_mark_red.png")
var unconfirmed_texture = preload("res://Assets/question_mark_black.png")
var self_id
var game_speed_multiplier: float = Overseer.game_settings["admiral"]["game_speed_multiplier"]
const SAFETY_MARGIN_MULTIPLIER: float = 0.2
var safety_margin: float = SAFETY_MARGIN_MULTIPLIER


func _ready():
	self.connect("finished", _on_finished)
	var speed_modifier = 1 / (game_speed_multiplier * safety_margin)
	print("self[\"speed_scale]\" = ", self["speed_scale"])
	print("speed_modifier = ", speed_modifier)
	self["speed_scale"] = speed_modifier
	print("self[\"speed_scale\"] set to ", self["speed_scale"])
	self["process_material"]["alpha_curve"]["curve"]["point_1/position"] = Vector2(speed_modifier,0)
	print("self[\"process_material\"][\"alpha_curve\"][\"curve\"][\"point_1/position\"] set to ", self["process_material"]["alpha_curve"]["curve"]["point_1/position"])

func init(in_id, in_position, blue, confirmed):
	self_id = in_id
	position = in_position
	one_shot = true
	if !confirmed:
		self["texture"] = unconfirmed_texture
	elif !blue:
		self["texture"] = nonblue_texture
	else:
		self["texture"] = blue_texture
	emitting = true

func _on_finished():
	print("emissions over, removing ghost node")
	self.queue_free()

func spotted(in_id):
	if self_id == in_id:
		print(self_id, "'s ghost hidden due to entity having been spotted again")
		hide()
