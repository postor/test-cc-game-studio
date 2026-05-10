extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const PlayerScript := preload("res://scripts/player.gd")
const DummyScript := preload("res://scripts/training_dummy.gd")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	if not _test_projectile_hit_and_depth_dodge():
		return
	if not _test_boss_damage_tools():
		return
	if not await _test_main_area_config_keeps_enemy_types():
		return
	print("ENEMY BEHAVIOR TEST PASS")
	quit(0)

func _test_projectile_hit_and_depth_dodge() -> bool:
	var player: Node2D = PlayerScript.new()
	var ranged: Node2D = DummyScript.new()
	root.add_child(ranged)
	root.add_child(player)
	player.reset_player()
	ranged.reset_dummy(Vector2(640.0, Tuning.GROUND_Y), 0.0, ranged.EnemyType.RANGED)
	ranged.projectiles.append({
		&"position": Vector2(player.position.x - 20.0, player.position.y - 52.0),
		&"depth": player.depth,
		&"facing": 1,
		&"life": 1.0,
		&"hit": false,
	})
	var start_health: int = player.health
	ranged.tick(1.0 / 60.0, false, player)
	if player.health >= start_health:
		push_error("Ranged projectile did not damage player on the same depth lane")
		quit(1)
		return false

	player.reset_player()
	ranged.reset_dummy(Vector2(640.0, Tuning.GROUND_Y), 0.0, ranged.EnemyType.RANGED)
	ranged.projectiles.append({
		&"position": Vector2(player.position.x - 20.0, player.position.y - 52.0),
		&"depth": Tuning.STAGE_DEPTH_BOTTOM,
		&"facing": 1,
		&"life": 1.0,
		&"hit": false,
	})
	start_health = player.health
	ranged.tick(1.0 / 60.0, false, player)
	if player.health < start_health:
		push_error("Ranged projectile hit despite a large depth mismatch")
		quit(1)
		return false
	return true

func _test_boss_damage_tools() -> bool:
	var player: Node2D = PlayerScript.new()
	var boss: Node2D = DummyScript.new()
	root.add_child(boss)
	root.add_child(player)
	player.reset_player()
	boss.reset_dummy(Vector2(680.0, Tuning.GROUND_Y), 0.0, boss.EnemyType.BOSS)
	player.position = Vector2(630.0, Tuning.GROUND_Y)
	player.depth = 0.0
	boss.state = boss.State.BOSS_PULSE_ACTIVE
	boss.state_timer = 0.0
	var start_health: int = player.health
	boss.tick(1.0 / 60.0, false, player)
	if player.health >= start_health:
		push_error("Boss guard pulse did not damage a close player")
		quit(1)
		return false

	player.reset_player()
	boss.reset_dummy(Vector2(680.0, Tuning.GROUND_Y), 0.0, boss.EnemyType.BOSS)
	player.position = Vector2(500.0, Tuning.GROUND_Y + 60.0)
	player.depth = 60.0
	boss.facing = -1
	boss.state = boss.State.BOSS_SWEEP_ACTIVE
	boss.state_timer = 0.0
	start_health = player.health
	boss.tick(1.0 / 60.0, false, player)
	if player.health >= start_health:
		push_error("Boss depth sweep did not damage a player in its lane band")
		quit(1)
		return false
	return true

func _test_main_area_config_keeps_enemy_types() -> bool:
	var main: Node = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	var dummies: Array = main.get("dummies")
	if dummies.size() != 4:
		push_error("Main scene missing four enemy slots")
		quit(1)
		return false
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main._begin_encounter()
	if dummies[0].enemy_type != dummies[0].EnemyType.SMALL or dummies[1].enemy_type != dummies[1].EnemyType.SMALL:
		push_error("Main scene did not initialize level 1 area 1 as two small enemies")
		quit(1)
		return false
	main.set("current_wave", 3)
	main.set("wave_defeats", 0)
	main._configure_wave()
	main._begin_encounter()
	if dummies[0].enemy_type != dummies[0].EnemyType.DASHER or dummies[1].enemy_type != dummies[1].EnemyType.SMALL:
		push_error("Main scene did not configure level 1 area 3 as dasher plus small")
		quit(1)
		return false
	main.set("current_level", 2)
	main.set("current_wave", 1)
	main._configure_wave()
	main._begin_encounter()
	if dummies[1].enemy_type != dummies[1].EnemyType.RANGED:
		push_error("Main scene did not configure level 2 ranged slot")
		quit(1)
		return false
	main.set("current_level", 4)
	main.set("current_wave", 2)
	main._configure_wave()
	main._begin_encounter()
	if dummies[0].enemy_type != dummies[0].EnemyType.BOSS or dummies[1].enemy_type != dummies[1].EnemyType.RANGED:
		push_error("Main scene did not configure boss arena enemies")
		quit(1)
		return false
	main.queue_free()
	return true
