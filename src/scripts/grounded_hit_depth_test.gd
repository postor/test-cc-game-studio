extends SceneTree

const DummyScript := preload("res://scripts/training_dummy.gd")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	var dummy: Node2D = DummyScript.new()
	root.add_child(dummy)
	dummy.reset_dummy(Vector2(Tuning.DUMMY_START.x, Tuning.GROUND_Y), -34.0, dummy.EnemyType.SMALL)
	dummy.apply_hit({
		&"knockback": Tuning.ATTACKS[&"light_1"][&"knockback"],
		&"facing": 1,
		&"damage": Tuning.ATTACKS[&"light_1"][&"damage"],
		&"hit_type": Tuning.ATTACKS[&"light_1"][&"hit_type"],
		&"allow_downed": false,
	})
	if dummy.state == dummy.State.AIRBORNE or dummy.state == dummy.State.DOWNED:
		push_error("Grounded light hit incorrectly made negative-depth dummy airborne/downed")
		quit(1)
		return
	for i: int in range(40):
		dummy.tick(1.0 / 60.0, false, null)
	if dummy.state == dummy.State.DOWNED:
		push_error("Grounded light hit incorrectly settled into downed state")
		quit(1)
		return

	dummy.reset_dummy(Vector2(Tuning.DUMMY_START.x, Tuning.GROUND_Y), -34.0, dummy.EnemyType.SMALL)
	dummy.apply_hit({
		&"knockback": Tuning.ATTACKS[&"launcher"][&"knockback"],
		&"facing": 1,
		&"damage": Tuning.ATTACKS[&"launcher"][&"damage"],
		&"hit_type": Tuning.ATTACKS[&"launcher"][&"hit_type"],
		&"allow_downed": false,
	})
	if dummy.state != dummy.State.AIRBORNE:
		push_error("Launcher no longer puts dummy airborne")
		quit(1)
		return

	print("GROUNDED HIT DEPTH TEST PASS")
	quit(0)
