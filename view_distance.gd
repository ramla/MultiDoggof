extends Area2D
class_name Visualbox

signal spotted

func _ready():
	print("visualbox is ", self)
	connect("spotted",_on_spotted)

func _process(_delta: float):
	var overlaps = self.get_overlapping_areas()
	for other in overlaps:
		print(other.get_owner(), " SPOTTED ", self.get_owner())
		spotted.emit(other.get_owner(), self.get_owner())
	
func _on_spotted(_spotter, _target):
	pass
