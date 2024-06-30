extends CanvasLayer


func _on_continue_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().call_group("world", "toggle_pause")


func _on_quit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().call_group("world", "end")
			get_tree().change_scene_to_file("res://scenes/world.tscn")
