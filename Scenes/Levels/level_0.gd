extends Node2D

@onready var player = $Player
@onready var level_door = $LevelZeroDoor
@onready var fade_layer_animation = $FadeLayer/AnimationPlayer
@onready var game = get_tree().root.get_node("Game")
@onready var vampire_scene = preload("res://Scenes/Characters/vampire_1.tscn")
@onready var vampire = vampire_scene.instantiate()
@onready var tip_arrow = $TipArrow

var dust_spill_instance: Node2D
var spray_mess_instance: Node2D
var water_spill_instance: Node2D
var water_spill_instance1: Node2D
var dialogue_counter = 0

func _ready():
	game.score_changed.connect(_on_score_changed)
	level_door.play("idle_door_closed")
	# Instance and place spills or messes in the level
	spawn_water_spills()
	spawn_dust()
	spawn_spray()
	spawn_vampire()
	player.is_control_enabled = false

func _process(delta):
	if GameState.is_dialogue_active == false:
		if dialogue_counter == 0:
			fade_layer_animation.play("fade_out")
			await fade_layer_animation.animation_finished
			start_level_dialogue(0)
			dialogue_counter = 1
			player.is_control_enabled = true
		elif dialogue_counter == 1:
			player.move_to(level_door.global_position + Vector2(0,125))
			await player.player_move_finished
			player.move_to(level_door.global_position + Vector2(0,100))
			await player.player_move_finished
			start_level_dialogue(1)
			dialogue_counter = 2
		elif dialogue_counter == 2:
			await open_door_and_spawn_vampire()
			start_level_dialogue(2)
			dialogue_counter = 3
		elif dialogue_counter == 3:
			if vampire.get_fade_status():
				await vampire.fade_out_animation()
				level_door.play("close_door")
				await level_door.animation_finished
				start_level_dialogue(3)
				dialogue_counter = 4
				tip_arrow.point_to(get_node("Broom"))
		elif dialogue_counter == 4 and player.held_item:
			if player.held_item.name == "Broom":
				tip_arrow.hide_point()
				tip_arrow.point_to(dust_spill_instance)
				start_level_dialogue(4)
				dialogue_counter = 5
		elif dialogue_counter == 5 and not is_instance_valid(dust_spill_instance):
			start_level_dialogue(5)
			dialogue_counter = 6
		elif dialogue_counter == 6 and player.held_item:
			if player.held_item.name == "Rag":
				start_level_dialogue(6)
				dialogue_counter = 7
				tip_arrow.point_to(get_node("Bucket"))
		elif dialogue_counter == 7 and player.held_item:
			if player.held_item.is_wet == true:
				start_level_dialogue(7)
				tip_arrow.point_to(spray_mess_instance)
				dialogue_counter = -1
		elif dialogue_counter == 8:
			start_level_dialogue(8)
			tip_arrow.point_to(get_node("Mop"))
			dialogue_counter = -2
		elif dialogue_counter == -2 and player.held_item:
			if player.held_item.name == "Mop":
				start_level_dialogue(9)
				if is_instance_valid(water_spill_instance):
					tip_arrow.point_to(water_spill_instance)
					dialogue_counter = 10
		elif dialogue_counter == 10 and not is_instance_valid(water_spill_instance):
			start_level_dialogue(10)
			dialogue_counter = -3
		elif dialogue_counter == -3:
				if player.held_item and player.held_item.name == "Mop":
					if player.held_item.is_wet == false:
						tip_arrow.point_to(get_node("Bucket"))
					elif is_instance_valid(water_spill_instance1):
						tip_arrow.point_to(water_spill_instance1)
		elif dialogue_counter == 11:
			start_level_dialogue(11)
			dialogue_counter = 12
		elif dialogue_counter == 12:
			start_level_dialogue(12)
			dialogue_counter = 13

func _on_score_changed(new_score: int) -> void:
	if new_score == 100:
		tip_arrow.point_to(get_node("Rag"))
	if new_score == 200:
		dialogue_counter = 8
	if new_score >= 400:
		dialogue_counter = 11
		#dialogue_counter = 7
		await open_door_and_spawn_vampire()
		#start_level_dialogue()

func open_door_and_spawn_vampire() -> void:
	level_door.play("open_door")
	await level_door.animation_finished

	#var vampire_scene = preload("res://Scenes/Characters/vampire_1.tscn")
	#var vampire = vampire_scene.instantiate()
	#add_child(vampire)  # Add under this level
	#vampire.global_position = level_door.global_position
	vampire.visible = true
	
	await vampire.fade_in_animation()
	
	#start_level_dialogue(1)

func start_level_dialogue(dialogue_set: int):
	var dialogue_dictionary = [
		{ 0 :
			[
				{"speaker": "Player", "text": "Ow! My head..."},
				{"speaker": "Player", "text": "Wh-where am I?"}
			]
		},
		{ 1 :
			[
				{"speaker": "Player", "text": "The door's locked!"},
				{"speaker": "Unknown", "text": "(SCREAMS FROM BEYOND THE DOOR)"},
				{"speaker": "Player", "text": "Hello! Is anyone out there?"},
				{"speaker": "Player", "text": "Help! I was kidnapped!"},
				{"speaker": "Player", "text": "Help!!!"}
			]
			
		},
		{ 2 : 
			[
				{"speaker": "Vampire", "text": "You have woken in a manner of bliss for your new role. For that, I am glad."},
				{"speaker": "Vampire", "text": "Yet you will restrain your heated breast, help."},
				{"speaker": "Vampire", "text": "It's almost daylight."},
				{"speaker": "Vampire", "text": "Your tools are all about you. See to the mess in here, first."},
				{"speaker": "Vampire", "text": "I will return in a moment with the details of the coming day's tasks."},
				{"speaker": "Vampire", "text": "Now, hurry!"}
			]
		},
		{ 3 :
			[
				{"speaker": "Player", "text": "Restrain my hot breast? Tools?"},
				{"speaker": "Tip", "text": "The room has quite a few messes, and there are various tool lying around that will be useful."},
				{"speaker": "Tip", "text": "Walk over to the broom and press 'e' to pick it up."}
			]
		},
		{ 4 :
			[
				{"speaker": "Player", "text": "How old is this broom?"},
				{"speaker": "Vampire", "text": "I pray the introductions are over, help."},
				{"speaker": "Vampire", "text": "Your next mission is close."},
				{"speaker": "Player", "text": "Yikes! Better clean up quick."},
				{"speaker": "Tip", "text": "Brooms can clean up dirt on the floor."},
				{"speaker": "Tip", "text": "Walk over to the dirt and rapidly tap 'q' to clean it up."}
			]
		},
		{ 5 :
			[
				{"speaker": "Tip", "text": "Good job! Now, drop the broom by pressing 'e' and go get the rag on the table."},
			]
		},
		{ 6 :
			[
				{"speaker": "Tip", "text": "Rags are only useful when wet. Walk over to the bucket and press 'f' to wet it."},
			]
		},
		{ 7 :
			[
				{"speaker": "Tip", "text": "Excellent. Now whatever mess is on that wall can be scrubbed off."},
				{"speaker": "Tip", "text": "Walk over to it and press the key that pops up to clean it."}
			]
		},
		{ 8 :
			[
				{"speaker": "Vampire", "text": "How fare you? I was certain the ecclisiastical teachings now included the mop."},
				{"speaker": "Vampire", "text": "Perhaps I was mistaken..."},
				{"speaker": "Tip", "text": "Pick up the mop using the same method as before."}
			]
		},
		{ 9 :
			[
				{"speaker": "Tip", "text": "To mop, go to the water mess and tap 'f' rapidly."}
			]
		},
		{ 10 :
			[
				{"speaker": "Tip", "text": "Woah! That took way longer to clean up than the others!"},
				{"speaker": "Tip", "text": "Perhaps a mop is more effective when wet..."}
			]
		},
		{ 11 :
			[
				{"speaker": "Player", "text": "Finally! Done!"}
			]
		},
		{ 12 :
			[
				{"speaker": "Vampire", "text": "Excellent! Another moment and your turn as scullion would become scallion!"},
				{"speaker": "Vampire", "text": "Prepare yourself, feeble peasant, for now you have become..."}
			]
		}
	]
	
	var dialogue_current_lines = dialogue_dictionary[dialogue_set][dialogue_set]
	
	var dialogue_box_scene = preload("res://Scenes/UI/dialogue_box.tscn")
	var dialogue_box = dialogue_box_scene.instantiate()
	
	get_tree().root.add_child(dialogue_box)
	#dialogue_box.global_position = Vector2(100, 300)
	
	var talking = dialogue_box.start(dialogue_current_lines)
	
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	
	return talking

func _on_dialogue_finished():
	pass

func spawn_water_spills():
	var water_spill_scene = preload("res://Scenes/Stuff/water_spill.tscn")
	var water_spill_scene1 = preload("res://Scenes/Stuff/water_spill.tscn")

	water_spill_instance = water_spill_scene.instantiate()
	water_spill_instance1 = water_spill_scene1.instantiate()

	water_spill_instance.position = Vector2(1100, 615)
	water_spill_instance1.position = Vector2(1275, 550)

	add_child(water_spill_instance)
	add_child(water_spill_instance1)

func spawn_dust():
	var dust_spill_scene = preload("res://Scenes/Stuff/dust_spill.tscn")
	dust_spill_instance = dust_spill_scene.instantiate()
	dust_spill_instance.position = Vector2(800, 550)
	add_child(dust_spill_instance)

func spawn_spray():
	var spray_mess_scene = preload("res://Scenes/Stuff/spray_mess.tscn")
	spray_mess_instance = spray_mess_scene.instantiate()
	spray_mess_instance.position = Vector2(1150, 465)
	add_child(spray_mess_instance)

func spawn_vampire():
	add_child(vampire)  # Add under this level
	vampire.global_position = level_door.global_position
	vampire.visible = true

func show_dialogue(message: String, message_position):
	var bubble = preload("res://Scenes/UI/dialogue_bubble.tscn").instantiate()
	get_parent().add_child(bubble)

	bubble.global_position = message_position + Vector2(25, -80)  # Adjust offset above player
	bubble.show_message(message, message_position, 2.0)
