extends CharacterBody2D
	class_name AdvancedPlayer
	
	# --- Movement Properties ---
	@export var speed: float = 300.0
	@export var jump_velocity: float = -400.0
	@export var wall_climb_speed: float = 150.0
	
	# --- Assister/Fighter Mode Properties ---
	@export var assister_duration: float = 5.0
	@export var switch_cooldown: float = 1.0
	
	# Form states
	enum Mode { FIGHTER, ASSISTER }
	var current_mode: Mode = Mode.FIGHTER
	
	# Action states
	var is_sticking: bool = false
	var is_climbing_obstacle: bool = false
	var is_attacking: bool = false
	var can_switch: bool = true
	
	# Physics
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# Nodes
	@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
	@onready var collision_shape: CollisionShape2D = $CollisionShape2D
	
	var assister_timer: Timer
	var cooldown_timer: Timer
	
	func _ready() -> void:
		# Ensure inputs exist
		_setup_inputs()
		
		# Setup mode switch timers
		assister_timer = Timer.new()
		assister_timer.one_shot = true
		assister_timer.timeout.connect(_on_assister_timeout)
		add_child(assister_timer)
		
		cooldown_timer = Timer.new()
		cooldown_timer.one_shot = true
		cooldown_timer.timeout.connect(_on_cooldown_timeout)
		add_child(cooldown_timer)
		
		# Connect to animation finished to detect when M1 attack is done
		if is_instance_valid(animated_sprite):
			animated_sprite.animation_finished.connect(_on_animation_finished)
	
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			# 1. Left Click: Attack (M1)
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not is_attacking and not is_sticking:
					is_attacking = true
					# Stop horizontal momentum when attacking on the floor
					if is_on_floor():
						velocity.x = 0
					if is_instance_valid(animated_sprite):
						animated_sprite.play("m1")
	
	func _physics_process(delta: float) -> void:
		# Disable normal input & movement if climbing an obstacle
		if is_climbing_obstacle:
			move_and_slide()
			return
	
		_handle_inputs()
		_handle_movement(delta)
		_handle_animations()
		
		move_and_slide()
	
	func _handle_inputs() -> void:
		# 2. 'S' Key: Switch to Assister
		if Input.is_action_just_pressed("switch_player"):
			_switch_to_assister()
			
		# 3. Shift key (Wall Stick): Stick to wall
		if Input.is_action_just_pressed("wall_stick"):
			if is_on_wall_only() or is_sticking:
				# If near a wall or currently sticking, toggle wall stick
				is_sticking = not is_sticking
				if is_sticking:
					velocity = Vector2.ZERO # Stop momentum when adhering to wall
	
		# 4. Spacebar: Jump
		if Input.is_action_just_pressed("jump") and not is_attacking:
			if is_on_floor():
				# Normal floor jump
				velocity.y = jump_velocity
			elif is_sticking:
				# Wall jump (push away from the wall)
				is_sticking = false
				velocity.y = jump_velocity
				velocity.x = get_wall_normal().x * speed
	
		# 5. 'O' key: Climb through obstacle
		if Input.is_action_just_pressed("climb_obstacle") and not is_climbing_obstacle:
			_start_obstacle_climb()
	
	func _handle_movement(delta: float) -> void:
		if is_sticking:
			# Wall sticking movement (up and down) using A (up) and D (down)
			# ui_left (A) gives -1 which moves UP (negative Y)
			# ui_right (D) gives +1 which moves DOWN (positive Y)
			var vertical_input := Input.get_axis("ui_left", "ui_right")
			velocity.y = vertical_input * wall_climb_speed
			velocity.x = 0 # Prevent drifting away from wall
		else:
			# Apply gravity
			if not is_on_floor():
				velocity.y += gravity * delta
	
			# Horizontal movement (A/D or Left/Right arrows)
			# Prevent moving while attacking on the ground
			if is_attacking and is_on_floor():
				velocity.x = move_toward(velocity.x, 0, speed)
			else:
				var direction := Input.get_axis("ui_left", "ui_right")
				if direction != 0:
					velocity.x = direction * speed
				else:
					velocity.x = move_toward(velocity.x, 0, speed)
	
	func _handle_animations() -> void:
		if not is_instance_valid(animated_sprite):
			return
	
		# Prevent standard animations from overriding the attack animation
		if is_attacking:
			return
	
		if is_sticking:
			if velocity.y != 0:
				# Moving up and down the wall
				animated_sprite.play("up_and_down_after_stiking_to_wall")
			else:
				# Idle on wall
				animated_sprite.play("sticking_to_wall")
		elif not is_on_floor():
			# In the air
			animated_sprite.play("jump")
		elif velocity.x != 0:
			# Running
			animated_sprite.flip_h = velocity.x < 0
			animated_sprite.play("run_right")
		else:
			# Standing still
			animated_sprite.play("idle")
	
	# Reset attack state when animation finishes
	func _on_animation_finished() -> void:
		if is_instance_valid(animated_sprite):
			if animated_sprite.animation == "m1":
				is_attacking = false
	
	func _start_obstacle_climb() -> void:
		is_climbing_obstacle = true
		is_attacking = false
		velocity = Vector2.ZERO
		
		if is_instance_valid(animated_sprite):
			animated_sprite.play("climb")
			
		# Disable collisions to pass through obstacles
		if is_instance_valid(collision_shape):
			collision_shape.disabled = true
			
		# Wait for the initial climb animation sequence
		await get_tree().create_timer(1.0).timeout
		
		if is_instance_valid(animated_sprite):
			animated_sprite.play("climb_once")
			
		# Finish climbing obstacle
		await get_tree().create_timer(0.5).timeout
		
		# Restore collisions
		if is_instance_valid(collision_shape):
			collision_shape.disabled = false
			
		is_climbing_obstacle = false
	
	func _switch_to_assister() -> void:
		# Only switch if cooldown is finished and we're currently Fighter
		if not can_switch or current_mode == Mode.ASSISTER:
			return
			
		current_mode = Mode.ASSISTER
		can_switch = false
		
		# Start 5-second assister duration
		assister_timer.start(assister_duration)
		
		# Optional Visual Feedback for Assister mode (e.g. blue tint)
		if is_instance_valid(animated_sprite):
			animated_sprite.modulate = Color(0.5, 0.8, 1.0)
			
		print("Switched to Assister Mode")
	
	func _on_assister_timeout() -> void:
		# Automatically revert to Fighter after 5 seconds
		current_mode = Mode.FIGHTER
		
		# Remove visual feedback tint
		if is_instance_valid(animated_sprite):
			animated_sprite.modulate = Color(1.0, 1.0, 1.0)
			
		# Start 1-second cooldown before they can switch again
		cooldown_timer.start(switch_cooldown)
		print("Reverted to Fighter Mode")
	
	func _on_cooldown_timeout() -> void:
		can_switch = true
		print("Switch Cooldown Complete")
	
	# Helper function to map required inputs automatically
	func _setup_inputs() -> void:
		_add_key("ui_left", KEY_A)
		_add_key("ui_right", KEY_D)
		_add_key("ui_up", KEY_W)
		_add_key("ui_down", KEY_S)
		
		_add_key("jump", KEY_SPACE)
		_add_key("climb_obstacle", KEY_O)
		_add_key("wall_stick", KEY_SHIFT)
		_add_key("switch_player", KEY_S)
	
	func _add_key(action: String, key: Key) -> void:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		var event := InputEventKey.new()
		event.physical_keycode = key
		
		var has_event = false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventKey and existing.physical_keycode == key:
				has_event = true
				break
				
		if not has_event:
			InputMap.action_add_event(action, event)
	
	func _add_mouse(action: String, button: MouseButton) -> void:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			
		var event := InputEventMouseButton.new()
		event.button_index = button
		
		var has_event = false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventMouseButton and existing.button_index == button:
				has_event = true
				break
				
		if not has_event:
			InputMap.action_add_event(action, event)
	
