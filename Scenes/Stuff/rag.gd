extends Sprite2D

@onready var area = $Area2D
@onready var sprite = $AnimatedSprite2D
@onready var instruction_label = $InstructionLabel

var is_picked_up: bool = false
var carried_by: Node = null  # Reference to the player carrying the broom
var is_wet = false

func _ready():
	if is_wet:
		sprite.play("idle_wet_rag_surface")
	else:
		sprite.play("idle_rag_surface")  # Default to idle state

func _on_area_2d_body_entered(body):
	if body.name == "Player" and not is_picked_up:
		#body.set("can_pick_up", self)  # Let the player know they can pick up this broom
		body.nearby_items.append(self)
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
	# Reparent the broom to the player to visually attach it
	get_parent().remove_child(self)
	player.add_child(self)
	position = Vector2(0, -20)  # Adjust position relative to the player sprite
	rotation = 0  # Reset any rotation if necessary
	self.visible = false

func put_down(player):
	is_picked_up = false
	# Reparent the broom back to the main scene
	player.remove_child(self)
	player.get_parent().add_child(self)
	global_position = player.global_position + Vector2(0, 25)  # Place it where the player is
	if is_wet:
		sprite.play("idle_wet_rag_surface")
	else:
		sprite.play("idle_rag_surface")
	self.visible = true

func start_ragging():
	var player = get_tree().root.get_node("Game/LevelContainer/Level0/Player")
	player.rag_clean(1.0)
	
	if player.sprite.flip_h == false:
		sprite.position = Vector2(2, -1)
	elif player.sprite.flip_h == true:
		sprite.position = Vector2(-2, -1)

	$RagSound.play()

func stop_ragging():
	sprite.position = Vector2(0, 0)
	if is_wet:
		sprite.play("idle_wet_rag_surface")
	else:
		sprite.play("idle_rag_surface")

func set_wet(wet: bool):
	is_wet = wet

func get_wet_status():
	return is_wet
