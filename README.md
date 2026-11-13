# Cat, Run Away! - playable P3

Three rescue rounds: top-down maze > key > door > side-view parkour > kitten > return to mother.
Each maze and parkour grows. Dogs chase the player; kittens are **only at the end of parkour**.

**Play:** open `project.godot` in Godot 4.6.3 and run F5. Keyboard: WASD or arrows; Space/Z jump; P/Escape pause. Android: big on-screen arrows and jump. Top-right DZW. toggles audio.

**Audio:** short synthetic meows in introduction/rescue and event-triggered dog barks when a dog detects a player. No perpetual meow loop.

**APK:** the `Android APK P3` GitHub Actions workflow automatically attempts a debug-signed Android build on each `main` push. When the job succeeds, the APK is at [P3 prerelease](https://github.com/karllondor/Cat-Run-Away/releases/tag/p3-preview) and the Actions run artifact. Check CI results before describing an APK as available.

**Validation:** `godot --headless --path . --script res://game/test_p3.gd` exercises 3 rescue loops and sound availability. A physical device playtest is still needed.

Read [P3 gameplay and build notes](docs/P3_PLAYABLE.md) for limitations.
Original 0.2 asset kit and review scenes remain in `assets/`, `godot/`, `previews/`.
