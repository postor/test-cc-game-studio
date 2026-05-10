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

	player.position = Vector2(420.0, Tuning.GROUND_Y)
	dummy.position = Vector2(780.0, Tuning.GROUND_Y)
	dummy.state = dummy.State.DOWNED
	dummy.state_timer = 0.0

	var reached_chase: bool = false
	for i: int in range(180):
		dummy.tick(1.0 / 60.0, false, player)
		if dummy.state == dummy.State.CHASE:
			reached_chase = true
			break
	if not reached_chase:
		push_error("Dummy did not get up into chase state")
		quit(1)
		return
	if dummy.get_hurtbox().size == Vector2.ZERO:
		push_error("Dummy hurtbox did not return after getting up")
		quit(1)
		return

	var start_distance: float = absf(dummy.position.x - player.position.x)
	for i: int in range(60):
		dummy.tick(1.0 / 60.0, false, player)
	var chase_distance: float = absf(dummy.position.x - player.position.x)
	if chase_distance >= start_distance:
		push_error("Dummy did not move toward the player while chasing")
		quit(1)
		return

	player.position = Vector2(dummy.position.x - 64.0, Tuning.GROUND_Y)
	player.velocity = Vector2.ZERO
	player.move_state = player.MoveState.GROUNDED
	dummy.state = dummy.State.CHASE
	dummy.state_timer = 0.0
	dummy.attack_cooldown_timer = 0.0

	var player_hit: bool = false
	for i: int in range(90):
		dummy.tick(1.0 / 60.0, false, player)
		player.tick(1.0 / 60.0, false, dummy)
		if player.hurt_flash_frames > 0:
			player_hit = true
			break
	if not player_hit:
		push_error("Dummy did not connect an attack at close range")
		quit(1)
		return

	print("DUMMY AI TEST PASS")
	quit(0)
