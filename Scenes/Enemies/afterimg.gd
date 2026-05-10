extends Node2D

@onready var anim := $AnimatedSprite2D

var fade_speed := 4.0

func setup(sprite_frames, animation_name, frame, pos, flip_h, z):
	anim.sprite_frames = sprite_frames
	anim.animation = animation_name
	anim.frame = frame
	anim.playing = false

	global_position = pos
	anim.flip_h = flip_h
	z_index = z - 1

	modulate.a = 0.6


func _process(delta):
	modulate.a -= fade_speed * delta
	if modulate.a <= 0:
		queue_free()
