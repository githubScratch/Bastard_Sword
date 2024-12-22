extends Node2D

# Reference to the player character, where Path2D is now a child
@export var player_path: NodePath  # Path to the player, set in the Inspector

@onready var begin_audio = $beginaudio  # Reference to the AudioStreamPlayer node
@onready var hud = $UILayer/HUD

@onready var fog: CPUParticles2D = %fog
@onready var rain: GPUParticles2D = $playerKnight/rain
@onready var spalsh: GPUParticles2D = $playerKnight/rain/spalsh
@onready var buttonSFX = $ButtonSFX  # Reference to the AudioStreamPlayer node

var high_score: int = 0
const HIGH_SCORE_FILE = "user://high_score.save"

var total_enemies_spawned = 0
var total_enemies_killed = 0
var max_enemies = 111
var horde_enemies = 222
var victory_achieved = false
var enemies_remaining = 0

@onready var timer = $Timer # Replace with your actual timer node paths
@onready var timer2 = $Timer2
@onready var timer3 = $Timer3
@onready var timer4 = $Timer4
@onready var timer5 = $swarmtimer

var elapsed_time = 0.0
var event_thresholds = [30, 60, 120, 150, 180, 210]  # Time thresholds for events (in seconds)
var triggered_events = []  # Stores which thresholds have already been triggered
var event_actions = {
	30: [Callable(self, "spawn_moblin").bind(20), Callable(self, "blood_rain")],
	90: [Callable(self, "spawn_goblin").bind(10)],
	120: [Callable(self, "spawn_kaboomist").bind(2), Callable(self, "spawn_moblin").bind(20)],
	150: [Callable(self, "spawn_goblin").bind(10), Callable(self, "spawn_warlock").bind(1)],
	180: [Callable(self, "enable_swarm_timer")],
	210: [Callable(self, "spawn_warlock").bind(3)]
}

var score := 0:
	set(value):
		score = value
		hud.update_score(score, high_score)  # Pass both the score and high score
  # Call the method on the HUD node

func _ready() -> void:
	score = 0
	total_enemies_spawned = 0 
	get_tree().paused = true
	player_path = NodePath("playerKnight")
	fog.preprocess = 5.0  # Preloads particles for 1 second
	fog.one_shot = false
	load_high_score()
	hud.update_score(score, high_score)
	spawn_moblin(6)
	spawn_goblin(1)

func _process(delta):
	# Increment the elapsed time
	elapsed_time += delta
	
	# Check thresholds
	check_thresholds()

func can_spawn_more_enemies() -> bool:
	if total_enemies_spawned >= max_enemies:
		stop_all_spawn_timers()
		print("Maximum enemy limit reached!")
		return false
	return true

func stop_all_spawn_timers():
	timer.stop()
	timer2.stop()
	timer3.stop()
	timer4.stop()
	timer5.stop()

func check_thresholds(): #check spawn timers for events
	for threshold in event_thresholds:
		if elapsed_time >= threshold and threshold not in triggered_events:
			triggered_events.append(threshold)
			trigger_event(threshold)

func trigger_event(threshold):
	print("Event triggered at:", threshold, "seconds")
	if threshold in event_actions:
		for action in event_actions[threshold]:
			action.call()  # Execute each action in the list
  # Execute the corresponding action

func blood_rain():
	print("blood rain")

func spawn_goblin(count: int):
	
	var remaining_spawns = max_enemies - total_enemies_spawned
	if remaining_spawns <= 0:
		return
		
	# Adjust count if it would exceed the limit
	count = mini(count, remaining_spawns)

	# Ensure the PathFollow2D node under the player is located
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null
	
	if path_follow != null:
		for i in range(count):
			if can_spawn_more_enemies():
				var goblin_instance = preload("res://scenes/goblin.tscn").instantiate()
				path_follow.progress_ratio = randf()
				goblin_instance.global_position = path_follow.global_position
				goblin_instance.killed.connect(_on_enemy_killed)
				goblin_instance.enemy_defeated.connect(_on_enemy_defeated)
				add_child(goblin_instance)
				total_enemies_spawned += 1
				print("Spawned enemy number: ", total_enemies_spawned)
	#else:
		#push_error("Failed to locate PathFollow2D under the player.")

func spawn_kaboomist(count: int):
	var remaining_spawns = max_enemies - total_enemies_spawned
	if remaining_spawns <= 0:
		return
		
	count = mini(count, remaining_spawns)
	
	# Locate the PathFollow2D node under the player
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null
	# Ensure path_follow was successfully located
	if path_follow != null:
		for i in range(count):
			if can_spawn_more_enemies():
				var kaboomist_instance = preload("res://scenes/kaboomist.tscn").instantiate()
				path_follow.progress_ratio = randf()
				kaboomist_instance.global_position = path_follow.global_position
				var character_body = kaboomist_instance.get_node("CharacterBody2D")
				character_body.killed.connect(_on_enemy_killed)
				character_body.enemy_defeated.connect(_on_enemy_defeated)
				add_child(kaboomist_instance)
				total_enemies_spawned += 1
				print("Spawned enemy number: ", total_enemies_spawned)
	#else:
		#push_error("Failed to locate PathFollow2D under the player.")

func spawn_warlock(count: int):
	
	var remaining_spawns = max_enemies - total_enemies_spawned
	if remaining_spawns <= 0:
		return
	count = mini(count, remaining_spawns)
	
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null

	if path_follow != null:
		for i in range(count):
			if can_spawn_more_enemies():
				var warlock_instance = preload("res://scenes/warlock.tscn").instantiate()  # Ensure the path is correct
				path_follow.progress_ratio = randf()  # Randomize position on the path
				warlock_instance.global_position = path_follow.global_position  # Set position on the instantiated 
				var character_body = warlock_instance.get_node("CharacterBody2D")
				character_body.killed.connect(_on_enemy_killed)
				character_body.enemy_defeated.connect(_on_enemy_defeated)
				add_child(warlock_instance)  # Add the instantiated  to the scene
				total_enemies_spawned += 1
				print("Spawned enemy number: ", total_enemies_spawned)
	#else:
		#push_error("Failed to locate PathFollow2D under the player.")

func spawn_moblin(count: int):
	var remaining_spawns = max_enemies - total_enemies_spawned
	if remaining_spawns <= 0:
		return
	count = mini(count, remaining_spawns)
	# Locate the PathFollow2D node under the player
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null
	# Ensure path_follow was successfully located
	if path_follow != null:
		for i in range(count):
			if can_spawn_more_enemies():
				var moblin_instance = preload("res://scenes/moblin.tscn").instantiate()  # Ensure the path is correct
				path_follow.progress_ratio = randf()  # Randomize position on the path
				moblin_instance.global_position = path_follow.global_position  # Set position on the instantiated goblin
				var character_body = moblin_instance.get_node("CharacterBody2D")
				character_body.killed.connect(_on_enemy_killed)
				character_body.enemy_defeated.connect(_on_enemy_defeated)
				add_child(moblin_instance)  # Add the instantiated goblin to the scene
				total_enemies_spawned += 1
				print("Spawned enemy number: ", total_enemies_spawned)
	else:
		push_error("Failed to locate PathFollow2D under the player.")

func _on_timer_timeout() -> void:
	if not %GameOverScreen.visible:
		spawn_goblin(2)

func _on_enemy_killed(score_value: int):
	if not %GameOverScreen.visible and not victory_achieved:
		score += score_value
		hud.update_score(score, high_score)

func _on_enemy_defeated():
	print("Enemy defeated signal received!")  # Debug print
	if not %GameOverScreen.visible and not victory_achieved:
		total_enemies_killed += 1
		print("Enemies defeated: ", total_enemies_killed)
		enemies_remaining = max_enemies - total_enemies_killed
		print("Enemies remaining: ", enemies_remaining)
		hud.update_enemies_remaining(enemies_remaining)
	if total_enemies_killed >= max_enemies:
			trigger_victory()

func trigger_victory():
	var _is_new_high_score = check_and_update_high_score(score)
	hud.update_high_score(high_score)  # Ensure the HUD always shows the current high score
	#$FinalScore.text = "Final Score: " + str(score)
	%VictoryScreen.visible = true
	player_knight.animated_sprite.modulate = Color(1, 0, 0, 0.75)  # Set to red
	player_knight.set_process(false)
	player_knight.set_physics_process(false)
	var victory_control = $VictoryScreen/Control  # Adjust this path
	if victory_control:
		victory_control.fade_in()

@onready var player_knight: Player = $playerKnight

func _on_player_knight_dead() -> void:
	var _is_new_high_score = check_and_update_high_score(score)
	hud.update_high_score(high_score)  # Ensure the HUD always shows the current high score
	#$FinalScore.text = "Final Score: " + str(score)
	%GameOverScreen.visible = true
	player_knight.animated_sprite.modulate = Color(1, 0, 0, 0.75)  # Set to red
	player_knight.set_process(false)
	player_knight.set_physics_process(false)
	var game_over_control = $GameOverScreen/Control  # Adjust this path
	if game_over_control:
		game_over_control.fade_in()

func _on_timer_2_timeout() -> void:
	if not %GameOverScreen.visible:
		spawn_kaboomist(1)

func _on_restart_button_pressed() -> void:
	# Hide the Game Over screen (optional, depending on your UI setup)
	$GameOverScreen.visible = false
	get_tree().reload_current_scene()
	#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	buttonSFX.play()
	
func _on_restart_button_2_pressed() -> void:
	# Get reference to SceneTree
	var scene_tree = Engine.get_main_loop()
	if scene_tree:
		%VictoryScreen.visible = false
		scene_tree.paused = false
		scene_tree.reload_current_scene()
		#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
		buttonSFX.play()
	else:
		push_error("Could not get scene tree!")

func _on_begin_button_pressed() -> void:
	$StartScreen.visible = false
	$SelectScreen.visible = true
	#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	buttonSFX.play()
	#reset_high_score()
	
func _on_pack_button_pressed() -> void:
	get_tree().paused = false
	$SelectScreen.visible = false
	buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	begin_audio.play()  # Play the sound effect
	enemies_remaining = max_enemies - total_enemies_killed
	hud.update_enemies_remaining(enemies_remaining)
	
func _on_horde_button_pressed() -> void:
	get_tree().paused = false
	max_enemies += horde_enemies
	$SelectScreen.visible = false
	#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	begin_audio.play()  # Play the sound effect
	enemies_remaining = max_enemies - total_enemies_killed
	hud.update_enemies_remaining(enemies_remaining)
	enable_swarm_timer()

func _on_back_button_pressed() -> void:
	$StartScreen.visible = true
	$ControlsScreen.visible = false
	#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	buttonSFX.play()

func _on_back_button_2_pressed() -> void:
	$StartScreen.visible = true
	$SelectScreen.visible = false
	#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	buttonSFX.play()

func _on_controls_button_pressed() -> void:
	$StartScreen.visible = false
	$ControlsScreen.visible = true
	#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	buttonSFX.play()


func _on_quit_button_pressed() -> void:
	#buttonSFX.pitch_scale = randf_range(0.8, 0.1)
	buttonSFX.play()
	get_tree().quit()  # Exits the game

func _on_timer_3_timeout() -> void:
	if not %GameOverScreen.visible:
		spawn_warlock(1)

func _on_timer_4_timeout() -> void:
	if not %GameOverScreen.visible:
		spawn_moblin(2)

func enable_swarm_timer():
	var swarm_timer = $swarmtimer  # Ensure you reference the correct Timer node
	swarm_timer.paused = false
	swarm_timer.start()  # Start the Timer

func _on_timer_5_timeout() -> void:
	if not %GameOverScreen.visible:
		spawn_goblin(1)
		spawn_moblin(2)
		
func load_high_score():
	# Try to load the high score from the file
	var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.READ)
	if file:
		high_score = file.get_line().to_int()
		file.close()
	else:
		high_score = 0
	print("Loaded high score:", high_score)

func save_high_score():
	# Save the high score to the file
	var file = FileAccess.open(HIGH_SCORE_FILE, FileAccess.WRITE)
	file.store_line(str(high_score))
	file.close()
	print("Saved high score:", high_score)


func check_and_update_high_score(player_score: int):
	# Check if the player's score is higher than the saved high score
	if player_score > high_score:
		high_score = player_score
		save_high_score()
		hud.update_high_score(high_score)  # Update the HUD
		return true # Indicates a new high score
	return false

func reset_high_score():
	high_score = 0  # Reset the high score in memory
	save_high_score()  # Save the reset value to the file
	hud.update_score(score, high_score)  # Update the HUD to reflect the change
	print("High score reset to:", high_score)  # For debugging
