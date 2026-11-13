# Cat, Run Away! P3 - playable vertical slice

This is a playable Godot 4.6.3 prototype developed from the existing asset kit. It replaces the asset-review scene as the main scene.

## Gameplay
- Animated mother-and-cat introductory scene with dialogue bubbles.
- Three increasingly large procedural top-down mazes.
- Pick up the key, enter the door, then play a longer side-scrolling parkour section.
- Exactly one kitten at the end of the parkour; return through the maze to the mother.
- 1 dog in maze 1, 2 dogs in maze 2, 3 dogs in maze 3.
- Dogs pursue the hero within detection radius, collide with and reset player; 3 hearts per maze.
- Forgiving platformer checkpoints, no falling to oblivion or kitten collision glitches.
- Big touch controls, keyboard WASD/arrows, space or Z to jump, P/Escape to pause.
- Sound on/off button at top right, event-triggered synthesized cat meows and dog barks (not voice lines).
- The end screen appears after all 3 kittens return home.

## Test/build
GitHub Actions `Android APK P3` should import the project, check runtime syntax, export a **debug-signed** Android APK, upload an artifact and publish a prerelease. The CI outcome must be checked before claiming APK availability. This repository is not tested on a physical handset by this commit.

Godot PC test: open `project.godot` in Godot 4.6.3 and press F6 on `game/main.tscn` or F5 to run the game.
Open GitHub Actions > Android APK P3 for build logs.
APK Releases: https://github.com/karllondor/Cat-Run-Away/releases/tag/p3-preview (only after a successful job).

## Known limitations
Audio is procedurally synthesized and deliberately not presented as realistic animal recordings. Parkour uses deterministic platforms and basic one-way top collisions. Art is retained from the v0.2 asset kit. Automated build verification is not physical-device QA.
