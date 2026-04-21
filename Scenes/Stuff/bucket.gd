extends Sprite2D

@onready var animation_sprite = $AnimatedSprite2D
@onready var instruction_label = $InstructionLabel
@onready var pickup_label = $PickUpLabel

var player_nearby = false
var player = null
var is_picked_up: bool = false
var carried_by: Node = null

func _ready():
	connect("body_entered", _on_area_2d_body_entered)
	connect("body_exited", _on_area_2d_body_exited)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = true
		player = body
	if body.name == "Player" and not is_picked_up:
		body.nearby_items.append(self)
		#body.set("can_pick_up", self)  # Let the player know they can pick up this broom
		if get_tree().root.get_node("Game/LevelContainer/Level0") and is_picked_up == false and body.held_item:
			if body.held_item.name in ["Mop", "Rag"]:
				instruction_label.visible = true
		elif get_tree().root.get_node("Game/LevelContainer/Level0") and is_picked_up == false:
				pickup_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = false
		player = null
	if body.name == "Player" and not is_picked_up:
		body.nearby_items.erase(self)
		#body.set("can_pick_up", null)  # Reset the pickup state for the player
	if instruction_label.visible == true:
		instruction_label.visible = false
	if pickup_label.visible == true:
		pickup_label.visible = false

func pick_up(player):
	is_picked_up = true
	instruction_label.visible = false
	carried_by = player

	# Reparent the broom to the player
	get_parent().remove_child(self)
	player.add_child(self)
	position = Vector2(0, -20)  # Adjust position relative to the player
	rotation = 0
	self.visible = false

func put_down(player):
	is_picked_up = false
	carried_by = null

	# Reparent back to the world
	player.remove_child(self)
	player.get_parent().add_child(self)
	global_position = player.global_position + Vector2(0, 35) # Place it where the player is
	self.visible = true

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("mop"):
		if player.held_item:
			if player.held_item.name in ["Mop", "Rag"]:
				animation_sprite.play("bucket_splash")
				player.held_item.set_wet(true)
		
