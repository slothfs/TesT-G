extends CharacterBody2D

@export var speed := 250.0
@export var jump_force := -450.0
@export var gravity := 1200.0
@export var fast_fall_speed := 800.0

@onready var anim = $AnimatedSprite2D

var is_busy := false


func _ready():
	anim.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movement
	var direction := Input.get_axis("left", "right")

	if !is_busy:
		velocity.x = direction * speed
	else:
		velocity.x = 0

	# Flip
	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and !is_busy:
		velocity.y = jump_force

	# Fast fall
	if Input.is_action_pressed("pull") and not is_on_floor():
		velocity.y = fast_fall_speed

	# Action animations
	if !is_busy:
		if Input.is_action_just_pressed("attack"):
			is_busy = true
			anim.play("attacking")

		elif Input.is_action_just_pressed("spell"):
			is_busy = true
			anim.play("spell")

		elif Input.is_action_just_pressed("hurt"):
			is_busy = true
			anim.play("hurt")

		elif Input.is_action_just_pressed("die"):
			is_busy = true
			anim.play("dying")

	# Normal animations
	if !is_busy:
		if direction != 0:
			anim.play("walk")
		else:
			anim.play("idle")

	move_and_slide()


func _on_animation_finished():
	if anim.animation in ["attacking", "spell", "hurt", "dying"]:
		is_busy = false
		anim.play("idle")
