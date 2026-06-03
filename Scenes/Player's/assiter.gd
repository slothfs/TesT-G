extends CharacterBody2D
class_name Assister

const SPEED = 250.0
const JUMP_FORCE = -400.0
const WALL_SLIDE_SPEED = 150.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_sticking: bool = false
var stick_normal: Vector2 = Vector2.ZERO
var is_climbing_obstacle: bool = false
var jumps_left: int = 2
var max_jumps: int = 2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if is_climbing_obstacle:
		move_and_slide()
		return
		
	if Input.is_action_just_pressed("climb_obstacle") and not is_climbing_obstacle:
		_start_obstacle_climb()
		
	if Input.is_action_just_pressed("wall_stick"):
		var wall_dir = 0
		var normal = Vector2.ZERO
		if is_on_wall():
			normal = get_wall_normal()
			wall_dir = -1 if normal.x > 0 else 1
		else:
			if test_move(global_transform, Vector2(-5, 0)):
				wall_dir = -1
				normal = Vector2(1, 0)
			elif test_move(global_transform, Vector2(5, 0)):
				wall_dir = 1
				normal = Vector2(-1, 0)

		if (wall_dir != 0 and not is_on_floor()) or is_sticking:
			if not is_sticking:
				is_sticking = true
				stick_normal = normal
				if stick_normal == Vector2.ZERO:
					stick_normal = Vector2(-1 if sprite.flip_h else 1, 0)
				velocity = Vector2.ZERO
				sprite.flip_h = stick_normal.x > 0
			else:
				is_sticking = false
				sprite.position.x = 0.0

	if is_sticking:
		var vert = 0.0
		if Input.is_action_pressed("move_up"):
			vert = -1.0
		elif Input.is_action_pressed("move_down"):
			vert = 1.0
			
		velocity.y = vert * WALL_SLIDE_SPEED
		velocity.x = -stick_normal.x * 100.0 # Push against wall strongly to maintain contact and avoid seam bounces
		
		if vert != 0:
			sprite.position.x = -3.0 * stick_normal.x # Fix sprite sheet offset for sliding animation
			if sprite.sprite_frames.has_animation("sticking_up&down"):
				if sprite.animation != "sticking_up&down":
					sprite.play("sticking_up&down")
				elif not sprite.is_playing():
					sprite.play()
		else:
			sprite.position.x = 0.0 # Reset offset when clinging
			if sprite.sprite_frames.has_animation("sticking"):
				if sprite.animation == "sticking_up&down":
					sprite.play("sticking")
					sprite.set_frame(6)
					sprite.pause()
				elif sprite.animation != "sticking":
					sprite.play("sticking")
			
		if Input.is_action_just_pressed("jump"):
			is_sticking = false
			sprite.position.x = 0.0
			velocity.y = JUMP_FORCE
			velocity.x = stick_normal.x * SPEED
			
		move_and_slide()
		if is_on_floor() or not test_move(global_transform, Vector2(-stick_normal.x * 15.0, 0)):
			is_sticking = false
			sprite.position.x = 0.0
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = max_jumps

	_handle_jump()

	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	_update_animation(direction)
	move_and_slide()

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_FORCE
		jumps_left -= 1
		if sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")
			sprite.set_frame(0)

func _update_animation(direction: float) -> void:
	if not is_on_floor():
		if sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")
		return

	if direction != 0:
		if sprite.sprite_frames.has_animation("run"):
			sprite.play("run")
	else:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _start_obstacle_climb() -> void:
	is_climbing_obstacle = true
	velocity = Vector2.ZERO
	
	if sprite.sprite_frames.has_animation("climb"):
		sprite.play("climb")
		
	if is_instance_valid(col_shape):
		col_shape.disabled = true
		
	await get_tree().create_timer(1.5).timeout
	
	if is_instance_valid(col_shape):
		col_shape.disabled = false
		
	is_climbing_obstacle = false
