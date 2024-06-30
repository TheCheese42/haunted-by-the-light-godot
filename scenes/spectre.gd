extends AnimatedSprite2D


@onready var player = get_tree().root.get_node("World/Player")
@onready var started := false
var speed = 310
const SPEED_GAIN_PER_SECOND_SPECTRE = 1.2
const SPECTRE_SPEED_CAP = 5


func start() -> void:
	play("awake")
	await get_tree().create_timer(1.4).timeout
	play("moving")
	$PointLight2D.position = Vector2(-4.5, 7.25)
	started = true


func _ready() -> void:
	play("idle")


func _process(delta: float) -> void:
	if started:
		speed += SPEED_GAIN_PER_SECOND_SPECTRE * delta
		if speed - player.player_speed > 5:
			speed = player.player_speed + 5
		elif speed - player.player_speed < -5:
			speed = player.player_speed - 5
		global_position.x += speed * delta
		global_position.y = player.global_position.y

	if get_tree().root.get_node("World").what_biome(global_position) == "dark":
		started = false


func _on_body_entered(_body: Node2D) -> void:
	get_tree().call_group("player", "kill")
