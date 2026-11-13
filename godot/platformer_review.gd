extends Node2D

var terrain: TileMapLayer
var hero: AnimatedSprite2D
var clock := 0.0

func art(path: String, at: Vector2, size: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/" + path)
	sprite.position = at
	sprite.scale = size / sprite.texture.get_size()
	add_child(sprite)

func land(x: int, y: int, width: int, height: int, stone: bool = false) -> void:
	for row in range(height):
		for col in range(width):
			var coords := Vector2i(3, 2 if stone else 0)
			if row == 0:
				coords = Vector2i(0 if col == 0 else 2 if col == width - 1 else 1, 2 if stone else 0)
			terrain.set_cell(Vector2i(x + col, y + row), 0, coords)

func _ready() -> void:
	art("platformer/backgrounds/garden_day.png", Vector2(640, 360), Vector2(1280, 720))
	terrain = TileMapLayer.new()
	terrain.tile_set = load("res://godot/platformer_tileset.tres")
	add_child(terrain)
	land(0, 6, 4, 6)
	land(16, 6, 4, 6)
	land(4, 10, 12, 3, true)
	for p in [["stepping_stone_small", Vector2(362, 438)], ["stepping_stone_medium", Vector2(544, 380)], ["stepping_stone_medium", Vector2(764, 350)], ["stepping_stone_medium", Vector2(909, 400)]]:
		var block: Node2D = load("res://godot/platforms/" + p[0] + ".tscn").instantiate()
		block.position = p[1]
		add_child(block)
	art("platformer/props/cave.png", Vector2(1170, 288), Vector2(164, 192))
	art("props/kitten_right.png", Vector2(1200, 350), Vector2(80, 80))
	art("platformer/props/checkpoint.png", Vector2(80, 326), Vector2(80, 118))
	for x in [550, 800]:
		var dog := AnimatedSprite2D.new()
		dog.sprite_frames = load("res://godot/dog_frames.tres")
		dog.position = Vector2(x, 589)
		dog.scale = Vector2.ONE * 0.85
		add_child(dog)
		dog.play("walk_right")
	hero = AnimatedSprite2D.new()
	hero.sprite_frames = load("res://godot/hero_frames.tres")
	hero.position = Vector2(645, 275)
	hero.scale = Vector2.ONE * 0.8
	add_child(hero)
	hero.play("jump_air")
	for i in range(3):
		art("ui/heart_full.png", Vector2(48 + i * 46, 104), Vector2(42, 42))
	var panel := CanvasLayer.new()
	add_child(panel)
	var title := Label.new()
	title.text = "CAT, RUN AWAY! / PLATFORMER ASSET REVIEW"
	title.position = Vector2(24, 16)
	title.add_theme_color_override("font_color", Color("153b33"))
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)
	var note := Label.new()
	note.text = "Asset composition, not a playable level. TAB: maze + animation review."
	note.position = Vector2(24, 53)
	note.add_theme_color_override("font_color", Color("153b33"))
	panel.add_child(note)
	var button := Button.new()
	button.text = "LABIRYNT / ANIMACJE"
	button.position = Vector2(1030, 15)
	button.size = Vector2(225, 46)
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://godot/asset_review.tscn"))
	panel.add_child(button)

func _process(delta: float) -> void:
	clock += delta
	if hero:
		hero.position.y = 275.0 - sin(clock * 2.0) * 12.0

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		get_tree().change_scene_to_file("res://godot/asset_review.tscn")
