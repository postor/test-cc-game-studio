class_name TrainingDummy
extends Node2D

const Tuning := preload("res://scripts/combat_tuning.gd")

signal attack_connected(hit_event: Dictionary)
signal defeated()

enum EnemyType { SMALL, DASHER, RANGED, BOSS }
enum State { IDLE, HITSTUN, AIRBORNE, DOWNED, DOWNED_BOUNCE, GETTING_UP, CHASE, ATTACK_WINDUP, ATTACK_ACTIVE, ATTACK_RECOVERY, DASH_WINDUP, DASH_ACTIVE, DASH_RECOVERY, RANGED_WINDUP, RANGED_RECOVERY, BOSS_PULSE_WINDUP, BOSS_PULSE_ACTIVE, BOSS_SWEEP_WINDUP, BOSS_SWEEP_ACTIVE, DEAD }

const DOWNED_DURATION: float = 0.85
const GETUP_DURATION: float = 0.35
const CHASE_SPEED: float = 115.0
const CHASE_STOP_DISTANCE: float = 68.0
const ATTACK_RANGE: float = 104.0
const ATTACK_WINDUP_DURATION: float = 0.28
const ATTACK_ACTIVE_DURATION: float = 0.16
const ATTACK_RECOVERY_DURATION: float = 0.48
const ATTACK_COOLDOWN_DURATION: float = 0.30
const ATTACK_HITBOX: Rect2 = Rect2(-104.0, -64.0, 62.0, 34.0)
const DASH_TRIGGER_RANGE: float = 230.0
const DASH_MIN_RANGE: float = 118.0
const DASH_WINDUP_DURATION: float = 0.82
const DASH_ACTIVE_DURATION: float = 0.24
const DASH_RECOVERY_DURATION: float = 0.62
const DASH_SPEED: float = 470.0
const DASH_HITBOX: Rect2 = Rect2(-86.0, -88.0, 74.0, 66.0)
const HAZARD_LOOKAHEAD_X: float = 92.0
const HAZARD_DEPTH_PADDING: float = 8.0
const HAZARD_CLEAR_DEPTH_PADDING: float = 18.0
const HAZARD_EDGE_PADDING: float = 18.0
const RANGED_KEEP_RANGE: float = 270.0
const RANGED_WINDUP_DURATION: float = 0.70
const RANGED_RECOVERY_DURATION: float = 0.52
const PROJECTILE_SPEED: float = 360.0
const PROJECTILE_LIFE: float = 1.45
const PROJECTILE_DEPTH_RANGE: float = 24.0
const PROJECTILE_HITBOX: Vector2 = Vector2(34.0, 24.0)
const BOSS_PULSE_RANGE_X: float = 118.0
const BOSS_PULSE_DEPTH_RANGE: float = 54.0
const BOSS_PULSE_WINDUP_DURATION: float = 0.58
const BOSS_PULSE_ACTIVE_DURATION: float = 0.20
const BOSS_SWEEP_WINDUP_DURATION: float = 0.82
const BOSS_SWEEP_ACTIVE_DURATION: float = 0.28
const BOSS_SWEEP_RANGE_X: float = 260.0
const BOSS_SWEEP_DEPTH_RANGE: float = 96.0
const NORMAL_DAMAGE: int = 8
const DASH_DAMAGE: int = 12
const PROJECTILE_DAMAGE: int = 5
const BOSS_PULSE_DAMAGE: int = 16
const BOSS_SWEEP_DAMAGE: int = 18

var velocity: Vector2 = Vector2.ZERO
var depth: float = 0.0
var enemy_type: EnemyType = EnemyType.SMALL
var state: State = State.IDLE
var facing: int = -1
var flash_frames: int = 0
var squash: float = 0.0
var state_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var attack_has_connected: bool = false
var health: int = Tuning.DUMMY_MAX_HEALTH
var corpse_timer: float = 0.0
var spawn_position: Vector2 = Tuning.DUMMY_START
var spawn_depth: float = 0.0
var projectiles: Array[Dictionary] = []
var debug_attack_hitbox: Rect2 = Rect2()
var stage_left: float = Tuning.STAGE_LEFT
var stage_right: float = Tuning.STAGE_RIGHT
var terrain_holes: Array[Dictionary] = []
var path_plan_active: bool = false
var path_plan_direction: float = 0.0
var path_plan_target_depth: float = 0.0
var hazard_avoid_top: float = 0.0
var hazard_avoid_bottom: float = 0.0
var hazard_avoid_left: float = 0.0
var hazard_avoid_right: float = 0.0

func reset_dummy(new_spawn_position: Vector2 = Tuning.DUMMY_START, new_depth: float = 0.0, new_type: EnemyType = EnemyType.SMALL) -> void:
	stage_left = Tuning.STAGE_LEFT
	stage_right = Tuning.STAGE_RIGHT
	terrain_holes.clear()
	spawn_position = new_spawn_position
	spawn_depth = clampf(new_depth, Tuning.STAGE_DEPTH_TOP, Tuning.STAGE_DEPTH_BOTTOM)
	enemy_type = new_type
	depth = spawn_depth
	position = _ground_position()
	velocity = Vector2.ZERO
	state = State.IDLE
	facing = -1
	flash_frames = 0
	squash = 0.0
	state_timer = 0.0
	attack_cooldown_timer = 0.0
	attack_has_connected = false
	health = _max_health()
	corpse_timer = 0.0
	projectiles.clear()
	debug_attack_hitbox = Rect2()
	_clear_hazard_avoidance()
	queue_redraw()

func get_hurtbox(allow_downed: bool = false, bypass_getup_invulnerable: bool = false) -> Rect2:
	if state == State.DEAD:
		return Rect2()
	if state == State.DOWNED or state == State.DOWNED_BOUNCE:
		if allow_downed:
			return Rect2(position + Vector2(-56.0, -36.0), Vector2(112.0, 42.0))
		return Rect2()
	if state == State.GETTING_UP:
		if bypass_getup_invulnerable:
			return Rect2(position + Vector2(-28.0, -78.0), Vector2(56.0, 78.0))
		return Rect2()
	return Rect2(position + Vector2(-24.0, -96.0), Vector2(48.0, 96.0))

func is_neutral() -> bool:
	return state == State.IDLE or state == State.CHASE or state == State.ATTACK_WINDUP or state == State.ATTACK_ACTIVE or state == State.ATTACK_RECOVERY

func apply_hit(hit_event: Dictionary) -> void:
	var damage: int = int(hit_event.get(&"damage", 0))
	health = maxi(health - damage, 0)
	if health <= 0:
		_begin_dead()
		defeated.emit()
		return
	if (state == State.DOWNED or state == State.DOWNED_BOUNCE) and bool(hit_event.get(&"allow_downed", false)):
		_apply_downed_hit(hit_event)
		return

	var hit_type: StringName = StringName(hit_event.get(&"hit_type", &""))
	var knockback: Vector2 = hit_event[&"knockback"]
	var horizontal_direction: float = float(hit_event.get(&"facing", 1))
	if hit_type == &"super" and hit_event.has(&"source_position"):
		horizontal_direction = signf(position.x - Vector2(hit_event[&"source_position"]).x)
		if is_zero_approx(horizontal_direction):
			horizontal_direction = float(hit_event.get(&"facing", 1))
	velocity.x = knockback.x * horizontal_direction
	if knockback.y < 0.0:
		velocity.y = knockback.y
		state = State.AIRBORNE
	elif position.y < _ground_y() - 1.0:
		velocity.y = maxf(velocity.y, knockback.y)
		state = State.AIRBORNE
	else:
		state = State.HITSTUN
	state_timer = 0.0
	attack_has_connected = false
	debug_attack_hitbox = Rect2()
	flash_frames = 7
	squash = 1.0
	queue_redraw()

func _apply_downed_hit(hit_event: Dictionary) -> void:
	var hit_type: StringName = StringName(hit_event[&"hit_type"])
	var knockback: Vector2 = hit_event[&"knockback"]
	var horizontal_direction: float = float(hit_event.get(&"facing", 1))
	if hit_type == &"super" and hit_event.has(&"source_position"):
		horizontal_direction = signf(position.x - Vector2(hit_event[&"source_position"]).x)
		if is_zero_approx(horizontal_direction):
			horizontal_direction = float(hit_event.get(&"facing", 1))
	var horizontal_scale: float = 1.0 if hit_type == &"super" else 0.25
	velocity.x = clampf(knockback.x * horizontal_scale * horizontal_direction, -420.0, 420.0)
	velocity.y = -360.0 if hit_type == &"super" else -120.0
	state = State.DOWNED_BOUNCE
	state_timer = 0.0
	attack_has_connected = false
	debug_attack_hitbox = Rect2()
	flash_frames = 6
	squash = 0.8
	queue_redraw()

func tick(delta: float, frozen: bool, player: Node2D = null) -> void:
	_update_projectiles(delta, player, frozen)
	if state == State.DEAD:
		corpse_timer += delta
		queue_redraw()
		return
	if frozen:
		return
	if flash_frames > 0:
		flash_frames -= 1
	squash = move_toward(squash, 0.0, delta * 6.0)
	attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)
	debug_attack_hitbox = Rect2()

	if state == State.AIRBORNE:
		velocity.y = minf(velocity.y + Tuning.GRAVITY * delta, Tuning.MAX_FALL_SPEED)
		position += velocity * delta
		velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
		var ground_y: float = _ground_y()
		if position.y >= ground_y:
			position.y = ground_y
			velocity = Vector2.ZERO
			state = State.DOWNED
			squash = 0.7
			state_timer = 0.0
	elif state == State.DOWNED_BOUNCE:
		velocity.y = minf(velocity.y + Tuning.GRAVITY * delta, Tuning.MAX_FALL_SPEED)
		position += velocity * delta
		velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
		var ground_y: float = _ground_y()
		if position.y >= ground_y:
			position.y = ground_y
			velocity = Vector2.ZERO
			state = State.DOWNED
			squash = 0.6
			state_timer = 0.0
	elif state == State.HITSTUN:
		position.x += velocity.x * delta
		velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
		if is_zero_approx(velocity.x):
			state = State.IDLE
			state_timer = 0.0
	elif state == State.DOWNED:
		state_timer += delta
		if state_timer >= DOWNED_DURATION:
			state = State.GETTING_UP
			state_timer = 0.0
	elif state == State.GETTING_UP:
		state_timer += delta
		if state_timer >= GETUP_DURATION:
			state = State.CHASE if player != null else State.IDLE
			state_timer = 0.0
			squash = 0.35
	elif player != null:
		_update_ai(delta, player)
	position.x = clampf(position.x, stage_left, stage_right)
	if state != State.AIRBORNE and state != State.DOWNED_BOUNCE:
		position.y = _ground_y()
	queue_redraw()

func _update_ai(delta: float, player: Node2D) -> void:
	var to_player: float = player.position.x - position.x
	var depth_delta: float = float(player.depth) - depth if "depth" in player else 0.0
	if absf(to_player) > 1.0:
		facing = 1 if to_player > 0.0 else -1

	match state:
		State.IDLE:
			state = State.CHASE
			state_timer = 0.0
		State.CHASE:
			if enemy_type == EnemyType.RANGED:
				_update_ranged_chase(delta, player, to_player, depth_delta)
				return
			if _avoid_hazard(delta, signf(to_player)):
				return
			if enemy_type == EnemyType.BOSS and _try_begin_boss_special(to_player, depth_delta):
				return
			if absf(depth_delta) <= Tuning.ENEMY_ATTACK_DEPTH_RANGE and attack_cooldown_timer <= 0.0:
				if absf(to_player) <= ATTACK_RANGE:
					_begin_attack(false)
					return
				if _can_dash_attack() and absf(to_player) <= DASH_TRIGGER_RANGE and absf(to_player) >= DASH_MIN_RANGE:
					_begin_attack(true)
					return
			if absf(to_player) <= ATTACK_RANGE and absf(depth_delta) <= Tuning.ENEMY_ATTACK_DEPTH_RANGE and attack_cooldown_timer <= 0.0:
				_begin_attack(false)
				return
			if absf(depth_delta) > 2.0 and not _following_hazard_path_plan():
				_move_depth(signf(depth_delta), delta)
			if absf(to_player) > CHASE_STOP_DISTANCE:
				_try_move_x(float(facing) * CHASE_SPEED * delta, delta)
		State.ATTACK_WINDUP:
			state_timer += delta
			if state_timer >= ATTACK_WINDUP_DURATION:
				state = State.ATTACK_ACTIVE
				state_timer = 0.0
				attack_has_connected = false
		State.ATTACK_ACTIVE:
			state_timer += delta
			_try_hit_player(player)
			if state_timer >= ATTACK_ACTIVE_DURATION:
				state = State.ATTACK_RECOVERY
				state_timer = 0.0
		State.ATTACK_RECOVERY:
			state_timer += delta
			if state_timer >= ATTACK_RECOVERY_DURATION:
				state = State.CHASE
				state_timer = 0.0
				attack_cooldown_timer = ATTACK_COOLDOWN_DURATION
		State.DASH_WINDUP:
			state_timer += delta
			if absf(to_player) > 1.0:
				facing = 1 if to_player > 0.0 else -1
			if _dash_path_hits_hazard(float(facing)):
				state = State.CHASE
				state_timer = 0.0
				attack_cooldown_timer = ATTACK_COOLDOWN_DURATION + 0.20
				return
			if state_timer >= DASH_WINDUP_DURATION:
				state = State.DASH_ACTIVE
				state_timer = 0.0
				attack_has_connected = false
		State.DASH_ACTIVE:
			state_timer += delta
			if not _try_move_x(float(facing) * DASH_SPEED * delta, delta):
				state = State.DASH_RECOVERY
				state_timer = 0.0
				return
			_try_hit_player(player, true)
			if state_timer >= DASH_ACTIVE_DURATION:
				state = State.DASH_RECOVERY
				state_timer = 0.0
		State.DASH_RECOVERY:
			state_timer += delta
			if state_timer >= DASH_RECOVERY_DURATION:
				state = State.CHASE
				state_timer = 0.0
				attack_cooldown_timer = ATTACK_COOLDOWN_DURATION + 0.35
		State.RANGED_WINDUP:
			state_timer += delta
			if absf(to_player) > 1.0:
				facing = 1 if to_player > 0.0 else -1
			if state_timer >= RANGED_WINDUP_DURATION:
				_spawn_projectile()
				state = State.RANGED_RECOVERY
				state_timer = 0.0
		State.RANGED_RECOVERY:
			state_timer += delta
			if state_timer >= RANGED_RECOVERY_DURATION:
				state = State.CHASE
				state_timer = 0.0
				attack_cooldown_timer = ATTACK_COOLDOWN_DURATION + 0.75
		State.BOSS_PULSE_WINDUP:
			state_timer += delta
			if state_timer >= BOSS_PULSE_WINDUP_DURATION:
				state = State.BOSS_PULSE_ACTIVE
				state_timer = 0.0
				attack_has_connected = false
		State.BOSS_PULSE_ACTIVE:
			state_timer += delta
			_try_hit_player_area(player, BOSS_PULSE_RANGE_X, BOSS_PULSE_DEPTH_RANGE, true)
			if state_timer >= BOSS_PULSE_ACTIVE_DURATION:
				state = State.ATTACK_RECOVERY
				state_timer = 0.0
		State.BOSS_SWEEP_WINDUP:
			state_timer += delta
			if absf(to_player) > 1.0:
				facing = 1 if to_player > 0.0 else -1
			if state_timer >= BOSS_SWEEP_WINDUP_DURATION:
				state = State.BOSS_SWEEP_ACTIVE
				state_timer = 0.0
				attack_has_connected = false
		State.BOSS_SWEEP_ACTIVE:
			state_timer += delta
			_try_hit_player_area(player, BOSS_SWEEP_RANGE_X, BOSS_SWEEP_DEPTH_RANGE, false)
			if state_timer >= BOSS_SWEEP_ACTIVE_DURATION:
				state = State.ATTACK_RECOVERY
				state_timer = 0.0

func _begin_attack(dash: bool = false) -> void:
	state = State.DASH_WINDUP if dash else State.ATTACK_WINDUP
	state_timer = 0.0
	velocity = Vector2.ZERO
	attack_has_connected = false

func _update_ranged_chase(delta: float, player: Node2D, to_player: float, depth_delta: float) -> void:
	if absf(to_player) > 1.0:
		facing = 1 if to_player > 0.0 else -1
	var retreat_direction: float = -float(facing)
	var hazard_avoided: bool = _avoid_hazard(delta, retreat_direction)
	if not hazard_avoided and absf(depth_delta) > 2.0 and not _following_hazard_path_plan():
		_move_depth(signf(depth_delta), delta)
	if absf(to_player) < RANGED_KEEP_RANGE - 40.0:
		_try_move_x(-float(facing) * CHASE_SPEED * 0.75 * delta, delta)
	elif absf(to_player) > RANGED_KEEP_RANGE + 50.0:
		_try_move_x(float(facing) * CHASE_SPEED * 0.65 * delta, delta)
	if absf(depth_delta) <= PROJECTILE_DEPTH_RANGE and attack_cooldown_timer <= 0.0:
		state = State.RANGED_WINDUP
		state_timer = 0.0
		attack_has_connected = false

func _try_begin_boss_special(to_player: float, depth_delta: float) -> bool:
	if attack_cooldown_timer > 0.0:
		return false
	if absf(to_player) <= BOSS_PULSE_RANGE_X and absf(depth_delta) <= BOSS_PULSE_DEPTH_RANGE:
		state = State.BOSS_PULSE_WINDUP
		state_timer = 0.0
		return true
	if absf(to_player) <= BOSS_SWEEP_RANGE_X and absf(depth_delta) <= BOSS_SWEEP_DEPTH_RANGE:
		state = State.BOSS_SWEEP_WINDUP
		state_timer = 0.0
		return true
	return false

func _can_dash_attack() -> bool:
	return enemy_type == EnemyType.DASHER or enemy_type == EnemyType.BOSS

func _try_move_x(delta_x: float, delta: float) -> bool:
	if is_zero_approx(delta_x):
		return true
	var next_x: float = clampf(position.x + delta_x, stage_left, stage_right)
	if _point_in_hazard(next_x, depth):
		_avoid_hazard(delta, signf(delta_x))
		return false
	position.x = next_x
	return true

func _move_depth(direction: float, delta: float) -> bool:
	if is_zero_approx(direction):
		return true
	var next_depth: float = clampf(depth + direction * Tuning.DEPTH_CHASE_SPEED * delta, Tuning.STAGE_DEPTH_TOP, Tuning.STAGE_DEPTH_BOTTOM)
	if _point_in_hazard(position.x, next_depth) and not _moving_toward_hazard_exit(direction):
		return false
	depth = next_depth
	return true

func _avoid_hazard(delta: float, travel_direction: float) -> bool:
	if _advance_hazard_path_plan(delta):
		return true
	var hazard: Dictionary = _hazard_ahead(travel_direction)
	if hazard.is_empty():
		return false
	var top: float = float(hazard[&"top"]) - HAZARD_DEPTH_PADDING
	var bottom: float = float(hazard[&"bottom"]) + HAZARD_DEPTH_PADDING
	var direction: float = _safe_depth_direction(top, bottom)
	_start_hazard_path_plan(hazard, direction)
	_advance_hazard_path_plan(delta)
	return true

func _advance_hazard_path_plan(delta: float) -> bool:
	if not path_plan_active or is_zero_approx(path_plan_direction):
		return false
	if not _inside_hazard_commit_corridor():
		_clear_hazard_avoidance()
		return false
	if _path_plan_depth_reached():
		return false
	_move_depth(path_plan_direction, delta * 1.35)
	return true

func _start_hazard_path_plan(hazard: Dictionary, direction: float) -> void:
	if is_zero_approx(direction):
		return
	if path_plan_active:
		return
	path_plan_active = true
	path_plan_direction = direction
	hazard_avoid_top = float(hazard[&"top"]) - HAZARD_DEPTH_PADDING
	hazard_avoid_bottom = float(hazard[&"bottom"]) + HAZARD_DEPTH_PADDING
	hazard_avoid_left = float(hazard[&"x"]) - HAZARD_EDGE_PADDING
	hazard_avoid_right = float(hazard[&"x"]) + float(hazard[&"w"]) + HAZARD_EDGE_PADDING
	path_plan_target_depth = hazard_avoid_top - HAZARD_CLEAR_DEPTH_PADDING if direction < 0.0 else hazard_avoid_bottom + HAZARD_CLEAR_DEPTH_PADDING

func _path_plan_depth_reached() -> bool:
	return depth <= path_plan_target_depth if path_plan_direction < 0.0 else depth >= path_plan_target_depth

func _following_hazard_path_plan() -> bool:
	if not path_plan_active or is_zero_approx(path_plan_direction):
		return false
	if not _inside_hazard_commit_corridor():
		_clear_hazard_avoidance()
		return false
	return _path_plan_depth_reached()

func _inside_hazard_commit_corridor() -> bool:
	return position.x >= hazard_avoid_left - HAZARD_LOOKAHEAD_X and position.x <= hazard_avoid_right + HAZARD_LOOKAHEAD_X

func _clear_hazard_avoidance() -> void:
	path_plan_active = false
	path_plan_direction = 0.0
	path_plan_target_depth = 0.0
	hazard_avoid_top = 0.0
	hazard_avoid_bottom = 0.0
	hazard_avoid_left = 0.0
	hazard_avoid_right = 0.0

func _hazard_ahead(travel_direction: float) -> Dictionary:
	if terrain_holes.is_empty():
		return {}
	var direction: float = travel_direction
	if is_zero_approx(direction):
		direction = float(facing)
	var ahead_x: float = position.x + signf(direction) * HAZARD_LOOKAHEAD_X
	for hole: Dictionary in terrain_holes:
		var left: float = float(hole[&"x"]) - HAZARD_EDGE_PADDING
		var right: float = float(hole[&"x"]) + float(hole[&"w"]) + HAZARD_EDGE_PADDING
		var top: float = float(hole[&"top"]) - HAZARD_DEPTH_PADDING
		var bottom: float = float(hole[&"bottom"]) + HAZARD_DEPTH_PADDING
		var crossing: bool = (ahead_x >= left and ahead_x <= right) or (position.x >= left and position.x <= right)
		if crossing and depth >= top and depth <= bottom:
			return hole
	return {}

func _point_in_hazard(x: float, test_depth: float) -> bool:
	for hole: Dictionary in terrain_holes:
		var left: float = float(hole[&"x"])
		var right: float = left + float(hole[&"w"])
		var top: float = float(hole[&"top"])
		var bottom: float = float(hole[&"bottom"])
		if x >= left and x <= right and test_depth >= top and test_depth <= bottom:
			return true
	return false

func _moving_toward_hazard_exit(direction: float) -> bool:
	for hole: Dictionary in terrain_holes:
		var left: float = float(hole[&"x"])
		var right: float = left + float(hole[&"w"])
		var top: float = float(hole[&"top"])
		var bottom: float = float(hole[&"bottom"])
		if position.x >= left and position.x <= right and depth >= top and depth <= bottom:
			return direction < 0.0 if absf(depth - top) < absf(bottom - depth) else direction > 0.0
	return false

func _safe_depth_direction(top: float, bottom: float) -> float:
	if top <= Tuning.STAGE_DEPTH_TOP + 4.0:
		return 1.0
	if bottom >= Tuning.STAGE_DEPTH_BOTTOM - 4.0:
		return -1.0
	var up_target: float = top - 14.0
	var down_target: float = bottom + 14.0
	return -1.0 if absf(depth - up_target) < absf(down_target - depth) else 1.0

func _dash_path_hits_hazard(direction: float) -> bool:
	if terrain_holes.is_empty():
		return false
	var dash_end_x: float = position.x + direction * DASH_SPEED * DASH_ACTIVE_DURATION
	for hole: Dictionary in terrain_holes:
		var left: float = float(hole[&"x"])
		var right: float = left + float(hole[&"w"])
		var top: float = float(hole[&"top"])
		var bottom: float = float(hole[&"bottom"])
		var crosses_x: bool = minf(position.x, dash_end_x) <= right and maxf(position.x, dash_end_x) >= left
		if crosses_x and depth >= top and depth <= bottom:
			return true
	return false

func _try_hit_player(player: Node2D, dash: bool = false) -> void:
	var hitbox: Rect2 = _world_attack_hitbox(dash)
	debug_attack_hitbox = hitbox
	if attack_has_connected:
		return
	if not player.has_method("get_hurtbox") or not player.has_method("apply_enemy_hit"):
		return
	var hurtbox: Rect2 = player.get_hurtbox()
	if "depth" in player and absf(depth - float(player.depth)) > Tuning.ENEMY_ATTACK_DEPTH_RANGE:
		return
	if hurtbox.size == Vector2.ZERO or not hitbox.intersects(hurtbox):
		return
	attack_has_connected = true
	var hit_event: Dictionary = {
		&"hit_position": hitbox.get_center(),
		&"source_position": position,
		&"facing": facing,
	}
	player.apply_enemy_hit(position, DASH_DAMAGE if dash else NORMAL_DAMAGE)
	attack_connected.emit(hit_event)

func _try_hit_player_area(player: Node2D, range_x: float, range_depth: float, radial: bool) -> void:
	if attack_has_connected or not player.has_method("get_hurtbox") or not player.has_method("apply_enemy_hit"):
		return
	if "depth" in player and absf(depth - float(player.depth)) > range_depth:
		return
	var x_delta: float = absf(player.position.x - position.x) if radial else (player.position.x - position.x) * float(facing)
	if x_delta < 0.0 or absf(x_delta) > range_x:
		return
	if player.get_hurtbox().size == Vector2.ZERO:
		return
	attack_has_connected = true
	player.apply_enemy_hit(position, BOSS_PULSE_DAMAGE if radial else BOSS_SWEEP_DAMAGE)
	attack_connected.emit({
		&"hit_position": player.position + Vector2(0.0, -52.0),
		&"source_position": position,
		&"facing": facing,
	})

func _spawn_projectile() -> void:
	projectiles.append({
		&"position": position + Vector2(36.0 * float(facing), -56.0),
		&"depth": depth,
		&"facing": facing,
		&"life": PROJECTILE_LIFE,
		&"hit": false,
	})

func _update_projectiles(delta: float, player: Node2D, frozen: bool) -> void:
	if frozen:
		return
	for projectile: Dictionary in projectiles:
		projectile[&"life"] = float(projectile[&"life"]) - delta
		projectile[&"position"] = projectile[&"position"] + Vector2(PROJECTILE_SPEED * float(projectile[&"facing"]) * delta, 0.0)
		if player != null and not bool(projectile[&"hit"]) and _projectile_hits_player(projectile, player):
			projectile[&"hit"] = true
			player.apply_enemy_hit(projectile[&"position"], PROJECTILE_DAMAGE)
			attack_connected.emit({
				&"hit_position": projectile[&"position"],
				&"source_position": projectile[&"position"],
				&"facing": projectile[&"facing"],
			})
	projectiles = projectiles.filter(func(projectile: Dictionary) -> bool:
		return float(projectile[&"life"]) > 0.0 and not bool(projectile[&"hit"])
	)

func _projectile_hits_player(projectile: Dictionary, player: Node2D) -> bool:
	if not player.has_method("get_hurtbox"):
		return false
	if "depth" in player and absf(float(projectile[&"depth"]) - float(player.depth)) > PROJECTILE_DEPTH_RANGE:
		return false
	var pos: Vector2 = projectile[&"position"]
	var hitbox: Rect2 = Rect2(pos - PROJECTILE_HITBOX * 0.5, PROJECTILE_HITBOX)
	var hurtbox: Rect2 = player.get_hurtbox()
	return hurtbox.size != Vector2.ZERO and hitbox.intersects(hurtbox)

func _world_attack_hitbox(dash: bool = false) -> Rect2:
	var local_rect: Rect2 = DASH_HITBOX if dash else ATTACK_HITBOX
	var local_x: float = local_rect.position.x
	if facing > 0:
		local_x = -local_rect.position.x - local_rect.size.x
	return Rect2(position + Vector2(local_x, local_rect.position.y), local_rect.size)

func is_corpse_finished() -> bool:
	return state == State.DEAD and corpse_timer >= Tuning.DUMMY_CORPSE_DURATION

func set_stage_bounds(left: float, right: float) -> void:
	stage_left = left
	stage_right = right
	position.x = clampf(position.x, stage_left, stage_right)

func set_terrain_holes(holes: Array) -> void:
	terrain_holes.clear()
	for hole: Dictionary in holes:
		terrain_holes.append(hole.duplicate())

func kill_by_fall() -> void:
	health = 0
	_begin_dead()
	defeated.emit()

func _begin_dead() -> void:
	state = State.DEAD
	corpse_timer = 0.0
	velocity = Vector2.ZERO
	attack_has_connected = true
	debug_attack_hitbox = Rect2()
	flash_frames = 10

func _max_health() -> int:
	match enemy_type:
		EnemyType.SMALL:
			return 115
		EnemyType.RANGED:
			return 120
		EnemyType.DASHER:
			return 145
		EnemyType.BOSS:
			return 720
	return Tuning.DUMMY_MAX_HEALTH

func _ground_y() -> float:
	return Tuning.GROUND_Y + depth

func _ground_position() -> Vector2:
	return Vector2(spawn_position.x, _ground_y())

func _draw() -> void:
	var body_color: Color = _body_color()
	var edge_color: Color = Color("#3a2519")
	var flash_color: Color = Color("#F4F0DC")
	var draw_color: Color = flash_color if flash_frames > 0 else body_color
	if state == State.DEAD:
		if int(corpse_timer * 16.0) % 2 == 0:
			draw_rect(Rect2(Vector2(-54.0, -26.0), Vector2(108.0, 24.0)), Color("#7A5436"))
			draw_rect(Rect2(Vector2(-58.0, -30.0), Vector2(116.0, 32.0)), edge_color, false, 3.0)
			draw_circle(Vector2(52.0, -18.0), 16.0, Color("#7A5436"))
			draw_circle(Vector2(52.0, -18.0), 18.0, edge_color, false, 3.0)
		return
	if state == State.DOWNED or state == State.DOWNED_BOUNCE:
		draw_rect(Rect2(Vector2(-52.0, -28.0), Vector2(104.0, 26.0)), draw_color)
		draw_rect(Rect2(Vector2(-56.0, -32.0), Vector2(112.0, 34.0)), edge_color, false, 3.0)
		draw_circle(Vector2(50.0, -18.0), 16.0, draw_color)
		draw_circle(Vector2(50.0, -18.0), 18.0, edge_color, false, 3.0)
		return
	if state == State.GETTING_UP:
		draw_rect(Rect2(Vector2(-44.0, -42.0), Vector2(88.0, 36.0)), draw_color)
		draw_rect(Rect2(Vector2(-48.0, -46.0), Vector2(96.0, 44.0)), edge_color, false, 3.0)
		draw_circle(Vector2(28.0 * float(facing), -52.0), 17.0, draw_color)
		draw_circle(Vector2(28.0 * float(facing), -52.0), 19.0, edge_color, false, 3.0)
		return
	var squash_y: float = 1.0 - squash * 0.10
	var squash_x: float = 1.0 + squash * 0.08
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(squash_x, squash_y))
	draw_rect(Rect2(Vector2(-18.0, -94.0), Vector2(36.0, 92.0)), draw_color)
	draw_rect(Rect2(Vector2(-22.0, -98.0), Vector2(44.0, 100.0)), edge_color, false, 3.0)
	draw_rect(Rect2(Vector2(-36.0, -62.0), Vector2(72.0, 12.0)), draw_color)
	draw_rect(Rect2(Vector2(-40.0, -66.0), Vector2(80.0, 20.0)), edge_color, false, 3.0)
	draw_circle(Vector2(0.0, -104.0), 18.0, draw_color)
	draw_circle(Vector2(0.0, -104.0), 20.0, edge_color, false, 3.0)
	if state == State.RANGED_WINDUP:
		draw_circle(Vector2(38.0 * float(facing), -58.0), 18.0 + sin(state_timer * 20.0) * 3.0, Color(0.43, 0.78, 0.77, 0.28))
	if state == State.BOSS_PULSE_WINDUP or state == State.BOSS_PULSE_ACTIVE:
		draw_circle(Vector2.ZERO, BOSS_PULSE_RANGE_X * 0.5, Color(0.91, 0.36, 0.22, 0.12))
		draw_circle(Vector2.ZERO, BOSS_PULSE_RANGE_X * 0.5, Color("#E85D75"), false, 4.0)
	if state == State.BOSS_SWEEP_WINDUP or state == State.BOSS_SWEEP_ACTIVE:
		draw_rect(Rect2(Vector2(0.0 if facing > 0 else -BOSS_SWEEP_RANGE_X, -22.0), Vector2(BOSS_SWEEP_RANGE_X, 28.0)), Color(0.91, 0.36, 0.22, 0.20))
	if state == State.DASH_WINDUP:
		draw_circle(Vector2(0.0, -44.0), 48.0 + sin(state_timer * 18.0) * 4.0, Color(0.91, 0.36, 0.22, 0.16))
		draw_circle(Vector2(0.0, -44.0), 50.0, Color("#E85D75"), false, 3.0)
	if state == State.ATTACK_WINDUP or state == State.ATTACK_ACTIVE or state == State.ATTACK_RECOVERY or state == State.DASH_ACTIVE or state == State.DASH_RECOVERY:
		var arm_end: Vector2 = Vector2(62.0 * float(facing), -58.0)
		var arm_color: Color = Color("#C66B3D") if state == State.ATTACK_ACTIVE or state == State.DASH_ACTIVE else draw_color
		draw_line(Vector2(18.0 * float(facing), -58.0), arm_end, arm_color, 7.0)
		draw_circle(arm_end, 9.0, arm_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if debug_attack_hitbox.size != Vector2.ZERO:
		var local_debug: Rect2 = Rect2(debug_attack_hitbox.position - position, debug_attack_hitbox.size)
		draw_rect(local_debug, Color(1.0, 0.3, 0.15, 0.18), true)
		draw_rect(local_debug, Color(1.0, 0.3, 0.15, 0.75), false, 2.0)
	for projectile: Dictionary in projectiles:
		var local_pos: Vector2 = Vector2(projectile[&"position"]) - position
		draw_circle(local_pos, 12.0, Color("#6EC6C4"))
		draw_circle(local_pos, 14.0, Color("#F4F0DC"), false, 2.0)

func _body_color() -> Color:
	match enemy_type:
		EnemyType.RANGED:
			return Color("#4E6B78")
		EnemyType.DASHER:
			return Color("#8E4E2F")
		EnemyType.BOSS:
			return Color("#6B3F78")
	return Color("#7A5436")
