@tool
extends EditorScript

func _run():
	var settings = EditorInterface.get_editor_settings()
	settings.set_setting("interface/theme/preset", "Default")
	settings.set_setting("interface/theme/base_color", Color(0.2, 0.2, 0.2))
	print("Theme reset")
