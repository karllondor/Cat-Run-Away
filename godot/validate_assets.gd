extends SceneTree

func _initialize() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	assert(parsed is Dictionary)
	var count := 0
	for item in parsed["assets"]:
		var resource = load("res://" + item["path"])
		assert(resource != null, item["path"])
		if item["kind"] != "audio":
			assert(resource.get_width() == item["width"], item["path"])
			assert(resource.get_height() == item["height"], item["path"])
		count += 1
	for kind in ["hero", "dog"]:
		var frames: SpriteFrames = load("res://godot/" + kind + "_frames.tres")
		assert(frames != null)
		for name in frames.get_animation_names():
			assert(frames.get_frame_count(name) > 0)
			for i in frames.get_frame_count(name):
				assert(frames.get_frame_texture(name, i) != null)
		assert(frames.has_animation("walk_left"))
	var scene = load("res://godot/asset_review.tscn")
	assert(scene != null)
	print("ASSET_VALIDATION_PASSED: ", count, " assets; both SpriteFrames; all frame references; review scene")
	quit(0)
