extends CharacterBody2D

class_name Kaboomist  # This makes the class globally accessible

signal killed(score_value: int)  # Modified signal to include score value
signal enemy_defeated  # New signal for tracking actual defeats
# Kaboomist variables
@onready var animated_sprite = $AnimatedSprite2D  # Reference to the AnimatedSprite2D node
@onready var audio_player = %OnHit  # Reference to the AudioStreamPlayer node
@onready var collision_shape = $CollisionShape2D
@onready var TNT_scene = preload("res://scenes/TNT.tscn")

@export var rotation_speed = 5.0  # Speed at which the kab rotates
var health = 300  # Initial health of the kab
var can_attack = true  # Flag to check if the kab can attack
var is_dead = false  # State to track if the kab is dead
var is_hurt = false
var damage_delay = 0.2  # Delay before applying damage
var knockback_force = 450.0  # Strength of the knockback effect
var bashback_force = 150.0
var knockback_duration = 0.1  # Duration of the knockback effect
var knockback_timer = 0.0  # Timer to track knockback duration
var throw_cooldown = 3.0  # Cooldown duration between attacks
var throw_timer = 0.0  # Timer to track the attack cooldown
var prepare_duration = 1.0  # Duration of the prepare animation
var prepare_timer = 0.0  # Timer for the prepare phase
var thrown_distance = -50.0  # Distance to throw towards the player
var thrown_duration = 0.2  # Duration of the throw
var thrown_timer = 0.0  # Timer for the throw
var state = "idle"  # Current state of the kab
var last_known_player_position: Vector2  # Store the player's last position
var last_damage_time = 0.0  # Store the last time damage was dealt
var current_time = Time.get_ticks_msec()
var move_speed = 90
var aggro_range = 400
var blood = load("res://scenes/blood.tscn")
var player: Node
var is_frenzied = false
var is_throwing_tnt = false  

func _ready():
	player = get_tree().get_root().get_node("amorphous2/playerKnight")  # Adjust the path as needed
	animated_sprite.play("walk")  # Play the hurt animation


func take_bash(_amount):
	if state == "preparing":
		prepare_timer = prepare_duration
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	animated_sprite.play("idle")  # Play the hurt animation
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
	audio_player.pitch_scale = randf_range(0.5, 0.7)
	audio_player.play()  # Play the sound effect
	animated_sprite.play("idle")  # Play the hurt animation
	velocity = (global_position.direction_to(get_node("/root/amorphous2/playerKnight").global_position) * -knockback_force)  # Apply knockback
	knockback_timer = knockback_duration
	start_shake_effect() # Trigger the shake effect
	start_flash_effect()  # Call the flash effect coroutine

	if health <= 0:
		die()
	await get_tree().create_timer(damage_delay).timeout  # Wait for the specified delay
	is_hurt = false

func die():
	is_dead = true
	collision_shape.disabled = true
	animated_sprite.play("death")
	var TNT_instance = preload("res://scenes/TNT.tscn").instantiate()  # Create TNT instance
	TNT_instance.global_position = global_position  # Set the starting position of TNT
	get_tree().current_scene.add_child(TNT_instance)  # Add TNT to the scene
	killed.emit(10)
	enemy_defeated.emit()
	await get_tree().create_timer(2.0).timeout
	queue_free()

func start_flash_effect():
	# Start the flash effect
	animated_sprite.modulate = Color(1, 0, 0, 0.35)  # Red with 50% transparency
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	animated_sprite.modulate = Color(1, 1, 1, 1)  # Red with 50% transparency

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

func _physics_process(delta):
	
	# Update timing for damage cooldown
	current_time = Time.get_ticks_msec()

	if is_dead:
		return

	if knockback_timer > 0:
		knockback_timer -= delta
		if knockback_timer <= 0:
			knockback_timer = 0
			velocity = Vector2.ZERO
		move_and_slide()
		return

	var player = get_node("/root/amorphous2/playerKnight")
	var distance_to_player = global_position.distance_to(player.global_position)

	# State handling with smoother movement and attack logic
	match state:
		"idle":
			if distance_to_player <= aggro_range and throw_timer <= 0:
				state = "preparing"
				prepare_timer = prepare_duration
				throw_timer = throw_cooldown
				animated_sprite.play("prepare")
				velocity = Vector2.ZERO
				last_known_player_position = player.global_position

		"preparing":
			prepare_timer -= delta
			if prepare_timer <= 0:
				state = "throwing"
				thrown_timer = thrown_duration
				animated_sprite.play("throw")
				velocity = Vector2.ZERO

		"throwing":
			if throw_timer > 0 and not is_throwing_tnt:  # Ensure only one TNT is thrown
				is_throwing_tnt = true  # Mark as throwing TNT
		
				var TNT_instance = preload("res://scenes/TNT.tscn").instantiate()  # Create TNT instance
		
				TNT_instance.global_position = global_position  # Set the starting position of TNT
				get_tree().current_scene.add_child(TNT_instance)  # Add TNT to the scene

				throw_timer -= delta  # Decrease throw cooldown timer

				# After throwing, reset state or continue animation
				if !animated_sprite.is_playing():
					animated_sprite.play("attack")

			else:
				velocity = Vector2.ZERO
				if animated_sprite.animation == "attack" and animated_sprite.is_playing():
					return
				else:
					is_throwing_tnt = false  # Reset flag when throw timer runs out
					state = "idle"
					animated_sprite.play("idle")

	if throw_timer > 0:
		throw_timer -= delta

	if state == "idle" and throw_timer <= 0:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
		move_and_slide()
		animated_sprite.play("idle")

		if velocity.length() > 0:
			var target_rotation = direction.angle()
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
