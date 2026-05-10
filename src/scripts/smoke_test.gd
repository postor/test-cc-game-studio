extends SceneTree

const Tuning := preload("res://scripts/combat_tuning.gd")
const MainScene := preload("res://scenes/Main.tscn")

func _initialize() -> void:
	var failures: Array[String] = []
	for attack_id: StringName in [&"light_1", &"light_2", &"light_3", &"launcher", &"air_slash", &"ki_blast", &"super"]:
		if not Tuning.ATTACKS.has(attack_id):
			failures.append("Missing attack data: %s" % attack_id)
			continue
		var data: Dictionary = Tuning.ATTACKS[attack_id]
		for key: StringName in [&"startup", &"active", &"recovery", &"hitbox", &"hit_type", &"hitstop", &"knockback", &"damage", &"meter_gain"]:
			if not data.has(key):
				failures.append("Attack %s missing key %s" % [attack_id, key])
		if int(data.get(&"startup", 0)) <= 0 or int(data.get(&"active", 0)) <= 0:
			failures.append("Attack %s has invalid frame data" % attack_id)

	var main: Node = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	if not main.has_method("_reset_training"):
		failures.append("Main scene missing reset method")
	var player: Node = main.get("player")
	var dummy: Node = main.get("dummy")
	if player == null:
		failures.append("Main scene did not create player")
	if dummy == null:
		failures.append("Main scene did not create dummy")
	if player != null and not player.has_signal("hit_confirmed"):
		failures.append("Player missing hit_confirmed signal")
	if dummy != null and not dummy.has_method("apply_hit"):
		failures.append("Dummy missing apply_hit method")
	main.queue_free()

	if failures.is_empty():
		print("SMOKE TEST PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
