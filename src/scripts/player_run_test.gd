extends SceneTree

const PlayerScript := preload("res://scripts/player.gd")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	var player: Node2D = PlayerScript.new()
	root.add_child(player)
	player.reset_player()

	_release_movement()
	Input.action_press(&"move_right")
	player.tick(1.0 / 60.0, false, null)
	if player.is_running:
		push_error("Single right press started running")
		quit(1)
		return
	Input.action_release(&"move_right")
	await process_frame

	Input.action_press(&"move_right")
	player.tick(1.0 / 60.0, false, null)
	if not player.is_running or player.run_direction != 1:
		push_error("Double right press did not start running")
		quit(1)
		return
	for i: int in range(12):
		player.tick(1.0 / 60.0, false, null)
	if player.velocity.x <= Tuning.GROUND_MAX_SPEED:
		push_error("Running did not exceed walk max speed")
		quit(1)
		return

	Input.action_press(&"move_left")
	player.tick(1.0 / 60.0, false, null)
	if player.is_running:
		push_error("Opposite input did not stop running")
		quit(1)
		return
	_release_movement()
	await process_frame

	Input.action_press(&"move_left")
	player.tick(1.0 / 60.0, false, null)
	Input.action_release(&"move_left")
	await process_frame
	for i: int in range(int(ceil(Tuning.RUN_DOUBLE_TAP_WINDOW * 60.0)) + 2):
		player.tick(1.0 / 60.0, false, null)
		await process_frame
	Input.action_press(&"move_left")
	player.tick(1.0 / 60.0, false, null)
	if player.is_running:
		push_error("Late second left press started running outside the double-tap window")
		quit(1)
		return

	_release_movement()
	player.queue_free()
	print("PLAYER RUN TEST PASS")
	quit(0)

func _release_movement() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
