# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6.2-stable
- **Language**: GDScript
- **Rendering**: Godot 2D rendering, pixel-art friendly viewport/camera configuration
- **Physics**: Godot Physics 2D for broad collision; combat knockback/launch arcs controlled by gameplay state logic

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Web / Browser
- **Input Methods**: Keyboard first, optional gamepad, optional touch fallback
- **Primary Input**: Keyboard
- **Gamepad Support**: Partial
- **Touch Support**: Partial
- **Platform Notes**: Browser build must avoid hover-only UI, support quick restart from keyboard, and keep action inputs responsive under Web export latency.

## Naming Conventions

- **Classes**: PascalCase, e.g. `PlayerController`
- **Variables**: snake_case, e.g. `move_speed`
- **Signals/Events**: snake_case past tense, e.g. `combo_changed`
- **Files**: snake_case matching class, e.g. `player_controller.gd`
- **Scenes/Prefabs**: PascalCase matching root node, e.g. `PlayerController.tscn`
- **Constants**: UPPER_SNAKE_CASE, e.g. `MAX_COMBO_WINDOW`

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6 ms
- **Draw Calls**: Keep 2D draw calls low enough for browser playback; profile before setting a hard cap.
- **Memory Ceiling**: Keep Web export lightweight; profile before setting a hard cap.

## Testing

- **Framework**: GUT for GDScript unit/integration tests
- **Minimum Coverage**: Focused coverage for gameplay state machines, combo timing, hit detection, and reset behavior
- **Required Tests**: Combat timing formulas, player attack state transitions, dummy hit/launch/land/reset states, combo counter behavior

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all `.gd` files)
- **Shader Specialist**: godot-shader-specialist (`.gdshader` files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated Godot UI specialist; primary covers UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, scene/node architecture, and cross-cutting code review. Invoke GDScript specialist for typed GDScript, signal architecture, and gameplay code. Invoke shader specialist for rendering and VFX. Invoke GDExtension specialist only when native extensions are actively needed.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row is missing for a file type, fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (`.gd` files) | godot-gdscript-specialist |
| Shader / material files (`.gdshader`, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (`.tscn`, `.tres`) | godot-specialist |
| Native extension / plugin files (`.gdextension`, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
