extends Area2D

@onready var label = $Label

var text = "Hello World!"
var index = 0
var typing_speed = 0.08


func _ready():
	label.text = ""
	label.hide()


func _on_body_entered(body):
	if body.name == "Player":
		label.show()
		index = 0
		label.text = ""

		type_text()


func type_text():
	while index < text.length():
		label.text += text[index]
		index += 1
		await get_tree().create_timer(typing_speed).timeout


func _on_body_exited(body):
	if body.name == "Player":
		label.text = ""
		label.hide()
