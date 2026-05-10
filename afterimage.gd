extends Node2D

var fade_speed := 1.5
var target_texture: Texture2D
var target_flip_h: bool
var target_offset: Vector2

func setup(texture, pos, flip_h, z, _scale = Vector2.ONE, _offset = Vector2.ZERO):
	target_texture = texture
	target_flip_h = flip_h
	target_offset = _offset

	global_position = pos
	z_index = z - 1
	global_scale = _scale
	modulate = Color(0.3, 0.8, 1.0, 0.8) # more visible blue

func _ready():
	$Sprite2D.texture = target_texture
	$Sprite2D.flip_h = target_flip_h
	$Sprite2D.offset = target_offset

func _process(delta):
	var real_delta = delta
	if Engine.time_scale > 0:
		real_delta = delta / Engine.time_scale
		
	modulate.a -= fade_speed * real_delta
	if modulate.a <= 0:
		queue_free()
