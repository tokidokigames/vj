extends Sprite2D

var cleaning_progress = 0.0
var max_progress = 100.0
var scrub_timer = 0.5
var last_scrub_time = 0.0
var sweep_animation_timer  # Store the dynamically created Timer

@onready var animated_sprite = $AnimatedSprite2D
@onready var progress_label = $ProgressLabelDust
@onready var instruction_label = $InstructionLabel
@onready var mess = $Area2D
var player: Node = null

func _ready():
	# Dynamically create and add a Timer
	sweep_animation_timer = Timer.new()
	sweep_animation_timer.wait_time = 1.0  # Adjust as needed
	sweep_animation_timer.one_shot = true
	sweep_animation_timer.timeout.connect(_on_sweep_animation_timeout)
	add_child(sweep_animation_timer)  # Attach to THIS DustSpill instance

	if progress_label:
		progress_label.text = "Sweep: 0%"
		progress_label.visible = false
	else:
		print("ProgressLabelDust node not found!")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
	if body.name == "Player" and body.held_item and body.held_item.name == "Broom":
		progress_label.visible = true
		if get_tree().root.get_node("Game/LevelContainer/Level0"):
			instruction_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		progress_label.visible = false
		instruction_label.visible = false
		#cleaning_progress = 0.0  # Reset progress when the player exits
	if instruction_label.visible == true:
		instruction_label.visible = false

func _process(delta):
	if player and player.held_item and player.held_item.name == "Broom":
			progress_label.visible = true
			if get_tree().root.get_node("Game/LevelContainer/Level0"):
				instruction_label.visible = true
	if progress_label.visible:
		var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
		if player and player.held_item and player.held_item.name == "Broom":
			if Input.is_action_just_pressed("sweep_q") or Input.is_action_just_pressed("sweep_e"):
			#if Input.is_action_just_pressed("sweep_q") or Input.is_action_just_pressed("sweep_e"):
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_scrub_time <= scrub_timer:
					cleaning_progress += 20.0
				#else:
				#	cleaning_progress = max(0.0, cleaning_progress - 10.0)
				last_scrub_time = current_time
				
				progress_label.text = "Sweep: %d%%" % int((cleaning_progress / max_progress) * 100)
				
				# Frame control based on progress
				var total_frames = animated_sprite.sprite_frames.get_frame_count("dust_clean_up")
				var target_frame = int((cleaning_progress / max_progress) * total_frames)
				target_frame = clamp(target_frame, 0, total_frames - 1)
				
				animated_sprite.animation = "dust_clean_up"
				animated_sprite.frame = target_frame
				animated_sprite.pause()
				
				# Start sweeping animation and timer
				player.held_item.start_sweeping()
				sweep_animation_timer.start()

				if cleaning_progress >= max_progress:
					clean_up()

func _on_sweep_animation_timeout():
	var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
	if player and player.held_item and player.held_item.name == "Broom":
		player.held_item.stop_sweeping()  # Stop animation when timer runs out

func clean_up():
	progress_label.visible = false
	var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
	
	get_tree().root.get_node("Game").add_score(100)
	get_tree().root.get_node("Game").show_score_popup(mess.global_position)

	if player.held_item:
		player.held_item.stop_sweeping()
	queue_free()
