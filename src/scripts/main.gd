extends Node2D

const Tuning := preload("res://scripts/combat_tuning.gd")
const TrainingDummyScript := preload("res://scripts/training_dummy.gd")
const PlayerScript := preload("res://scripts/player.gd")

var player: Node2D
var dummy: Node2D
var dummies: Array[Node2D] = []
var combo_count: int = 0
var best_combo: int = 0
var hitstop_frames: int = 0
var shake_timer: float = 0.0
var shake_strength: float = 0.0
var hit_sparks: Array[Dictionary] = []
var paused: bool = false
var current_level: int = 1
var current_wave: int = 1
var transition_timer: float = 0.0
var transition_title: String = ""
var transition_subtitle: String = ""
var game_over: bool = false
var game_over_reason: String = "Press R to retry from Level 1"
var demo_cleared: bool = false
var wave_defeats: int = 0
var defeats_required: int = 2
var area_time_remaining: float = 0.0
var scene_mode: int = SceneMode.LEVEL_INTRO
var gameplay_camera: Camera2D
var camera_x: float = 0.0
var encounter_locked: bool = false
var active_spawn_wave: int = 0
var awaiting_map_advance: bool = false
var advance_hint_timer: float = 0.0
var last_advance_progress_x: float = 0.0

enum SceneMode { LEVEL_INTRO, SCENE_TRANSITION, COMBAT, GAME_OVER, DEMO_CLEAR }

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const AREA_WORLD_SPACING: float = 1120.0
const CAMERA_TARGET_X: float = 520.0
const ENCOUNTER_TRIGGER_OFFSET: float = 210.0
const ENCOUNTER_SPAWN_MARGIN: float = 260.0
const ENCOUNTER_OFFSCREEN_BUFFER: float = 360.0
const SPAWN_OFFSCREEN_PADDING: float = 96.0
const ADVANCE_HINT_DELAY: float = 1.4
const ADVANCE_PROGRESS_EPSILON: float = 5.0
const LEVEL_EXIT_PADDING: float = 360.0

const LEVEL_TITLES: Array[String] = [
	"Training Alley",
	"Bridge Crossfire",
	"Dojo Trial",
	"Break-Sky Warden",
]

const LEVEL_BRIEFINGS: Array[String] = [
	"Learn light-chain launch routes while avoiding shallow alley gaps.",
	"Cross the broken bridge, close on ranged soldiers, and keep a safe lane around floor holes.",
	"Survive longer dojo rooms with split lanes, dashers, and ranged pressure.",
	"Defeat the Break-Sky Warden in an unstable arena with boss sweeps and lethal gaps.",
]

const LEVEL_CONFIGS: Array[Dictionary] = [
	{
		&"terrain": &"alley",
		&"time": 72.0,
		&"areas": [
			{&"name": "Gate", &"left": 150.0, &"right": 1110.0, &"enemies": [&"SMALL", &"SMALL"], &"waves": [[&"SMALL", &"SMALL"], [&"DASHER"]], &"spawn_points": [{&"side": &"right"}, {&"side": &"right"}], &"holes": []},
			{&"name": "Drain Walk", &"left": 135.0, &"right": 1135.0, &"enemies": [&"SMALL", &"DASHER"], &"holes": [{&"x": 610.0, &"w": 130.0, &"top": -76.0, &"bottom": -30.0}]},
			{&"name": "Back Alley", &"left": 130.0, &"right": 1145.0, &"enemies": [&"DASHER", &"SMALL"], &"holes": [{&"x": 445.0, &"w": 110.0, &"top": 28.0, &"bottom": 78.0}]},
		],
	},
	{
		&"terrain": &"bridge",
		&"time": 96.0,
		&"areas": [
			{&"name": "Bridgehead", &"left": 145.0, &"right": 1140.0, &"enemies": [&"SMALL", &"RANGED"], &"waves": [[&"SMALL", &"RANGED"], [&"DASHER", &"SMALL"]], &"spawn_points": [{&"side": &"right"}, {&"side": &"door", &"offset": 40.0}], &"holes": [{&"x": 540.0, &"w": 140.0, &"top": -12.0, &"bottom": 34.0}]},
			{&"name": "Broken Span", &"left": 125.0, &"right": 1160.0, &"enemies": [&"RANGED", &"DASHER"], &"holes": [{&"x": 350.0, &"w": 120.0, &"top": -78.0, &"bottom": -42.0}, {&"x": 805.0, &"w": 150.0, &"top": 34.0, &"bottom": 78.0}]},
			{&"name": "Far Rail", &"left": 140.0, &"right": 1145.0, &"enemies": [&"DASHER", &"RANGED"], &"holes": [{&"x": 675.0, &"w": 155.0, &"top": -22.0, &"bottom": 24.0}]},
		],
	},
	{
		&"terrain": &"dojo",
		&"time": 112.0,
		&"areas": [
			{&"name": "Outer Mat", &"left": 155.0, &"right": 1120.0, &"enemies": [&"DASHER", &"DASHER"], &"waves": [[&"DASHER", &"DASHER"], [&"RANGED"]], &"spawn_points": [{&"side": &"right"}, {&"side": &"right"}], &"holes": []},
			{&"name": "Split Floor", &"left": 130.0, &"right": 1155.0, &"enemies": [&"RANGED", &"DASHER"], &"holes": [{&"x": 590.0, &"w": 115.0, &"top": -78.0, &"bottom": -36.0}, {&"x": 590.0, &"w": 115.0, &"top": 36.0, &"bottom": 78.0}]},
			{&"name": "Inner Trial", &"left": 120.0, &"right": 1160.0, &"enemies": [&"DASHER", &"RANGED", &"SMALL", &"DASHER"], &"holes": [{&"x": 365.0, &"w": 105.0, &"top": 22.0, &"bottom": 76.0}, {&"x": 860.0, &"w": 120.0, &"top": -76.0, &"bottom": -24.0}]},
		],
	},
	{
		&"terrain": &"boss",
		&"time": 140.0,
		&"areas": [
			{&"name": "Ritual Gate", &"left": 145.0, &"right": 1135.0, &"enemies": [&"DASHER", &"RANGED"], &"waves": [[&"DASHER", &"RANGED"], [&"DASHER", &"SMALL"]], &"spawn_points": [{&"side": &"right"}, {&"side": &"door", &"offset": 36.0}], &"holes": [{&"x": 520.0, &"w": 105.0, &"top": -76.0, &"bottom": -38.0}]},
			{&"name": "Warden Floor", &"left": 125.0, &"right": 1160.0, &"enemies": [&"BOSS", &"RANGED"], &"holes": [{&"x": 300.0, &"w": 120.0, &"top": 34.0, &"bottom": 78.0}, {&"x": 910.0, &"w": 125.0, &"top": -78.0, &"bottom": -34.0}]},
			{&"name": "Break-Sky Ring", &"left": 120.0, &"right": 1160.0, &"enemies": [&"BOSS", &"DASHER", &"RANGED"], &"holes": [{&"x": 610.0, &"w": 130.0, &"top": -18.0, &"bottom": 20.0}]},
		],
	},
]

func _ready() -> void:
	randomize()
	gameplay_camera = Camera2D.new()
	gameplay_camera.position = VIEWPORT_SIZE * 0.5
	gameplay_camera.enabled = true
	add_child(gameplay_camera)
	player = PlayerScript.new()
	_create_dummies()
	add_child(player)
	player.reset_player()
	player.hit_confirmed.connect(_on_hit_confirmed)
	player.route_dropped.connect(_on_route_dropped)
	_start_level_intro(1)
	set_process(true)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"pause"):
		paused = not paused
	if Input.is_action_just_pressed(&"reset_training"):
		_reset_training()
	if (scene_mode == SceneMode.LEVEL_INTRO or scene_mode == SceneMode.SCENE_TRANSITION) and (Input.is_action_just_pressed(&"light_attack") or Input.is_action_just_pressed(&"launcher")):
		transition_timer = 0.0
	if game_over or demo_cleared:
		_update_effects(delta)
		queue_redraw()
		return
	if scene_mode == SceneMode.LEVEL_INTRO or scene_mode == SceneMode.SCENE_TRANSITION:
		_update_level_flow(delta)
		_update_effects(delta)
		queue_redraw()
		return
	if paused:
		queue_redraw()
		return

	var frozen: bool = hitstop_frames > 0
	if hitstop_frames > 0:
		hitstop_frames -= 1
	player.tick(delta, frozen, dummies)
	for target: Node2D in dummies:
		target.tick(delta, frozen, player)
		if target.is_corpse_finished():
			_hide_dummy(target)
	if player.move_state == player.MoveState.DEFEATED:
		_begin_game_over()
	_check_terrain_falls()
	_update_effects(delta)
	_update_camera()
	_update_level_flow(delta)
	queue_redraw()

func _reset_training() -> void:
	combo_count = 0
	hitstop_frames = 0
	shake_timer = 0.0
	shake_strength = 0.0
	hit_sparks.clear()
	player.reset_player()
	for i: int in range(dummies.size()):
		_hide_dummy(dummies[i])
	current_level = 1
	current_wave = 1
	game_over = false
	demo_cleared = false
	game_over_reason = "Press R to retry from Level 1"
	wave_defeats = 0
	camera_x = 0.0
	encounter_locked = false
	active_spawn_wave = 0
	awaiting_map_advance = false
	advance_hint_timer = 0.0
	last_advance_progress_x = 0.0
	_start_level_intro(current_level)
	paused = false

func _on_hit_confirmed(hit_event: Dictionary) -> void:
	combo_count += 1
	best_combo = maxi(best_combo, combo_count)
	if hit_event.has(&"target_id"):
		var target: Node2D = _find_dummy_by_id(int(hit_event[&"target_id"]))
		if target != null:
			target.apply_hit(hit_event)
	player.add_meter(int(hit_event.get(&"meter_gain", 0)))
	hitstop_frames = int(hit_event[&"hitstop_frames"])
	shake_timer = 0.18
	shake_strength = float(hit_event[&"shake"])
	hit_sparks.append({
		&"position": hit_event[&"hit_position"],
		&"life": 0.18,
		&"type": hit_event[&"hit_type"],
	})

func _on_route_dropped() -> void:
	if player.attack_phase == player.AttackPhase.READY and _all_dummies_neutral():
		combo_count = 0

func _on_dummy_attack_connected(hit_event: Dictionary) -> void:
	shake_timer = 0.10
	shake_strength = 3.0
	hit_sparks.append({
		&"position": hit_event[&"hit_position"],
		&"life": 0.14,
		&"type": &"enemy",
	})

func _on_dummy_defeated(defeated_dummy: Node2D) -> void:
	combo_count = 0
	shake_timer = 0.22
	shake_strength = 10.0
	hit_sparks.append({
		&"position": defeated_dummy.position + Vector2(0.0, -58.0),
		&"life": 0.24,
		&"type": &"super",
	})
	wave_defeats += 1
	if wave_defeats >= defeats_required:
		_advance_wave_or_level()

func _start_level_intro(level: int) -> void:
	current_level = clampi(level, 1, LEVEL_TITLES.size())
	current_wave = 1
	wave_defeats = 0
	camera_x = 0.0
	encounter_locked = false
	active_spawn_wave = 0
	awaiting_map_advance = false
	advance_hint_timer = 0.0
	last_advance_progress_x = 0.0
	area_time_remaining = float(_level_config().get(&"time", 90.0))
	scene_mode = SceneMode.LEVEL_INTRO
	transition_timer = 3.0
	transition_title = "LEVEL %d" % current_level
	transition_subtitle = LEVEL_TITLES[current_level - 1]
	player.visible = false
	for target: Node2D in dummies:
		_hide_dummy(target)

func _advance_wave_or_level() -> void:
	if game_over or demo_cleared or transition_timer > 0.0:
		return
	if active_spawn_wave < _current_spawn_waves().size() - 1:
		active_spawn_wave += 1
		wave_defeats = 0
		_spawn_current_wave()
		return
	_award_wave_clear()
	encounter_locked = false
	active_spawn_wave = 0
	wave_defeats = 0
	current_wave += 1
	awaiting_map_advance = true
	advance_hint_timer = 0.0
	last_advance_progress_x = player.position.x if player != null else _level_start_x()
	player.set_stage_bounds(_level_start_x(), _current_progress_right())
	for target: Node2D in dummies:
		_hide_dummy(target)

func _update_level_flow(delta: float) -> void:
	if scene_mode == SceneMode.COMBAT and not paused:
		area_time_remaining = maxf(area_time_remaining - delta, 0.0)
		if area_time_remaining <= 0.0:
			_begin_game_over("Time ran out. Press R to retry from Level 1")
			return
		_update_map_progress(delta)
		return
	if transition_timer > 0.0:
		transition_timer = maxf(transition_timer - delta, 0.0)
	if transition_timer > 0.0:
		return
	if scene_mode == SceneMode.LEVEL_INTRO:
		scene_mode = SceneMode.SCENE_TRANSITION
		transition_timer = 0.9
		transition_title = "ENTERING"
		transition_subtitle = _current_area_name()
	elif scene_mode == SceneMode.SCENE_TRANSITION:
		_begin_combat_area()

func _begin_game_over(reason: String = "Press R to retry from Level 1") -> void:
	if game_over:
		return
	game_over = true
	scene_mode = SceneMode.GAME_OVER
	transition_timer = 0.0
	transition_title = "GAME OVER"
	transition_subtitle = reason
	game_over_reason = reason

func _begin_demo_clear() -> void:
	demo_cleared = true
	scene_mode = SceneMode.DEMO_CLEAR
	transition_timer = 0.0
	transition_title = "DEMO CLEAR"
	transition_subtitle = "All four level prototypes cleared. Press R to replay."
	player.visible = false
	for target: Node2D in dummies:
		_hide_dummy(target)

func _award_wave_clear() -> void:
	player.health = mini(player.health + 35, Tuning.PLAYER_MAX_HEALTH)
	player.add_meter(20)

func _configure_wave() -> void:
	_begin_combat_area()

func _begin_combat_area() -> void:
	scene_mode = SceneMode.COMBAT
	transition_timer = 0.0
	wave_defeats = 0
	active_spawn_wave = 0
	encounter_locked = false
	awaiting_map_advance = false
	advance_hint_timer = 0.0
	var area: Dictionary = _current_area()
	var waves: Array = _current_spawn_waves()
	defeats_required = (waves[0] as Array).size() if not waves.is_empty() else 0
	area_time_remaining = maxf(area_time_remaining, 1.0)
	player.visible = true
	player.set_stage_bounds(_level_start_x(), _current_progress_right())
	player.depth = 0.0
	player.position = Vector2(_level_start_x() + 190.0, Tuning.GROUND_Y)
	player.velocity = Vector2.ZERO
	player.move_state = player.MoveState.GROUNDED
	player.attack_phase = player.AttackPhase.READY
	player.current_attack = &""
	_update_camera()
	for i: int in range(dummies.size()):
		_hide_dummy(dummies[i])

func _create_dummies() -> void:
	dummies.clear()
	for i: int in range(4):
		var new_dummy: Node2D = TrainingDummyScript.new()
		add_child(new_dummy)
		new_dummy.attack_connected.connect(_on_dummy_attack_connected)
		new_dummy.defeated.connect(_on_dummy_defeated.bind(new_dummy))
		dummies.append(new_dummy)
		_hide_dummy(new_dummy)
	dummy = dummies[0]

func _update_map_progress(delta: float) -> void:
	if encounter_locked:
		player.set_stage_bounds(_current_area_left(), _current_encounter_right())
		return
	if current_wave > _area_count():
		if player.position.x >= _level_exit_x():
			if current_level >= LEVEL_TITLES.size():
				_begin_demo_clear()
				return
			current_level += 1
			_start_level_intro(current_level)
		return
	player.set_stage_bounds(_level_start_x(), _current_progress_right())
	var trigger_x: float = _current_area_left() + ENCOUNTER_TRIGGER_OFFSET
	if player.position.x >= trigger_x:
		_begin_encounter()
		return
	if awaiting_map_advance:
		if player.position.x > last_advance_progress_x + ADVANCE_PROGRESS_EPSILON:
			awaiting_map_advance = false
			advance_hint_timer = 0.0
		else:
			advance_hint_timer += delta

func _begin_encounter() -> void:
	encounter_locked = true
	awaiting_map_advance = false
	advance_hint_timer = 0.0
	active_spawn_wave = 0
	wave_defeats = 0
	player.set_stage_bounds(_current_area_left(), _current_encounter_right())
	_spawn_current_wave()

func _spawn_current_wave() -> void:
	var waves: Array = _current_spawn_waves()
	if waves.is_empty():
		_advance_wave_or_level()
		return
	var enemies: Array = waves[clampi(active_spawn_wave, 0, waves.size() - 1)]
	defeats_required = enemies.size()
	for i: int in range(dummies.size()):
		if i < enemies.size():
			_respawn_dummy(dummies[i], i)
		else:
			_hide_dummy(dummies[i])

func _respawn_dummy(target: Node2D, index: int = -1) -> void:
	var resolved_index: int = index
	if resolved_index < 0:
		resolved_index = dummies.find(target)
	var area: Dictionary = _current_area()
	var waves: Array = _current_spawn_waves()
	var enemies: Array = waves[clampi(active_spawn_wave, 0, waves.size() - 1)] if not waves.is_empty() else []
	if resolved_index < 0 or resolved_index >= enemies.size():
		_hide_dummy(target)
		return
	var left: float = _current_area_left()
	var right: float = _current_encounter_right()
	var lane_options: Array[float] = [-34.0, 34.0, 0.0, 58.0]
	var lane: float = lane_options[resolved_index % lane_options.size()]
	var spawn_points: Array = area.get(&"spawn_points", [])
	var spawn_x: float = _spawn_x_from_point(spawn_points[resolved_index % spawn_points.size()] if not spawn_points.is_empty() else {}, resolved_index, lane)
	spawn_x = _safe_spawn_x(spawn_x, lane)
	var enemy_type: int = _enemy_type_from_name(StringName(enemies[resolved_index]), target)
	target.visible = true
	target.reset_dummy(Vector2(spawn_x, Tuning.GROUND_Y), lane, enemy_type)
	target.set_stage_bounds(left, right)
	target.set_terrain_holes(_world_holes_for_current_area())

func _enemy_type_from_name(type_name: StringName, target: Node2D) -> int:
	match type_name:
		&"RANGED":
			return target.EnemyType.RANGED
		&"DASHER":
			return target.EnemyType.DASHER
		&"BOSS":
			return target.EnemyType.BOSS
	return target.EnemyType.SMALL

func _hide_dummy(target: Node2D) -> void:
	target.visible = false
	target.state = target.State.DEAD
	target.corpse_timer = Tuning.DUMMY_CORPSE_DURATION
	target.health = 0
	target.projectiles.clear()
	target.set_terrain_holes([])

func _find_dummy_by_id(instance_id: int) -> Node2D:
	for target: Node2D in dummies:
		if target.get_instance_id() == instance_id:
			return target
	return null

func _all_dummies_neutral() -> bool:
	for target: Node2D in dummies:
		if target.visible and not target.is_neutral():
			return false
	return true

func _level_config() -> Dictionary:
	return LEVEL_CONFIGS[current_level - 1]

func _area_count() -> int:
	return (_level_config().get(&"areas", []) as Array).size()

func _current_area() -> Dictionary:
	var areas: Array = _level_config().get(&"areas", [])
	if current_wave > areas.size():
		return areas[areas.size() - 1]
	return areas[clampi(current_wave - 1, 0, areas.size() - 1)]

func _current_area_name() -> String:
	if current_wave > _area_count():
		return "Exit"
	return String(_current_area().get(&"name", "Area %d" % current_wave))

func _current_holes() -> Array:
	if current_wave > _area_count():
		return []
	return _current_area().get(&"holes", [])

func _all_level_holes() -> Array[Dictionary]:
	var holes: Array[Dictionary] = []
	var areas: Array = _level_config().get(&"areas", [])
	for area_index: int in range(areas.size()):
		var world_offset: float = _area_world_offset(area_index + 1)
		var area: Dictionary = areas[area_index]
		for hole: Dictionary in area.get(&"holes", []):
			var copied: Dictionary = hole.duplicate()
			copied[&"x"] = float(copied[&"x"]) + world_offset
			holes.append(copied)
	return holes

func _current_spawn_waves() -> Array:
	var area: Dictionary = _current_area()
	if area.has(&"waves"):
		return area[&"waves"]
	return [area.get(&"enemies", [&"SMALL", &"SMALL"])]

func _area_world_offset(area_index: int) -> float:
	return float(maxi(area_index - 1, 0)) * AREA_WORLD_SPACING

func _level_start_x() -> float:
	return Tuning.STAGE_LEFT

func _current_area_left() -> float:
	return float(_current_area().get(&"left", Tuning.STAGE_LEFT)) + _area_world_offset(current_wave)

func _current_area_right() -> float:
	return float(_current_area().get(&"right", Tuning.STAGE_RIGHT)) + _area_world_offset(current_wave)

func _current_encounter_right() -> float:
	return maxf(_current_area_right(), camera_x + VIEWPORT_SIZE.x + ENCOUNTER_OFFSCREEN_BUFFER)

func _current_progress_right() -> float:
	if current_wave > _area_count():
		return _level_exit_x()
	return _current_area_right()

func _level_exit_x() -> float:
	var areas: Array = _level_config().get(&"areas", [])
	if areas.is_empty():
		return Tuning.STAGE_RIGHT
	var last_index: int = areas.size()
	var last_area: Dictionary = areas[last_index - 1]
	return float(last_area.get(&"right", Tuning.STAGE_RIGHT)) + _area_world_offset(last_index) + LEVEL_EXIT_PADDING

func _update_camera() -> void:
	if player == null:
		return
	var max_camera_x: float = maxf(_level_exit_x() - VIEWPORT_SIZE.x, 0.0)
	var target_x: float = clampf(player.position.x - CAMERA_TARGET_X, 0.0, max_camera_x)
	camera_x = move_toward(camera_x, maxf(camera_x, target_x), 36.0)
	if gameplay_camera != null:
		gameplay_camera.position = Vector2(camera_x + VIEWPORT_SIZE.x * 0.5, VIEWPORT_SIZE.y * 0.5)

func _spawn_x_from_point(spawn_point: Variant, index: int, lane: float) -> float:
	var point: Dictionary = spawn_point if spawn_point is Dictionary else {}
	var side: StringName = StringName(point.get(&"side", &"right"))
	var offset: float = float(point.get(&"offset", 0.0))
	var x: float
	if side == &"left":
		x = camera_x - SPAWN_OFFSCREEN_PADDING - float(index % 2) * 92.0
		x = maxf(x, _current_area_left() + ENCOUNTER_SPAWN_MARGIN)
	elif side == &"door":
		x = _current_area_left() + ENCOUNTER_SPAWN_MARGIN + offset
	else:
		x = camera_x + VIEWPORT_SIZE.x + SPAWN_OFFSCREEN_PADDING + float(index % 2) * 92.0
		x = minf(x, _current_encounter_right() - ENCOUNTER_SPAWN_MARGIN)
	if index >= 2:
		x -= 130.0
	return x

func _check_terrain_falls() -> void:
	if scene_mode != SceneMode.COMBAT:
		return
	if _point_in_hole(player.position.x, player.depth):
		_begin_game_over("You fell through broken ground. Press R to retry from Level 1")
		player.visible = false
		return
	for target: Node2D in dummies:
		if not target.visible or target.state == target.State.DEAD:
			continue
		if _point_in_hole(target.position.x, target.depth):
			target.kill_by_fall()

func _point_in_hole(x: float, depth: float) -> bool:
	for hole: Dictionary in _all_level_holes():
		var left: float = float(hole[&"x"])
		var right: float = left + float(hole[&"w"])
		var top: float = float(hole[&"top"])
		var bottom: float = float(hole[&"bottom"])
		if x >= left and x <= right and depth >= top and depth <= bottom:
			return true
	return false

func _safe_spawn_x(preferred_x: float, lane: float) -> float:
	var left: float = _current_area_left()
	var right: float = _current_area_right()
	var x: float = clampf(preferred_x, left + 80.0, right - 80.0)
	for attempt: int in range(10):
		if not _point_in_hole(x, lane):
			return x
		x = clampf(x - 70.0, left + 80.0, right - 80.0)
	return left + 220.0

func _world_holes_for_current_area() -> Array[Dictionary]:
	var holes: Array[Dictionary] = []
	var world_offset: float = _area_world_offset(current_wave)
	for hole: Dictionary in _current_holes():
		var copied: Dictionary = hole.duplicate()
		copied[&"x"] = float(copied[&"x"]) + world_offset
		holes.append(copied)
	return holes

func _update_effects(delta: float) -> void:
	shake_timer = maxf(shake_timer - delta, 0.0)
	for spark: Dictionary in hit_sparks:
		spark[&"life"] = float(spark[&"life"]) - delta
	hit_sparks = hit_sparks.filter(func(spark: Dictionary) -> bool: return float(spark[&"life"]) > 0.0)

func _draw() -> void:
	var offset: Vector2 = Vector2.ZERO
	if shake_timer > 0.0:
		offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	draw_set_transform(offset, 0.0, Vector2.ONE)
	_draw_background()
	draw_set_transform(offset, 0.0, Vector2.ONE)
	_draw_hit_sparks()
	draw_set_transform(Vector2(camera_x, 0.0), 0.0, Vector2.ONE)
	_draw_hud()
	_draw_overlays()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_background() -> void:
	var terrain: StringName = _level_config().get(&"terrain", &"alley")
	var sky: Color = Color("#141414")
	var ground: Color = Color("#4A4D4A")
	var grid: Color = Color("#383b38")
	match terrain:
		&"bridge":
			sky = Color("#18212A")
			ground = Color("#3F4F55")
			grid = Color("#29343A")
		&"dojo":
			sky = Color("#171514")
			ground = Color("#514735")
			grid = Color("#3B3326")
		&"boss":
			sky = Color("#18111D")
			ground = Color("#423845")
			grid = Color("#2D2430")
	draw_rect(Rect2(Vector2(camera_x, 0.0), VIEWPORT_SIZE), sky)
	draw_rect(Rect2(Vector2(camera_x, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_TOP - 14.0), Vector2(VIEWPORT_SIZE.x, Tuning.STAGE_DEPTH_BOTTOM - Tuning.STAGE_DEPTH_TOP + 194.0)), ground)
	draw_rect(Rect2(Vector2(camera_x, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_TOP), Vector2(VIEWPORT_SIZE.x, Tuning.STAGE_DEPTH_BOTTOM - Tuning.STAGE_DEPTH_TOP)), Color(0.20, 0.24, 0.23, 0.40))
	var level_left: float = _level_start_x()
	var level_right: float = _level_exit_x()
	draw_rect(Rect2(Vector2(level_left - 520.0, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_TOP), Vector2(520.0, Tuning.STAGE_DEPTH_BOTTOM - Tuning.STAGE_DEPTH_TOP)), Color(0.0, 0.0, 0.0, 0.20))
	draw_rect(Rect2(Vector2(level_right, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_TOP), Vector2(520.0, Tuning.STAGE_DEPTH_BOTTOM - Tuning.STAGE_DEPTH_TOP)), Color(0.0, 0.0, 0.0, 0.20))
	draw_line(Vector2(level_left, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_TOP), Vector2(level_right, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_TOP), Color("#6EC6C4"), 2.0)
	draw_line(Vector2(level_left, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_BOTTOM), Vector2(level_right, Tuning.GROUND_Y + Tuning.STAGE_DEPTH_BOTTOM), Color("#6EC6C4"), 2.0)
	var grid_start: int = int(floor(camera_x / 64.0)) * 64
	for x: int in range(grid_start, int(camera_x + VIEWPORT_SIZE.x) + 96, 64):
		draw_line(Vector2(float(x), Tuning.GROUND_Y), Vector2(float(x) + 28.0, 720.0), grid, 2.0)
	for y: int in range(int(Tuning.GROUND_Y), 720, 32):
		draw_line(Vector2(level_left, float(y)), Vector2(level_right, float(y)), Color("#393c39"), 2.0)
	_draw_holes()
	for area_index: int in range(1, _area_count() + 1):
		var marker_x: float = _area_world_offset(area_index) + 80.0
		draw_rect(Rect2(Vector2(marker_x, 120.0), Vector2(180.0, 260.0)), Color("#8E2F2D"))
		draw_rect(Rect2(Vector2(marker_x + 6.0, 126.0), Vector2(168.0, 248.0)), Color("#141414"), false, 3.0)
	draw_line(Vector2(_level_start_x(), 150.0), Vector2(_level_exit_x(), 150.0), Color("#7A5436"), 10.0)

func _draw_holes() -> void:
	for hole: Dictionary in _all_level_holes():
		var x: float = float(hole[&"x"])
		var w: float = float(hole[&"w"])
		var top_y: float = Tuning.GROUND_Y + float(hole[&"top"])
		var bottom_y: float = Tuning.GROUND_Y + float(hole[&"bottom"])
		var rect: Rect2 = Rect2(Vector2(x, top_y), Vector2(w, bottom_y - top_y))
		draw_rect(rect, Color("#080808"))
		draw_rect(rect.grow(4.0), Color(0.9, 0.22, 0.18, 0.28), false, 3.0)
		draw_line(rect.position + Vector2(8.0, 8.0), rect.end - Vector2(8.0, 8.0), Color(0.9, 0.22, 0.18, 0.35), 2.0)
		draw_line(Vector2(rect.end.x - 8.0, rect.position.y + 8.0), Vector2(rect.position.x + 8.0, rect.end.y - 8.0), Color(0.9, 0.22, 0.18, 0.35), 2.0)

func _draw_hit_sparks() -> void:
	for spark: Dictionary in hit_sparks:
		var pos: Vector2 = spark[&"position"]
		var life: float = float(spark[&"life"])
		var t: float = clampf(life / 0.18, 0.0, 1.0)
		var color: Color = Color("#6EC6C4") if spark[&"type"] == &"launcher" or spark[&"type"] == &"air" or spark[&"type"] == &"ki" else Color("#F2B84B")
		if spark[&"type"] == &"super":
			color = Color("#E85D75")
		draw_circle(pos, 22.0 * t, color)
		draw_circle(pos, 10.0 * t, Color("#F4F0DC"))
		draw_line(pos + Vector2(-34.0 * t, 0.0), pos + Vector2(34.0 * t, 0.0), Color("#F4F0DC"), 4.0)
		draw_line(pos + Vector2(0.0, -24.0 * t), pos + Vector2(0.0, 24.0 * t), color, 4.0)

func _draw_hud() -> void:
	var text_color: Color = Color("#F4F0DC")
	var gold: Color = Color("#F2B84B")
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 48.0), "三段破空 - Training Demo", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, text_color)
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 84.0), "WASD or Arrows: Move   Space: Jump   J: Slash   K: Ki Strike   J+K: Super   R: Reset   Esc: Pause", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#cfc8b2"))
	_draw_bars()
	draw_string(ThemeDB.fallback_font, Vector2(1010.0, 54.0), "COMBO %02d" % combo_count, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 34, gold)
	draw_string(ThemeDB.fallback_font, Vector2(1010.0, 90.0), "BEST %02d" % best_combo, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, text_color)
	draw_string(ThemeDB.fallback_font, Vector2(1010.0, 126.0), "LEVEL %d-%d" % [current_level, current_wave], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color("#cfc8b2"))
	draw_string(ThemeDB.fallback_font, Vector2(1010.0, 152.0), "%s  %03ds" % [_current_area_name(), int(ceil(area_time_remaining))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#cfc8b2"))
	var progress_text: String = "ADVANCE ->" if awaiting_map_advance and advance_hint_timer >= ADVANCE_HINT_DELAY else ""
	if progress_text != "":
		draw_rect(Rect2(Vector2(470.0, 602.0), Vector2(340.0, 42.0)), Color(0.08, 0.08, 0.08, 0.72))
		draw_rect(Rect2(Vector2(470.0, 602.0), Vector2(340.0, 42.0)), Color("#F2B84B"), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(512.0, 631.0), "Area clear. Keep moving right.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 21, gold)
	elif encounter_locked:
		draw_string(ThemeDB.fallback_font, Vector2(478.0, 631.0), "Clear all enemies before advancing.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color("#E85D75"))
	if player.current_attack != &"":
		var data: Dictionary = Tuning.ATTACKS[player.current_attack]
		draw_string(ThemeDB.fallback_font, Vector2(40.0, 124.0), "Attack: %s  Phase: %s  Frame: %d" % [data[&"display"], player.AttackPhase.keys()[player.attack_phase], player.phase_frame], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#6EC6C4"))
	if paused:
		draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color(0.0, 0.0, 0.0, 0.55))
		draw_string(ThemeDB.fallback_font, Vector2(520.0, 330.0), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 52, gold)
		draw_string(ThemeDB.fallback_font, Vector2(430.0, 372.0), "Esc to resume    R to reset", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, text_color)

func _draw_overlays() -> void:
	if game_over:
		draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color(0.0, 0.0, 0.0, 0.70))
		draw_string(ThemeDB.fallback_font, Vector2(452.0, 318.0), "GAME OVER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 58, Color("#E85D75"))
		draw_string(ThemeDB.fallback_font, Vector2(360.0, 366.0), game_over_reason, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color("#F4F0DC"))
		return
	if demo_cleared:
		draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color(0.0, 0.0, 0.0, 0.70))
		draw_string(ThemeDB.fallback_font, Vector2(434.0, 318.0), "DEMO CLEAR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 58, Color("#F2B84B"))
		draw_string(ThemeDB.fallback_font, Vector2(346.0, 366.0), transition_subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color("#F4F0DC"))
		return
	if transition_timer > 0.0:
		var alpha: float = clampf(transition_timer / 0.35, 0.0, 1.0)
		var overlay_alpha: float = 0.68 if scene_mode == SceneMode.LEVEL_INTRO else 0.46
		draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color(0.0, 0.0, 0.0, overlay_alpha * alpha))
		draw_string(ThemeDB.fallback_font, Vector2(498.0, 276.0), transition_title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 54, Color("#F2B84B"))
		draw_string(ThemeDB.fallback_font, Vector2(470.0, 324.0), transition_subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, Color("#F4F0DC"))
		if scene_mode == SceneMode.LEVEL_INTRO:
			draw_string(ThemeDB.fallback_font, Vector2(310.0, 370.0), LEVEL_BRIEFINGS[current_level - 1], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("#cfc8b2"))
			draw_string(ThemeDB.fallback_font, Vector2(430.0, 410.0), "Areas: %d    Time: %ds    Broken ground is lethal." % [_area_count(), int(float(_level_config().get(&"time", 90.0)))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color("#6EC6C4"))

func _draw_bars() -> void:
	_draw_value_bar(Vector2(40.0, 106.0), Vector2(230.0, 16.0), float(player.health) / float(Tuning.PLAYER_MAX_HEALTH), Color("#8E2F2D"), "PLAYER HP %d/%d" % [player.health, Tuning.PLAYER_MAX_HEALTH])
	_draw_value_bar(Vector2(40.0, 132.0), Vector2(230.0, 14.0), _visible_meter_ratio(), Color("#6EC6C4"), "QI %03d" % player.meter)
	var extra: int = _meter_extra_count()
	if extra > 0:
		var suffix_color: Color = Color("#F4F0DC")
		if player.meter >= Tuning.METER_MAX and int(Time.get_ticks_msec() / 180) % 2 == 0:
			suffix_color = Color("#F2B84B")
		draw_string(ThemeDB.fallback_font, Vector2(278.0, 145.0), "+%d" % extra, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, suffix_color)
	for i: int in range(dummies.size()):
		var target: Node2D = dummies[i]
		if not target.visible:
			continue
		var max_health: int = target._max_health()
		var label: String = "%s HP %d/%d" % [target.EnemyType.keys()[target.enemy_type], target.health, max_health]
		_draw_value_bar(Vector2(760.0, 106.0 + float(i) * 26.0), Vector2(260.0, 16.0), float(target.health) / float(max_health), Color("#7A5436"), label)

func _draw_value_bar(origin: Vector2, size: Vector2, ratio: float, fill: Color, label: String) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	draw_rect(Rect2(origin, size), Color("#141414"))
	draw_rect(Rect2(origin, Vector2(size.x * clamped, size.y)), fill)
	draw_rect(Rect2(origin, size), Color("#F4F0DC"), false, 2.0)
	draw_string(ThemeDB.fallback_font, origin + Vector2(0.0, -4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#F4F0DC"))

func _visible_meter_ratio() -> float:
	if player.meter <= 100:
		return float(player.meter) / 100.0
	var visible: int = player.meter % 100
	if visible == 0:
		visible = 100
	return float(visible) / 100.0

func _meter_extra_count() -> int:
	if player.meter >= 300:
		return 2
	if player.meter > 200:
		return 2
	if player.meter == 200:
		return 1
	if player.meter > 100:
		return 1
	return 0
