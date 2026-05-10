extends Area2D

@export var speed: float = 400.0
@export var fall_gravity: float = 600.0
var velocity: Vector2 = Vector2.ZERO
var direction: int = 1
var is_active: bool = true

@onready var sprite = $Sprite2D
@onready var particles = $GPUParticles2D

func _ready() -> void:
	# Initial velocity
	velocity = Vector2(direction * speed, -250.0)
	
	# Connect signals
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	velocity.y += fall_gravity * delta
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
		
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		explode_and_die()
	elif body is TileMap or body.is_class("TileMapLayer") or body is StaticBody2D or body.name == "Ground":
		# Assume it hit the ground/wall
		explode_and_die()
	elif "collision_layer" in body and (body.collision_layer & 1) != 0:
		explode_and_die()

func explode_and_die() -> void:
	is_active = false
	
	# Hide sprite and stop trail
	if sprite:
		sprite.visible = false
	if particles:
		particles.emitting = false
	
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Create explosion particles
	var explosion = CPUParticles2D.new()
	explosion.emitting = true
	explosion.one_shot = true
	explosion.amount = 15
	explosion.lifetime = 0.5
	explosion.explosiveness = 0.9
	explosion.spread = 180.0
	explosion.gravity = Vector2(0, 200)
	explosion.initial_velocity_min = 50.0
	explosion.initial_velocity_max = 120.0
	explosion.scale_amount_min = 2.0
	explosion.scale_amount_max = 4.0
	explosion.color = Color(0.5, 0.5, 0.5) # Grey rock
	add_child(explosion)
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
