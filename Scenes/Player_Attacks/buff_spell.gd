extends Area2D

func _ready():
	# Make it visually distinct and fade out over time
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 5.0)
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _process(delta):
	# Spin the visual
	rotation += 3.0 * delta