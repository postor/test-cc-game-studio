extends SceneTree

const PlayerScript := preload("res://scripts/player.gd")
const DummyScript := preload("res://scripts/training_dummy.gd")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	var player: Node2D = PlayerScript.new()
	var enemy: Node2D = DummyScript.new()
	root.add_child(enemy)
	root.add_child(player)
	player.reset_player()

	enemy.reset_dummy(Vector2(760.0, Tuning.GROUND_Y), 0.0, enemy.EnemyType.RANGED)
	player.position.x = 500.0
	player.depth = 0.0
	player.position.y = Tuning.GROUND_Y
	enemy.state = enemy.State.CHASE
	var fired: bool = false
	for i: int in range(120):
		enemy.tick(1.0 / 60.0, false, player)
		if not enemy.projectiles.is_empty():
			fired = true
			break
	if not fired:
		push_error("Ranged enemy did not fire a projectile")
		quit(1)
		return

	var boss: Node2D = DummyScript.new()
	var close_player: Node2D = PlayerScript.new()
	root.add_child(boss)
	root.add_child(close_player)
	close_player.reset_player()
	boss.reset_dummy(Vector2(760.0, Tuning.GROUND_Y), 0.0, boss.EnemyType.BOSS)
	close_player.position.x = 700.0
	close_player.depth = 0.0
	close_player.position.y = Tuning.GROUND_Y
	boss.state = boss.State.CHASE
	var pulse_started: bool = false
	for i: int in range(90):
		boss.tick(1.0 / 60.0, false, close_player)
		if boss.state == boss.State.BOSS_PULSE_WINDUP or boss.state == boss.State.BOSS_PULSE_ACTIVE:
			pulse_started = true
			break
	if not pulse_started:
		push_error("Boss did not start guard pulse at close range")
		quit(1)
		return

	boss.reset_dummy(Vector2(760.0, Tuning.GROUND_Y), 0.0, boss.EnemyType.BOSS)
	close_player.reset_player()
	close_player.position.x = 590.0
	close_player.depth = 70.0
	close_player.position.y = Tuning.GROUND_Y + close_player.depth
	boss.state = boss.State.CHASE
	var sweep_started: bool = false
	for i: int in range(90):
		boss.tick(1.0 / 60.0, false, close_player)
		if boss.state == boss.State.BOSS_SWEEP_WINDUP or boss.state == boss.State.BOSS_SWEEP_ACTIVE:
			sweep_started = true
			break
	if not sweep_started:
		push_error("Boss did not start depth sweep at wider range")
		quit(1)
		return

	print("ENEMY TYPES TEST PASS")
	quit(0)
