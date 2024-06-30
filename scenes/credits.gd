extends CenterContainer

@onready var rich_text_label = $RichTextLabel
@onready var tween = get_tree().create_tween()

func _ready():
	start_credits_scroll()

func start_credits_scroll():
	var credits_text = "[center][font_size=48]Haunted by the Light[/font_size]\n"
	credits_text += "[font_size=24]by TheCheese[/font_size]\n\n\n\n\n\n\n\n"
	credits_text += "[font_size=36]Credits[/font_size]\n\n"
	credits_text += "[font_size=24]Music (Menu) - 'Mysterious Sewer' by smark (CC0)\nMusic (Grass) - 'Overworld/Menu' by Umplix (CC0)\nMusic (Ice) - 'Horizon' by HitCtrl (CC-BY 3.0) [Modified: Reduced Quality]\n(https://creativecommons.org/licenses/by/3.0/)\nMusic (Obsidian) -  'Dungeon Ambience' by yd (CC0)[/font_size][/center]"
	
	rich_text_label.bbcode_text = credits_text
	$".".global_position.y = 800
	
	var label_height = rich_text_label.get_content_height()
	var scroll_duration = label_height / 20.0
	
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($".", "global_position:y", -1000, scroll_duration)
	tween.play()
	
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _process(_delta) -> void:
	if Input.is_action_just_pressed("quit_credits"):
		get_tree().change_scene_to_file("res://scenes/world.tscn")
