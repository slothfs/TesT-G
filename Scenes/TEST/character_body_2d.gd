extends CharacterBody2D

@export var speed := 250.0
@export var jump_force := -450.0
@export var gravity := 1200.0
@export var fast_fall_speed := 800.0

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Left / Right movement
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	# Fast fall (press S / down)
	if Input.is_action_pressed("ui_down") and not is_on_floor():
		velocity.y = fast_fall_speed

	move_and_slide()
