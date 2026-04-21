extends Sprite2D

var random_number: int = 0  # The number the player must press
var num_label: Label  # Label to show the random number

@onready var animated_sprite = $AnimatedSprite2D
@onready var audio_player = $AudioStreamPlayer2D
@onready var mess = $Area2D
@onready var instruction_label = $InstructionLabel
var player: Node = null

var scrubbing: bool = false

func _ready():
	num_label = $RandomNum  # Ensure the label node exists as a child
	num_label.visible = false  # Start with the label hidden

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
	if body.name == "Player" and body.held_item and body.held_item.name == "Rag":
		body.current_spray_mess = self
		if get_tree().root.get_node("Game/LevelContainer/Level0"):
			instruction_label.visible = true
		show_random_number()

func _on_area_2d_body_exited(body):
	if body.name == "Player":
		player = null
		# Hide the label when the player exits the area
		num_label.visible = false
		body.current_spray_mess = null
		if instruction_label.visible == true:
			instruction_label.visible = false

func show_random_number():
	random_number = randi() % 5 + 1  # Generate a number between 1 and 5
	num_label.text = "%d" % random_number
	num_label.visible = true  # Show the label

func _process(delta):
	if player and player.held_item and player.held_item.name == "Rag":
		num_label.visible = true
		if get_tree().root.get_node("Game/LevelContainer/Level0"):
			instruction_label.visible = true
	scrubbing = false
	var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
	if num_label.visible:
		for i in range(1, 6):  # Check numbers 1-5
			if Input.is_action_just_pressed("ui_%d" % i):
				scrubbing = true
				if i == random_number and player.held_item.get_wet_status():  # Correct number pressed
					if get_tree().root.get_node("Game/LevelContainer/Level0/Player"):  # Ensure player exists
						animated_sprite.play("spray_clean_up")
						player.held_item.start_ragging()
						await get_tree().create_timer(1.0).timeout 
					clean_up()
				else:
					# Optionally, add logic for incorrect presses
					player.held_item.start_ragging()

func clean_up():
	num_label.visible = false  # Hide the label
	
	var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
	if player.held_item:
		player.held_item.stop_ragging()

	get_tree().root.get_node("Game").add_score(100)
	get_tree().root.get_node("Game").show_score_popup(mess.global_position)
	
	queue_free()  # Remove the spill from the game
