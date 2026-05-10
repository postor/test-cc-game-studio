class_name PlayerFighter
extends Node2D

const Tuning := preload("res://scripts/combat_tuning.gd")

signal hit_confirmed(hit_event: Dictionary)
signal attack_started(attack_id: StringName)
signal route_dropped()

enum MoveState { GROUNDED, AIRBORNE, DEFEATED }
enum AttackPhase { READY, STARTUP, ACTIVE, RECOVERY }

var velocity: Vector2 = Vector2.ZERO
var depth: float = 0.0
var facing: int = 1
var move_state: MoveState = MoveState.GROUNDED
var attack_phase: AttackPhase = AttackPhase.READY
var current_attack: StringName = &""
var phase_frame: int = 0
var active_frame_index: int = 0
var attack_instance_id: int = 0
var hit_targets: Dictionary = {}
var buffered_action: StringName = &""
var buffer_age: int = 0
var route_step: int = 0
var slash_vfx_frames: int = 0
var hurt_flash_frames: int = 0
var hurtstun_timer: float = 0.0
var guard_timer: float = 0.0
var defeat_timer: float = 0.0
var health: int = Tuning.PLAYER_MAX_HEALTH
var meter: int = 0
var debug_hitbox: Rect2 = Rect2()
var stage_left: float = Tuning.STAGE_LEFT
var stage_right: float = Tuning.STAGE_RIGHT

func reset_player() -> void:
	stage_left = Tuning.STAGE_LEFT
	stage_right = Tuning.STAGE_RIGHT
	depth = 0.0
	position = _ground_position()
	velocity = Vector2.ZERO
	facing = 1
	move_state = MoveState.GROUNDED
	attack_phase = AttackPhase.READY
	current_attack = &""
	phase_frame = 0
	active_frame_index = 0
	attack_instance_id = 0
	hit_targets.clear()
	buffered_action = &""
	buffer_age = 0
	route_step = 0
	slash_vfx_frames = 0
	hurt_flash_frames = 0
	hurtstun_timer = 0.0
	guard_timer = 0.0
	defeat_timer = 0.0
	health = Tuning.PLAYER_MAX_HEALTH
	meter = 0
	debug_hitbox = Rect2()
	queue_redraw()

func tick(delta: float, frozen: bool, dummy: Variant) -> void:
	if frozen:
		queue_redraw()
		return
	if move_state == MoveState.DEFEATED:
		defeat_timer += delta
		hurt_flash_frames = 0
		queue_redraw()
		return
	if hurt_flash_frames > 0:
		hurt_flash_frames -= 1
	hurtstun_timer = maxf(hurtstun_timer - delta, 0.0)
	guard_timer = maxf(guard_timer - delta, 0.0)
	_update_movement(delta)
	_update_attack(delta, dummy)
	if slash_vfx_frames > 0:
		slash_vfx_frames -= 1
	queue_redraw()

func get_hurtbox() -> Rect2:
	if hurtstun_timer > 0.0 or guard_timer > 0.0 or move_state == MoveState.DEFEATED:
		return Rect2()
	return Rect2(position + Vector2(-18.0, -94.0), Vector2(36.0, 94.0))

func apply_enemy_hit(source_position: Vector2, damage: int = 10) -> void:
	if guard_timer > 0.0:
		return
	var away: int = 1 if position.x >= source_position.x else -1
	facing = -away
	velocity.x = 170.0 * float(away)
	if move_state == MoveState.GROUNDED:
		velocity.y = -120.0
		move_state = MoveState.AIRBORNE
	_end_attack(false)
	hurtstun_timer = 0.24
	hurt_flash_frames = 10
	health = maxi(health - damage, 0)
	if health <= 0:
		_begin_defeat()
	queue_redraw()

func add_meter(amount: int) -> void:
	meter = clampi(meter + amount, 0, Tuning.METER_MAX)

func _update_movement(delta: float) -> void:
	if move_state == MoveState.DEFEATED:
		return
	var horizontal_intent: float = Input.get_axis(&"move_left", &"move_right")
	var depth_intent: float = Input.get_axis(&"move_up", &"move_down")
	if attack_phase == AttackPhase.READY and not is_zero_approx(horizontal_intent):
		facing = 1 if horizontal_intent > 0.0 else -1

	if move_state == MoveState.GROUNDED:
		if not _movement_locked():
			depth = clampf(depth + depth_intent * Tuning.DEPTH_SPEED * delta, Tuning.STAGE_DEPTH_TOP, Tuning.STAGE_DEPTH_BOTTOM)
		if is_zero_approx(horizontal_intent) or _movement_locked():
			velocity.x = move_toward(velocity.x, 0.0, Tuning.GROUND_DECELERATION * delta)
		else:
			velocity.x = move_toward(
				velocity.x,
				horizontal_intent * Tuning.GROUND_MAX_SPEED,
				Tuning.GROUND_ACCELERATION * delta
			)
		if Input.is_action_just_pressed(&"jump") and attack_phase == AttackPhase.READY:
			velocity.y = -sqrt(2.0 * Tuning.GRAVITY * Tuning.JUMP_HEIGHT)
			move_state = MoveState.AIRBORNE
	else:
		if not _movement_locked():
			depth = clampf(depth + depth_intent * Tuning.DEPTH_SPEED * 0.65 * delta, Tuning.STAGE_DEPTH_TOP, Tuning.STAGE_DEPTH_BOTTOM)
		if not _movement_locked():
			velocity.x = move_toward(
				velocity.x,
				horizontal_intent * Tuning.AIR_MAX_SPEED,
				Tuning.AIR_ACCELERATION * delta
			)
		velocity.y = minf(velocity.y + Tuning.GRAVITY * delta, Tuning.MAX_FALL_SPEED)

	position += velocity * delta
	position.x = clampf(position.x, stage_left, stage_right)
	var ground_y: float = _ground_y()
	if position.y >= ground_y:
		position.y = ground_y
		velocity.y = 0.0
		move_state = MoveState.GROUNDED
		if current_attack == &"air_slash":
			_end_attack(true)
	else:
		move_state = MoveState.AIRBORNE

func _movement_locked() -> bool:
	return attack_phase != AttackPhase.READY or hurtstun_timer > 0.0

func _update_attack(delta: float, dummy: Variant) -> void:
	if move_state == MoveState.DEFEATED:
		return
	if attack_phase == AttackPhase.READY:
		if _super_pressed() and _can_pay(&"super"):
			_start_attack(&"super")
		elif Input.is_action_just_pressed(&"launcher") and _can_pay(&"ki_blast"):
			_start_attack(&"ki_blast")
		elif Input.is_action_just_pressed(&"light_attack"):
			if move_state == MoveState.AIRBORNE:
				_start_attack(&"air_slash")
			else:
				_start_attack(&"light_1")
		return

	_capture_buffer()
	phase_frame += 1
	var data: Dictionary = Tuning.ATTACKS[current_attack]
	if attack_phase == AttackPhase.STARTUP and phase_frame >= int(data[&"startup"]):
		attack_phase = AttackPhase.ACTIVE
		phase_frame = 0
		active_frame_index = 0
	elif attack_phase == AttackPhase.ACTIVE:
		active_frame_index += 1
		_apply_attack_advance(data, delta)
		_check_targets(dummy)
		if phase_frame >= int(data[&"active"]):
			attack_phase = AttackPhase.RECOVERY
			phase_frame = 0
	elif attack_phase == AttackPhase.RECOVERY:
		_try_consume_chain(data)
		if attack_phase == AttackPhase.RECOVERY and phase_frame >= int(data[&"recovery"]):
			_end_attack(true)

func _capture_buffer() -> void:
	if buffered_action != &"":
		buffer_age += 1
	if _super_pressed() and _can_pay(&"super"):
		buffered_action = &"super"
		buffer_age = 0
	elif Input.is_action_just_pressed(&"launcher") and _can_pay(&"ki_blast"):
		buffered_action = &"ki_blast"
		buffer_age = 0
	elif Input.is_action_just_pressed(&"light_attack"):
		buffered_action = &"light_attack"
		buffer_age = 0

func _try_consume_chain(data: Dictionary) -> void:
	if _try_consume_special(data):
		return
	var chain_start: int = int(data[&"chain_start"])
	var chain_end: int = int(data[&"chain_end"])
	if chain_start < 0:
		return
	if bool(data.get(&"auto_chain", false)) and phase_frame >= chain_start and phase_frame <= chain_end:
		_start_attack(data[&"next_attack"])
		return
	var expected_action: StringName = data[&"next_action"]
	if phase_frame < chain_start or phase_frame > chain_end:
		return
	if buffered_action == expected_action and buffer_age <= int(data[&"buffer"]):
		_start_attack(data[&"next_attack"])

func _try_consume_special(data: Dictionary) -> bool:
	if buffered_action != &"super" and buffered_action != &"ki_blast":
		return false
	var start: int = int(data.get(&"special_chain_start", 0))
	var end: int = int(data.get(&"special_chain_end", int(data[&"recovery"])))
	if phase_frame < start or phase_frame > end:
		return false
	if buffer_age > int(data.get(&"buffer", 6)):
		return false
	if not _can_pay(buffered_action):
		return false
	_start_attack(buffered_action)
	return true

func _start_attack(attack_id: StringName) -> void:
	if not _pay_attack_cost(attack_id):
		return
	current_attack = attack_id
	attack_phase = AttackPhase.STARTUP
	phase_frame = 0
	active_frame_index = 0
	attack_instance_id += 1
	hit_targets.clear()
	buffered_action = &""
	buffer_age = 0
	slash_vfx_frames = 8
	match attack_id:
		&"light_1":
			route_step = 1
		&"light_2":
			route_step = 2
		&"light_3":
			route_step = 3
		&"launcher":
			route_step = 4
		&"air_slash":
			route_step = 5
			velocity.y = maxf(velocity.y, Tuning.AIR_SLASH_MIN_FALL_SPEED)
		&"ki_blast":
			route_step = 6
		&"super":
			route_step = 7
			guard_timer = float(Tuning.ATTACKS[&"super"].get(&"guard_time", 1.0))
	attack_started.emit(attack_id)

func _end_attack(drop_route: bool) -> void:
	attack_phase = AttackPhase.READY
	current_attack = &""
	phase_frame = 0
	active_frame_index = 0
	buffered_action = &""
	buffer_age = 0
	debug_hitbox = Rect2()
	if drop_route:
		route_step = 0
		route_dropped.emit()

func _check_targets(targets: Variant) -> void:
	if targets is Array:
		for target: Node2D in targets:
			_check_hit(target)
	elif targets != null:
		_check_hit(targets)

func _check_hit(dummy: Node2D) -> void:
	var data: Dictionary = Tuning.ATTACKS[current_attack]
	var hitbox: Rect2 = _world_hitbox(data[&"hitbox"])
	debug_hitbox = hitbox
	var allow_downed: bool = bool(data.get(&"allow_downed", false))
	var bypass_getup_invulnerable: bool = current_attack == &"ki_blast" or current_attack == &"super"
	if not _depth_matches(dummy, data):
		return
	if not hitbox.intersects(dummy.get_hurtbox(allow_downed, bypass_getup_invulnerable)):
		return
	var hit_key: String = "%s_%s_%s" % [dummy.get_instance_id(), attack_instance_id, _hit_slice(data)]
	if hit_targets.has(hit_key):
		return
	hit_targets[hit_key] = true
	var hit_event: Dictionary = {
		&"hit_event_id": "%s_%s_%s" % [attack_instance_id, dummy.get_instance_id(), _hit_slice(data)],
		&"attack_instance_id": attack_instance_id,
		&"target_id": dummy.get_instance_id(),
		&"attack_id": current_attack,
		&"route_step": route_step,
		&"hit_type": data[&"hit_type"],
		&"active_frame_index": active_frame_index,
		&"hit_position": hitbox.get_center(),
		&"source_position": position,
		&"depth": depth,
		&"hit_direction": Vector2(float(facing), -0.65 if current_attack == &"launcher" else 0.0).normalized(),
		&"facing": facing,
		&"knockback": data[&"knockback"],
		&"damage": data[&"damage"],
		&"meter_gain": data[&"meter_gain"],
		&"allow_downed": allow_downed,
		&"hitstop_frames": data[&"hitstop"],
		&"shake": data[&"shake"],
	}
	hit_confirmed.emit(hit_event)

func _hit_slice(data: Dictionary) -> int:
	var max_hits: int = maxi(int(data.get(&"max_hits", 1)), 1)
	if max_hits == 1:
		return 0
	var active_frames: int = maxi(int(data[&"active"]), 1)
	var slice_size: int = maxi(int(ceil(float(active_frames) / float(max_hits))), 1)
	return mini(int(floor(float(active_frame_index) / float(slice_size))), max_hits - 1)

func _apply_attack_advance(data: Dictionary, delta: float) -> void:
	var advance: float = float(data.get(&"advance", 0.0))
	if advance <= 0.0:
		return
	position.x = clampf(position.x + advance * float(facing) * delta, stage_left, stage_right)

func set_stage_bounds(left: float, right: float) -> void:
	stage_left = left
	stage_right = right
	position.x = clampf(position.x, stage_left, stage_right)

func _depth_matches(dummy: Node2D, data: Dictionary) -> bool:
	if not "depth" in dummy:
		return true
	return absf(depth - float(dummy.depth)) <= float(data.get(&"depth_range", 0.0))

func _super_pressed() -> bool:
	return (Input.is_action_pressed(&"light_attack") and Input.is_action_just_pressed(&"launcher")) or (Input.is_action_pressed(&"launcher") and Input.is_action_just_pressed(&"light_attack"))

func _can_pay(attack_id: StringName) -> bool:
	return meter >= int(Tuning.ATTACKS[attack_id].get(&"cost", 0))

func _pay_attack_cost(attack_id: StringName) -> bool:
	var cost: int = int(Tuning.ATTACKS[attack_id].get(&"cost", 0))
	if meter < cost:
		return false
	meter -= cost
	return true

func _begin_defeat() -> void:
	health = 0
	move_state = MoveState.DEFEATED
	attack_phase = AttackPhase.READY
	current_attack = &""
	velocity = Vector2.ZERO
	defeat_timer = 0.0
	debug_hitbox = Rect2()

func _world_hitbox(local_rect: Rect2) -> Rect2:
	var x: float = local_rect.position.x if facing > 0 else -local_rect.position.x - local_rect.size.x
	return Rect2(position + Vector2(x, local_rect.position.y), local_rect.size)

func _ground_y() -> float:
	return Tuning.GROUND_Y + depth

func _ground_position() -> Vector2:
	return Vector2(Tuning.PLAYER_START.x, _ground_y())

func _draw() -> void:
	var body_color: Color = Color("#8E2F2D") if hurt_flash_frames > 0 else Color("#2b3135")
	var trim_color: Color = Color("#F4F0DC")
	var sword_color: Color = Color("#F4F0DC")
	var accent_color: Color = Color("#6EC6C4") if move_state == MoveState.AIRBORNE or guard_timer > 0.0 else Color("#F2B84B")
	var flip: float = float(facing)
	if move_state == MoveState.DEFEATED:
		var blink_alpha: float = 0.45 + 0.35 * absf(sin(defeat_timer * 10.0))
		draw_rect(Rect2(Vector2(-50.0, -28.0), Vector2(100.0, 24.0)), Color(0.55, 0.18, 0.18, blink_alpha))
		draw_rect(Rect2(Vector2(-54.0, -32.0), Vector2(108.0, 32.0)), Color("#141414"), false, 3.0)
		draw_circle(Vector2(48.0 * flip, -18.0), 15.0, Color(0.55, 0.18, 0.18, blink_alpha))
		draw_circle(Vector2(48.0 * flip, -18.0), 17.0, Color("#141414"), false, 3.0)
		return
	draw_rect(Rect2(Vector2(-16.0, -72.0), Vector2(32.0, 68.0)), body_color)
	draw_rect(Rect2(Vector2(-18.0, -74.0), Vector2(36.0, 72.0)), Color("#141414"), false, 3.0)
	draw_circle(Vector2(0.0, -88.0), 14.0, body_color)
	draw_circle(Vector2(0.0, -88.0), 16.0, Color("#141414"), false, 3.0)
	draw_line(Vector2(-8.0, -42.0), Vector2(24.0 * flip, -24.0), trim_color, 4.0)
	draw_line(Vector2(8.0 * flip, -58.0), Vector2(54.0 * flip, -72.0), sword_color, 5.0)
	if slash_vfx_frames > 0:
		var data: Dictionary = Tuning.ATTACKS.get(current_attack, {})
		var hit_type: StringName = data.get(&"hit_type", &"light")
		var vfx_color: Color = Color("#6EC6C4") if hit_type == &"launcher" or hit_type == &"air" or hit_type == &"ki" else Color("#F2B84B")
		var radius: float = 70.0 if hit_type == &"super" else 52.0 if hit_type == &"ki" else 42.0
		draw_arc(Vector2(48.0 * flip, -58.0), radius, -0.8 if flip > 0 else 2.4, 0.8 if flip > 0 else 3.8, 14, vfx_color, 5.0)
	if guard_timer > 0.0:
		draw_circle(Vector2.ZERO, 58.0, Color(0.43, 0.78, 0.77, 0.18))
		draw_circle(Vector2.ZERO, 60.0, Color("#6EC6C4"), false, 3.0)
	if debug_hitbox.size != Vector2.ZERO:
		var local_debug: Rect2 = Rect2(debug_hitbox.position - position, debug_hitbox.size)
		draw_rect(local_debug, Color(0.2, 0.8, 1.0, 0.20), true)
		draw_rect(local_debug, Color(0.2, 0.8, 1.0, 0.75), false, 2.0)
	draw_circle(Vector2(-10.0, -4.0), 5.0, accent_color)
	draw_circle(Vector2(10.0, -4.0), 5.0, accent_color)
