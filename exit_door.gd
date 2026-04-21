extends Area2D

@export var target_scene: String = "res://next_scene.tscn"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":  # Assuming the player node is named "Player"
		get_tree().change_scene_to_file(target_scene)  # Change to the target scene
