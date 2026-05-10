# Attach this to GPUParticles2D

extends GPUParticles2D

@export var target : Node2D
@export var follow_speed := 7.0

func _ready():
	emitting = true

	# AUTO MATERIAL
	var mat = ParticleProcessMaterial.new()
	process_material = mat

	# SKY BLUE GLOW COLOR
	mat.color = Color(0.4, 0.9, 1.0, 1.0)

	# RANDOM FLOATING MOVEMENT
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 20.0
	
	# STOP FALLING DOWN
	mat.gravity = Vector3(0, 0, 0)

	# PARTICLE SIZE
	mat.scale_min = 0.15
	mat.scale_max = 0.35

	# FADE OUT EFFECT
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	mat.alpha_curve = curve

	# PARTICLE SETTINGS
	amount = 60
	lifetime = 0.6
	preprocess = 0.2

	# SMOOTH TRAIL
	trail_enabled = true

func _process(delta):
	if target:
		# Smooth follow lag effect
		global_position = global_position.lerp(
			target.global_position,
			follow_speed * delta
		)
