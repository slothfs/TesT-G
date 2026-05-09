extends CharacterBody2D

@export var speed := 250.0
@export var jump_force := -450.0
@export var gravity := 1200.0
@export var fast_fall_speed := 800.0

@export var projectile_scene: PackedScene
@export var buff_scene: PackedScene

@onready var anim = $AnimatedSprite2D

var is_busy := false

var base_speed := 0.0
var base_jump_force := 0.0
var is_buffed := false


func _ready():
	base_speed = speed
	base_jump_force = jump_force
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
			var mouse_pos = get_global_mouse_position()
			anim.flip_h = mouse_pos.x < global_position.x
			anim.play("attacking")
			shoot()

		elif Input.is_action_just_pressed("spell"):
			is_busy = true
			anim.play("spell")
			cast_buff()

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
		
func shoot():
	if not projectile_scene:
		return
	var projectile = projectile_scene.instantiate()

	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.z_index = z_index - 1
	var mouse_pos = get_global_mouse_position()
	projectile.direction = (mouse_pos - global_position).normalized()
	projectile.start_position = projectile.global_position
	projectile.rotation = projectile.direction.angle()

func cast_buff():
	if is_buffed:
		return
	is_buffed = true
	
	if buff_scene:
		var buff_fx = buff_scene.instantiate()
		add_child(buff_fx)
		buff_fx.position = Vector2.ZERO
		buff_fx.z_index = 1
		buff_fx.scale = Vector2(6.0, 6.0)
		var spr = buff_fx.get_node_or_null("AnimatedSprite2D")
		if spr:
			spr.play("default")
			spr.animation_finished.connect(buff_fx.queue_free)
		
	# Apply buff (1.5x speed, 1.3x jump height)
	speed = base_speed * 1.5
	jump_force = base_jump_force * 1.3
	
	# Create a timer to remove buff
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_remove_buff)

func _remove_buff():
	speed = base_speed
	jump_force = base_jump_force
	is_buffed = false
