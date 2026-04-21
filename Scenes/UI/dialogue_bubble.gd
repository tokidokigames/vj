extends Control

@onready var label = $BubbleText
@onready var timer = $Timer

#var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
var player_position = self.global_position

func _ready():
	call_deferred("_setup")

func _setup():
	var player = get_node("/root/Game/LevelContainer/Level0/Player")
	if player:
		var player_position = player.global_position
		position = player_position + Vector2(25, -80)  # offset above the player

func _process(delta) -> void:
	self.global_position = player_position + Vector2(25, -80)

func show_message(text: String, message_position, duration: float = 2.0):
	player_position = message_position
	label.text = text
	show()
	timer.start(duration)

func _on_timer_timeout() -> void:
	hide()
