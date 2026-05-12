extends CharacterBody2D

@export var speed := 250.0
@export var jump_force := -450.0
@export var gravity := 1200.0
@export var fast_fall_speed := 800.0

@export var projectile_scene: PackedScene
@export var buff_scene: PackedScene

var afterimage_scene = preload("res://Scenes/Players/afterimage.tscn")
@export var afterimage_count := 6
@export var afterimage_delay := 0.03

@onready var anim = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

var is_busy := false

var base_speed := 0.0
var base_jump_force := 0.0
var base_gravity := 0.0
var is_buffed := false
var afterimage_timer := 0.0

var is_grappling := false
var grapple_target := Vector2.ZERO
var grapple_length := 0.0
@export var grapple_max_length := 600.0
var grapple_line: Line2D

func _ready():
	Engine.time_scale = 1.0
	base_speed = speed
	base_jump_force = jump_force
	base_gravity = gravity
	anim.animation_finished.connect(_on_animation_finished)
	
	ray_cast_2d.target_position = Vector2(grapple_max_length, 0)
	
	grapple_line = Line2D.new()
	grapple_line.width = 3.0
	grapple_line.default_color = Color(0.8, 0.6, 0.4)
	grapple_line.top_level = true
	grapple_line.hide()
	add_child(grapple_line)
	
	var stretch_mat = ShaderMaterial.new()
	stretch_mat.shader = preload("res://Scenes/Players/stretch.gdshader")
	anim.material = stretch_mat


func _physics_process(delta):
	_set_ray_cast_direction()

	var direction := Input.get_axis("left", "right")

	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true

	if is_grappling:
		_process_grappling(delta, direction)
	else:
		_process_normal_movement(delta, direction)

	if is_buffed:
		_process_buff(delta)

	move_and_slide()

func _process_normal_movement(delta: float, direction: float):
	if not is_on_floor():
		velocity.y += gravity * delta

	if !is_busy:
		velocity.x = direction * speed
	else:
		velocity.x = 0

	if Input.is_action_just_pressed("jump") and is_on_floor() and !is_busy:
		velocity.y = jump_force

	if Input.is_action_pressed("pull") and not is_on_floor():
		velocity.y = fast_fall_speed

	if !is_busy:
		if Input.is_action_just_pressed("spell"):
			is_busy = true
			anim.play("spell")
			cast_buff()

		elif Input.is_action_just_pressed("hurt"):
			is_busy = true
			anim.play("hurt")

		elif Input.is_action_just_pressed("die"):
			is_busy = true
			anim.play("dying")

	if !is_busy:
		if direction != 0:
			anim.play("walk")
		else:
			anim.play("idle")


func _process_grappling(delta: float, direction: float):
	anim.play("idle")
	
	var local_target = anim.to_local(grapple_target)
	anim.material.set_shader_parameter("target_pos", local_target)
	anim.material.set_shader_parameter("stretch_amount", 1.0)
	
	if Input.is_action_just_pressed("jump"):
		_stop_grapple()
		velocity.y = jump_force * 0.8
		return

	var dir_to_target = (grapple_target - global_position).normalized()
	velocity = dir_to_target * 1200.0
	
	var dist = global_position.distance_to(grapple_target)
	if dist < 60.0:
		_stop_grapple()

func _stop_grapple():
	is_grappling = false
	grapple_line.hide()
	if anim.material:
		anim.material.set_shader_parameter("stretch_amount", 0.0)


func _process_buff(delta: float):
	var real_delta = delta
	if Engine.time_scale > 0:
		real_delta = delta / Engine.time_scale
		
	afterimage_timer -= real_delta
	if afterimage_timer <= 0:
		if velocity.length() > 10.0:
			spawn_afterimage()
		afterimage_timer = 0.04


func take_damage(amount):
	if !is_busy:
		is_busy = true
		if is_grappling:
			_stop_grapple()
		anim.play("hurt")


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
			spr.speed_scale = 1.0 / 0.4
			spr.play("default")
			spr.animation_finished.connect(buff_fx.queue_free)

	Engine.time_scale = 0.4

	speed = (base_speed / 0.4) * 1.5
	jump_force = (base_jump_force / 0.4) * 1.2
	gravity = base_gravity / (0.4 * 0.4)
	fast_fall_speed = 800.0 / 0.4
	
	anim.speed_scale = 1.0 / 0.4

	var timer = get_tree().create_timer(5.0, true, false, true)
	timer.timeout.connect(_remove_buff)


func _remove_buff():
	speed = base_speed
	jump_force = base_jump_force
	gravity = base_gravity
	fast_fall_speed = 800.0
	Engine.time_scale = 1.0
	anim.speed_scale = 1.0
	is_buffed = false


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
		
		
func _set_ray_cast_direction():
	ray_cast_2d.look_at(get_global_mouse_position())
	ray_cast_2d.target_position = Vector2(grapple_max_length, 0)


func _input(event):
	if event.is_action_pressed("attack"):
		if !is_busy and !is_grappling:
			is_busy = true
			var mouse_pos = get_global_mouse_position()
			anim.flip_h = mouse_pos.x < global_position.x
			anim.play("attacking")
			shoot()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		if !is_busy and !is_grappling:
			if ray_cast_2d.is_colliding():
				grapple_target = ray_cast_2d.get_collision_point()
				grapple_length = global_position.distance_to(grapple_target)
				is_grappling = true
