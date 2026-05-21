extends CharacterBody2D
class_name Fighter

const SPEED = 250.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.2

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_attacking: bool = false
var is_dashing: bool = false
var is_hurt: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 1.0
var health: int = 100

var max_jumps: int = 2
var jumps_left: int = 2

# Combo system variables
var combo_step: int = 0
var combo_timer: float = 0.0
var next_attack_queued: bool = false
const COMBO_WINDOW: float = 0.3

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Make certain animations non-looping so they finish properly
	var non_looping = [
		"dash", "dash_a", "dash_attack", "dead", "down_attack", 
		"front_attackM1", "front_attackM2", "hurt", "idle_attack", "up_attack"
	]
	for anim_name in non_looping:
		if anim.sprite_frames.has_animation(anim_name):
			anim.sprite_frames.set_animation_loop(anim_name, false)
			
	anim.animation_finished.connect(_on_animation_finished)
	
	# Register default inputs if they don't exist
	_ensure_input_action("move_left", KEY_A)
	_ensure_input_action("move_right", KEY_D)
	_ensure_input_action("move_up", KEY_W)
	_ensure_input_action("move_down", KEY_S)
	_ensure_input_action("jump", KEY_SPACE)
	_ensure_input_action("dash", KEY_SHIFT)
	_ensure_input_mouse_action("attack1", MOUSE_BUTTON_LEFT)
	_ensure_input_mouse_action("attack2", MOUSE_BUTTON_RIGHT)

func _ensure_input_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event = InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)

func _ensure_input_mouse_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event = InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action_name, event)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	is_attacking = false
	is_dashing = false
	combo_step = 0
	next_attack_queued = false
	if health <= 0:
		anim.play("dead")
	else:
		is_hurt = true
		anim.play("hurt")

func _physics_process(delta: float) -> void:
	if anim.animation == "dead":
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return
		
	if is_hurt:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return
		
	# Combo timer ticks down when not attacking
	if not is_attacking and combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_step = 0 # Reset combo if we wait too long

	if is_dashing:
		velocity.y = 0
		velocity.x = dash_direction * DASH_SPEED
		dash_timer -= delta
		
		# Allow attacking during dash
		if Input.is_action_just_pressed("attack1"):
			is_dashing = false
			is_attacking = true
			combo_step = 0
			anim.play("dash_attack")
			return
			
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = max_jumps

	# Handle attacks
	if Input.is_action_just_pressed("attack1"):
		if not is_attacking:
			_start_attack()
		else:
			# Queue the next attack if we are already attacking
			next_attack_queued = true
			
		if is_on_floor():
			velocity.x = 0
		return

	# Right click for an alternative heavy attack
	if Input.is_action_just_pressed("attack2") and not is_attacking:
		is_attacking = true
		combo_step = 0 # Reset normal combo
		anim.play("front_attackM2")
		if is_on_floor():
			velocity.x = 0
		return

	if is_attacking:
		move_and_slide()
		return

	# Handle jump
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		# Restart jump animation if it's the second jump
		if not is_on_floor():
			anim.play("jump")
			anim.set_frame_and_progress(0, 0.0)
		
	# Handle dash
	if Input.is_action_just_pressed("dash") and is_on_floor():
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_direction = -1.0 if anim.flip_h else 1.0
		anim.play("dash")
		return

	# Movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	_update_animation(direction)
	move_and_slide()

func _start_attack() -> void:
	is_attacking = true
	combo_timer = 0.0 # Reset timer while attacking
	
	if Input.is_action_pressed("move_up"):
		anim.play("up_attack")
		combo_step = 0
	elif Input.is_action_pressed("move_down"):
		anim.play("down_attack")
		combo_step = 0
	else:
		# Ground combo sequence
		if combo_step == 0:
			anim.play("front_attackM1")
			combo_step = 1
		elif combo_step == 1:
			anim.play("front_attackM2")
			combo_step = 2
		elif combo_step == 2:
			anim.play("idle_attack")
			combo_step = 0 # End of combo

func _update_animation(direction: float) -> void:
	if is_attacking or is_dashing or is_hurt or anim.animation == "dead":
		return
		
	if not is_on_floor():
		if velocity.y < -50.0:
			anim.play("jump")
		elif velocity.y > 50.0:
			anim.play("fall")
		else:
			anim.play("mid_air")
	else:
		if direction != 0:
			anim.play("run")
		else:
			anim.play("idle")

func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		if next_attack_queued:
			next_attack_queued = false
			_start_attack()
		else:
			# Start the window where player can continue the combo
			combo_timer = COMBO_WINDOW
			
	if is_dashing and (anim.animation == "dash" or anim.animation == "dash_a" or anim.animation == "dash_attack"):
		is_dashing = false
		
	if is_hurt and anim.animation == "hurt":
		is_hurt = false
