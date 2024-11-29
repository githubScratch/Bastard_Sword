extends CharacterBody2D

class_name Moblin

signal killed #sends score updates, etc

###########always face player

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var audio_hit = %OnHit  # Reference to the AudioStreamPlayer node
@onready var collision_shape_2d: CollisionShape2D = $GrabAura/CollisionShape2D

@export var move_speed = 40.0
@export var rotation_speed = 5
@export var run_away_multiplier = 1.5
@export var bump_speed = 200.0
@export var bump_push_time = 0.4
@export var pre_bump_timer = 0.25
@export var wander_time_range = Vector2(2, 6)
@export var pause_time_range = Vector2(0.5, 2)
@export var player_detect_range = 100.0
@export var mob_detect_range = 300.0
@export var bump_distance = 75.0
@export var knockback_force = 75.0
@export var speed_multiplier = 0.25 # Reduce speed to 50%
@export var transition_duration: float = 0.35  # Duration of the transition in seconds
@export var normal_move_speed: float = 225  # Player's original speed
@export var bump_cooldown_time = 1.0  # Cooldown time for bump

var bump_cooldown_timer = 0.0  # Tracks the cooldown timer
var health = 50
var is_dead = false
var is_hurt = false
var damage_delay = 0.2  # Delay before applying damage
var player: Node
var state = "wander"
var wander_range = 400
var wander_timer = 0.0
var pause_timer = 0.0
var bump_timer = 0.0
var run_away_timer = 0.0
var wander_direction = Vector2.ZERO  # Keep track of the wandering direction
var current_time = Time.get_ticks_msec()
var bashback_force = 350.0
var knockback_duration = 0.1
var knockback_timer = 0.0
var blood = load("res://scenes/blood.tscn")


func take_bash(_amount):
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	animated_sprite.play("run")  # Play the hurt animation
	velocity = (global_position.direction_to(get_node("/root/amorphous2/playerKnight").global_position) * -bashback_force)  # Apply knockback
	start_shake_effect() # Trigger the shake effect
	start_flash_effect()  # Call the flash effect coroutine
	knockback_timer = knockback_duration
	if health <= 0:
		die()

func take_damage(amount):
	if is_dead:
		return
	if is_hurt:
		return
	is_hurt = true
	await get_tree().create_timer(0.2).timeout  # Wait for the specified delay
	health -= amount
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	var blood_instantiate = blood.instantiate() #bloodpslatter
	get_tree().current_scene.add_child(blood_instantiate)
	blood_instantiate.global_position = global_position
	blood_instantiate.rotation = global_position.angle_to_point(player.global_position) - 180
	audio_hit.pitch_scale = randf_range(0.4, 0.6)
	audio_hit.play()  # Play the sound effect
	animated_sprite.play("walk")  # Play the hurt animation
	velocity = (global_position.direction_to(get_node("/root/amorphous2/playerKnight").global_position) * -knockback_force)  # Apply knockback
	knockback_timer = knockback_duration
	start_shake_effect() # Trigger the shake effect
	start_flash_effect()  # Call the flash effect coroutine

	if health <= 0:
		die()
	await get_tree().create_timer(damage_delay).timeout  # Wait for the specified delay
	is_hurt = false

func die():
	var sprite = $AnimatedSprite2D  # Replace with your visual node
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0, 3.0)
	animated_sprite.play("death")
	is_dead = true
	collision_shape.disabled = true
	collision_shape_2d.disabled = true
	
	killed.emit() #condense later to a new score value with a new emit recognition
	await get_tree().create_timer(2.0).timeout
	queue_free()

func start_flash_effect():
	# Start the flash effect
	animated_sprite.modulate = Color(1, 0, 0, 0.35)  # Red with 50% transparency
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	animated_sprite.modulate = Color(.4, .46, .79, 1)  # Red with 50% transparency

func start_shake_effect():
	# Store the original position
	var original_position = animated_sprite.position
	# Shake parameters
	var shake_duration = 0.1  # Duration of shake
	var shake_magnitude = 2  # Magnitude of shake
	var shake_timer = 0.0  # Timer to track shake duration

	# Shake effect loop
	while shake_timer < shake_duration:
		# Randomly offset the position
		var offset = Vector2(randf_range(-shake_magnitude, shake_magnitude), randf_range(-shake_magnitude, shake_magnitude))
		animated_sprite.position = original_position + offset
		shake_timer += get_process_delta_time()  # Increment the timer
		await get_tree().create_timer(0.03).timeout  # Wait briefly before next shake

	# Reset to the original position after shaking
	animated_sprite.position = original_position

func _ready():
	player = get_node("/root/amorphous2/playerKnight")
	_randomize_timers()
	state = "wander"

func _physics_process(delta):
	current_time = Time.get_ticks_msec()
	#print("State:", state, "Direction:", wander_direction, "Velocity:", velocity)

	# Decrement the bump cooldown timer
	if bump_cooldown_timer > 0:
		bump_cooldown_timer -= delta

	# Detect player
	var distance_to_player = global_position.distance_to(player.global_position)
	if state != "bump" and bump_cooldown_timer <= 0:
		if distance_to_player <= bump_distance:
			state = "bump"
			bump_timer = 0.5  # Example bump duration
		elif distance_to_player <= player_detect_range:
			state = "run_away"
			run_away_timer = randf_range(2, 4)  # Example run away duration

	match state:
		"wander":
			_handle_wander(delta)
		"pause":
				# Transition to wandering after a random pause
			pause_timer -= delta
			if pause_timer <= 0:
				state = "wander"
				_randomize_timers()
		"run_away":
			_handle_run_away(delta)
		"bump":
			_handle_bump(delta)

func _handle_wander(delta):
	wander_timer -= delta
	if wander_timer <= 0:
		state = "pause"
		_randomize_timers()
		return

	# Move in the calculated wander direction
	velocity = wander_direction * move_speed
	move_and_slide()
	animated_sprite.play("walk")

	# Update position
	if velocity.length() > 0:
		move_and_slide()
		var target_rotation = velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)


func _handle_pause(delta):
	pause_timer -= delta
	if pause_timer <= 0:
		state = "wander"
		_randomize_timers()

func _handle_run_away(delta):
	run_away_timer -= delta
	if run_away_timer <= 0:
		state = "wander"
		_randomize_timers()
		return
	var away_direction = global_position.direction_to(player.global_position).normalized() * -1
	velocity = away_direction * move_speed * run_away_multiplier
	move_and_slide()
	animated_sprite.play("run")

func _handle_bump(delta):
	bump_timer -= delta
	if bump_timer <= 0:
		state = "pause"
		velocity = Vector2.ZERO
		_randomize_timers()
		return
	await get_tree().create_timer(pre_bump_timer).timeout
	var toward_player = global_position.direction_to(player.global_position).normalized()
	velocity = toward_player * bump_speed
	move_and_slide()
	animated_sprite.play("bump")

func _randomize_timers():
	wander_timer = randf_range(2, 6)  # Wander for 2 to 6 seconds
	pause_timer = randf_range(0.5, 2)  # Pause for 0.5 to 2 seconds

	# Get player's position
	var player_position = player.global_position
	
	# Generate a random point within a 500-unit radius around the player
	var random_angle = randf() * TAU  # Random angle in radians
	var random_distance = randf_range(0, wander_range)  # Random distance within 500 units
	var target_point = player_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
	
	# Calculate the wander direction toward the target point
	wander_direction = (target_point - global_position).normalized()

	#print("Randomized: wander_timer =", wander_timer, "pause_timer =", pause_timer, "wander_direction =", wander_direction, "target_point =", target_point)

func _on_grab_aura_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):  # Ensure the object is the player
		# Create tween
		var tween := create_tween()
		
		# Adjust movement speed gradually
		tween.tween_property(body, "move_speed", body.move_speed * speed_multiplier, transition_duration)
		
		await get_tree().create_timer(bump_push_time).timeout
		bump_speed = 50

func _on_grab_aura_body_exited(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):  # Ensure the object is the player
		# Create tween
		var tween := create_tween()
		
		# Restore movement speed gradually
		tween.tween_property(body, "move_speed", normal_move_speed, transition_duration)

func _on_exit_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):  # Ensure the object is the player
		bump_speed = 200
