extends CanvasLayer

signal countdown_finished

@onready var label = $Label

func start():
	get_tree().paused = true
	label.visible = true
	run_countdown()

func run_countdown():
	await show_number(3)
	await show_number(2)
	await show_number(1)

	label.text = "GO!"
	await get_tree().create_timer(0.8).timeout

	label.visible = false
	get_tree().paused = false

	countdown_finished.emit()
	queue_free()

func show_number(n):
	label.text = str(n)
	await get_tree().create_timer(1.0).timeout
