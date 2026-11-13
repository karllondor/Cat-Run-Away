extends Node2D
## Cat, Run Away! P3 - complete three-rescue playable prototype.
## Generated mazes + side-view parkour, touchscreen and keyboard controls.
const SCREEN = Vector2(1280.0, 720.0)
const TOTAL_KITTENS = 3
const MAZE_SPEED = 215.0
const PARKOUR_SPEED = 270.0
const GRAVITY = 1350.0
const JUMP_SPEED = -600.0

var mode := "intro"
var stage_index := 0
var rescued := 0
var hearts := 3
var has_key := false
var paused := false
var sound_enabled := true
var elapsed := 0.0
var intro_elapsed := 0.0
var notice := ""
var notice_timer := 0.0
var font: Font = ThemeDB.fallback_font
var rng := RandomNumberGenerator.new()
var cache: Dictionary = {}
var sounds: Dictionary = {}
var audio_cooldown: Dictionary = {}
var touching: Dictionary = {}
var jump_requested := false
var was_jump_down := false

var maze: Array = []
var maze_columns := 15
var maze_rows := 9
var maze_cell_size := 54.0
var maze_origin := Vector2.ZERO
var start_cell := Vector2i(1, 1)
var key_cell := Vector2i(1, 1)
var door_cell := Vector2i(1, 1)
var player_pos := Vector2.ZERO
var facing := Vector2(1, 0)
var dogs: Array[Dictionary] = []

var platforms: Array[Rect2] = []
var world_end := 5000.0
var camera_x := 0.0
var velocity := Vector2.ZERO
var grounded := false
var checkpoint := Vector2.ZERO
var last_checkpoint := -1

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    rng.randomize()
    sounds["meow1"] = _animal_synth("meow", 0)
    sounds["meow2"] = _animal_synth("meow", 1)
    sounds["bark1"] = _animal_synth("bark", 0)
    sounds["bark2"] = _animal_synth("bark", 1)
    _play_sound("meow1")

func _texture(path: String) -> Texture2D:
    if not cache.has(path):
        cache[path] = load("res://assets/" + path)
    return cache[path]

func _stamp(path: String, at: Vector2, size: Vector2) -> void:
    var texture := _texture(path)
    if texture != null:
        draw_texture_rect(texture, Rect2(at, size), false)

func _label(text_value: String, pos: Vector2, size: int = 22, color: Color = Color.WHITE, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
    draw_string(font, pos, text_value, align, width, size, color)

func _play_sound(name: String, spacing: float = 0.15) -> void:
    if not sound_enabled:
        return
    if audio_cooldown.get(name, 0.0) > 0.0:
        return
    audio_cooldown[name] = spacing
    var stream: AudioStream = sounds.get(name)
    if stream == null:
        stream = load("res://assets/audio/" + name + ".wav")
    if stream == null:
        return
    var player := AudioStreamPlayer.new()
    player.stream = stream
    player.volume_db = -7.0 if name.begins_with("meow") else -9.0
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func _animal_synth(kind: String, variation: int) -> AudioStreamWAV:
    ## Short original, event-triggered, synthetic cat and dog vocalisations.
    var rate := 22050
    var duration := 0.62 if kind == "meow" else 0.32
    var length := int(duration * rate)
    var bytes := PackedByteArray()
    bytes.resize(length * 2)
    var phase := 0.0
    for i in range(length):
        var t := float(i) / float(length)
        var hz := 0.0
        var signal := 0.0
        var envelope := 0.0
        if kind == "meow":
            hz = 540.0 + variation * 85.0 + 250.0 * sin(PI * t) - 125.0 * t + 18.0 * sin(TAU * 9.0 * t)
            envelope = pow(maxf(0.0, sin(PI * t)), 0.8)
            signal = sin(phase) * 0.72 + sin(phase * 2.0) * 0.19 + sin(phase * 3.0) * 0.09
        else:
            hz = 190.0 + variation * 30.0 - 65.0 * t
            var pulse := 1.0 if t < 0.44 else (0.75 if t > 0.53 else 0.0)
            envelope = minf(1.0, t * 50.0) * pow(1.0 - t, 1.8) * pulse
            signal = sin(phase) * 0.55 + sin(phase * 1.95) * 0.26 + rng.randf_range(-0.26, 0.26)
        phase += TAU * hz / float(rate)
        var sample := int(clampf(signal * envelope, -1.0, 1.0) * 17000.0)
        bytes[i * 2] = sample & 255
        bytes[i * 2 + 1] = (sample >> 8) & 255
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.stereo = false
    stream.data = bytes
    return stream

func _start_maze() -> void:
    mode = "maze"
    hearts = 3
    has_key = false
    _build_maze()
    player_pos = _cell_center(start_cell)
    facing = Vector2.RIGHT
    _set_notice("Znajdz klucz, potem otworz drzwi!", 3.0)
    _play_sound("meow2", 0.8)

func _set_notice(text_value: String, seconds: float = 2.5) -> void:
    notice = text_value
    notice_timer = seconds

func _build_maze() -> void:
    var dimensions := [Vector2i(15, 9), Vector2i(19, 11), Vector2i(21, 13)]
    var dims: Vector2i = dimensions[stage_index]
    maze_columns = dims.x
    maze_rows = dims.y
    maze_cell_size = [57.0, 49.0, 44.0][stage_index]
    maze_origin = Vector2((SCREEN.x - maze_columns * maze_cell_size) * 0.5, (SCREEN.y - maze_rows * maze_cell_size) * 0.5 + 16.0)
    maze.clear()
    for y in range(maze_rows):
        var row: Array = []
        for x in range(maze_columns):
            row.append(1)
        maze.append(row)
    rng.seed = 42173 + stage_index * 9029
    var trail: Array[Vector2i] = [start_cell]
    maze[start_cell.y][start_cell.x] = 0
    var jumps := [Vector2i(0,-2), Vector2i(2,0), Vector2i(0,2), Vector2i(-2,0)]
    while not trail.is_empty():
        var here: Vector2i = trail.back()
        var choices: Array[Vector2i] = []
        for move in jumps:
            var next: Vector2i = here + move
            if next.x > 0 and next.x < maze_columns - 1 and next.y > 0 and next.y < maze_rows - 1 and maze[next.y][next.x] == 1:
                choices.append(next)
        if choices.is_empty():
            trail.pop_back()
            continue
        var target: Vector2i = choices[rng.randi_range(0, choices.size() - 1)]
        var midway: Vector2i = here + (target - here) / 2
        maze[midway.y][midway.x] = 0
        maze[target.y][target.x] = 0
        trail.append(target)
    key_cell = _farthest(start_cell)
    door_cell = _farthest(key_cell)
    if door_cell == key_cell:
        door_cell = start_cell
    dogs.clear()
    var dog_count := stage_index + 1
    var route: Array[Vector2i] = _open_cells()
    route.shuffle()
    for cell in route:
        if dogs.size() >= dog_count:
            break
        if cell == start_cell or cell == key_cell or cell == door_cell:
            continue
        if _distance_cells(cell, start_cell) < 5:
            continue
        dogs.append({"pos":_cell_center(cell), "face": Vector2.RIGHT, "bark":0.0})

func _open_cells() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for y in range(1, maze_rows - 1):
        for x in range(1, maze_columns - 1):
            if maze[y][x] == 0:
                result.append(Vector2i(x, y))
    return result

func _farthest(from_cell: Vector2i) -> Vector2i:
    var queue: Array[Vector2i] = [from_cell]
    var distance: Dictionary = {from_cell: 0}
    var farthest := from_cell
    var cursor := 0
    while cursor < queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        for move in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var candidate: Vector2i = current + move
            if _is_open(candidate) and not distance.has(candidate):
                distance[candidate] = distance[current] + 1
                queue.append(candidate)
                if distance[candidate] > distance[farthest]:
                    farthest = candidate
    return farthest

func _next_maze_step(a: Vector2i, b: Vector2i) -> Vector2i:
    if a == b:
        return a
    var queue: Array[Vector2i] = [a]
    var seen: Dictionary = {a: true}
    var prev: Dictionary = {}
    var at := 0
    while at < queue.size() and not seen.has(b):
        var current: Vector2i = queue[at]
        at += 1
        for dir in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
            var next: Vector2i = current + dir
            if _is_open(next) and not seen.has(next):
                seen[next] = true
                prev[next] = current
                queue.append(next)
    if not seen.has(b):
        return a
    var node: Vector2i = b
    while prev.has(node) and prev[node] != a:
        node = prev[node]
    return node

func _is_open(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < maze_columns and cell.y < maze_rows and maze[cell.y][cell.x] == 0

func _cell_center(cell: Vector2i) -> Vector2:
    return maze_origin + (Vector2(cell) + Vector2(0.5, 0.5)) * maze_cell_size

func _cell_at(pos: Vector2) -> Vector2i:
    var v: Vector2 = (pos - maze_origin) / maze_cell_size
    return Vector2i(floori(v.x), floori(v.y))

func _distance_cells(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)

func _passable(pos: Vector2, radius: float = 13.0) -> bool:
    for dx in [-radius, radius]:
        for dy in [-radius, radius]:
            if not _is_open(_cell_at(pos + Vector2(dx, dy))):
                return false
    return true

func _walk_in_maze(dir: Vector2, dt: float) -> void:
    if dir.length_squared() > 1.0:
        dir = dir.normalized()
    if dir.length_squared() > 0.01:
        facing = dir
    var step := dir * MAZE_SPEED * dt
    if _passable(player_pos + Vector2(step.x, 0)):
        player_pos.x += step.x
    if _passable(player_pos + Vector2(0, step.y)):
        player_pos.y += step.y

func _update_dogs(dt: float) -> void:
    for i in range(dogs.size()):
        var dog: Dictionary = dogs[i]
        var pos: Vector2 = dog["pos"]
        var distance := pos.distance_to(player_pos)
        var direction := Vector2.ZERO
        if distance < maze_cell_size * (3.8 + stage_index * 0.7):
            var target_cell := _next_maze_step(_cell_at(pos), _cell_at(player_pos))
            var target := _cell_center(target_cell)
            direction = (target - pos).normalized()
            dog["bark"] = maxf(0.0, float(dog["bark"]) - dt)
            if float(dog["bark"]) <= 0.0:
                _play_sound("bark" + str(i % 2 + 1), 1.0)
                dog["bark"] = 2.7
        else:
            dog["bark"] = maxf(0.0, float(dog["bark"]) - dt)
            var offset := _cell_center(_cell_at(pos)) - pos
            if offset.length() > 5.0:
                direction = offset.normalized()
            elif rng.randf() < dt * 1.0:
                var options: Array[Vector2] = []
                for move in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
                    if _is_open(_cell_at(pos) + Vector2i(move)):
                        options.append(move)
                if not options.is_empty():
                    direction = options[rng.randi_range(0, options.size()-1)]
        if direction.length_squared() > 0.01:
            dog["face"] = direction
            var movement := direction * (108.0 + 22.0 * stage_index) * dt
            if _passable(pos + Vector2(movement.x, 0), 10.0):
                pos.x += movement.x
            if _passable(pos + Vector2(0, movement.y), 10.0):
                pos.y += movement.y
            dog["pos"] = pos
        dogs[i] = dog
        if pos.distance_to(player_pos) < 34.0 and audio_cooldown.get("hurt", 0.0) <= 0.0:
            _play_sound("hurt", 1.2)
            hearts -= 1
            player_pos = _cell_center(start_cell)
            _set_notice("Uwaga na pieska! Sprobuj ponownie.", 1.8)
            if hearts <= 0:
                _start_maze()
            return

func _update_maze(dt: float) -> void:
    var direction := _movement_axis()
    _walk_in_maze(direction, dt)
    if not has_key and player_pos.distance_to(_cell_center(key_cell)) < maze_cell_size * 0.4:
        has_key = true
        _play_sound("key_collect")
        _set_notice("Masz klucz! Znajdz drzwi.", 2.7)
    if mode == "maze" and has_key and player_pos.distance_to(_cell_center(door_cell)) < maze_cell_size * 0.45:
        _play_sound("door_open")
        _begin_parkour()
        return
    if mode == "home" and player_pos.distance_to(_cell_center(start_cell)) < maze_cell_size * 0.6:
        if stage_index + 1 < TOTAL_KITTENS:
            stage_index += 1
            _start_maze()
            _set_notice("Nowy labirynt! Uratuj nastepnego kotka!", 4.0)
        else:
            mode = "won"
            _play_sound("meow1")
        return
    _update_dogs(dt)

func _begin_parkour() -> void:
    mode = "parkour"
    platforms.clear()
    var first := Rect2(0, 590, 720, 200)
    platforms.append(first)
    var right := first.end.x
    var count := [12, 16, 20][stage_index]
    for i in range(count):
        var gap := 100.0 + float((i + stage_index) % 3) * 15.0
        var width := 300.0 + float(i % 3) * 45.0
        var height := 590.0 - float([0, 30, 60, 10, 48, 20][i % 6])
        var rect := Rect2(right + gap, height, width, 800.0 - height)
        platforms.append(rect)
        right = rect.end.x
    world_end = right
    player_pos = Vector2(135, 590)
    velocity = Vector2.ZERO
    grounded = true
    camera_x = 0
    checkpoint = player_pos
    last_checkpoint = -1
    _set_notice("Parkour: skacz po platformach! Kotek czeka na koncu.", 3.6)

func _update_parkour(dt: float) -> void:
    var axis := _movement_axis().x
    var old := player_pos
    velocity.x = axis * PARKOUR_SPEED
    if jump_requested and grounded:
        velocity.y = JUMP_SPEED
        grounded = false
        _play_sound("jump", 0.2)
    jump_requested = false
    velocity.y += GRAVITY * dt
    player_pos += velocity * dt
    player_pos.x = clampf(player_pos.x, 22.0, world_end - 25.0)
    grounded = false
    for platform in platforms:
        if player_pos.x + 20.0 <= platform.position.x or player_pos.x - 20.0 >= platform.end.x:
            continue
        if old.y <= platform.position.y + 10.0 and player_pos.y >= platform.position.y and velocity.y >= 0.0:
            player_pos.y = platform.position.y
            velocity.y = 0.0
            grounded = true
            break
    if grounded:
        for i in range(platforms.size()):
            var p: Rect2 = platforms[i]
            if i > last_checkpoint and i % 3 == 0 and player_pos.x >= p.position.x and player_pos.x <= p.end.x:
                last_checkpoint = i
                checkpoint = Vector2(p.position.x + 64.0, p.position.y)
    if player_pos.y > 800.0:
        player_pos = checkpoint
        velocity = Vector2.ZERO
        grounded = true
        _set_notice("Jeszcze raz od ostatniego punktu!", 2.0)
        _play_sound("hurt", 0.7)
    camera_x = clampf(player_pos.x - 350.0, 0.0, maxf(0.0, world_end - SCREEN.x))
    var end_rect: Rect2 = platforms.back()
    var kitten_pos := Vector2(world_end - 105.0, end_rect.position.y)
    if player_pos.distance_to(kitten_pos) < 75.0:
        rescued += 1
        _play_sound("kitten_rescued")
        _play_sound("meow" + str((rescued % 2) + 1))
        mode = "home"
        dogs.clear()
        has_key = true
        player_pos = _cell_center(door_cell)
        _set_notice("Kotek uratowany! Wroc do mamy kotki.", 4.0)

func _movement_axis() -> Vector2:
    var result := Vector2.ZERO
    if _pressed("left") or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        result.x -= 1.0
    if _pressed("right") or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        result.x += 1.0
    if _pressed("up") or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        result.y -= 1.0
    if _pressed("down") or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        result.y += 1.0
    return result.normalized()

func _pressed(command: String) -> bool:
    return touching.values().has(command)

func _process(delta: float) -> void:
    var dt := minf(delta, 0.045)
    elapsed += dt
    for name in audio_cooldown.keys():
        audio_cooldown[name] = maxf(0.0, float(audio_cooldown[name]) - dt)
    if not paused:
        if notice_timer > 0.0:
            notice_timer -= dt
        if mode == "intro":
            intro_elapsed += dt
            if intro_elapsed >= 5.3:
                _start_maze()
        elif mode == "maze" or mode == "home":
            _update_maze(dt)
        elif mode == "parkour":
            var key_jump := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_Z)
            if key_jump and not was_jump_down:
                jump_requested = true
            was_jump_down = key_jump
            _update_parkour(dt)
    queue_redraw()

func _control_at(pos: Vector2) -> String:
    if Rect2(1184, 10, 80, 75).has_point(pos):
        return "sound"
    if Rect2(1095, 10, 80, 75).has_point(pos):
        return "pause"
    if paused or mode == "intro" or mode == "won":
        return "resume"
    for item in [
        {"name":"left", "pos":Vector2(82, 611), "rad":53.0},
        {"name":"right", "pos":Vector2(270, 611), "rad":53.0},
        {"name":"up", "pos":Vector2(176, 518), "rad":52.0},
        {"name":"down", "pos":Vector2(176, 621), "rad":52.0}
    ]:
        if mode == "parkour" and item["name"] in ["up", "down"]:
            continue
        if pos.distance_to(item["pos"]) < item["rad"]:
            return item["name"]
    if mode == "parkour" and pos.distance_to(Vector2(1115, 590)) < 91.0:
        return "jump"
    return ""

func _set_touch(index: int, pos: Vector2, down: bool) -> void:
    if not down:
        touching.erase(index)
        return
    var command := _control_at(pos)
    if command == "sound":
        sound_enabled = not sound_enabled
        touching.erase(index)
    elif command == "pause":
        paused = not paused
        touching.clear()
    elif mode == "intro":
        intro_elapsed = 6.0
        touching.clear()
    elif mode == "won":
        stage_index = 0
        rescued = 0
        paused = false
        touching.clear()
        _start_maze()
    elif paused:
        paused = false
        touching.clear()
    elif command == "jump":
        jump_requested = true
        touching[index] = command
    else:
        touching[index] = command

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        _set_touch(event.index, event.position, event.pressed)
    elif event is InputEventScreenDrag:
        _set_touch(event.index, event.position, true)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _set_touch(999, event.position, event.pressed)
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
            paused = not paused
            touching.clear()
        elif event.keycode == KEY_ENTER and mode == "intro":
            _start_maze()
        elif (event.keycode == KEY_SPACE or event.keycode == KEY_Z) and mode == "parkour":
            jump_requested = true

func _draw_maze() -> void:
    draw_rect(Rect2(Vector2.ZERO, SCREEN), Color("a5d8ac"))
    var size := Vector2.ONE * maze_cell_size
    for y in range(maze_rows):
        for x in range(maze_columns):
            var at := maze_origin + Vector2(x, y) * maze_cell_size
            if maze[y][x] == 1:
                _stamp("tiles/hedge_block.png", at, size)
            else:
                _stamp("tiles/grass.png", at, size)
                if (x + y * 3) % 13 == 0:
                    _stamp("tiles/flowers.png", at + size * 0.17, size * 0.65)
    var mother := _cell_center(start_cell)
    _stamp("props/mother_down.png", mother - Vector2(maze_cell_size * 0.7, maze_cell_size * 0.82), size * 1.35)
    if not has_key:
        var key_pos := _cell_center(key_cell)
        _stamp("props/key.png", key_pos - size * 0.48, size * 0.96)
    var door := _cell_center(door_cell)
    _stamp("props/door_open.png" if has_key else "props/door_closed.png", door - size * 0.58, size * 1.16)
    for i in range(dogs.size()):
        var dog: Dictionary = dogs[i]
        var pos: Vector2 = dog["pos"]
        var face: Vector2 = dog["face"]
        var anim := "dog_%02d.png" % (8 + int(elapsed * 7.0 + i) % 4)
        if absf(face.y) > absf(face.x):
            anim = "dog_%02d.png" % ((4 if face.y < 0 else 0) + int(elapsed * 7.0 + i) % 4)
        elif face.x < 0:
            anim = "dog_left_%d.png" % (int(elapsed * 7.0 + i) % 4)
        _stamp("characters/" + anim, pos - size * 0.74, size * 1.48)
    var frame := int(elapsed * 8.0) % 4
    var sprite := "hero_%02d.png" % (8 + frame)
    if absf(facing.y) > absf(facing.x):
        sprite = "hero_%02d.png" % ((4 if facing.y < 0 else 0) + frame)
    elif facing.x < 0:
        sprite = "hero_left_%d.png" % frame
    _stamp("characters/" + sprite, player_pos - size * 0.76, size * 1.52)

func _draw_parkour() -> void:
    _stamp("platformer/backgrounds/garden_day.png", Vector2.ZERO, SCREEN)
    draw_rect(Rect2(0, 0, 1280, 70), Color(0.10, 0.30, 0.32, 0.72))
    for i in range(platforms.size()):
        var p: Rect2 = platforms[i]
        var screen_left := p.position.x - camera_x
        if screen_left > SCREEN.x + 160.0 or screen_left + p.size.x < -160.0:
            continue
        for j in range(int(ceil(p.size.x / 64.0))):
            var at := Vector2(screen_left + j * 64.0, p.position.y)
            var tile_w := minf(64.0, p.size.x - float(j) * 64.0)
            _stamp("platformer/tiles/earth_top_center.png", at, Vector2(tile_w, 64))
            draw_rect(Rect2(at.x, at.y + 58, tile_w, 720 - at.y), Color("8a663a"))
            _stamp("platformer/tiles/earth_fill.png", at + Vector2(0, 64), Vector2(tile_w, 64))
        if i > 0 and i % 3 == 0:
            _stamp("platformer/props/checkpoint.png", Vector2(screen_left + 15.0, p.position.y - 115.0), Vector2(90, 115))
        if i % 3 == 2:
            _stamp("platformer/props/flower_bush.png", Vector2(screen_left + 145, p.position.y - 64), Vector2(96, 64))
    var last: Rect2 = platforms.back()
    var kitten_x := world_end - 105.0 - camera_x
    _stamp("props/kitten_right.png", Vector2(kitten_x - 55, last.position.y - 116), Vector2(110, 110))
    var character := "characters/hero_%02d.png" % (8 + int(elapsed * 9.0) % 4)
    if not grounded:
        character = "characters/hero_14.png"
    elif velocity.x < -1.0:
        character = "characters/hero_left_%d.png" % (int(elapsed * 9.0) % 4)
    _stamp(character, Vector2(player_pos.x - camera_x - 55.0, player_pos.y - 105.0), Vector2(110, 110))
    var completion := clampf(player_pos.x / world_end, 0.0, 1.0)
    draw_rect(Rect2(400, 30, 450, 13), Color(0.13, 0.28, 0.24, 0.8))
    draw_rect(Rect2(400, 30, 450 * completion, 13), Color("fadc79"))

func _control(center: Vector2, radius: float, name: String, arrow: Vector2 = Vector2.ZERO) -> void:
    var active := _pressed(name)
    draw_circle(center, radius, Color(0.12, 0.25, 0.28, 0.80 if active else 0.59))
    draw_arc(center, radius, 0, TAU, 40, Color(1, 1, 1, 0.85), 3.0, true)
    if arrow != Vector2.ZERO:
        var a := arrow.normalized()
        var normal := Vector2(-a.y, a.x)
        var corners := PackedVector2Array([center + a * 23.0, center - a * 10.0 + normal * 17.0, center - a * 10.0 - normal * 17.0])
        draw_colored_polygon(corners, Color("ffedcf"))
    else:
        _label("SKOK", center + Vector2(-40, 8), 29, Color.WHITE, 80, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_controls() -> void:
    if mode != "maze" and mode != "home" and mode != "parkour":
        return
    _control(Vector2(82,611), 48, "left", Vector2.LEFT)
    _control(Vector2(270,611), 48, "right", Vector2.RIGHT)
    if mode != "parkour":
        _control(Vector2(176,518), 48, "up", Vector2.UP)
        _control(Vector2(176,621), 48, "down", Vector2.DOWN)
    else:
        _control(Vector2(1115,590), 75, "jump")

func _draw_hud() -> void:
    if mode in ["maze", "home", "parkour"]:
        draw_rect(Rect2(0, 0, 1280, 77), Color(0.09,0.27,0.26,0.83))
        var title := "Labirynt" if mode == "maze" else ("Wracamy do mamy" if mode == "home" else "Parkour")
        _label("KOTKI %d/3  |  ETAP %d/3  |  %s" % [rescued, stage_index+1, title], Vector2(30, 31), 26)
        if mode != "parkour":
            _label("KLUCZ: TAK" if has_key else "KLUCZ: NIE", Vector2(33, 62), 18, Color("ffe5a0"))
            for i in range(hearts):
                _stamp("ui/heart_full.png", Vector2(235 + 38*i, 38), Vector2(33,33))
    draw_rect(Rect2(1095, 10, 80, 62), Color(0.10,0.24,0.26,0.86))
    draw_rect(Rect2(1184, 10, 80, 62), Color(0.10,0.24,0.26,0.86))
    _label("II", Vector2(1120,53), 28)
    _label("DZW." if sound_enabled else "OFF", Vector2(1188,48), 20)
    if notice_timer > 0.0 and mode != "intro":
        draw_rect(Rect2(255, 88, 770, 56), Color(0.06, 0.24, 0.24, 0.8))
        _label(notice, Vector2(280, 125), 23, Color("ffe8ac"), 720, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_intro() -> void:
    _stamp("platformer/backgrounds/garden_day.png", Vector2.ZERO, SCREEN)
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.06,0.15,0.15,0.25))
    _stamp("props/mother_down.png", Vector2(210, 325 + sin(elapsed * 2.0) * 7.0), Vector2(220,220))
    _stamp("characters/hero_00.png", Vector2(800, 338), Vector2(190,190))
    draw_rect(Rect2(320, 110, 665, 160), Color("fffae9"))
    var dialogue := "Gdzie sa moje male kotki?" if intro_elapsed < 2.4 else "Pomoz mi je odnalezc, prosze!"
    _label(dialogue, Vector2(346, 175), 34, Color("334e45"), 615, HORIZONTAL_ALIGNMENT_CENTER)
    _label("CAT, RUN AWAY!", Vector2(340, 83), 47, Color("fff1b8"), 650, HORIZONTAL_ALIGNMENT_CENTER)
    _label("Dotknij ekranu, aby rozpoczac", Vector2(380, 655), 28, Color("fff7dc"), 520, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_ending() -> void:
    _stamp("platformer/backgrounds/garden_day.png", Vector2.ZERO, SCREEN)
    draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.06,0.21,0.18,0.55))
    _label("BRAWO!", Vector2(390, 155), 75, Color("ffe99a"), 500, HORIZONTAL_ALIGNMENT_CENTER)
    _label("Wszystkie 3 kotki sa juz z mama!", Vector2(280, 235), 33, Color.WHITE, 720, HORIZONTAL_ALIGNMENT_CENTER)
    _stamp("props/mother_down.png", Vector2(330,310), Vector2(170,170))
    for i in range(3):
        _stamp("props/kitten_down.png", Vector2(520 + i*155, 350), Vector2(130,130))
    _label("Dotknij ekranu, aby zagrac ponownie", Vector2(300, 610), 25, Color.WHITE, 680, HORIZONTAL_ALIGNMENT_CENTER)

func _draw() -> void:
    if mode == "intro":
        _draw_intro()
    elif mode == "maze" or mode == "home":
        _draw_maze()
    elif mode == "parkour":
        _draw_parkour()
    elif mode == "won":
        _draw_ending()
    if mode != "intro" and mode != "won":
        _draw_controls()
        _draw_hud()
    if paused:
        draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0,0,0,0.67))
        _label("PAUZA", Vector2(400,305), 63, Color.WHITE, 480, HORIZONTAL_ALIGNMENT_CENTER)
        _label("Dotknij ekranu lub nacisnij P", Vector2(320,390), 26, Color.WHITE, 640, HORIZONTAL_ALIGNMENT_CENTER)
