extends CharacterBody2D

@export var speed := 250.0
@export var jump_force := -450.0
@export var gravity := 1200.0
@export var fast_fall_speed := 800.0

@export var projectile_scene: PackedScene
@export var buff_scene: PackedScene

# 🔥 Afterimage settings
var afterimage_scene = preload("res://Scenes/Players/afterimage.tscn")
@export var afterimage_count := 6
@export var afterimage_delay := 0.03

@onready var anim = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

const GRAPPLING = preload("uid://bvy37v27yal2d")

var is_busy := false

var base_speed := 0.0
var base_jump_force := 0.0
var base_gravity := 0.0
var is_buffed := false
var afterimage_timer := 0.0

func _ready():
	Engine.time_scale = 1.0
	base_speed = speed
	base_jump_force = jump_force
	base_gravity = gravity
	anim.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	_set_ray_cast_direction()

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movement
	var direction := Input.get_axis("left", "right")

	if is_buffed:
		var real_delta = delta
		if Engine.time_scale > 0:
			real_delta = delta / Engine.time_scale
			
		afterimage_timer -= real_delta
		if afterimage_timer <= 0:
			if velocity.length() > 10.0:
				spawn_afterimage()
			afterimage_timer = 0.04 # spawn every 0.04 real seconds

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

	# Actions
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
			# create_afterimage_trail()

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


func take_damage(amount):
	if !is_busy:
		is_busy = true
		anim.play("hurt")

func _on_animation_finished():
	if anim.animation in ["attacking", "spell", "hurt", "dying"]:
		is_busy = false
		anim.play("idle")


# ----------------------------
# SHOOT
# ----------------------------
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


# ----------------------------
# BUFF
# ----------------------------
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
			spr.speed_scale = 1.0 / 0.4
			spr.play("default")
			spr.animation_finished.connect(buff_fx.queue_free)

	Engine.time_scale = 0.4

	# Counteract the slow-mo for the player so they move and animate fast!
	speed = (base_speed / 0.4) * 1.5      # 1.5x real speed
	jump_force = (base_jump_force / 0.4) * 1.2 # slightly higher jump
	gravity = base_gravity / (0.4 * 0.4)  # gravity needs 1/t^2 scaling
	fast_fall_speed = 800.0 / 0.4
	
	anim.speed_scale = 1.0 / 0.4          # animate at normal speed!

	var timer = get_tree().create_timer(5.0, true, false, true) # 5 seconds real-time
	timer.timeout.connect(_remove_buff)


func _remove_buff():
	speed = base_speed
	jump_force = base_jump_force
	gravity = base_gravity
	fast_fall_speed = 800.0
	Engine.time_scale = 1.0
	anim.speed_scale = 1.0
	is_buffed = false


# ----------------------------
# AFTERIMAGE SYSTEM
# ----------------------------

func spawn_afterimage():
	if not afterimage_scene:
		return

	var img = afterimage_scene.instantiate()

	var tex = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)

	img.setup(
		tex,
		anim.global_position,
		anim.flip_h,
		z_index,
		anim.global_scale,
		anim.offset
	)

	get_parent().add_child(img)


func create_afterimage_trail():
	for i in range(afterimage_count):
		spawn_afterimage()
		await get_tree().create_timer(afterimage_delay).timeout
		
		
func _set_ray
