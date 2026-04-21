extends Control

@onready var start_button = $StartButton

func _ready():
	pass

func show_welcome():
	show()
	get_tree().paused = true

func _on_start_button_pressed() -> void:
	hide()
	get_tree().paused = false
