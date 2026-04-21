extends Node2D

@onready var area = $Area2D
@onready var sprite = $AnimatedSprite2D  # Reference to the sprite for animations
@onready var instruction_label = $InstructionLabel

var is_picked_up: bool = false
var carried_by: Node = null  # Reference to the player carrying the broom
var is_sweeping: bool = false  # Track sweeping state

func _ready():
	sprite.play("idle_broom")  # Default to idle state

func _on_area_2d_body_entered(body):
	if body.name == "Player" and not is_picked_up:
		body.nearby_items.append(self)
		#body.set("can_pick_up", self)  # Let the player know they can pick up this broom
		if get_tree().root.get_node("Game/LevelContainer/Level0") and is_picked_up == false and body.held_item == null:
			instruction_label.visible = true

func _on_area_2d_body_exited(body):
	if body.name == "Player" and not is_picked_up:
		body.nearby_items.erase(self)
		#body.set("can_pick_up", null)  # Reset the pickup state for the player
	if instruction_label.visible == true:
		instruction_label.visible = false

func pick_up(player):
	is_picked_up = true
	instruction_label.visible = false
	carried_by = player
	sprite.visible = false

	# Reparent the broom to the player
	get_parent().remove_child(self)
	player.add_child(self)
	position = Vector2(0, -20)  # Adjust position relative to the player
	rotation = 0
	show()

func put_down(player):
	is_picked_up = false
	carried_by = null

	# Reparent back to the world
	player.remove_child(self)
	player.get_parent().add_child(self)
	global_position = player.global_position  # Place it where the player is
	sprite.visible = true
	show()
	stop_sweeping()

func start_sweeping():
	if has_node("AnimatedSprite2D"):
		var anim_sprite = $AnimatedSprite2D
		var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
		if anim_sprite.animation != "sweeping" or !anim_sprite.is_playing():
			if player.sprite.flip_h == false:
				anim_sprite.position = Vector2(1, 2)
			elif player.sprite.flip_h == true:
				anim_sprite.position = Vector2(-1, 2)
			anim_sprite.play("sweeping")  # Start sweeping animation
			$SweepSound.play()

func stop_sweeping():
	if has_node("AnimatedSprite2D"):
		var anim_sprite = $AnimatedSprite2D
		if anim_sprite.animation == "sweeping":
			anim_sprite.position = Vector2(0, 0)
			anim_sprite.play("idle_broom")  # Change back to idle when done
