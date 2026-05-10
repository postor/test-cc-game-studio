extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const Tuning := preload("res://scripts/combat_tuning.gd")

const FPS: float = 60.0
const DURATION_SECONDS: float = 120.0

var main: Node
var player: Node2D
var dummies: Array
var last_health: int = 0
var damage_taken: int = 0
var defeats_seen: int = 0
var attack_presses: int = 0
var ki_presses: int = 0
var super_presses: int = 0

func _initialize() -> void:
	main = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	player = main.get("player")
	dummies = main.get("dummies")
	last_health = player.health
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)

	for frame: int in range(int(DURATION_SECONDS * FPS)):
		_drive_player(frame)
		main._process(1.0 / FPS)
		_collect_metrics()
		_release_actions()
		if main.get("game_over"):
			break

	_print_report()
	quit(0)

func _drive_player(frame: int) -> void:
	var target: Node2D = _pick_target()
	if target == null:
		return
	var x_delta: float = target.position.x - player.position.x
	var depth_delta: float = float(target.depth) - float(player.depth)

	var projectile_dodge: int = _projectile_dodge_direction()
	if projectile_dodge != 0:
		Input.action_press(&"move_down" if projectile_dodge > 0 else &"move_up")
		return
	var avoid_depth_direction: int = _hole_avoid_direction(x_delta)
	if avoid_depth_direction != 0:
		Input.action_press(&"move_down" if avoid_depth_direction > 0 else &"move_up")
		Input.action_press(&"move_left" if x_delta > 0.0 else &"move_right")
		return
	if absf(depth_delta) > 8.0:
		Input.action_press(&"move_down" if depth_delta > 0.0 else &"move_up")
	if absf(x_delta) > 74.0:
		Input.action_press(&"move_right" if x_delta > 0.0 else &"move_left")

	if _incoming_threat_near():
		if player.meter >= Tuning.SUPER_COST:
			Input.action_press(&"light_attack")
			Input.action_press(&"launcher")
			super_presses += 1
			return
		if absf(depth_delta) < 28.0:
			Input.action_press(&"move_down" if player.depth <= 0.0 else &"move_up")

	if player.attack_phase != player.AttackPhase.READY:
		return

	if player.meter >= Tuning.KI_STRIKE_COST and absf(x_delta) < 240.0 and absf(depth_delta) < 44.0 and _target_wants_ki(target):
		Input.action_press(&"launcher")
		ki_presses += 1
	elif player.meter >= Tuning.SUPER_COST and absf(x_delta) < 260.0 and absf(depth_delta) < 80.0 and _enemy_pressure_high():
		Input.action_press(&"light_attack")
		Input.action_press(&"launcher")
		super_presses += 1
	elif player.meter >= Tuning.KI_STRIKE_COST and absf(x_delta) < 240.0 and absf(depth_delta) < 44.0 and (frame % 14) == 0:
		Input.action_press(&"launcher")
		ki_presses += 1
	elif absf(x_delta) < 96.0 and absf(depth_delta) < 22.0:
		Input.action_press(&"light_attack")
		attack_presses += 1

func _release_actions() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down", &"light_attack", &"launcher"]:
		Input.action_release(action)

func _pick_target() -> Node2D:
	var best: Node2D = null
	var best_score: float = INF
	for target: Node2D in dummies:
		if target.state == target.State.DEAD:
			continue
		var score: float = absf(target.position.x - player.position.x) + absf(float(target.depth) - float(player.depth)) * 2.0
		if target.enemy_type == target.EnemyType.RANGED:
			score -= 90.0
		if target.enemy_type == target.EnemyType.BOSS:
			score -= 55.0
		if score < best_score:
			best_score = score
			best = target
	return best

func _projectile_dodge_direction() -> int:
	for target: Node2D in dummies:
		if target.enemy_type != target.EnemyType.RANGED and target.enemy_type != target.EnemyType.BOSS:
			continue
		for projectile: Dictionary in target.projectiles:
			var projectile_position: Vector2 = projectile[&"position"]
			var depth_delta: float = absf(float(projectile[&"depth"]) - float(player.depth))
			var x_delta: float = absf(projectile_position.x - player.position.x)
			if depth_delta <= 28.0 and x_delta <= 150.0:
				return 1 if player.depth <= 0.0 else -1
	return 0

func _incoming_threat_near() -> bool:
	for target: Node2D in dummies:
		if target.state == target.State.DASH_ACTIVE or target.state == target.State.BOSS_PULSE_ACTIVE or target.state == target.State.BOSS_SWEEP_ACTIVE:
			if absf(target.position.x - player.position.x) < 220.0 and absf(float(target.depth) - float(player.depth)) < 80.0:
				return true
		if target.enemy_type == target.EnemyType.RANGED and not target.projectiles.is_empty():
			return true
	return false

func _enemy_pressure_high() -> bool:
	var active_count: int = 0
	for target: Node2D in dummies:
		if target.state != target.State.DEAD:
			active_count += 1
	return active_count >= 2 or player.health <= 45

func _target_wants_ki(target: Node2D) -> bool:
	return target.state == target.State.AIRBORNE or target.state == target.State.DOWNED or target.state == target.State.DOWNED_BOUNCE

func _hole_avoid_direction(x_delta: float) -> int:
	if not main.has_method("_current_holes"):
		return 0
	var direction: float = signf(x_delta)
	if is_zero_approx(direction):
		direction = float(player.facing)
	for hole: Dictionary in main._current_holes():
		var left: float = float(hole[&"x"]) - 18.0
		var right: float = float(hole[&"x"]) + float(hole[&"w"]) + 18.0
		var top: float = float(hole[&"top"]) - 8.0
		var bottom: float = float(hole[&"bottom"]) + 8.0
		var ahead_x: float = player.position.x + direction * 180.0
		var crossing_hole: bool = ahead_x >= left and ahead_x <= right
		var already_over_hole: bool = player.position.x >= left and player.position.x <= right
		var unsafe_depth: bool = player.depth >= top and player.depth <= bottom
		if (crossing_hole or already_over_hole) and unsafe_depth:
			var up_distance: float = absf(player.depth - (top - 12.0))
			var down_distance: float = absf((bottom + 12.0) - player.depth)
			if top <= Tuning.STAGE_DEPTH_TOP + 4.0:
				return 1
			if bottom >= Tuning.STAGE_DEPTH_BOTTOM - 4.0:
				return -1
			return -1 if up_distance < down_distance else 1
	return 0

func _collect_metrics() -> void:
	if player.health < last_health:
		damage_taken += last_health - player.health
	last_health = player.health
	for target: Node2D in dummies:
		if target.state == target.State.DEAD and target.corpse_timer <= (1.0 / FPS) + 0.001:
			defeats_seen += 1

func _print_report() -> void:
	print("AUTO PLAYTEST REPORT")
	print("game_over=%s level=%d wave=%d" % [str(main.get("game_over")), main.get("current_level"), main.get("current_wave")])
	if main.get("game_over"):
		print("game_over_reason=%s" % String(main.get("game_over_reason")))
	print("player_health=%d meter=%d damage_taken=%d" % [player.health, player.meter, damage_taken])
	print("defeats_seen=%d best_combo=%d combo=%d" % [defeats_seen, main.get("best_combo"), main.get("combo_count")])
	print("inputs light=%d ki=%d super=%d" % [attack_presses, ki_presses, super_presses])
	for i: int in range(dummies.size()):
		var target: Node2D = dummies[i]
		print("enemy%d type=%s hp=%d state=%s depth=%.1f x=%.1f" % [
			i + 1,
			target.EnemyType.keys()[target.enemy_type],
			target.health,
			target.State.keys()[target.state],
			target.depth,
			target.position.x,
		])
