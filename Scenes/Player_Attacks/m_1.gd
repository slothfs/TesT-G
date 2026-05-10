extends Area2D

@export var speed := 600.0
@export var max_distance := 1000.0
@export var fall_gravity := 600.0

var direction := Vector2.ZERO
var start_position := Vector2.ZERO

var velocity := Vector2.ZERO
var initialized := false

func _process(delta):
	var real_delta = delta
	if Engine.time_scale > 0:
		real_delta = delta / Engine.time_scale
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.speed_scale = 1.0 / Engine.time_scale

	if not initialized:
		velocity = direction * speed
		initialized = true
		
	# Apply gravity over time
	velocity.y += fall_gravity * real_delta
	
	# Move projectile
	global_position += velocity * real_delta
	
	# Update rotation to point in the direction of current velocity
	rotation = velocity.angle()

	# delete after traveling max distance from start (straight line distance limit)
	if global_position.distance_to(start_position) >= max_distance:
		queue_free()
