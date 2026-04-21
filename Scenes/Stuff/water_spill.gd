extends Sprite2D

# Declare instance variables
var cleaning_progress = 0.0
var max_progress = 100.0
var scrub_timer = 0.5
var last_scrub_time = 0.0
var scrub_animation_timer  # Store the dynamically created Timer

# Node references
@onready var animated_sprite = $AnimatedSprite2D
@onready var progress_label = $ProgressLabel
@onready var instruction_label = $InstructionLabel
@onready var audio_player = $AudioStreamPlayer2D
@onready var mess = $Area2D
var player: Node = null

func _ready():
	# Dynamically create and add a Timer
	scrub_animation_timer = Timer.new()
	scrub_animation_timer.wait_time = 1.0  # Adjust as needed
	scrub_animation_timer.one_shot = true  # Stops automatically
	scrub_animation_timer.timeout.connect(_on_scrub_animation_timeout)
	add_child(scrub_animation_timer)  # Attach to THIS WaterSpill instance

	#print("WaterSpill instance:", self.get_instance_id(), "- Timer added:", scrub_animation_timer)

	if progress_label:
		progress_label.text = "Mop: 0%"
		progress_label.visible = false
	else:
		print("ProgressLabel node not found!")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
	if body.name == "Player" and body.held_item and body.held_item.name == "Mop":
		progress_label.visible = true
		if get_tree().root.get_node("Game/LevelContainer/Level0"):
			instruction_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		progress_label.visible = false
		#cleaning_progress = 0.0  # Reset progress when the player exits
		if instruction_label.visible == true:
			instruction_label.visible = false

func _process(delta):
	if player and player.held_item and player.held_item.name == "Mop":
			progress_label.visible = true
			if get_tree().root.get_node("Game/LevelContainer/Level0"):
				instruction_label.visible = true
	if progress_label.visible:
		var first_mop = true
		var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")  # Adjust path if needed
		if player and player.held_item and player.held_item.name == "Mop":
			if Input.is_action_just_pressed("mop"):
				var current_time = Time.get_ticks_msec() / 1000.0
				if player.held_item.get_wet_status() and current_time - last_scrub_time <= scrub_timer:
					cleaning_progress += 20.0
				elif not player.held_item.get_wet_status() and current_time - last_scrub_time <= scrub_timer:
					cleaning_progress += 5.0
				last_scrub_time = current_time
				
				progress_label.text = "Mop: %d%%" % int((cleaning_progress / max_progress) * 100)
				
				# Frame control based on progress
				var total_frames = animated_sprite.sprite_frames.get_frame_count("water_clean_up")
				var target_frame = int((cleaning_progress / max_progress) * total_frames)
				target_frame = clamp(target_frame, 0, total_frames - 1)
				
				animated_sprite.animation = "water_clean_up"
				animated_sprite.frame = target_frame
				animated_sprite.pause()
				
				progress_label.text = "Mop: %d%%" % int((cleaning_progress / max_progress) * 100)
				
				# Start animation and timer
				player.held_item.start_mopping()
				scrub_animation_timer.start()  # Reset and restart the timer
				
				if cleaning_progress >= max_progress:
					clean_up()

func _on_scrub_animation_timeout():
	var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
	if player and player.held_item and player.held_item.name == "Mop":
		player.held_item.stop_mopping()  # Stop animation when timer runs out

func clean_up():
	progress_label.visible = false
	var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
	
	#$AudioStreamPlayer2D.play()
	#await audio_player.finished
	get_tree().root.get_node("Game").add_score(100)
	get_tree().root.get_node("Game").show_score_popup(mess.global_position)
	
	if player.held_item and player.held_item.name == "Mop":
		player.held_item.stop_mopping()
	queue_free()
