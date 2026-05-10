extends SceneTree

const PlayerScript := preload("res://scripts/player.gd")
const DummyScript := preload("res://scripts/training_dummy.gd")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	if not _test_chaser_changes_depth_before_hole():
		return
	if not _test_boss_changes_depth_before_hole():
		return
	if not _test_ranged_retreats_around_hole():
		return
	if not _test_dashers_cancel_hazard_dash():
		return
	if not _test_chaser_does_not_jitter_near_hole_edge():
		return
	print("ENEMY HAZARD AVOIDANCE TEST PASS")
	quit(0)

func _test_chaser_changes_depth_before_hole() -> bool:
	var player: Node2D = PlayerScript.new()
	var enemy: Node2D = DummyScript.new()
	root.add_child(enemy)
	root.add_child(player)
	player.reset_player()
	player.position.x = 760.0
	player.depth = -50.0
	player.position.y = Tuning.GROUND_Y + player.depth
	enemy.reset_dummy(Vector2(500.0, Tuning.GROUND_Y), -50.0, enemy.EnemyType.SMALL)
	enemy.set_stage_bounds(120.0, 1160.0)
	enemy.set_terrain_holes([{&"x": 610.0, &"w": 130.0, &"top": -76.0, &"bottom": -30.0}])
	enemy.state = enemy.State.CHASE
	for i: int in range(80):
		enemy.tick(1.0 / 60.0, false, player)
		if _point_in_hole(enemy.position.x, enemy.depth, -76.0, -30.0):
			push_error("Small enemy walked into a known hazard")
			quit(1)
			return false
	if enemy.depth <= -42.0:
		push_error("Small enemy did not change depth to avoid the hazard")
		quit(1)
		return false
	return true

func _test_boss_changes_depth_before_hole() -> bool:
	var player: Node2D = PlayerScript.new()
	var enemy: Node2D = DummyScript.new()
	root.add_child(enemy)
	root.add_child(player)
	player.reset_player()
	player.position.x = 760.0
	player.depth = -50.0
	player.position.y = Tuning.GROUND_Y + player.depth
	enemy.reset_dummy(Vector2(500.0, Tuning.GROUND_Y), -50.0, enemy.EnemyType.BOSS)
	enemy.set_stage_bounds(120.0, 1160.0)
	enemy.set_terrain_holes([{&"x": 610.0, &"w": 130.0, &"top": -76.0, &"bottom": -30.0}])
	enemy.state = enemy.State.CHASE
	for i: int in range(80):
		enemy.tick(1.0 / 60.0, false, player)
		if _point_in_hole(enemy.position.x, enemy.depth, -76.0, -30.0):
			push_error("Boss walked into a known hazard")
			quit(1)
			return false
	if enemy.depth <= -42.0:
		push_error("Boss did not change depth to avoid the hazard")
		quit(1)
		return false
	return true

func _test_ranged_retreats_around_hole() -> bool:
	var player: Node2D = PlayerScript.new()
	var enemy: Node2D = DummyScript.new()
	root.add_child(enemy)
	root.add_child(player)
	player.reset_player()
	player.position.x = 520.0
	player.depth = 50.0
	player.position.y = Tuning.GROUND_Y + player.depth
	enemy.reset_dummy(Vector2(585.0, Tuning.GROUND_Y), 50.0, enemy.EnemyType.RANGED)
	enemy.set_stage_bounds(120.0, 1160.0)
	enemy.set_terrain_holes([{&"x": 610.0, &"w": 130.0, &"top": 30.0, &"bottom": 78.0}])
	enemy.state = enemy.State.CHASE
	for i: int in range(80):
		enemy.tick(1.0 / 60.0, false, player)
		if _point_in_hole(enemy.position.x, enemy.depth, 30.0, 78.0):
			push_error("Ranged enemy retreated into a known hazard")
			quit(1)
			return false
	if enemy.depth >= 42.0:
		push_error("Ranged enemy did not leave the hazardous depth band")
		quit(1)
		return false
	return true

func _test_dashers_cancel_hazard_dash() -> bool:
	for type_name: StringName in [&"DASHER", &"BOSS"]:
		var player: Node2D = PlayerScript.new()
		var enemy: Node2D = DummyScript.new()
		root.add_child(enemy)
		root.add_child(player)
		player.reset_player()
		player.position.x = 740.0
		player.depth = -50.0
		player.position.y = Tuning.GROUND_Y + player.depth
		var enemy_type: int = enemy.EnemyType.BOSS if type_name == &"BOSS" else enemy.EnemyType.DASHER
		enemy.reset_dummy(Vector2(500.0, Tuning.GROUND_Y), -50.0, enemy_type)
		enemy.set_stage_bounds(120.0, 1160.0)
		enemy.set_terrain_holes([{&"x": 610.0, &"w": 130.0, &"top": -76.0, &"bottom": -30.0}])
		enemy.state = enemy.State.CHASE
		for i: int in range(70):
			enemy.tick(1.0 / 60.0, false, player)
			if enemy.state == enemy.State.DASH_ACTIVE:
				push_error("%s enemy started a dash through a known hazard" % type_name)
				quit(1)
				return false
			if _point_in_hole(enemy.position.x, enemy.depth, -76.0, -30.0):
				push_error("%s enemy entered a known hazard while avoiding dash" % type_name)
				quit(1)
				return false
	return true

func _test_chaser_does_not_jitter_near_hole_edge() -> bool:
	var player: Node2D = PlayerScript.new()
	var enemy: Node2D = DummyScript.new()
	root.add_child(enemy)
	root.add_child(player)
	player.reset_player()
	player.position.x = 760.0
	player.depth = -50.0
	player.position.y = Tuning.GROUND_Y + player.depth
	enemy.reset_dummy(Vector2(590.0, Tuning.GROUND_Y), -50.0, enemy.EnemyType.SMALL)
	enemy.set_stage_bounds(120.0, 1160.0)
	enemy.set_terrain_holes([{&"x": 610.0, &"w": 130.0, &"top": -76.0, &"bottom": -30.0}])
	enemy.state = enemy.State.CHASE
	var last_sign: int = 0
	var sign_flips: int = 0
	for i: int in range(80):
		var previous_depth: float = enemy.depth
		enemy.tick(1.0 / 60.0, false, player)
		if _point_in_hole(enemy.position.x, enemy.depth, -76.0, -30.0):
			push_error("Small enemy entered a hazard while testing edge jitter")
			quit(1)
			return false
		var depth_step: float = enemy.depth - previous_depth
		if absf(depth_step) > 0.01:
			var step_sign: int = 1 if depth_step > 0.0 else -1
			if last_sign != 0 and step_sign != last_sign:
				sign_flips += 1
			last_sign = step_sign
	if sign_flips > 1:
		push_error("Small enemy jittered near hazard edge with %d depth direction flips" % sign_flips)
		quit(1)
		return false
	return true

func _point_in_hole(x: float, depth: float, top: float, bottom: float) -> bool:
	return x >= 610.0 and x <= 740.0 and depth >= top and depth <= bottom
