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

	player.position = Vector2(Tuning.DUMMY_START.x - 60.0, Tuning.GROUND_Y - 120.0)
	player.velocity = Vector2(0.0, -40.0)
	player.move_state = player.MoveState.AIRBORNE
	player._start_attack(&"air_slash")

	if player.velocity.y < Tuning.AIR_SLASH_MIN_FALL_SPEED:
		push_error("Air slash did not force downward velocity")
		quit(1)
		return

	var player_landed: bool = false
	for i: int in range(180):
		player.tick(1.0 / 60.0, false, dummy)
		dummy.tick(1.0 / 60.0, false)
		if player.position.y >= Tuning.GROUND_Y and player.attack_phase == player.AttackPhase.READY:
			player_landed = true
			break
	if not player_landed:
		push_error("Player did not land and recover from air slash within 180 frames")
		quit(1)
		return

	dummy.position = Vector2(Tuning.DUMMY_START.x, Tuning.GROUND_Y - 150.0)
	dummy.velocity = Vector2(0.0, -20.0)
	dummy.state = dummy.State.AIRBORNE
	dummy.apply_hit({
		&"knockback": Vector2(75.0, 120.0),
		&"facing": 1,
	})
	for i: int in range(240):
		dummy.tick(1.0 / 60.0, false, player)
		if dummy.position.y >= Tuning.GROUND_Y and dummy.state == dummy.State.DOWNED:
			if dummy.get_hurtbox().size != Vector2.ZERO:
				push_error("Downed dummy still has an active hurtbox")
				quit(1)
				return
			break

	if dummy.state != dummy.State.DOWNED:
		push_error("Dummy did not enter downed state after airborne air-slash hit")
		quit(1)
		return

	var stood_up: bool = false
	for i: int in range(180):
		dummy.tick(1.0 / 60.0, false, player)
		if dummy.state == dummy.State.CHASE or dummy.state == dummy.State.ATTACK_WINDUP or dummy.state == dummy.State.ATTACK_ACTIVE or dummy.state == dummy.State.ATTACK_RECOVERY:
			stood_up = true
			break
	if not stood_up:
		push_error("Dummy did not stand up and resume AI after knockdown")
		quit(1)
		return

	print("AIR CHASE TEST PASS")
	quit(0)
