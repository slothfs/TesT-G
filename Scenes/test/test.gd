extends Node

@onready var CountdownScene = preload("res://Scenes/UI/count_down.tscn")

func _ready():
	var countdown = CountdownScene.instantiate()
	add_child(countdown)

	$Player.set_locked(true)

	countdown.countdown_finished.connect(func():
		$Player.set_locked(false)
	)

	countdown.start()
	
func _process(delta):
	if Input.is_action_just_pressed("reload"):
		get_tree().reload_current_scene()
