extends CharacterBody2D
class_name Fighter

const SPEED := 250.0
const JUMP_FORCE := -400.0
const DASH_SPEED := 700.0
const DASH_TIME := 0.15
const COMBO_TIME := 0.35
const ATTACK_FRICTION := 1200.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var health := 100

var attacking := false
var dashing := false
var mouse_dashing := false
var mouse_dash_target := Vector2.ZERO
var mouse_dash_timer := 0.0
const MOUSE_DASH_SPEED := 1200.0
var hurt := false
var dead := false

var combo := 0
var combo_timer := 0.0
var queued_attack := false

var dash_timer := 0.0
var dash_direction := 1.0

var max_jumps := 2
var jumps_left := 2

# --- NEW FEATURES STATE ---
var is_sticking := false
var stick_normal := Vector2.ZERO
var is_climbing_obstacle := false
var current_mode := 0 # 0 = Fighter, 1 = Assister
var can_switch := true

var cooldown_timer := 0.0

@export var assister_scene_path: String = "res://Scenes/Player's/assiter.tscn"
var assister_instance: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	_setup_animations()
	_setup_inputs()

	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if current_mode == 1:
		if is_instance_valid(assister_instance):
			global_position = assister_instance.global_position
			
		if Input.is_action_just_pressed("switch_player"):
			_revert_to_fighter()
			return
			
		return # Stop processing Fighter physics while Assister is active

	elif not can_switch:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_switch = true

	if Input.is_action_just_pressed("switch_player"):
		_switch_to_assister()
		
	if Input.is_action_just_pressed("climb_obstacle") and not is_climbing_obstacle:
		_start_obstacle_climb()

	if dead:
		velocity.y += gravity * delta
		move_and_slide()
		return

	if is_climbing_obstacle:
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = max_jumps

	if combo_timer > 0.0:
		combo_timer -= delta

		if combo_timer <= 0.0:
			combo = 0

	if hurt:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta * 10.0)
		move_and_slide()
		return

	if mouse_dashing:
		mouse_dash_timer -= delta
		var dist = global_position.distance_to(mouse_dash_target)
		if dist < 20.0 or mouse_dash_timer <= 0.0:
			mouse_dashing = false
			velocity = Vector2.ZERO
		else:
			velocity = global_position.direction_to(mouse_dash_target) * MOUSE_DASH_SPEED
		
		move_and_slide()
		
		if Engine.get_frames_drawn() % 3 == 0:
			_create_ghost()
			
		return

	if dashing:
		_handle_dash(delta)
		move_and_slide()
		return

	_handle_jump()
	_handle_dash_input()
	_handle_attack_input()

	if attacking:
		velocity.x = move_toward(velocity.x, 0.0, ATTACK_FRICTION * delta)
		move_and_slide()
		return

	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Keep light ahead of player
	if is_instance_valid(light):
		var offset_x = -60.0 if sprite.flip_h else 60.0
		light.position.x = lerp(light.position.x, offset_x, delta * 15.0)

	_update_animation(direction)

	move_and_slide()

func _handle_jump() -> void:

	if Input.is_action_just_pressed("jump") and jumps_left > 0:

		velocity.y = JUMP_FORCE
		jumps_left -= 1

		sprite.play("jump")
		sprite.set_frame(0)

func _handle_dash_input() -> void:

	if Input.is_action_just_pressed("dash") and not attacking:

		dashing = true
		dash_timer = DASH_TIME
		dash_direction = -1.0 if sprite.flip_h else 1.0

		sprite.play("dash")

func _handle_dash(delta: float) -> void:

	dash_timer -= delta

	velocity.y = 0.0
	velocity.x = dash_direction * DASH_SPEED

	if Input.is_action_just_pressed("attack1"):

		dashing = false
		attacking = true
		combo = 0

		sprite.play("dash_attack")
		return

	if dash_timer <= 0.0:
		dashing = false

func _handle_attack_input() -> void:

	if Input.is_action_just_pressed("attack1"):

		if attacking and not queued_attack:
			queued_attack = true
			return

		var mouse_pos = get_global_mouse_position()
		
		# If cursor is far, do the magic dash
		if global_position.distance_to(mouse_pos) > 120.0:
			mouse_dash_target = mouse_pos
			mouse_dashing = true
			mouse_dash_timer = 0.25
			
			attacking = true
			dashing = false
			queued_attack = false
			combo = 0
			combo_timer = 0.0
			
			sprite.flip_h = mouse_dash_target.x < global_position.x
			sprite.play("dash_attack")
		else:
			# If cursor is close, do normal M1 and directional attacks
			_start_attack()

	if Input.is_action_just_pressed("attack2") and not attacking:

		attacking = true
		combo = 0

		sprite.play("front_attackM2")

func _start_attack() -> void:

	attacking = true
	combo_timer = 0.0

	if Input.is_action_pressed("move_up"):

		sprite.play("up_attack")
		combo = 0
		return

	if Input.is_action_pressed("move_down"):

		sprite.play("down_attack")
		combo = 0
		return

	match combo:

		0:
			sprite.play("front_attackM1")
			combo = 1

		1:
			sprite.play("front_attackM2")
			combo = 2

		2:
			sprite.play("idle_attack")
			combo = 0

func take_damage(amount: int) -> void:

	if dead:
		return

	health -= amount

	attacking = false
	dashing = false
	queued_attack = false
	combo = 0

	if health <= 0:

		dead = true
		sprite.play("dead")
		return

	hurt = true
	sprite.play("hurt")

func _update_animation(direction: float) -> void:

	if attacking or dashing or hurt or dead:
		return

	if not is_on_floor():

		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")

		return

	if direction != 0:
		sprite.play("run")
	else:
		sprite.play("idle")

func _on_animation_finished() -> void:

	print(sprite.animation + " finished")

	match sprite.animation:

		"hurt":
			hurt = false

		"front_attackM1", "front_attackM2", "idle_attack", "up_attack", "down_attack", "dash_attack":

			attacking = false

			if queued_attack:

				queued_attack = false
				_start_attack()

			else:
				combo_timer = COMBO_TIME

		"dash", "dash_a":
			dashing = false

func _setup_animations() -> void:

	var non_looping = [
		"front_attackM1",
		"front_attackM2",
		"idle_attack",
		"up_attack",
		"down_attack",
		"dash",
		"dash_attack",
		"dash_a",
		"hurt",
		"dead"
	]

	for anim_name in non_looping:

		if sprite.sprite_frames.has_animation(anim_name):
			sprite.sprite_frames.set_animation_loop(anim_name, false)

func _setup_inputs() -> void:

	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_key("move_up", KEY_W)
	_add_key("move_down", KEY_S)

	_add_key("jump", KEY_SPACE)
	_add_key("dash", KEY_SHIFT)
	
	_add_key("climb_obstacle", KEY_O)
	_add_key("switch_player", KEY_Q)
	_add_key("wall_stick", KEY_SHIFT)

	_add_mouse("attack1", MOUSE_BUTTON_LEFT)
	_add_mouse("attack2", MOUSE_BUTTON_RIGHT)

func _add_key(action: String, key: Key) -> void:

	if InputMap.has_action(action):
		return

	InputMap.add_action(action)

	var event := InputEventKey.new()
	event.physical_keycode = key

	InputMap.action_add_event(action, event)

func _add_mouse(action: String, button: MouseButton) -> void:

	if InputMap.has_action(action):
		return

	InputMap.add_action(action)

	var event := InputEventMouseButton.new()
	event.button_index = button

	InputMap.action_add_event(action, event)

func set_locked(state: bool):
	$CollisionShape2D.disabled = state
	visible = not state
	
	# stop movement when locked
	if state:
		velocity = Vector2.ZERO

func _create_ghost() -> void:
	if not sprite.sprite_frames: return
	var ghost = Sprite2D.new()
	var tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex: return
	ghost.texture = tex
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(0.5, 0.5, 1.0, 0.8) # Purplish/bluish ghost
	
	get_tree().current_scene.add_child(ghost)
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)

func _start_obstacle_climb() -> void:
	is_climbing_obstacle = true
	attacking = false
	dashing = false
	velocity = Vector2.ZERO
	
	if sprite.sprite_frames.has_animation("climb"):
		sprite.play("climb")
		
	if is_instance_valid(col_shape):
		col_shape.disabled = true
		
	await get_tree().create_timer(1.0).timeout
	
	if sprite.sprite_frames.has_animation("climb_once"):
		sprite.play("climb_once")
		
	await get_tree().create_timer(0.5).timeout
	
	if is_instance_valid(col_shape):
		col_shape.disabled = false
		
	is_climbing_obstacle = false

func _switch_to_assister() -> void:
	if not can_switch or current_mode == 1:
		return
		
	current_mode = 1
	can_switch = false
	
	var assister_pack = load(assister_scene_path)
	if assister_pack:
		assister_instance = assister_pack.instantiate()
		get_parent().add_child(assister_instance)
		assister_instance.global_position = global_position
		
		# Hide fighter and disable collision
		sprite.visible = false
		if is_instance_valid(col_shape):
			col_shape.disabled = true
			
		print("Switched to Assister")

func _revert_to_fighter() -> void:
	if current_mode == 0: return
	
	current_mode = 0
	cooldown_timer = 1.0
	can_switch = false
	
	if is_instance_valid(assister_instance):
		global_position = assister_instance.global_position
		assister_instance.queue_free()
		
	sprite.visible = true
	if is_instance_valid(col_shape):
		col_shape.disabled = false
		
	print("Reverted to Fighter")
