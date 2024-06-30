extends CharacterBody2D

var started := false
var ended := false
var paused := false

var player_speed := 300.0
const SPEED_GAIN_PER_SECOND = 3.5
const JUMP_VELOCITY = -1300.0

var jump_requested_time := 0.0


func _ready() -> void:
	$AnimatedSprite2D.play("idle")


func start() -> void:
	velocity.y = JUMP_VELOCITY
	await get_tree().create_timer(1.2).timeout
	$AnimatedSprite2D.play("moving")
	started = true


func kill() -> void:
	$AnimatedSprite2D.play("dead")
	ended = true
	velocity = Vector2.ZERO
	get_tree().root.get_node("World/Spectre").started = false

	var after_fade = _restart_game
	var hearts = get_tree().root.get_node("World/Hearts/HeartsControl/HeartsMargin/HBoxContainer")
	var right_most_cp = null
	var right_most_cp_local = null
	var right_most_cp_layer = null
	var right_most_cp_data = null
	if hearts.get_child_count() > 0:
		for map in get_tree().root.get_node("World/Maps").get_children():
			var checkpoints: TileMapLayer = map.find_child("checkpoints", true, false)
			for checkpoint: Vector2i in checkpoints.get_used_cells():
				var cp_data = checkpoints.get_cell_tile_data(checkpoint)
				if cp_data.get_custom_data("active"):
					checkpoint.x -= 1  # For some reason 1 tile right to the actual checkpoint...
					var global_checkpoint = map_to_global(checkpoints, checkpoint, 4, checkpoints.global_position)
					if right_most_cp == null or right_most_cp.x < global_checkpoint.x:
						right_most_cp = global_checkpoint
						right_most_cp_local = checkpoint
						right_most_cp_layer = checkpoints
						right_most_cp_data = cp_data
		if right_most_cp:
			hearts.get_child(-1).queue_free()
			right_most_cp.x -= 1
			player_speed = right_most_cp_data.get_custom_data("velocity")
			after_fade = _start_from_checkpoint.bind(right_most_cp)
			right_most_cp_local.x += 1

	await get_tree().create_timer(0.4).timeout
	get_tree().call_group("fade_overlay", "start_fade_out", 200, after_fade)
	await get_tree().create_timer(5.4).timeout
	right_most_cp_layer.set_cell(right_most_cp_local)


func _restart_game() -> void:
	get_tree().call_group("world", "end")
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _start_from_checkpoint(cp_pos: Vector2) -> void:
	global_position = cp_pos
	get_tree().root.get_node("World/Spectre").global_position.x = global_position.x - 320
	get_tree().root.get_node("World/Spectre").global_position.y = global_position.y
	$AnimatedSprite2D.play("idle")
	get_tree().call_group("fade_overlay", "start_fade_in", 200)
	await get_tree().create_timer(4.0).timeout
	ended = false
	$AnimatedSprite2D.play("moving")
	get_tree().root.get_node("World/Spectre").started = true


func map_to_global(map: TileMapLayer, tile: Vector2i, scale_: float = 1.0, offset: Vector2 = Vector2.ZERO) -> Vector2:
	return map.map_to_local(tile) * scale_ + offset


func win() -> void:
	$AnimatedSprite2D.play("victory")
	ended = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(2.0).timeout
	get_tree().call_group("fade_overlay", "start_fade_out", 200, _change_to_outro)

func _change_to_outro() -> void:
	get_tree().call_group("world", "end")
	get_tree().change_scene_to_file("res://scenes/outro.tscn")


func _process(delta: float) -> void:
	if paused:
		return

	if not started:
		pass
	
	elif ended:
		pass
	
	else:
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
			else:
				jump_requested_time = Time.get_unix_time_from_system()
		elif jump_requested_time:
			if jump_requested_time > Time.get_unix_time_from_system() - 0.1:
				if is_on_floor():
					velocity.y = JUMP_VELOCITY
			else:
				jump_requested_time = 0.0
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if not is_on_floor() and Input.is_action_just_released("jump"):
			var stop_jump_value = -800 * (velocity.y / JUMP_VELOCITY)
			if velocity.y < stop_jump_value:
				velocity.y = stop_jump_value

		player_speed += SPEED_GAIN_PER_SECOND * delta
		velocity.x = player_speed
	
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var obstacle_layers = []
			for map in get_tree().root.get_node("World/Maps").get_children():
				var ice_obstacles: TileMapLayer = map.find_child("ice_obstacles", true, false)
				var obs_obstacles: TileMapLayer = map.find_child("obs_obstacles", true, false)
				obstacle_layers.append(ice_obstacles)
				obstacle_layers.append(obs_obstacles)
			if collision.get_collider() in obstacle_layers:
				kill()

	if not ended:
		if not is_on_floor():
			velocity += get_gravity() * delta
	move_and_slide()

	if global_position.y > 1000 and not ended:
		kill()
	if global_position.x > 61200 and not ended:
		win()
