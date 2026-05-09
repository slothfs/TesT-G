extends CharacterBody2D

@export var speed = 100
@export var jump_force = -350
@export var gravity = 900
@export var health = 5

var player
var dead = false
var attacking = false
var sliding = false

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

	# During attack/slide
	if attacking or sliding:
		move_and_slide()
		return

	var distance = global_position.distance_to(player.global_position)

	# Random slide chance while chasing
	if distance > 70 and randi() % 250 == 0:
		random_slide(dir)
		return

	# Attack when close
	if distance < 70:
		attack()

	# Chase player
	else:
		velocity.x = dir * speed

		if is_on_floor():
			play_anim("run")

	move_and_slide()


func attack():

	attacking = true

	var dir = sign(player.global_position.x - global_position.x)

	var attack_num = randi() % 2

	match attack_num:

		# Sword attack
		0:

			play_anim("attack")

			velocity.x = dir * 120

			await get_tree().create_timer(0.4).timeout

			velocity.x = 0


		# Kick attack
		1:

			play_anim("kick")

			velocity.x = dir * 80

			await get_tree().create_timer(0.5).timeout

			velocity.x = 0

	attacking = false


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
