extends SceneTree

func _initialize() -> void:
	var tiles: TileSet = load("res://godot/platformer_tileset.tres")
	assert(tiles != null)
	assert(tiles.tile_size == Vector2i(64, 64))
	assert(tiles.get_physics_layers_count() == 1)
	assert(tiles.get_physics_layer_collision_layer(0) == 1)
	var atlas: TileSetAtlasSource = tiles.get_source(0)
	assert(atlas.get_tiles_count() == 16)
	for y in range(4):
		for x in range(4):
			var data := atlas.get_tile_data(Vector2i(x, y), 0)
			assert(data.get_collision_polygons_count(0) == 1)
			assert(data.get_collision_polygon_points(0, 0).size() == 4)
	var dir := DirAccess.open("res://godot/platforms")
	var count := 0
	for filename in dir.get_files():
		if filename.ends_with(".tscn"):
			var instance = load("res://godot/platforms/" + filename).instantiate()
			assert(instance is StaticBody2D)
			assert(instance.get_node("Collision").polygon.size() == 4)
			instance.free()
			count += 1
	assert(count == 11)
	print("PLATFORMER_VALIDATION_PASSED: 16 terrain collisions, 11 reusable StaticBody2D scenes")
	quit(0)
