extends Node2D

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("pop")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "pop":
		queue_free()
