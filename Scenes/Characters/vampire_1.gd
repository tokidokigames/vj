extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var fade_layer = $FadeLayer/AnimationPlayer

var is_visible = false

func _ready():
	self.modulate.a = 0.0  # Start invisible
	sprite.play("vampire_idle_down")  # Default idle

func fade_in_animation():
	is_visible = true
	fade_layer.play("fade_in")  # Play your modulate animation
	
func fade_out_animation():
	is_visible = false
	fade_layer.play("fade_out")
	await fade_layer.animation_finished

func get_fade_status():
	return is_visible
