# 三段破空 Demo

Godot 4.6.2 Web-first 2D combat training prototype.

## Run

Open this folder as a Godot project:

```powershell
..\Godot_v4.6.2-stable_win64.exe --path .
```

Or run a headless smoke test:

```powershell
..\Godot_v4.6.2-stable_win64_console.exe --headless --path . -s res://scripts/smoke_test.gd
```

## Build Web HTML

Install the Godot 4.6.2 export templates, then export the Web preset:

```powershell
New-Item -ItemType Directory -Force ..\dist\web
..\Godot_v4.6.2-stable_win64_console.exe --headless --path . --import
..\Godot_v4.6.2-stable_win64_console.exe --headless --path . --export-release Web ..\dist\web\index.html
```

The generated HTML build is written to `dist/web/`.

## Docker + nginx

From the repository root, build the image. The Docker build downloads Godot 4.6.2 and its export templates, exports the Web preset, then copies the static HTML build into nginx:

```powershell
docker build -t ccgs-godot-web .
```

Serve the exported build with nginx:

```powershell
docker run --rm -p 8080:80 ccgs-godot-web
```

Open `http://localhost:8080`.

## Controls

- `A` / `D` or arrow keys: move; double-tap left or right to run
- `Space`: jump
- `J`: slash / air slash
- `K`: launcher
- `R`: reset training
- `Esc`: pause

## Implemented Demo Goals

- Single training room.
- Player movement and jump.
- Ground slash chain.
- Dedicated launcher.
- Air slash.
- Training dummy hitstun, knockback, airborne, landing, reset.
- Hit detection with duplicate-hit suppression.
- Hitstop, screen shake, hit spark, dummy flash.
- Combo and best-combo HUD.
- Debug attack phase display.

## Notes

All art is placeholder-drawn in GDScript using `_draw()`. Timing and hitbox values live in `scripts/combat_tuning.gd` for fast iteration.
