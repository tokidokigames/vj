extends Control

@onready var TipArrow = $TipArrowAnimation

var target: Node2D = null
var offset := Vector2(0, -40)

func _ready():
	TipArrow.play("tip_arrow")

func _process(delta):
	if not is_instance_valid(target):
		hide()
		return
		
	if not target.is_inside_tree():
		hide()
		return
		
	if target and target.is_inside_tree():
		global_position = target.global_position + offset
	else:
		hide()  # target lost → hide the arrow

func point_to(new_target: Node2D, new_offset := Vector2(0, -40)):
	target = new_target
	offset = new_offset
	show()

func hide_point():
	hide()
