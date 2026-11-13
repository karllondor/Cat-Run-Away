extends SceneTree

func _initialize() -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/platformer/terrain_atlas_64.png")
	atlas.texture_region_size = Vector2i(64, 64)
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(64, 64)
	tiles.add_physics_layer()
	tiles.set_physics_layer_collision_layer(0, 1)
	tiles.set_physics_layer_collision_mask(0, 0)
	tiles.add_source(atlas, 0)
	for y in range(4):
		for x in range(4):
			var coords := Vector2i(x, y)
			atlas.create_tile(coords)
			var data := atlas.get_tile_data(coords, 0)
			data.set_collision_polygons_count(0, 1)
			var top := -24.0 if y == 0 and x < 3 else -32.0
			data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-32, top), Vector2(32, top), Vector2(32, 32), Vector2(-32, 32)]))
	var err := ResourceSaver.save(tiles, "res://godot/platformer_tileset.tres")
	assert(err == OK)
	print("TILESET_BUILD_PASSED: 16 atlas tiles, physics layer 1")
	quit(0)
