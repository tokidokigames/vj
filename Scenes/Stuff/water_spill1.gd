extends Sprite2D

# Declare instance variables for individual spills
var cleaning_progress = 0.0
var max_progress = 100.0
var scrub_timer = 0.5
var last_scrub_time = 0.0
var is_player_near = false  # Tracks whether the player is near this spill

# Node reference
@onready var progress_label = $ProgressLabel  # Update this path if needed
@onready var audio_player = $AudioStreamPlayer2D  # Reference to the AudioStreamPlayer2D node

func _ready():
	if progress_label:
		progress_label.text = "Clean: 0%"
		progress_label.visible = false
	else:
		print("ProgressLabel node not found!")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.held_item and body.held_item.name == "Mop":
		progress_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		progress_label.visible = false
		cleaning_progress = 0.0  # Reset progress when the player exits

func _process(delta):
	# Only clean if the progress label is visible and the player is holding the mop
	if progress_label.visible:
		if Input.is_action_just_pressed("scrub"):
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_scrub_time <= scrub_timer:
				cleaning_progress += 20.0  # Increase progress
			else:
				cleaning_progress = max(0.0, cleaning_progress - 10.0)  # Penalize for slow scrubbing
			last_scrub_time = current_time

			# Update the progress text
			progress_label.text = "Mop: %d%%" % int((cleaning_progress / max_progress) * 100)

			# Check if the mess is fully cleaned
			if cleaning_progress >= max_progress:
				clean_up()

func clean_up():
	progress_label.visible = false
	#print("Cleanup started!")  # Debug print
	$AudioStreamPlayer2D.play()  # Play the cleanup sound
	#print("Sound triggered!")  # Debug print
	await audio_player.finished  # Wait for the sound to finish playing
	get_tree().root.get_node("Game").add_score(100)
	queue_free()  # Remove the water spill from the game 
