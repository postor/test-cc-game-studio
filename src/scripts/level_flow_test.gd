extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const Tuning := preload("res://scripts/combat_tuning.gd")

func _initialize() -> void:
	var main: Node = MainScene.instantiate()
	root.add_child(main)
	await process_frame
	if int(main.get("current_level")) != 1 or String(main.get("transition_title")) != "LEVEL 1":
		push_error("Level intro did not initialize")
		quit(1)
		return
	if int(main.get("scene_mode")) != main.SceneMode.LEVEL_INTRO:
		push_error("Level intro did not use the independent intro scene mode")
		quit(1)
		return
	main.set("wave_defeats", main.get("defeats_required") - 1)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	if int(main.get("scene_mode")) != main.SceneMode.COMBAT:
		push_error("Intro did not transition into combat scene")
		quit(1)
		return
	var player: Node = main.get("player")
	if bool(main.get("encounter_locked")):
		push_error("Combat should start in map-advance mode before the encounter trigger")
		quit(1)
		return
	player.position.x = main._current_area_left() + 220.0
	main._update_level_flow(0.0)
	if not bool(main.get("encounter_locked")):
		push_error("Player crossing the encounter trigger did not lock the area")
		quit(1)
		return
	var first_wave_count: int = int(main.get("defeats_required"))
	main._advance_wave_or_level()
	if int(main.get("current_wave")) != 1 or int(main.get("active_spawn_wave")) != 1 or int(main.get("defeats_required")) == first_wave_count:
		push_error("Encounter did not advance to a second spawn wave before map progress")
		quit(1)
		return
	main._advance_wave_or_level()
	if int(main.get("current_wave")) != 2 or not bool(main.get("awaiting_map_advance")) or bool(main.get("encounter_locked")):
		push_error("Encounter clear did not unlock map advancement")
		quit(1)
		return
	player.position.x = main.get("last_advance_progress_x")
	main._update_level_flow(1.5)
	if float(main.get("advance_hint_timer")) < 1.4:
		push_error("Advance hint timer did not build while the player waited after clearing enemies")
		quit(1)
		return
	player.position.x = main.get("last_advance_progress_x") + 20.0
	main._update_level_flow(0.0)
	if bool(main.get("awaiting_map_advance")):
		push_error("Advance hint did not clear once the player moved forward")
		quit(1)
		return
	main.set("current_wave", 4)
	player.position.x = main._level_exit_x()
	main._update_level_flow(0.0)
	if int(main.get("current_level")) != 2 or String(main.get("transition_title")) != "LEVEL 2":
		push_error("Level transition did not wait for the player to reach the level exit")
		quit(1)
		return
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	player = main.get("player")
	player.position.x = 760.0
	main._update_camera()
	var level_two_camera_before_clear: float = float(main.get("camera_x"))
	player.position.x = main._current_area_left() + 220.0
	main._update_level_flow(0.0)
	main._advance_wave_or_level()
	main._advance_wave_or_level()
	main._update_camera()
	if float(main.get("camera_x")) < level_two_camera_before_clear:
		push_error("Level 2 camera moved backward after clearing the first encounter")
		quit(1)
		return
	main.set("current_level", 1)
	main.set("current_wave", 2)
	main._configure_wave()
	player = main.get("player")
	player.position.x = main._area_world_offset(2) + 620.0
	player.depth = -50.0
	player.position.y = Tuning.GROUND_Y + player.depth
	main._check_terrain_falls()
	if not bool(main.get("game_over")) or not String(main.get("game_over_reason")).contains("fell"):
		push_error("Player fall did not trigger game over")
		quit(1)
		return
	main._reset_training()
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("current_level", 1)
	main.set("current_wave", 2)
	main._configure_wave()
	var falling_dummy: Node = main.get("dummy")
	falling_dummy.position.x = main._area_world_offset(2) + 620.0
	falling_dummy.depth = -50.0
	falling_dummy.position.y = Tuning.GROUND_Y + falling_dummy.depth
	main._check_terrain_falls()
	if falling_dummy.state != falling_dummy.State.DEAD:
		push_error("Enemy fall did not kill the enemy directly")
		quit(1)
		return
	main._reset_training()
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	main.set("transition_timer", 0.0)
	main._update_level_flow(0.0)
	player = main.get("player")
	player.health = 0
	player._begin_defeat()
	main._process(1.0 / 60.0)
	if not bool(main.get("game_over")) or String(main.get("transition_title")) != "GAME OVER":
		push_error("Game over flow did not trigger")
		quit(1)
		return
	print("LEVEL FLOW TEST PASS")
	quit(0)
