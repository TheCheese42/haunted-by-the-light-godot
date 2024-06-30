extends CenterContainer


func _ready() -> void:
	get_tree().call_group("fade_overlay", "start_fade_in", 250)
	await get_tree().create_timer(4.0).timeout
	get_tree().call_group("fade_overlay", "start_fade_out", 250, _back_to_world)


func _back_to_world() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/world.tscn")
