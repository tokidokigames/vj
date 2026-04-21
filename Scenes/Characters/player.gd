extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var hand_position = $AnimatedSprite2D/HandPosition

signal player_move_finished

var holding_tool = false
var is_cleaning = false  # Tracks if the player is actively cleaning
var is_scrubbing = false  # Prevents animation from restarting every frame
var held_item: Node2D = null
var can_pick_up: Node2D = null  # Reference to the tool
var nearby_items := []
var cleaning_timer = null  # Timer to keep player in cleaning animation
var current_spray_mess: Node2D = null
var last_direction: Vector2 = Vector2.DOWN  # Default facing direction
var is_wet = false
var is_control_enabled = true  # Normal player movement flag
var move_speed = 100.0  # Adjust to your actual speed
var move_target: Vector2 = Vector2.ZERO
var is_moving_to_target = false

func _ready():
	sprite.play("idle_empty_down")  # Default animation
	cleaning_timer = Timer.new()
	cleaning_timer.wait_time = 1.5  # Default cleaning duration
	cleaning_timer.one_shot = true
	cleaning_timer.connect("timeout", stop_cleaning)
	add_child(cleaning_timer)

func _physics_process(delta: float) -> void:
	if is_moving_to_target and (move_target != self.global_position):
		var direction = (move_target - global_position)
		last_direction = direction
		if direction.length() > 4.0:
			velocity = direction.normalized() * move_speed * 2
			#update_animation(direction)
			sprite.play(get_walk_animation_from_direction(direction)) # Force walk
			move_and_slide()
		else:
			is_moving_to_target = false
			velocity = Vector2.ZERO
			direction = Vector2.ZERO
			update_animation(direction)
			is_control_enabled = true
			emit_signal("player_move_finished")
	#else:
		# your normal input-based movement here, e.g.:
		#if is_control_enabled:
			#handle_player_input(delta)
			#update_animation()
			
	if GameState.is_dialogue_active or not is_control_enabled:
		return
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 500

	# Handle sprite flipping
	if Input.is_action_pressed("move_right"):
		#sprite.flip_h = false
		hand_position.position.x = 7
	elif Input.is_action_pressed("move_left"):
		#sprite.flip_h = true
		hand_position.position.x = -7

	# Move the held item to the player's hand [UNUSED]
	if holding_tool and held_item and sprite.animation and not is_scrubbing:
		held_item.global_position = hand_position.global_position
	elif holding_tool and held_item and sprite.animation and is_scrubbing:
		held_item.global_position = hand_position.global_position + Vector2(0, -1)

	# Update animation
	update_animation(direction)

	move_and_slide()

func _process(delta: float) -> void:
	# Handle tool pickup/drop with E
	if Input.is_action_just_pressed("interact"):
		_on_pick_up()

	# Start cleaning actions when pressing the correct keys
	if Input.is_action_just_pressed("mop") and holding_tool:
		if held_item.name == "Mop":
			start_mopping(1.0)  # Mop cleaning takes 2 seconds
	elif (Input.is_action_just_pressed("sweep_q")) and holding_tool:
		if held_item.name == "Broom":
			start_sweeping(1.0)  # Sweeping takes 1.5 seconds

	if current_spray_mess and current_spray_mess.scrubbing and not is_scrubbing:
		is_scrubbing = true  # Set flag so it only triggers once
		rag_clean(1.0)

	if held_item and held_item.name in ["Mop", "Rag"]:
		is_wet = held_item.get_wet_status()

func _on_pick_up():
	if held_item == null and nearby_items.size() > 0:
		var closest_item = null
		var min_distance = INF

		for item in nearby_items:
			var dist = global_position.distance_to(item.global_position)
			if dist < min_distance:
				min_distance = dist
				closest_item = item

		if closest_item:
			held_item = closest_item
			held_item.pick_up(self)
			holding_tool = true
			#sprite.play("walk_tool")

			held_item.reparent(self)
			held_item.global_position = hand_position.global_position
			held_item.z_index = sprite.z_index - 1
	elif held_item:
		# Put down logic
		held_item.put_down(self)
		holding_tool = false
		sprite.play("walk_empty")

		var dropped_item = held_item
		held_item = null
		dropped_item.reparent(get_parent())
		#dropped_item.global_position = global_position #Handled individually for the tools
		dropped_item.z_index = 0
#func _on_pick_up():
	#if held_item == null and can_pick_up:
		## Pick up the item
		#held_item = can_pick_up
		#held_item.pick_up(self)
		#holding_tool = true
		#update_animation(Vector2.ZERO)
#
		## Attach the item to the hand
		#held_item.reparent(self)
		#held_item.global_position = hand_position.global_position
#
		## Set tool behind sprite
		#held_item.z_index = sprite.z_index - 1
	#elif held_item:
		## Put down the held item
		#held_item.put_down(self)
		#holding_tool = false
#
		## Detach and drop where player stands
		#var dropped_item = held_item
		#held_item = null
		#dropped_item.reparent(get_parent())
		#dropped_item.global_position = global_position
		#dropped_item.z_index = 0

func move_to(target_position: Vector2) -> void:
	is_control_enabled = false
	move_target = target_position
	is_moving_to_target = true
	
	# Wait until it arrives
	while is_moving_to_target:
		await get_tree().physics_frame
		if is_control_enabled:
			return

func start_mopping(duration: float):
	if not holding_tool:
		return
	
	is_cleaning = true
	if held_item.name == "Mop":
		if abs(last_direction.x) > abs(last_direction.y):
			sprite.play("mopping_right" if last_direction.x > 0 else "mopping_left")
		else:
			sprite.play("mopping_down" if last_direction.y > 0 else "mopping_up")
	cleaning_timer.wait_time = duration
	cleaning_timer.start()

func start_sweeping(duration: float):
	if not holding_tool:
		return
	
	is_cleaning = true
	if held_item.name == "Broom":
		if abs(last_direction.x) > abs(last_direction.y):
			sprite.play("sweeping_right" if last_direction.x > 0 else "sweeping_left")
		else:
			sprite.play("sweeping_down" if last_direction.y > 0 else "sweeping_up")
	cleaning_timer.wait_time = duration
	cleaning_timer.start()

func stop_cleaning():
	is_cleaning = false
	update_animation(Vector2.ZERO)  # Revert to idle/walking animations

func rag_clean(duration: float):
	if held_item.name == "Rag":
		if abs(last_direction.x) > abs(last_direction.y):
			sprite.play("rag_right" if last_direction.x > 0 else "rag_left")
		else:
			sprite.play("rag_down" if last_direction.y > 0 else "rag_up")
		# Move the rag up relative to HandPosition
	if held_item:
		held_item.position = hand_position.position + Vector2(0, -1)  # Move up by 1 pixel

	await get_tree().create_timer(1.0).timeout  

	# Reset rag position after scrubbing
	if held_item:
		held_item.position = hand_position.position 
		held_item.stop_ragging()

	is_scrubbing = false  # Reset flag after scrubbing ends

func update_animation(direction: Vector2):
	if is_cleaning:
		pass  # Cleaning animations are handled elsewhere
	elif is_scrubbing:
		pass
	elif direction != Vector2.ZERO and not holding_tool:
		last_direction = direction  # Save direction
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				sprite.play("walk_right")
			else:
				sprite.play("walk_left")
		else:
			if direction.y > 0:
				sprite.play("walk_down")
			else:
				sprite.play("walk_up")
	elif direction != Vector2.ZERO and holding_tool:
		last_direction = direction  # Save direction
		if held_item.name == "Broom":
			if abs(direction.x) > abs(direction.y):
				if direction.x > 0:
					sprite.play("walk_broom_right")
				else:
					sprite.play("walk_broom_left")
			else:
				if direction.y > 0:
					sprite.play("walk_broom_down")
				else:
					sprite.play("walk_broom_up")
		elif held_item.name == "Mop":
			if held_item.get_wet_status():
				if abs(direction.x) > abs(direction.y):
					if direction.x > 0:
						sprite.play("walk_wet_mop_right")
					else:
						sprite.play("walk_wet_mop_left")
				else:
					if direction.y > 0:
						sprite.play("walk_wet_mop_down")
					else:
						sprite.play("walk_wet_mop_up")
			else:
				if abs(direction.x) > abs(direction.y):
					if direction.x > 0:
						sprite.play("walk_mop_right")
					else:
						sprite.play("walk_mop_left")
				else:
					if direction.y > 0:
						sprite.play("walk_mop_down")
					else:
						sprite.play("walk_mop_up")
		elif held_item.name == "Rag":
			if held_item.get_wet_status():
				if abs(direction.x) > abs(direction.y):
					if direction.x > 0:
						sprite.play("walk_wet_rag_right")
					else:
						sprite.play("walk_wet_rag_left")
				else:
					if direction.y > 0:
						sprite.play("walk_wet_rag_down")
					else:
						sprite.play("walk_wet_rag_up")
			else:
				if abs(direction.x) > abs(direction.y):
					if direction.x > 0:
						sprite.play("walk_rag_right")
					else:
						sprite.play("walk_rag_left")
				else:
					if direction.y > 0:
						sprite.play("walk_rag_down")
					else:
						sprite.play("walk_rag_up")
		elif held_item.name == "Bucket":
			if abs(direction.x) > abs(direction.y):
				if direction.x > 0:
					sprite.play("walk_bucket_right")
				else:
					sprite.play("walk_bucket_left")
			else:
				if direction.y > 0:
					sprite.play("walk_bucket_down")
				else:
					sprite.play("walk_bucket_up")
		else:
			sprite.play("walk_tool")
	else:
		# Use last_direction to choose idle animation
		if not holding_tool:
			if abs(last_direction.x) > abs(last_direction.y):
				sprite.play("idle_empty_right" if last_direction.x > 0 else "idle_empty_left")
			else:
				sprite.play("idle_empty_down" if last_direction.y > 0 else "idle_empty_up")
		else:
			if held_item.name == "Broom":
				if abs(last_direction.x) > abs(last_direction.y):
					sprite.play("idle_broom_right" if last_direction.x > 0 else "idle_broom_left")
				else:
					sprite.play("idle_broom_down" if last_direction.y > 0 else "idle_broom_up")
			elif held_item.name == "Mop":
				if held_item.get_wet_status():
					if abs(last_direction.x) > abs(last_direction.y):
						sprite.play("idle_wet_mop_right" if last_direction.x > 0 else "idle_wet_mop_left")
					else:
						sprite.play("idle_wet_mop_down" if last_direction.y > 0 else "idle_wet_mop_up")
				else:
					if abs(last_direction.x) > abs(last_direction.y):
						sprite.play("idle_mop_right" if last_direction.x > 0 else "idle_mop_left")
					else:
						sprite.play("idle_mop_down" if last_direction.y > 0 else "idle_mop_up")
			elif held_item.name == "Rag":
				if held_item.get_wet_status():
					if abs(last_direction.x) > abs(last_direction.y):
						sprite.play("idle_wet_rag_right" if last_direction.x > 0 else "idle_wet_rag_left")
					else:
						sprite.play("idle_wet_rag_down" if last_direction.y > 0 else "idle_wet_rag_up")
				else:
					if abs(last_direction.x) > abs(last_direction.y):
						sprite.play("idle_rag_right" if last_direction.x > 0 else "idle_rag_left")
					else:
						sprite.play("idle_rag_down" if last_direction.y > 0 else "idle_rag_up")
			elif held_item.name == "Bucket":
				if abs(last_direction.x) > abs(last_direction.y):
					sprite.play("idle_bucket_right" if last_direction.x > 0 else "idle_bucket_left")
				else:
					sprite.play("idle_bucket_down" if last_direction.y > 0 else "idle_bucket_up")

func get_walk_animation_from_direction(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			return "walk_right"
		else:
			return "walk_left"
	else:
		if direction.y > 0:
			return "walk_down"
		else:
			return "walk_up"
			
