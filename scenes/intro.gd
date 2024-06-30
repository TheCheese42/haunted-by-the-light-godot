extends CenterContainer


var _second_text_texture = load("res://assets/textures/text/intro/when_there_was_no_dark_mode.png")


func _ready() -> void:
	get_tree().call_group("fade_overlay", "start_fade_in", 350)
	await get_tree().create_timer(2.0).timeout
	get_tree().call_group("fade_overlay", "start_fade_out", 350, _second_text)


func _second_text() -> void:
	$Control/TextureRect.texture = _second_text_texture
	get_tree().call_group("fade_overlay", "start_fade_in", 350)
	await get_tree().create_timer(2.5).timeout
	get_tree().call_group("fade_overlay", "start_fade_out", 350, _switch_to_world)


func _switch_to_world() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")
