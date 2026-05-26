extends Node2D

@onready var sprite = $"1"
@onready var particles = $GPUParticles2D

var last_pos: Vector2
var rotation_speed: float = 20.0 # Fast and snappy rotation
var is_spinning: bool = false
var current_spin: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	last_pos = get_viewport().get_mouse_position()
	particles.emitting = false

func _process(delta):
	var current_pos = get_viewport().get_mouse_position()
	global_position = current_pos
	
	# Emit particles only when the cursor is moving
	if current_pos.distance_squared_to(last_pos) > 1.0:
		particles.emitting = true
	else:
		particles.emitting = false
	last_pos = current_pos
	
	# Handle 360 rotation on click / hold
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_spinning = true
		
	if is_spinning:
		var step = rotation_speed * delta
		sprite.rotation += step
		current_spin += step
		
		# Check if a full 360 rotation (TAU) is completed
		if current_spin >= TAU:
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				# Snap to exactly 0 to stop cleanly
				sprite.rotation = 0.0
				current_spin = 0.0
				is_spinning = false
			else:
				# Keep spinning, but wrap the values to prevent them from growing infinitely
				current_spin -= TAU
				sprite.rotation = current_spin
