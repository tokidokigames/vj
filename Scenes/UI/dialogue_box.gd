extends CanvasLayer

@onready var portrait = $Control/Portrait
@onready var text_label = $Control/Text
@onready var title_label = $Control/Title
@onready var close_button = $Control/CloseButton
@onready var instruction = $Control/Instruction

signal dialogue_finished

var dialogue_data = []  # Array of dictionaries [{speaker, text, portrait_path}, ...]
var current_index = 0

func start(dialogue: Array):
	GameState.is_dialogue_active = true
	dialogue_data = dialogue
	current_index = 0
	show_line()
	return true

func show_line():
	if current_index >= dialogue_data.size():
		hide()
		emit_signal("dialogue_finished")
		GameState.is_dialogue_active = false
		close_button.visible = true
		instruction.visible = false
		return

	var line = dialogue_data[current_index]
	text_label.text = line["text"]
	title_label.text = line["speaker"]
	
	match line["speaker"]:
		"Player":
			portrait.play("player_talking")
		"Vampire":
			portrait.play("vampire1_talking")
		"Unknown":
			portrait.play("unknown")
		_:
			portrait.play("tip_checkmark")
			
	close_button.visible = false
	instruction.visible = true
	show()

func _input(event):
	if visible and event.is_action_pressed("ui_accept"):
		current_index += 1
		show_line()


func _on_close_button_pressed() -> void:
	queue_free()
