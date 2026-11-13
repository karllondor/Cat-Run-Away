extends SceneTree
# Quick gameplay regression test run with --headless --path . --script res://game/test_p3.gd

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var game: Variant = load("res://game/main.tscn").instantiate()
    root.add_child(game)
    assert(game.mode == "intro")
    assert(game.sounds.has("meow1") and game.sounds.has("meow2"))
    assert(game.sounds.has("bark1") and game.sounds.has("bark2"))
    for stage in range(3):
        game.stage_index = stage
        game._start_maze()
        assert(game.mode == "maze")
        assert(game.dogs.size() == stage + 1)
        assert(game._is_open(game.key_cell))
        assert(game._is_open(game.door_cell))
        assert(game.door_cell != game.start_cell)
        assert(game.door_cell != game.key_cell)
        game.player_pos = game._cell_center(game.key_cell)
        game._update_maze(0.016)
        assert(game.has_key)
        game.player_pos = game._cell_center(game.door_cell)
        game._update_maze(0.016)
        assert(game.mode == "parkour")
        assert(game.platforms.size() == [13, 17, 21][stage])
        var last: Rect2 = game.platforms.back()
        game.player_pos = Vector2(game.world_end - 105.0, last.position.y)
        game.velocity = Vector2.ZERO
        game.grounded = true
        game._update_parkour(0.016)
        assert(game.mode == "home")
        assert(game.rescued == stage + 1)
        assert(game.dogs.is_empty())
        game._update_maze(0.016)
        assert(game.mode == "home")
        game.player_pos = game._cell_center(game.start_cell)
        game._update_maze(0.016)
        assert(game.mode == ("won" if stage == 2 else "maze"))
    assert(game.rescued == 3)
    print("P3 TESTS PASS: three mazes, keys, doors, parkour, home returns, animal audio")
    quit(0)
