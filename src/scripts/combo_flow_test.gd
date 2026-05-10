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
	player.position = Vector2(640.0, Tuning.GROUND_Y)
	dummy.position = Vector2(715.0, Tuning.GROUND_Y)

	var hits: Array[StringName] = []
	player.hit_confirmed.connect(func(hit_event: Dictionary) -> void:
		hits.append(hit_event[&"attack_id"])
		dummy.apply_hit(hit_event)
		player.add_meter(int(hit_event.get(&"meter_gain", 0)))
	)

	player._start_attack(&"light_1")
	var auto_launched: bool = false
	for i: int in range(180):
		if player.attack_phase == player.AttackPhase.RECOVERY and player.current_attack == &"light_1" and player.phase_frame == 3:
			player.buffered_action = &"light_attack"
			player.buffer_age = 0
		if player.attack_phase == player.AttackPhase.RECOVERY and player.current_attack == &"light_2" and player.phase_frame == 3:
			player.buffered_action = &"light_attack"
			player.buffer_age = 0
		player.tick(1.0 / 60.0, false, dummy)
		dummy.tick(1.0 / 60.0, false, player)
		if hits.has(&"launcher") and dummy.state == dummy.State.AIRBORNE:
			auto_launched = true
			break
	if not auto_launched:
		push_error("Light chain did not auto-trigger fourth-hit launcher")
		quit(1)
		return

	player._end_attack(false)
	player.meter = 90
	player.position = Vector2(dummy.position.x - 72.0, Tuning.GROUND_Y)
	player._start_attack(&"ki_blast")
	var ki_hits: int = 0
	for i: int in range(80):
		var before_count: int = hits.size()
		player.tick(1.0 / 60.0, false, dummy)
		dummy.tick(1.0 / 60.0, false, player)
		for j: int in range(before_count, hits.size()):
			if hits[j] == &"ki_blast":
				ki_hits += 1
	if ki_hits < 2:
		push_error("Ki strike did not produce repeated hit slices")
		quit(1)
		return

	print("COMBO FLOW TEST PASS")
	quit(0)
