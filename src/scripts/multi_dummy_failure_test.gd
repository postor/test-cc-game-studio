extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const PlayerScript := preload("res://scripts/player.gd")
const DummyScript := preload("res://scripts/training_dummy.gd")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	var main: Node = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	var dummies: Array = main.get("dummies")
	if dummies.size() != 4:
		push_error("Main scene did not create four enemy slots")
		quit(1)
		return
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)

	var player: Node2D = main.get("player")
	player.position.x = 640.0
	player.depth = 0.0
	player.position.y = Tuning.GROUND_Y
	player.facing = 1
	player.meter = 100
	for i: int in range(2):
		var target: Node2D = dummies[i]
		target.visible = true
		target.state = target.State.IDLE
		target.position.x = 700.0 + float(i) * 24.0
		target.depth = 0.0
		target.position.y = Tuning.GROUND_Y
		target.health = Tuning.DUMMY_MAX_HEALTH
	player._start_attack(&"super")
	for i: int in range(40):
		player.tick(1.0 / 60.0, false, dummies)
	if dummies[0].health >= Tuning.DUMMY_MAX_HEALTH or dummies[1].health >= Tuning.DUMMY_MAX_HEALTH:
		push_error("Player multi-target attack did not hit both dummies")
		quit(1)
		return
	for i: int in range(2):
		var target_after_super: Node2D = dummies[i]
		if target_after_super.state != target_after_super.State.AIRBORNE and target_after_super.state != target_after_super.State.DOWNED and target_after_super.state != target_after_super.State.DOWNED_BOUNCE:
			push_error("Super did not force every hit dummy into airborne/downed reaction")
			quit(1)
			return
		if target_after_super.velocity.y >= 0.0:
			push_error("Super did not launch a hit dummy upward")
			quit(1)
			return
		if absf(target_after_super.velocity.x) <= 250.0:
			push_error("Super did not push a hit dummy a large horizontal distance")
			quit(1)
			return

	var dummy: Node2D = DummyScript.new()
	var target_player: Node2D = PlayerScript.new()
	root.add_child(dummy)
	root.add_child(target_player)
	dummy.reset_dummy(Vector2(800.0, Tuning.GROUND_Y), 0.0, dummy.EnemyType.DASHER)
	target_player.reset_player()
	target_player.position.x = 610.0
	target_player.depth = 0.0
	target_player.position.y = Tuning.GROUND_Y
	dummy.state = dummy.State.CHASE
	var entered_dash_windup: bool = false
	var entered_dash_active: bool = false
	for i: int in range(90):
		dummy.tick(1.0 / 60.0, false, target_player)
		if dummy.state == dummy.State.DASH_WINDUP:
			entered_dash_windup = true
		if dummy.state == dummy.State.DASH_ACTIVE:
			entered_dash_active = true
			break
	if not entered_dash_windup or not entered_dash_active:
		push_error("Dummy did not use long-windup dash attack")
		quit(1)
		return

	target_player.health = 10
	target_player.apply_enemy_hit(dummy.position)
	if target_player.move_state != target_player.MoveState.DEFEATED:
		push_error("Player did not enter defeat animation at zero health")
		quit(1)
		return

	print("MULTI DUMMY FAILURE TEST PASS")
	quit(0)
