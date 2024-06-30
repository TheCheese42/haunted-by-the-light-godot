extends Node2D


var maps = load("res://scenes/maps.tscn").instantiate()
const map_size = 30
const tile_size = 16
const tile_scale = 4
const total_tile_size = tile_size * tile_scale
const total_map_size = map_size * total_tile_size
const maps_per_biome = 10
const grass_maps_start = total_map_size
const ice_maps_start = total_map_size * 11
const obs_maps_start = total_map_size * 21
const dark_maps_start = total_map_size * 31

var started := false
var paused := false

var last_biome: String = "init"
var stars_offset_map := {}
var clouds_offset_map := {}
var butterflies_offset_map := {}
var ice_transition_done := false
var obs_transition_done := false
var points := 0
var highscore_beaten := false
var highscore: int
var best_score_in_run := 0
var do_not_set_score := false
@onready var player_start_pos = $Player.global_position.x


func what_biome(pos: Vector2) -> String:
	if pos.x < grass_maps_start - total_tile_size:
		return "init"
	elif pos.x < ice_maps_start - total_tile_size:
		return "grass"
	elif pos.x < obs_maps_start - total_tile_size:
		return "ice"
	elif pos.x < dark_maps_start - total_tile_size:
		return "obs"
	else:
		return "dark"


func _ready() -> void:
	$MenuMusic.play()
	var data: SaveData = load("user://savedata.tres")
	if data == null:
		data = SaveData.new()
	highscore = data.highscore
	$Points/MarginContainer/PointsLabel.text = "Highscore: " + str(highscore)
	$Spectre.global_position.x = $Player.global_position.x - 512.0
	$Spectre.global_position.y = $Player.global_position.y

	var map_nodes = maps.get_children()
	var init_map: Node2D = map_nodes[0]
	init_map.scale = Vector2(tile_scale, tile_scale)
	init_map.visible = true
	var grass_maps: Array[Node] = map_nodes[1].get_children()
	grass_maps.shuffle()
	for gmap in grass_maps:
		gmap.scale = Vector2(tile_scale, tile_scale)
	var ice_maps: Array[Node] = map_nodes[2].get_children()
	ice_maps.shuffle()
	for imap in ice_maps:
		imap.scale = Vector2(tile_scale, tile_scale)
	var obs_maps: Array[Node] = map_nodes[3].get_children()
	obs_maps.shuffle()
	for omap in obs_maps:
		omap.scale = Vector2(tile_scale, tile_scale)
	var dark_map: Node2D = map_nodes[4]
	dark_map.scale = Vector2(tile_scale, tile_scale)
	dark_map.visible = true

	var cur_pos = Vector2.ZERO

	init_map.global_position = cur_pos
	var duped_init_map = init_map.duplicate(DUPLICATE_USE_INSTANTIATION)
	$Maps.add_child(duped_init_map)
	$Maps.move_child(duped_init_map, 0)
	cur_pos.x += total_map_size

	while maps_per_biome - len(grass_maps) > 0:
		grass_maps.append(grass_maps[randi() % grass_maps.size()])
	for gmap in grass_maps:
		gmap.global_position = cur_pos
		var duped_gmap = gmap.duplicate(DUPLICATE_USE_INSTANTIATION)
		$Maps.add_child(duped_gmap)
		$Maps.move_child(duped_gmap, 0)
		cur_pos.x += total_map_size
	
	while maps_per_biome - len(ice_maps) > 0:
		ice_maps.append(ice_maps[randi() % ice_maps.size()])
	for imap: Node2D in ice_maps:
		imap.global_position = cur_pos
		var duped_imap = imap.duplicate(DUPLICATE_USE_INSTANTIATION)
		$Maps.add_child(duped_imap)
		$Maps.move_child(duped_imap, 0)
		cur_pos.x += total_map_size
	
	while maps_per_biome - len(obs_maps) > 0:
		obs_maps.append(obs_maps[randi() % obs_maps.size()])
	for omap in obs_maps:
		omap.global_position = cur_pos
		var duped_omap = omap.duplicate(DUPLICATE_USE_INSTANTIATION)
		$Maps.add_child(duped_omap)
		$Maps.move_child(duped_omap, 0)
		cur_pos.x += total_map_size
	
	dark_map.global_position = cur_pos
	var duped_dark_map = dark_map.duplicate(DUPLICATE_USE_INSTANTIATION)
	$Maps.add_child(duped_dark_map)
	$Maps.move_child(duped_dark_map, 0)
	cur_pos.x += total_map_size
	
	for map in $Maps.get_children():
		if map.name in ["init_map", "darkness"]:
			continue
		var walls: TileMapLayer = map.find_child("walls", true, false)
		var checkpoints: TileMapLayer = map.find_child("checkpoints", true, false)
		var ice_obstacles: TileMapLayer = map.find_child("ice_obstacles", true, false)
		var obs_obstacles: TileMapLayer = map.find_child("obs_obstacles", true, false)
		for wall: Vector2i in walls.get_used_cells():
			var wall_data = walls.get_cell_tile_data(wall)
			if wall_data.get_custom_data("checkable"):
				if (
					not map.name.begins_with("obsidian") and randf() < 0.02
					or map.name.begins_with("obsidian") and randf() < 0.015
				):
					var can_set := true
					var cp_pos := wall
					cp_pos.y -= 1
					for ice_obstacle: Vector2i in ice_obstacles.get_used_cells():
						if ice_obstacle == cp_pos:
							can_set = false
					for obs_obstacle: Vector2i in obs_obstacles.get_used_cells():
						if obs_obstacle == cp_pos:
							can_set = false
					for wall_obstacle: Vector2i in walls.get_used_cells():
						if wall_obstacle == cp_pos:
							can_set = false
					if can_set:
						checkpoints.set_cell(cp_pos, 6, Vector2i(0, 0))
	
	get_tree().call_group("fade_overlay", "start_fade_in", 500)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		if $Player.started != true:
			start()
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	if Input.is_action_just_pressed("pause"):
		toggle_pause()

	if started:
		for map in $Maps.get_children():
			var checkpoints: TileMapLayer = map.find_child("checkpoints", true, false)
			for checkpoint: Vector2i in checkpoints.get_used_cells():
				var cp_data = checkpoints.get_cell_tile_data(checkpoint)
				if not cp_data.get_custom_data("active"):
					if (
						$Player.global_position.x > map_to_global(checkpoints, checkpoint, tile_scale, checkpoints.global_position).x - total_tile_size
						and $Player.global_position.x < map_to_global(checkpoints, checkpoint, tile_scale, checkpoints.global_position).x - total_tile_size / 2.0
						and $Player.global_position.y <= map_to_global(checkpoints, checkpoint, tile_scale, checkpoints.global_position).y + total_tile_size
					):
						checkpoints.set_cell(checkpoint, 7, Vector2i(0, 0))
						var new_cp_data = checkpoints.get_cell_tile_data(checkpoint)
						new_cp_data.set_custom_data("velocity", $Player.player_speed)
			var ice_obstacles: TileMapLayer = map.find_child("ice_obstacles", true, false)
			for obstacle: Vector2i in ice_obstacles.get_used_cells():
				var ob_data = ice_obstacles.get_cell_tile_data(obstacle)
				if not ob_data.get_custom_data("falling"):
					if (
						map_to_global(ice_obstacles, obstacle, tile_scale, ice_obstacles.global_position).y < -500
						and $Player.global_position.x > map_to_global(ice_obstacles, obstacle, tile_scale, ice_obstacles.global_position).x - 350
					):
						if ice_obstacles.get_cell_atlas_coords(obstacle) == Vector2i(0, 1):
							var sprite = Sprite2D.new()
							sprite.texture = load("res://assets/textures/ice/stalactite.png")
							sprite.texture_filter = sprite.TEXTURE_FILTER_NEAREST
							sprite.visible = true
							ice_obstacles.add_child(sprite)
							sprite.global_position = map_to_global(ice_obstacles, obstacle, tile_scale, ice_obstacles.global_position)
						ice_obstacles.set_cell(obstacle)
			for child in ice_obstacles.get_children():
				if is_instance_of(child, Sprite2D):
					child.global_position.y += 1000 * delta
					if child.global_position.y > 800:
						child.queue_free()

		var cur_biome = what_biome($Player.global_position)
		if cur_biome == "ice" and last_biome == "grass":
			if not ice_transition_done:
				ice_transition_done = true
				for cloud in $Clouds.get_children():
					cloud.queue_free()
				for butterfly in $Butterflies.get_children():
					butterfly.queue_free()
				$OverworldMusic.stop()
				$OverworldMusic.queue_free()
				$IceMusic.play()
				var tween = get_tree().create_tween()
				tween.tween_property($Player/Camera2D/BG, "color", Color8(0, 51, 96), 0.6)
				$IceStars.visible = true
				for i in 300:
					var star = $IceStars.get_child(0).duplicate()
					stars_offset_map[star] = Vector2(randi_range(-1500, 1500), randi_range(-1000, 1000))
					var scale_ = randi_range(1, 3)
					star.scale = Vector2(scale_, scale_)
					$IceStars.add_child(star)
				$IceStars.remove_child($IceStars.get_child(0))
				
		elif cur_biome == "obs" and last_biome == "ice":
			if not obs_transition_done:
				obs_transition_done = true
				var tween = get_tree().create_tween()
				tween.tween_property($Player/Camera2D/BG, "color", Color8(20, 20, 20), 0.6)
				$IceStars.visible = false
				$ObsStars.visible = true
				stars_offset_map.clear()
				for i in 60:
					var star = $ObsStars.get_child(0).duplicate()
					stars_offset_map[star] = Vector2(randi_range(-1500, 1500), randi_range(-1000, 1000))
					var scale_ = randi_range(1, 3)
					star.scale = Vector2(scale_, scale_)
					if scale_ == 1:
						star.play("small")
					else:
						star.play("big")
					$ObsStars.add_child(star)
				$ObsStars.remove_child($ObsStars.get_child(0))

		last_biome = cur_biome

		if obs_transition_done:
			for star in $ObsStars.get_children():
				star.global_position = $Player/Camera2D.get_screen_center_position() + stars_offset_map[star]
		elif ice_transition_done:
			for star in $IceStars.get_children():
				star.global_position = $Player/Camera2D.get_screen_center_position() + stars_offset_map[star]

		for cloud in $Clouds.get_children():
			if not cloud.visible:
				continue
			clouds_offset_map[cloud].x -= 20 * delta
			cloud.global_position = $Player/Camera2D.get_screen_center_position() + clouds_offset_map[cloud]
		for butterfly in $Butterflies.get_children():
			if not butterfly.visible:
				continue
			butterflies_offset_map[butterfly].x -= 35 * delta
			butterfly.global_position = $Player/Camera2D.get_screen_center_position() + butterflies_offset_map[butterfly]

		if started:
			points = round(($Player.global_position.x - player_start_pos) / 40.0)
			if not do_not_set_score:
				$Points/MarginContainer/PointsLabel.text = str(max(points, best_score_in_run))
			if points > highscore and not highscore_beaten and highscore != 0:
				highscore_beaten = true
				do_not_set_score = true
				$Points/MarginContainer/PointsLabel.text = "New Highscore!"
				for i in 6:
					var tween = get_tree().create_tween()
					tween.set_ease(Tween.EASE_IN_OUT)
					var target_color = Color8(0, 0, 0, 0) if i % 2 == 0 else Color8(0, 0, 0, 255)
					tween.tween_property(
						$Points/MarginContainer/PointsLabel.label_settings,
						"font_color", target_color, 0.5,
					)
					await tween.finished
				do_not_set_score = false
			if points > best_score_in_run:
				best_score_in_run = points


func map_to_global(map: TileMapLayer, tile: Vector2i, scale_: float = 1.0, offset: Vector2 = Vector2.ZERO) -> Vector2:
	return map.map_to_local(tile) * scale_ + offset


func start() -> void:
	if started:
		return
	
	started = true
	remove_child($CanvasLayer)
	remove_child($MenuMusic)
	$Hearts.visible = true
	$Spectre.start()
	$Points/MarginContainer/PointsLabel.visible = false
	
	await get_tree().create_timer(0.8).timeout
	$OverworldMusic.play()
	$Player.start()
	$CloudTimer.start()
	$ButterflyTimer.start()
	$Points/MarginContainer/PointsLabel.visible = true
	$PauseIcon.visible = true


func end() -> void:
	if highscore_beaten:
		var data = SaveData.new()
		data.highscore = best_score_in_run
		ResourceSaver.save(data, "user://savedata.tres")


func toggle_pause() -> void:
	if not started:
		return
	paused = not paused
	$Player.paused = paused
	$Spectre.started = not paused
	$Pause.visible = paused


func _on_cloud_timeout() -> void:
	if not ice_transition_done:
		var cloud = $Clouds.get_child(0).duplicate()
		cloud.visible = true
		cloud.play("cloud" + str(randi_range(1, 3)))
		clouds_offset_map[cloud] = Vector2(
			DisplayServer.window_get_size().x / 2.0 + 100.0,
			-DisplayServer.window_get_size().y / 2.0 + 200,
		)
		$Clouds.add_child(cloud)


func _on_butterfly_timeout() -> void:
	if not ice_transition_done:
		var butterfly = $Butterflies.get_child(0).duplicate()
		butterfly.visible = true
		butterfly.play("fly" + str(randi_range(1, 3)))
		butterflies_offset_map[butterfly] = Vector2(
			DisplayServer.window_get_size().x / 2.0 + 100.0,
			-DisplayServer.window_get_size().y / 2.0 + randi_range(300, 400),
		)
		$Butterflies.add_child(butterfly)


func _on_pause_icon_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggle_pause()
