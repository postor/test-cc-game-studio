extends Node2D

const SPRITE_ROOT: String = "E:/study/sprite/output/processed/split-pick-cleaned-cropped-normalized"
const ATTACK_ROOT: String = "res://assets/attacks"
const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const GROUND_Y: float = 575.0
const WALK_SPEED: float = 220.0
const RUN_SPEED: float = 360.0
const DEPTH_SPEED: float = 145.0
const GRAVITY: float = 1500.0
const JUMP_VELOCITY: float = -680.0
const DOUBLE_TAP_WINDOW: float = 0.28
const RECENT_INPUT_LIMIT: int = 12
const ATTACK_STEP_COUNT: int = 4
const ATTACK_FPS: float = 12.0
const ATTACK_FORWARD_SPEED: float = 84.0
const ATTACK_CHAIN_WINDOW: float = 0.36
const DEFAULT_ATTACK_HEIGHT_SCALE: float = 1.2
const ATTACK_TIME_SCALE: float = 1.5
const ATTACK_CHAIN_CHASE_DISTANCE: float = 96.0
const ATTACK_CHAIN_IDEAL_GAP: float = 245.0

const DebugEnemyScript := preload("res://scripts/debug_enemy.gd")

enum ActorState { LOCOMOTION, ATTACKING }

var sprite: AnimatedSprite2D
var shadow: Polygon2D
var enemy: Node2D
var enemy_shadow: Polygon2D
var velocity: Vector2 = Vector2.ZERO
var depth: float = 0.0
var facing: int = 1
var actor_state: ActorState = ActorState.LOCOMOTION
var is_running: bool = false
var run_direction: int = 0
var last_tap_direction: int = 0
var tap_timer: float = 0.0
var attack_hint_timer: float = 0.0
var move_input: Vector2 = Vector2.ZERO
var recent_inputs: Array[String] = []
var attack_step: int = 0
var attack_timer: float = 0.0
var attack_duration: float = 0.0
var attack_buffered: bool = false
var attack_hit_done: bool = false
var attack_debug_rect: Rect2 = Rect2()
var previous_attack_progress: float = 0.0
var combo_window_timer: float = 0.0
var combo_next_step: int = 1
var walk_frame_height: int = 0
var attack_height_scale: float = DEFAULT_ATTACK_HEIGHT_SCALE
var load_error: String = ""


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#141414"))
	_create_scene_nodes()
	_load_animation_frames()
	_update_animation()
	set_process(true)


func _process(delta: float) -> void:
	_update_debug_actor(delta)
	_update_animation()
	attack_hint_timer = maxf(attack_hint_timer - delta, 0.0)
	if actor_state != ActorState.ATTACKING:
		combo_window_timer = maxf(combo_window_timer - delta, 0.0)
		if combo_window_timer <= 0.0:
			combo_next_step = 1
	queue_redraw()


func _create_scene_nodes() -> void:
	shadow = Polygon2D.new()
	shadow.color = Color(0.0, 0.0, 0.0, 0.28)
	shadow.polygon = PackedVector2Array([
		Vector2(-72.0, -13.0),
		Vector2(72.0, -13.0),
		Vector2(96.0, 0.0),
		Vector2(72.0, 13.0),
		Vector2(-72.0, 13.0),
		Vector2(-96.0, 0.0),
	])
	shadow.position = Vector2(420.0, GROUND_Y)
	add_child(shadow)

	sprite = AnimatedSprite2D.new()
	sprite.position = Vector2(420.0, GROUND_Y)
	sprite.centered = true
	sprite.offset = Vector2(0.0, -420.0)
	sprite.scale = Vector2(0.36, 0.36)
	add_child(sprite)

	enemy_shadow = Polygon2D.new()
	enemy_shadow.color = Color(0.0, 0.0, 0.0, 0.24)
	enemy_shadow.polygon = shadow.polygon
	enemy_shadow.position = Vector2(760.0, GROUND_Y)
	add_child(enemy_shadow)

	enemy = DebugEnemyScript.new()
	add_child(enemy)
	enemy.reset_enemy(Vector2(760.0, GROUND_Y), 0.0)


func _load_animation_frames() -> void:
	load_error = ""
	walk_frame_height = 0
	var frames := SpriteFrames.new()
	for animation_name: String in ["walk", "run", "jump"]:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name != "jump")
		frames.set_animation_speed(animation_name, 12.0 if animation_name != "run" else 16.0)
		var loaded_count: int = _add_frames_from_folder(frames, animation_name)
		if loaded_count == 0:
			load_error += "%s has no loaded PNG frames. " % animation_name
	_add_attack_frames(frames)
	sprite.sprite_frames = frames
	if frames.has_animation("walk") and frames.get_frame_count("walk") > 0:
		sprite.play("walk")


func _add_frames_from_folder(frames: SpriteFrames, animation_name: String) -> int:
	var directory := DirAccess.open("%s/%s" % [SPRITE_ROOT, animation_name])
	if directory == null:
		return 0
	var files: PackedStringArray = directory.get_files()
	files.sort()
	var loaded_count: int = 0
	for file_name: String in files:
		if not file_name.to_lower().ends_with(".png"):
			continue
		var image := Image.new()
		var image_path: String = "%s/%s/%s" % [SPRITE_ROOT, animation_name, file_name]
		if image.load(image_path) != OK:
			continue
		if animation_name == "walk" and walk_frame_height <= 0:
			walk_frame_height = image.get_height()
		frames.add_frame(animation_name, ImageTexture.create_from_image(image))
		loaded_count += 1
	return loaded_count


func _add_attack_frames(frames: SpriteFrames) -> void:
	var attack_textures: Array[Texture2D] = _load_textures_from_folder(ATTACK_ROOT)
	if attack_textures.is_empty():
		load_error += "attack has no loaded PNG frames. "
		return
	for step: int in range(ATTACK_STEP_COUNT):
		var animation_name: String = _attack_animation_name(step + 1)
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, false)
		frames.set_animation_speed(animation_name, _attack_animation_fps())
		var start_index: int = int(floor(float(step) * float(attack_textures.size()) / float(ATTACK_STEP_COUNT)))
		var end_index: int = int(floor(float(step + 1) * float(attack_textures.size()) / float(ATTACK_STEP_COUNT))) - 1
		for frame_index: int in range(start_index, maxi(start_index, end_index) + 1):
			frames.add_frame(animation_name, attack_textures[clampi(frame_index, 0, attack_textures.size() - 1)])


func _load_textures_from_folder(folder_path: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var directory := DirAccess.open(folder_path)
	if directory == null:
		return textures
	var files: PackedStringArray = directory.get_files()
	files.sort()
	for file_name: String in files:
		if not file_name.to_lower().ends_with(".png"):
			continue
		var image := Image.new()
		if image.load("%s/%s" % [folder_path, file_name]) != OK:
			continue
		if walk_frame_height > 0 and image.get_height() > 0:
			var target_height: int = maxi(1, int(round(float(walk_frame_height) * attack_height_scale)))
			var target_width: int = maxi(1, int(round(float(image.get_width()) * float(target_height) / float(image.get_height()))))
			image.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)
		textures.append(ImageTexture.create_from_image(image))
	return textures


func _update_debug_actor(delta: float) -> void:
	attack_debug_rect = Rect2()
	if tap_timer > 0.0:
		tap_timer = maxf(tap_timer - delta, 0.0)
		if tap_timer <= 0.0:
			last_tap_direction = 0

	var horizontal: float = _axis(KEY_A, KEY_D)
	var vertical: float = _axis(KEY_W, KEY_S)
	move_input = Vector2(horizontal, vertical)
	var was_grounded: bool = _is_grounded()
	_capture_recent_inputs()
	if actor_state == ActorState.ATTACKING:
		_update_attack_state(delta, was_grounded)
		enemy.tick(delta)
		enemy_shadow.position = Vector2(enemy.position.x, GROUND_Y + enemy.depth)
		return
	_capture_run_tap()
	var horizontal_direction: int = _direction_from_axis(horizontal)
	if is_running and horizontal_direction != 0 and horizontal_direction != run_direction:
		_stop_running()
	if not is_zero_approx(horizontal):
		facing = horizontal_direction

	var speed: float = RUN_SPEED if is_running else WALK_SPEED
	if is_running and horizontal_direction == 0:
		velocity.x = float(run_direction) * RUN_SPEED
	else:
		velocity.x = horizontal * speed
	var depth_speed: float = RUN_SPEED if is_running else DEPTH_SPEED
	depth = clampf(depth + vertical * depth_speed * delta, -72.0, 72.0)
	var jumped: bool = false
	if Input.is_action_just_pressed(&"launcher") and _is_grounded():
		_stop_running()
		_clear_combo_window()
		velocity.y = JUMP_VELOCITY
		jumped = true
	if Input.is_action_just_pressed(&"light_attack"):
		_stop_running()
		_start_attack(combo_next_step if combo_window_timer > 0.0 else 1)
		enemy.tick(delta)
		enemy_shadow.position = Vector2(enemy.position.x, GROUND_Y + enemy.depth)
		return

	sprite.position.x = clampf(sprite.position.x + velocity.x * delta, 120.0, 1160.0)
	var ground_y: float = GROUND_Y + depth
	if was_grounded and not jumped:
		velocity.y = 0.0
		sprite.position.y = ground_y
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
		sprite.position.y += velocity.y * delta
	if sprite.position.y >= ground_y:
		sprite.position.y = ground_y
		velocity.y = 0.0
	shadow.position = Vector2(sprite.position.x, ground_y)
	sprite.flip_h = facing < 0
	enemy.tick(delta)
	enemy_shadow.position = Vector2(enemy.position.x, GROUND_Y + enemy.depth)


func _start_attack(step: int) -> void:
	_stop_running()
	actor_state = ActorState.ATTACKING
	attack_step = clampi(step, 1, ATTACK_STEP_COUNT)
	attack_timer = 0.0
	attack_buffered = false
	attack_hit_done = false
	previous_attack_progress = 0.0
	combo_window_timer = 0.0
	combo_next_step = 1
	velocity = Vector2.ZERO
	_apply_chain_chase()
	var animation_name: String = _attack_animation_name(attack_step)
	var frame_count: int = sprite.sprite_frames.get_frame_count(animation_name) if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name) else 0
	attack_duration = maxf(float(frame_count) / _attack_animation_fps(), 0.16)
	sprite.play(animation_name)


func _update_attack_state(delta: float, was_grounded: bool) -> void:
	if Input.is_action_just_pressed(&"light_attack"):
		attack_buffered = true
	if was_grounded:
		velocity.y = 0.0
		sprite.position.y = GROUND_Y + depth
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
		sprite.position.y += velocity.y * delta
	shadow.position = Vector2(sprite.position.x, GROUND_Y + depth)
	sprite.flip_h = facing < 0
	attack_timer += delta
	var progress: float = clampf(attack_timer / attack_duration, 0.0, 1.0)
	var step_forward: float = _attack_forward_distance() * (progress - previous_attack_progress)
	previous_attack_progress = progress
	sprite.position.x = clampf(sprite.position.x + float(facing) * step_forward, 120.0, 1160.0)
	shadow.position = Vector2(sprite.position.x, GROUND_Y + depth)
	if not attack_hit_done and attack_timer >= attack_duration * 0.38:
		_try_attack_hit()
	if attack_timer >= attack_duration:
		if attack_buffered and attack_step < ATTACK_STEP_COUNT and attack_timer <= attack_duration + _scaled_chain_window():
			_start_attack(attack_step + 1)
		else:
			_end_attack()


func _try_attack_hit() -> void:
	attack_hit_done = true
	attack_debug_rect = _current_attack_rect()
	if not attack_debug_rect.intersects(enemy.hurtbox()):
		return
	if absf(depth - enemy.depth) > 48.0:
		return
	enemy.apply_hit(facing, attack_step == ATTACK_STEP_COUNT, ATTACK_TIME_SCALE)


func _end_attack() -> void:
	var finished_step: int = attack_step
	actor_state = ActorState.LOCOMOTION
	attack_step = 0
	attack_timer = 0.0
	attack_duration = 0.0
	attack_buffered = false
	attack_hit_done = false
	previous_attack_progress = 0.0
	attack_debug_rect = Rect2()
	if finished_step < ATTACK_STEP_COUNT:
		combo_next_step = finished_step + 1
		combo_window_timer = _scaled_chain_window()
	else:
		_clear_combo_window()


func _end_attack_without_combo() -> void:
	actor_state = ActorState.LOCOMOTION
	attack_step = 0
	attack_timer = 0.0
	attack_duration = 0.0
	attack_buffered = false
	attack_hit_done = false
	previous_attack_progress = 0.0
	attack_debug_rect = Rect2()
	_clear_combo_window()


func _capture_run_tap() -> void:
	var pressed_direction: int = 0
	if Input.is_key_pressed(KEY_A) and Input.is_action_just_pressed(&"move_left"):
		pressed_direction = -1
	elif Input.is_key_pressed(KEY_D) and Input.is_action_just_pressed(&"move_right"):
		pressed_direction = 1
	if pressed_direction == 0:
		return
	if last_tap_direction == pressed_direction and tap_timer > 0.0:
		is_running = true
		run_direction = pressed_direction
		last_tap_direction = 0
		tap_timer = 0.0
		return
	last_tap_direction = pressed_direction
	tap_timer = DOUBLE_TAP_WINDOW
	if run_direction != pressed_direction:
		is_running = false
		run_direction = 0


func _stop_running() -> void:
	is_running = false
	run_direction = 0
	last_tap_direction = 0
	tap_timer = 0.0


func _clear_combo_window() -> void:
	combo_window_timer = 0.0
	combo_next_step = 1


func _capture_recent_inputs() -> void:
	if Input.is_action_just_pressed(&"move_up"):
		_push_recent_input("↑")
	if Input.is_action_just_pressed(&"move_down"):
		_push_recent_input("↓")
	if Input.is_action_just_pressed(&"move_left"):
		_push_recent_input("←")
	if Input.is_action_just_pressed(&"move_right"):
		_push_recent_input("→")
	if Input.is_action_just_pressed(&"light_attack"):
		_push_recent_input("A")
	if Input.is_action_just_pressed(&"launcher"):
		_push_recent_input("B")


func _push_recent_input(label: String) -> void:
	recent_inputs.append(label)
	while recent_inputs.size() > RECENT_INPUT_LIMIT:
		recent_inputs.pop_front()


func _update_animation() -> void:
	if sprite.sprite_frames == null:
		return
	if actor_state == ActorState.ATTACKING:
		return
	var is_moving: bool = move_input.length_squared() > 0.0 or is_running or absf(velocity.x) > 1.0
	var next_animation: String = "jump" if not _is_grounded() else "run" if is_running else "walk"
	if sprite.animation != next_animation:
		sprite.play(next_animation)
	if _is_grounded() and not is_moving:
		sprite.pause()
	else:
		sprite.play()


func _axis(negative_key: int, positive_key: int) -> float:
	return float(int(Input.is_key_pressed(positive_key)) - int(Input.is_key_pressed(negative_key)))


func _direction_from_axis(axis: float) -> int:
	if axis > 0.0:
		return 1
	if axis < 0.0:
		return -1
	return 0


func _is_grounded() -> bool:
	return sprite.position.y >= GROUND_Y + depth - 0.5 and is_zero_approx(velocity.y)


func _attack_animation_name(step: int) -> String:
	return "attack_%d" % step


func _attack_forward_distance() -> float:
	return ATTACK_FORWARD_SPEED * float(sprite.sprite_frames.get_frame_count(_attack_animation_name(attack_step))) / ATTACK_FPS


func _apply_chain_chase() -> void:
	if attack_step <= 1:
		return
	if enemy == null:
		return
	if absf(depth - enemy.depth) > 48.0:
		return
	var gap: float = (enemy.position.x - sprite.position.x) * float(facing)
	if gap <= ATTACK_CHAIN_IDEAL_GAP:
		return
	var chase: float = minf(gap - ATTACK_CHAIN_IDEAL_GAP, ATTACK_CHAIN_CHASE_DISTANCE)
	sprite.position.x = clampf(sprite.position.x + float(facing) * chase, 120.0, 1160.0)
	shadow.position = Vector2(sprite.position.x, GROUND_Y + depth)


func _attack_animation_fps() -> float:
	return ATTACK_FPS / ATTACK_TIME_SCALE


func _scaled_chain_window() -> float:
	return ATTACK_CHAIN_WINDOW * ATTACK_TIME_SCALE


func _current_attack_rect() -> Rect2:
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame) if sprite.sprite_frames != null else null
	if texture == null:
		return Rect2()
	var texture_size: Vector2 = Vector2(texture.get_width(), texture.get_height())
	var local_top_left: Vector2 = -texture_size * 0.5 if sprite.centered else Vector2.ZERO
	local_top_left += sprite.offset
	var top_left: Vector2 = sprite.position + local_top_left * sprite.scale
	var full_size: Vector2 = texture_size * sprite.scale.abs()
	var sprite_rect := Rect2(top_left, full_size)
	var front_width: float = sprite_rect.size.x * 2.0 / 3.0
	if facing > 0:
		top_left = Vector2(sprite_rect.end.x - front_width, sprite_rect.position.y)
	else:
		top_left = sprite_rect.position
	return Rect2(top_left, Vector2(front_width, sprite_rect.size.y))


func _draw() -> void:
	_draw_stage()
	_draw_hud()
	_draw_attack_debug()


func _draw_stage() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("#17191B"))
	draw_rect(Rect2(Vector2(0.0, GROUND_Y - 88.0), Vector2(VIEWPORT_SIZE.x, 222.0)), Color("#3F4845"))
	draw_rect(Rect2(Vector2(0.0, GROUND_Y - 72.0), Vector2(VIEWPORT_SIZE.x, 144.0)), Color("#293431"))
	for x: int in range(0, int(VIEWPORT_SIZE.x) + 80, 80):
		draw_line(Vector2(float(x), GROUND_Y - 86.0), Vector2(float(x) + 44.0, GROUND_Y + 114.0), Color("#43504C"), 2.0)
	for y: int in range(int(GROUND_Y - 72.0), int(GROUND_Y + 73.0), 24):
		draw_line(Vector2(0.0, float(y)), Vector2(VIEWPORT_SIZE.x, float(y)), Color("#46534F"), 1.0)
	draw_line(Vector2(120.0, GROUND_Y - 72.0), Vector2(1160.0, GROUND_Y - 72.0), Color("#6EC6C4"), 2.0)
	draw_line(Vector2(120.0, GROUND_Y + 72.0), Vector2(1160.0, GROUND_Y + 72.0), Color("#6EC6C4"), 2.0)


func _draw_hud() -> void:
	var mode_text: String = "RUN" if is_running else "WALK"
	if actor_state == ActorState.ATTACKING:
		mode_text = "ATTACK %d" % attack_step
	if not _is_grounded():
		mode_text = "JUMP"
	if attack_hint_timer > 0.0:
		mode_text = "ATTACK RESERVED"
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 48.0), "Sprite Debug Changing", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color("#F4F0DC"))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 80.0), "WASD move    AA/DD run    K jump    J attack chain", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#cfc8b2"))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 114.0), "Mode: %s    Frames: walk %d / run %d / jump %d / attack %d" % [
		mode_text,
		sprite.sprite_frames.get_frame_count("walk") if sprite.sprite_frames != null else 0,
		sprite.sprite_frames.get_frame_count("run") if sprite.sprite_frames != null else 0,
		sprite.sprite_frames.get_frame_count("jump") if sprite.sprite_frames != null else 0,
		_attack_frame_total(),
	], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#6EC6C4"))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 148.0), "Recent: %s    Attack scale %.2fx    Time %.2fx" % [" ".join(recent_inputs), attack_height_scale, ATTACK_TIME_SCALE], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#F2B84B"))
	if load_error != "":
		draw_string(ThemeDB.fallback_font, Vector2(36.0, 214.0), load_error, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#E85D75"))


func _attack_frame_total() -> int:
	if sprite.sprite_frames == null:
		return 0
	var total: int = 0
	for step: int in range(1, ATTACK_STEP_COUNT + 1):
		total += sprite.sprite_frames.get_frame_count(_attack_animation_name(step))
	return total


func _draw_attack_debug() -> void:
	if attack_debug_rect.size == Vector2.ZERO:
		return
	draw_rect(attack_debug_rect, Color(0.95, 0.68, 0.18, 0.18), true)
	draw_rect(attack_debug_rect, Color("#F2B84B"), false, 2.0)
