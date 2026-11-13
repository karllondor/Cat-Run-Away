extends Node2D

var cache: Dictionary = {}
var font: Font = ThemeDB.fallback_font
var clock := 0.0
var actor_nodes: Array[AnimatedSprite2D] = []

func tex(path: String) -> Texture2D:
	if not cache.has(path):
		cache[path] = load("res://assets/" + path)
	return cache[path]

func stamp(path: String, at: Vector2, size: Vector2) -> void:
	draw_texture_rect(tex(path), Rect2(at, size), false)

func label_at(text: String, at: Vector2, size: int = 22, color: Color = Color("ffdf93")) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func actor(kind: String, animation_name: String, at: Vector2, scale_value: float = 0.65) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://godot/" + kind + "_frames.tres")
	sprite.position = at
	sprite.scale = Vector2.ONE * scale_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	sprite.play(animation_name)
	actor_nodes.append(sprite)

func _ready() -> void:
	var button := Button.new()
	button.text = "PARKOUR"
	button.position = Vector2(1100, 25)
	button.size = Vector2(150, 46)
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://godot/platformer_review.tscn"))
	add_child(button)
	actor("hero", "walk_down", Vector2(210, 330))
	actor("dog", "walk_down", Vector2(210, 465))
	actor("hero", "walk_right", Vector2(800, 360))
	actor("dog", "walk_right", Vector2(1140, 495))
	for i in range(4):
		actor("hero", ["walk_down", "walk_up", "walk_right", "walk_left"][i], Vector2(90 + i * 120, 655), 0.7)
		actor("dog", ["walk_down", "walk_up", "walk_right", "walk_left"][i], Vector2(710 + i * 120, 655), 0.7)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		get_tree().change_scene_to_file("res://godot/platformer_review.tscn")
		return
	if event is InputEventKey and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_6:
		var sounds := ["key_collect", "jump", "hurt", "kitten_rescued", "door_open", "ui_tap"]
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/" + sounds[event.keycode - KEY_1] + ".wav")
		add_child(player)
		player.finished.connect(player.queue_free)
		player.play()

func _draw() -> void:
	label_at("CAT, RUN AWAY! / ASSET REVIEW 0.1", Vector2(32, 42), 28)
	label_at("Animation and composition preview. Not a playable level.", Vector2(32, 73), 18, Color("a9d5bd"))
	label_at("TOP-DOWN MAZE", Vector2(32, 115))
	label_at("SIDE-VIEW PARKOUR", Vector2(670, 115))
	for y in range(7):
		for x in range(9):
			var at := Vector2(32 + x * 64, 140 + y * 56)
			stamp("tiles/grass.png", at, Vector2(64, 56))
			if x in [2, 3, 6] or y in [2, 5]:
				stamp("tiles/stone_path.png", at, Vector2(64, 56))
			elif x % 3 != 1:
				stamp("tiles/hedge_block.png", at, Vector2(64, 56))
	stamp("props/door_closed.png", Vector2(390, 135), Vector2(100, 100))
	stamp("props/key.png", Vector2(120, 390), Vector2(52, 52))
	stamp("props/mother_down.png", Vector2(200, 130), Vector2(90, 90))
	stamp("ui/quest.png", Vector2(227, 120), Vector2(30, 30))
	stamp("tiles/flowers.png", Vector2(470, 400), Vector2(64, 64))
	stamp("tiles/tree.png", Vector2(40, 160), Vector2(125, 125))
	draw_rect(Rect2(670, 140, 578, 390), Color("bce1e8"))
	for x in range(9):
		stamp("tiles/earth_fill.png", Vector2(670 + x * 64, 466), Vector2(64, 64))
	for x in [0, 1, 7, 8]:
		stamp("tiles/grass_platform.png", Vector2(670 + x * 64, 338), Vector2(64, 64))
		stamp("tiles/earth_fill.png", Vector2(670 + x * 64, 402), Vector2(64, 64))
	for x in [3, 5]:
		stamp("tiles/rock_platform.png", Vector2(670 + x * 64, 330), Vector2(64, 64))
	stamp("props/kitten_right.png", Vector2(1170, 310), Vector2(70, 70))
	var phase := int(clock * 3.0) % 4
	stamp("characters/hero_%02d.png" % (12 + phase), Vector2(930, 250), Vector2(100, 100))
	for i in range(3):
		stamp("ui/heart_full.png", Vector2(685 + i * 36, 150), Vector2(32, 32))
	label_at("CAT / FOUR DIRECTIONS", Vector2(32, 590), 20)
	label_at("DOG / FOUR DIRECTIONS", Vector2(670, 590), 20)
	label_at("Keyboard 1-6: sound effects", Vector2(32, 737), 18, Color("a9d5bd"))
