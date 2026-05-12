extends CharacterBody2D

@export var speed = 100
@export var jump_force = -350
@export var gravity = 900
@export var health = 5

var player
var dead = false
var attacking = false
var sliding = false
var throwing = false

@onready var sprite = $AnimatedSprite2D


func _ready():
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta):

	if dead:
		return

	# Gravity
	velocity.y += gravity * delta

	if player == null:
		move_and_slide()
		return

	var dir = sign(player.global_position.x - global_position.x)

	# Flip sprite
	sprite.flip_h = dir < 0

	# Lock movement during actions
	if attacking or sliding or throwing:
		move_and_slide()
		return

	var distance = global_position.distance_to(player.global_position)

	# Random slide
	if distance > 70 and randi() % 250 == 0:
		random_slide(dir)
		return

	# Random THROW (mid/long range)
	if distance > 80 and distance < 400 and randi() % 180 == 0:
		throw_projectile(dir)
		return

	# Attack when close
	if distance < 70:
		attack()
	else:
		# Chase
		velocity.x = dir * speed

		if is_on_floor():
			play_anim("run")

	move_and_slide()


func attack():
	attacking = true

	var dir = sign(player.global_position.x - global_position.x)
	var attack_num = randi() % 2

	match attack_num:

		0:
			play_anim("attacking")
			velocity.x = dir * 120
			await get_tree().create_timer(0.4).timeout
			velocity.x = 0

		1:
			play_anim("kick")
			velocity.x = dir * 80
			await get_tree().create_timer(0.5).timeout
			velocity.x = 0

	attacking = false


func throw_projectile(dir):
	throwing = true

	play_anim("throwing")

	velocity.x = 0

	# wait for throw animation timing
	await get_tree().create_timer(0.35).timeout

	var rock = preload("res://Scenes/OBJ/rock.tscn").instantiate()
	rock.global_position = global_position + Vector2(dir * 20, -40)
	rock.direction = dir
	get_tree().current_scene.add_child(rock)

	await get_tree().create_timer(0.2).timeout

	throwing = false


func random_slide(dir):
	sliding = true

	play_anim("slide")

	velocity.x = dir * 350

	await get_tree().create_timer(0.7).timeout

	velocity.x = 0
	sliding = false


func take_damage(amount):
	if dead:
		return

	health -= amount
	play_anim("hurt")

	await get_tree().create_timer(0.4).timeout

	if health <= 0:
		die()


func die():
	dead = true
	velocity = Vector2.ZERO

	play_anim("dying")

	await get_tree().create_timer(1.0).timeout
	queue_free()


func play_anim(anim):
	if sprite.animation != anim:
		sprite.play(anim)
