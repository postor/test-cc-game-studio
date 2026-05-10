extends SceneTree

const PlayerScript := preload("res://scripts/player.gd")
const DummyScript := preload("res://scripts/training_dummy.gd")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	var player: Node2D = PlayerScript.new()
	var dummy: Node2D = DummyScript.new()
	root.add_child(dummy)
	root.add_child(player)
	player.reset_player()
	dummy.reset_dummy()
	player.position.x = 640.0
	player.facing = 1
	dummy.position.x = 700.0

	var hits: Array[StringName] = []
	player.hit_confirmed.connect(func(hit_event: Dictionary) -> void:
		hits.append(hit_event[&"attack_id"])
		dummy.apply_hit(hit_event)
	)

	player.depth = 0.0
	player.position.y = Tuning.GROUND_Y
	dummy.depth = 38.0
	dummy.position.y = Tuning.GROUND_Y + dummy.depth
	player._start_attack(&"light_1")
	for i: int in range(24):
		player.tick(1.0 / 60.0, false, dummy)
	if not hits.is_empty():
		push_error("Light attack hit outside its depth range")
		quit(1)
		return

	player._end_attack(false)
	player.meter = 60
	player.position = Vector2(640.0, Tuning.GROUND_Y)
	player.depth = 0.0
	player.facing = 1
	dummy.position = Vector2(700.0, Tuning.GROUND_Y + dummy.depth)
	player._start_attack(&"ki_blast")
	for i: int in range(40):
		player.tick(1.0 / 60.0, false, dummy)
	if hits.is_empty():
		push_error("Ki strike failed inside its wider depth range")
		quit(1)
		return

	var after_ki_hits: int = hits.size()
	player._end_attack(false)
	player.meter = 100
	player.facing = 1
	dummy.depth = 76.0
	dummy.position.y = Tuning.GROUND_Y + dummy.depth
	player._start_attack(&"super")
	for i: int in range(60):
		player.tick(1.0 / 60.0, false, dummy)
	if hits.size() <= after_ki_hits:
		push_error("Super failed inside its widest depth range")
		quit(1)
		return

	dummy.state = dummy.State.CHASE
	dummy.depth = Tuning.STAGE_DEPTH_BOTTOM
	dummy.position.y = Tuning.GROUND_Y + dummy.depth
	player.depth = Tuning.STAGE_DEPTH_TOP
	player.position.y = Tuning.GROUND_Y + player.depth
	var start_delta: float = absf(dummy.depth - player.depth)
	for i: int in range(90):
		dummy.tick(1.0 / 60.0, false, player)
	var end_delta: float = absf(dummy.depth - player.depth)
	if end_delta >= start_delta:
		push_error("Dummy did not chase the player across depth")
		quit(1)
		return

	print("DEPTH COMBAT TEST PASS")
	quit(0)
