extends SceneTree

const PlayerScript := preload("res://scripts/player.gd")
const DummyScript := preload("res://scripts/training_dummy.gd")
const MainScene := preload("res://scenes/Main.tscn")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	var player: Node2D = PlayerScript.new()
	var dummy: Node2D = DummyScript.new()
	root.add_child(dummy)
	root.add_child(player)
	player.reset_player()
	dummy.reset_dummy()

	player.meter = 100
	player._start_attack(&"ki_blast")
	if player.meter != 70:
		push_error("Ki strike did not consume 30 qi")
		quit(1)
		return
	if player.current_attack != &"ki_blast":
		push_error("Ki strike did not start with enough qi")
		quit(1)
		return

	dummy.state = dummy.State.DOWNED
	dummy.state_timer = 0.0
	var downed_health: int = dummy.health
	dummy.apply_hit({
		&"knockback": Tuning.ATTACKS[&"ki_blast"][&"knockback"],
		&"facing": 1,
		&"damage": Tuning.ATTACKS[&"ki_blast"][&"damage"],
		&"hit_type": &"ki",
		&"allow_downed": true,
	})
	if dummy.health >= downed_health:
		push_error("Downed dummy did not take ki strike damage")
		quit(1)
		return
	if dummy.state != dummy.State.DOWNED_BOUNCE:
		push_error("Downed dummy was not kept in downed bounce reaction")
		quit(1)
		return
	for i: int in range(60):
		dummy.tick(1.0 / 60.0, false, player)
	if dummy.state != dummy.State.DOWNED:
		push_error("Downed bounce did not return to downed state")
		quit(1)
		return

	dummy.state = dummy.State.GETTING_UP
	dummy.health = dummy._max_health()
	if dummy.get_hurtbox(false).size != Vector2.ZERO:
		push_error("Getting-up dummy lost normal invulnerability")
		quit(1)
		return
	if dummy.get_hurtbox(true, true).size == Vector2.ZERO:
		push_error("Getting-up dummy did not expose hurtbox to ki/super")
		quit(1)
		return

	player._end_attack(false)
	player.meter = 100
	player._start_attack(&"super")
	if player.meter != 0:
		push_error("Super did not consume 100 qi")
		quit(1)
		return
	if player.guard_timer <= 0.0:
		push_error("Super did not grant self-protection")
		quit(1)
		return

	dummy.reset_dummy(Vector2(760.0, Tuning.GROUND_Y), 0.0, dummy.EnemyType.SMALL)
	dummy.state = dummy.State.GETTING_UP
	var getup_health: int = dummy.health
	dummy.apply_hit({
		&"knockback": Tuning.ATTACKS[&"ki_blast"][&"knockback"],
		&"facing": 1,
		&"damage": Tuning.ATTACKS[&"ki_blast"][&"damage"],
		&"hit_type": &"ki",
		&"allow_downed": true,
	})
	if dummy.health >= getup_health:
		push_error("Getting-up dummy did not take ki strike damage")
		quit(1)
		return

	dummy.reset_dummy(Vector2(760.0, Tuning.GROUND_Y), 0.0, dummy.EnemyType.BOSS)
	dummy.state = dummy.State.GETTING_UP
	dummy.apply_hit({
		&"knockback": Tuning.ATTACKS[&"super"][&"knockback"],
		&"facing": 1,
		&"source_position": Vector2(640.0, Tuning.GROUND_Y),
		&"damage": Tuning.ATTACKS[&"super"][&"damage"],
		&"hit_type": &"super",
		&"allow_downed": true,
	})
	if dummy.state != dummy.State.AIRBORNE or dummy.velocity.y >= 0.0 or dummy.velocity.x <= 250.0:
		push_error("Super did not launch getting-up dummy away from the player")
		quit(1)
		return

	var main: Node = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	var main_dummy: Node = main.get("dummy")
	main_dummy.health = 1
	main._on_hit_confirmed({
		&"target_id": main_dummy.get_instance_id(),
		&"hit_position": Vector2.ZERO,
		&"hit_type": &"super",
		&"hitstop_frames": 0,
		&"shake": 0.0,
		&"knockback": Vector2.ZERO,
		&"facing": 1,
		&"damage": 10,
		&"meter_gain": 0,
		&"allow_downed": true,
	})
	if main_dummy.state != main_dummy.State.DEAD:
		push_error("Main scene did not leave a defeated dummy corpse")
		quit(1)
		return
	for i: int in range(60):
		main._process(1.0 / 60.0)
	if main_dummy.visible:
		push_error("Main scene did not hide a finished corpse in area flow")
		quit(1)
		return
	main.queue_free()

	print("COMBAT SYSTEM TEST PASS")
	quit(0)
