extends Node2D

# Reference to the player character, where Path2D is now a child
@export var player_path: NodePath  # Path to the player, set in the Inspector

@onready var begin_audio = $beginaudio  # Reference to the AudioStreamPlayer node
@onready var hud = $UILayer/HUD

@onready var fog: CPUParticles2D = %fog

var elapsed_time = 0.0
var event_thresholds = [30, 60, 120, 150, 180]  # Time thresholds for events (in seconds)
var triggered_events = []  # Stores which thresholds have already been triggered
var event_actions = {
	30: [Callable(self, "spawn_moblin").bind(20)],
	60: [Callable(self, "spawn_goblin").bind(10)],
	120: [Callable(self, "spawn_kaboomist").bind(2), Callable(self, "spawn_moblin").bind(20)],
	150: [Callable(self, "spawn_goblin").bind(10), Callable(self, "spawn_warlock").bind(1)],
	180: [Callable(self, "enable_swarm_timer")]
}

var score := 0:
	set(value):
		score = value
		hud.update_score(score)  # Call the method on the HUD node

func _ready() -> void:
	score = 0
	get_tree().paused = true
	player_path = NodePath("playerKnight")
	fog.preprocess = 5.0  # Preloads particles for 1 second
	fog.one_shot = false

func _process(delta):
	# Increment the elapsed time
	elapsed_time += delta
	
	# Check thresholds
	check_thresholds()

func check_thresholds():
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

func spawn_goblin(count: int):
	# Ensure the PathFollow2D node under the player is located
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null
	
	if path_follow != null:
		for i in range(count):
			# Instantiate and spawn each goblin
			var goblin_instance = preload("res://scenes/goblin.tscn").instantiate()
			path_follow.progress_ratio = randf()  # Randomize position on the path
			goblin_instance.global_position = path_follow.global_position  # Set position on the instantiated goblin
			goblin_instance.killed.connect(_on_enemy_killed)  # Connect signals
			add_child(goblin_instance)  # Add the instantiated goblin to the scene
	else:
		push_error("Failed to locate PathFollow2D under the player.")

func spawn_kaboomist(count: int):
	# Locate the PathFollow2D node under the player
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null
	# Ensure path_follow was successfully located
	if path_follow != null:
		for i in range(count):
			var kaboomist_instance = preload("res://scenes/kaboomist.tscn").instantiate()  # Ensure the path is correct
			path_follow.progress_ratio = randf()  # Randomize position on the path
			kaboomist_instance.global_position = path_follow.global_position  # Set position on the instantiated goblin
			var character_body = kaboomist_instance.get_node("CharacterBody2D")
			character_body.killed.connect(_on_enemy_killed)
			add_child(kaboomist_instance)  # Add the instantiated goblin to the scene
	else:
		push_error("Failed to locate PathFollow2D under the player.")

func spawn_warlock(count: int):
	# Locate the PathFollow2D node under the player
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null
	# Ensure path_follow was successfully located
	if path_follow != null:
		for i in range(count):
			var warlock_instance = preload("res://scenes/warlock.tscn").instantiate()  # Ensure the path is correct
			path_follow.progress_ratio = randf()  # Randomize position on the path
			warlock_instance.global_position = path_follow.global_position  # Set position on the instantiated 
			var character_body = warlock_instance.get_node("CharacterBody2D")
			character_body.killed.connect(_on_enemy_killed)
			add_child(warlock_instance)  # Add the instantiated  to the scene
		
	else:
		push_error("Failed to locate PathFollow2D under the player.")

func spawn_moblin(count: int):
	# Locate the PathFollow2D node under the player
	var player = get_node(player_path)
	var path_follow = player.get_node("Path2D/PathFollow2D") if player else null
	# Ensure path_follow was successfully located
	if path_follow != null:
		for i in range(count):
			var moblin_instance = preload("res://scenes/moblin.tscn").instantiate()  # Ensure the path is correct
			path_follow.progress_ratio = randf()  # Randomize position on the path
			moblin_instance.global_position = path_follow.global_position  # Set position on the instantiated goblin
			var character_body = moblin_instance.get_node("CharacterBody2D")
			character_body.killed.connect(_on_enemy_killed)
			add_child(moblin_instance)  # Add the instantiated goblin to the scene
	else:
		push_error("Failed to locate PathFollow2D under the player.")

func _on_timer_timeout() -> void:
	if not %GameOverScreen.visible:
		spawn_goblin(2)

func _on_enemy_killed():
	if not %GameOverScreen.visible:
		score += 1

@onready var player_knight: Player = $playerKnight

func _on_player_knight_dead() -> void:
	%GameOverScreen.visible = true
	player_knight.set_process(false)
	player_knight.set_physics_process(false)
	player_knight.animated_sprite.modulate = Color(1, 0, 0, 0.75)  # Set to red
	var game_over_control = $GameOverScreen/Control  # Adjust this path
	if game_over_control:
		game_over_control.fade_in()

func _on_timer_2_timeout() -> void:
	if not %GameOverScreen.visible:
		spawn_kaboomist(1)

func _on_restart_button_pressed() -> void:
	# Hide the Game Over screen (optional, depending on your UI setup)
	$GameOverScreen.visible = false

	# Reload the current scene (restart the game)
	get_tree().reload_current_scene()

func _on_begin_button_pressed() -> void:
	get_tree().paused = false
	$StartScreen.visible = false
	begin_audio.pitch_scale = randf_range(0.9, 1.1)
	begin_audio.play()  # Play the sound effect

func _on_back_button_pressed() -> void:
	$StartScreen.visible = true
	$ControlsScreen.visible = false

func _on_controls_button_pressed() -> void:
	$StartScreen.visible = false
	$ControlsScreen.visible = true


func _on_quit_button_pressed() -> void:
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
		spawn_goblin(4)
