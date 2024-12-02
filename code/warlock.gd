extends CharacterBody2D

class_name Warlock  # This makes the class globally accessible

signal killed #sends score updates, etc

# Kaboomist variables
@onready var animated_sprite = $AnimatedSprite2D  # Reference to the AnimatedSprite2D node
@onready var audio_hit = %OnHit  # Reference to the AudioStreamPlayer node
@onready var collision_shape = $CollisionShape2D
@export var rotation_speed = 5.0  # Speed at which the kab rotates
#@onready var TNT_scene = preload("res://scenes/TNT.tscn")

var health = 150  # Initial health of the kab
var can_attack = true  # Flag to check if the kab can attack
var is_dead = false  # State to track if the kab is dead
var is_hurt = false
var damage_delay = 0.2  # Delay before applying damage
var knockback_force = 250.0  # Strength of the knockback effect
var bashback_force = 350.0
var knockback_duration = 1.25  # Duration of the knockback effect
var knockback_timer = 0.0  # Timer to track knockback duration
var throw_cooldown = 3.0  # Cooldown duration between attacks
var throw_timer = 0.0  # Timer to track the attack cooldown
var prepare_duration = 1.0  # Duration of the prepare animation
var prepare_timer = 0.0  # Timer for the prepare phase
#var thrown_distance = -50.0  # Distance to throw towards the player
#var thrown_duration = 0.2  # Duration of the throw
#var thrown_timer = 0.0  # Timer for the throw
var state = "idle"  # Current state of the kab
var last_known_player_position: Vector2  # Store the player's last position
var last_damage_time = 0.0  # Store the last time damage was dealt
var current_time = Time.get_ticks_msec()
var move_speed = 90
#var aggro_range = 300
var blood = load("res://scenes/blood.tscn")
var player: Node

@export var speed_multiplier = 0.65 # Reduce speed to 50%
@export var audio_pitch_multiplier: float = 0.95  # Pitch adjustment multiplier
@export var transition_duration: float = 0.35  # Duration of the transition in seconds
@export var normal_move_speed: float = 225  # Player's original speed
@export var reset_interval: float = 1.0  # Interval for periodic reset
var affected_bodies: Array = []  # List of affected bodies
@onready var slow_aura: Area2D = %SlowAura
@onready var collision_shape_2d: CollisionShape2D = $SlowAura/CollisionShape2D

func _ready():
	player = get_tree().get_root().get_node("amorphous2/playerKnight")  # Adjust the path as needed
	animated_sprite.play("idle")  # Play the hurt animation

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
	audio_hit.pitch_scale = randf_range(0.4, 0.6)
	audio_hit.play()  # Play the sound effect
	animated_sprite.play("idle")  # Play the hurt animation
	velocity = (global_position.direction_to(get_node("/root/amorphous2/playerKnight").global_position) * -knockback_force)  # Apply knockback
	knockback_timer = knockback_duration
	start_shake_effect() # Trigger the shake effect
	#start_flash_effect()  # Call the flash effect coroutine
	increase_scale(Vector2(1.2, 1.2))
	
	if health > 50:
		animated_sprite.modulate = Color(.4, .46, .79, 0.1)
		await get_tree().create_timer(1.25).timeout
		animated_sprite.modulate = Color(.4, .46, .79, 0.6)
	
	if health <= 0:
		die()
	await get_tree().create_timer(damage_delay).timeout  # Wait for the specified delay
	is_hurt = false

func die():
	var sprite = $AnimatedSprite2D  # Replace with your visual node
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0, 3.0)
	var particles = slow_aura.get_node("CPUParticles2D3")
	tween.tween_property(particles, "modulate", Color(0, 0, 0, 0), 1.0)  # Fades to transparent
	particles.emitting = false
	is_dead = true
	collision_shape.disabled = true
	collision_shape_2d.disabled = true
	animated_sprite.play("death")
	killed.emit() #condense later to a new score value with a new emit recognition
	killed.emit()
	killed.emit()
	killed.emit()
	await get_tree().create_timer(2.0).timeout
	queue_free()


func increase_scale(scale_factor: Vector2) -> void:
	if slow_aura:
		slow_aura.scale *= scale_factor
	var particles = slow_aura.get_node("CPUParticles2D3")
	if particles and health > 49:
		particles.scale *= scale_factor
		particles.set("scale_amount_min", particles.get("scale_amount_min") * 1.25 * scale_factor.x)
		particles.set("scale_amount_max", particles.get("scale_amount_max") * 1.25 * scale_factor.x)


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
	#var distance_to_player = global_position.distance_to(player.global_position)

	# State handling with smoother movement and attack logic

	if state == "idle" and throw_timer <= 0:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * move_speed
		move_and_slide()
		animated_sprite.play("idle")

		if velocity.length() > 0:
			var target_rotation = direction.angle()
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

func transition_audio_pitch_scale(bus_name: String, target_pitch: float, duration: float):
	# Get the index of the custom bus
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	# Get the AudioEffectPitchShift instance
	var effect = AudioServer.get_bus_effect(bus_index, 0)  # Assuming the PitchShift effect is the first
	if effect and effect is AudioEffectPitchShift:
		# Get the current pitch scale
		var current_pitch = effect.pitch_scale
		
		# Create a Tween
		var tween = create_tween()
		
		# Tween the pitch scale over the specified duration
		tween.tween_property(effect, "pitch_scale", target_pitch, duration)
	
func _on_slow_aura_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):  # Ensure the object is the player
		# Create tween
		var tween := create_tween()
		# Adjust movement speed gradually
		tween.tween_property(body, "move_speed", body.move_speed * speed_multiplier, transition_duration)
		# Adjust audio pitch gradually
		#var audio_player: AudioStreamPlayer2D = body.get_node("song1")  # Adjust path if needed
		#if audio_player:
			#tween.tween_property(audio_player, "pitch_scale", audio_player.pitch_scale * audio_pitch_multiplier, transition_duration)
		#await get_tree().create_timer(0.2).timeout
		transition_audio_pitch_scale("GameAudio", 0.8, 0.4)  # Transition to 80% pitch over 2 seconds
		
func _on_slow_aura_body_exited(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):  # Ensure the object is the player
		# Create tween
		var tween := create_tween()
		# Restore movement speed gradually
		tween.tween_property(body, "move_speed", normal_move_speed, transition_duration)
		# Restore audio pitch gradually
		#var audio_player: AudioStreamPlayer2D = body.get_node("song1")  # Adjust path if needed
		#if audio_player:
			#tween.tween_property(audio_player, "pitch_scale", 1.0, transition_duration)
		#await get_tree().create_timer(0.5).timeout
		transition_audio_pitch_scale("GameAudio", 1.0, 0.5)  # Reset pitch to normal over 2 seconds
