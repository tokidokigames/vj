extends Node2D

var score: int = 0
var total_time := 5000.0
var time_left := 0.0

	
@onready var player = $LevelContainer/Level0/Player
@onready var score_label = $UI/ScoreLabel
@onready var game_over_label = $UI/GameOverLabel
@onready var timer = $Timer
@onready var timer_label = $UI/TimerLabel
#@onready var level0_node = $LevelContainer/Level0
@onready var ui_layer = $UI
#@onready var fade_layer_animation = $FadeLayer/AnimationPlayer
#@onready var level_zero_door = $LevelContainer/Level0/Door  

signal score_changed(new_score: int)

func _ready():
	var screen_size = get_viewport().get_visible_rect().size
	var popup = preload("res://Scenes/UI/welcome_popup.tscn").instantiate()
	ui_layer.add_child(popup)
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.show_welcome()

	game_over_label.visible = false
	time_left = total_time
	update_timer_label()
	timer.start()

func _process(delta):
	if timer.is_stopped():
		return

	if time_left > 0:
		time_left -= delta
		update_timer_label()

		if time_left <= 0:
			time_left = 0
			end_level_lose()
	
	if Input.is_action_just_pressed("show_tip"):
		show_tip()

func add_score(points: int):
	score += points
	score_label.text = "Score: %d" % score
	emit_signal("score_changed", score)

func end_level_win():
	game_over_label.visible = true
	get_tree().paused = true

func end_level_lose():
	timer.stop()
	if score < 400:
		game_over_label.text = "You Lose!"
		game_over_label.visible = true
		get_tree().paused = true

func update_timer_label():
	timer_label.text = "Time: %d" % time_left

func show_score_popup(pos: Vector2):
	var popup_scene = preload("res://Scenes/UI/score_popup.tscn")
	var popup = popup_scene.instantiate()
	
	# Important: this sets the position BEFORE the animation plays
	popup.global_position = pos
	
	# Add the popup to the level or UI (whichever makes more sense for your setup)
	$LevelContainer/Level0.add_child(popup)

func show_dialogue(message: String, message_position):
	var bubble = preload("res://Scenes/UI/dialogue_bubble.tscn").instantiate()
	get_parent().add_child(bubble)

	bubble.global_position = message_position + Vector2(25, -80)  # Adjust offset above player
	bubble.show_message(message, message_position, 2.0)

func show_tip():
	var tip_box_scene = preload("res://Scenes/UI/dialogue_box.tscn")
	var tip_box = tip_box_scene.instantiate()
	var canvas_layer = get_node("/root/Game/UI")
	canvas_layer.add_child(tip_box)
	
	tip_box.visible = true
