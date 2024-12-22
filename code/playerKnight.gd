extends CharacterBody2D

class_name Player

# Variables for movement and rotation speeds
@export var move_speed = 225  # Normal movement speed in pixels per second
var current_speed = move_speed
var sprint_speed_multiplier = 1.75  # Sprint speed multiplier
var rotation_speed = 8  # Rotation speed in radians per second
var stop_threshold = 40  # Distance to stop moving when close to the mouse
var defend_slowdown_factor = 0.5  # 50% slowdown while defending
var hold_direction_slowdown_factor = 0.65  # 50% slowdown when holding direction key

var lunge_distance = 150  # Distance to lunge when attacking
var lunge_duration = 0.15  # Duration of the lunge effect
var feint_distance = 75  # Distance to feint when shield bashing
var feint_duration = 0.25  # Duration of the feint effect
var basic_attack_lunge_distance = 50  # Distance for basic attack lunge
var basic_attack_lunge_duration = 0.15  # Duration of basic attack lunge
var dodge_distance = 175  # Distance to dodge
var dodge_duration = 0.3  # Duration of the dodge

var attack_recovery_time = 0.5  # Recovery time after attacking while defending
var attack_move_recovery_time = 0.5  # Recovery time after any attack
var attack_move_recovery_speed = 0.1  # 10% of normal speed during recovery
var attack_recovery_timer = 0.0
var attack_move_recovery_timer = 0.0

@export var health = 300.0
var blood = load("res://scenes/blood.tscn")

# Internal state flags and timers
var is_attacking = false
var is_bashing = false
var is_defending = false
var dodge_move_recovery_time = 0.15
var dodge_move_recovery_timer = 0.0
var lunge_timer = 0.0
var feint_timer = 0.0
var basic_attack_lunge_timer = 0.0  # Timer for basic attack lunge
var dodge_timer = 0.0
var sprint_timer = 0.0
var sprint_recovery = .5
var defend_timer = 0.0
var defend_recovery = .5
var dodge_direction = Vector2.ZERO  # Dodge direction
var is_dead = false
var is_hurt = false
var damage_delay = 0.2

#stamina
var max_stamina = 100.0  # Maximum stamina value
var current_stamina = max_stamina  # Current stamina value
var defend_stamina_cost = 20.0  
var sprint_stamina_cost = 50.0 # Stamina cost per second when sprinting
var attack_stamina_cost = 15.0  # Stamina cost for each attack
var sprint_attack_stamina_cost = 30
var bash_stamina_cost = 30
var dodge_stamina_cost = 30
var stamina_recovery_rate = 30.0  # Stamina recovery rate per second
var stamina_recovery_delay = 2.0  # Delay before recovery resumes after reaching 0 stamina
var recovery_timer = 0.0  # Timer for delaying recovery

#testing zone
var locked_target = null

signal dead

# Reference to the AnimatedSprite2D node and attack Area2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D  # Ensure you have the correct path
@onready var attack_area = $AttackArea  # Reference to the Area2D node
@onready var hurt_box = $HurtBox  # Reference to the HurtBox node
@onready var audio_player = $AudioStreamPlayer2D  # Reference to the AudioStreamPlayer node
@onready var shield_bash = $shieldbash  # Reference to the AudioStreamPlayer node
@onready var defended = $defended  # Reference to the AudioStreamPlayer node
@onready var dodgeSFX = $dodgeSFX
@onready var health_bar = get_node("/root/amorphous2/UILayer/HUD/HealthBar")  # Adjust path as needed
@onready var stamina_bar = get_node("/root/amorphous2/UILayer/HUD/StaminaBar")  # Adjust path as needed
@export var bashback_distance := 250.0    # Knockback distance for affected units
@export var bashback_duration := 0.4      # Duration of knockback effect
@export var bash_damage := 50   
@onready var bash_box = $BashBox
@onready var hurt_player: AudioStreamPlayer2D = %hurtplayer
@onready var vignette_rect: ColorRect = $VignetteCavnas/ColorRect
var vignette_stamina_ratio = 1.0  # Smoothly updated ratio

func _ready():
	bash_box.monitoring = false  # Disable the explosion area until ready to explode

func update_vignette():
	# Ensure the ColorRect node exists and has a ShaderMaterial
	if vignette_rect and vignette_rect.material and vignette_rect.material is ShaderMaterial:
		var shader_material = vignette_rect.material as ShaderMaterial

		# Use the smoothed vignette_stamina_ratio
		var intensity = (1.0 - vignette_stamina_ratio) * 2.0
		intensity = clamp(intensity, 0.0, 1.0)

		var radius = 0.5 + intensity * 3.0

		# Update shader parameters directly as properties
		if health == 150:
			shader_material.set("shader_parameter/MainAlpha", intensity * 1)
			shader_material.set("shader_parameter/outerRadius", 0.5 + intensity * 1.5)
		elif health < 150 and health > 99:
			shader_material.set("shader_parameter/MainAlpha", intensity * 1.15)
			shader_material.set("shader_parameter/outerRadius", 0.5 + intensity * 1)
		elif health >= 0 and health <= 99:
			shader_material.set("shader_parameter/MainAlpha", intensity * 1.45)
			shader_material.set("shader_parameter/outerRadius", 0.5 + intensity * 0.85)
	else:
		print("Error: Vignette material is missing or not a ShaderMaterial.")


func take_damage(amount):
	if is_hurt:
		return
	if is_defending and current_stamina > 0: #add check to see if source of damage is to the front of the character
		var stamina_damage = amount
		#var stamina_damage = amount / 2
		current_stamina -= stamina_damage
		if current_stamina < 0:
			current_stamina = 0
		stamina_bar.value = current_stamina  # Update stamina bar value
		var screen_shake = get_node("/root/amorphous2/ScreenShake")
		screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
		start_shake_effect()# Trigger the shake effect
		defended.pitch_scale = randf_range(0.8, 1.0)
		defended.play()  # Play the sound effect#add defend sound effect
	elif health > 0:
		is_hurt = true
		await get_tree().create_timer(damage_delay).timeout
		health -= amount
		var blood_instantiate = blood.instantiate()
		get_tree().current_scene.add_child(blood_instantiate)
		blood_instantiate.global_position = global_position
		hurt_player.pitch_scale = randf_range(0.7, 0.9)
		hurt_player.play()
		health_bar.value = health  # Update health bar value
		%ProgressBar.value = int(health)  # Update the health bar here

	if health <= 0:
		die()  # Call die method if health is zero or below
		animated_sprite.play("hurt")  # Play the hurt animation
		health = 0
	else:
		var screen_shake = get_node("/root/amorphous2/ScreenShake")
		screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
		start_shake_effect()# Trigger the shake effect
		start_flash_effect()  # Call the flash effect coroutine
			# Slow down the game
		Engine.time_scale = 0.3  # Set time scale to 0.1 for slow motion
			# Wait for a brief moment to create the slow-motion effect
		await get_tree().create_timer(0.1).timeout  # Duration of slow motion
			# Restore the original time scale
		Engine.time_scale = 1
	await get_tree().create_timer(damage_delay).timeout
	is_hurt = false
	
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

func die():
	dead.emit()
	#print("Player has died")  # Logic for player death
	#queue_free()  # Remove the player from the scene or trigger a game over

func _physics_process(delta):
	
	%StaminaBar.value = int(current_stamina)  # Update the health bar here
	stamina_bar.value = current_stamina  # Update health bar value
	# Smoothly interpolate vignette_stamina_ratio to the new stamina ratio
	var target_ratio = current_stamina / max_stamina
	if vignette_stamina_ratio != target_ratio:
		var tween = create_tween()
		tween.tween_property(self, "vignette_stamina_ratio", target_ratio, 0.5)

	# Update the vignette shader with the interpolated ratio
	update_vignette()
	
		# Calculate base movement
	var mouse_pos = get_global_mouse_position()
	var distance_to_mouse = global_position.distance_to(mouse_pos)
	current_speed = move_speed
	var is_moving = false

	# Handle attack recovery timers
	if attack_recovery_timer > 0:
		attack_recovery_timer -= delta
		if attack_recovery_timer <= 0:
			attack_recovery_timer = 0

	if attack_move_recovery_timer > 0:
		attack_move_recovery_timer -= delta
		if attack_move_recovery_timer <= 0:
			attack_move_recovery_timer = 0

	if dodge_move_recovery_timer > 0:
		dodge_move_recovery_timer -= delta
		if dodge_move_recovery_timer <= 0:
			dodge_move_recovery_timer = 0

	# Handle lunge duration
	if lunge_timer > 0:
		lunge_timer -= delta
		if lunge_timer <= 0:
			lunge_timer = 0

	# Handle feint duration
	if feint_timer > 0:
		feint_timer -= delta
		if feint_timer <= 0:
			feint_timer = 0
			
	# Handle sprint stutter
	if sprint_timer > 0:
		sprint_timer -= delta
		if sprint_timer <= 0:
			sprint_timer = 0
			
	# Handle sprint stutter
	if defend_timer > 0:
		defend_timer -= delta
		if defend_timer <= 0:
			defend_timer = 0

	# Handle basic attack lunge duration
	if basic_attack_lunge_timer > 0:
		basic_attack_lunge_timer -= delta
		if basic_attack_lunge_timer <= 0:
			basic_attack_lunge_timer = 0

	# Handle dodge movement and duration
	if dodge_timer > 0:
		dodge_timer -= delta
		velocity = dodge_direction * (dodge_distance / dodge_duration)
		dodge_move_recovery_timer = dodge_move_recovery_time
		move_and_slide()  # Apply dodge movement
		return  # Skip other actions while dodging
	else:
		dodge_direction = Vector2.ZERO  # Reset direction
		collision_shape.disabled = false  # Re-enable collision after dodge
		is_defending = false  # Ensure we exit the defend state
		is_bashing = false  # Ensure we exit the bash state

	#stamina: Regenerate stamina if not sprinting, defending, or attacking
	if current_stamina < max_stamina and recovery_timer <= 0:
		current_stamina += stamina_recovery_rate * delta
		if current_stamina > max_stamina:
			current_stamina = max_stamina
	else:
		# #stamina: If at 0 stamina, pause recovery for a second
		if current_stamina <= 0:
			recovery_timer -= delta
			if recovery_timer <= 0:
				recovery_timer = 0

	# Check for defend action
	if Input.is_action_pressed("defend") and attack_recovery_timer <= 0 and current_stamina > 9 and defend_timer <= 0:  # #stamina: Only defend if stamina is available
		is_defending = true
		hurt_box.set_deferred("monitoring", false)
		current_stamina -= defend_stamina_cost * delta
		current_speed *= defend_slowdown_factor
		if current_stamina <=10:
			defend_timer = defend_recovery #stutter prevention
		if not is_attacking:
			animated_sprite.play("defend")
			#current_speed *= hold_direction_slowdown_factor
			#if not locked_target or not locked_target.get_tree(): 
				#locked_target = get_nearest_enemy()
			#if locked_target and locked_target.get_tree():
			# Face the locked target
				#var target_angle = (locked_target.global_position - global_position).angle()
				#rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
	else:
		is_defending = false
		hurt_box.set_deferred("monitoring", true)
		collision_shape.disabled = false
		#locked_target = null

	# Apply sprint speed if sprinting
	if Input.is_action_pressed("sprint") and not is_defending and current_stamina > 9 and sprint_timer <= 0:  # #stamina: Only sprint if stamina is available
		current_speed *= sprint_speed_multiplier
		current_stamina -= sprint_stamina_cost * delta  # #stamina: Drain stamina while sprinting
		if current_stamina <=10:
			sprint_timer = sprint_recovery #stutter prevention
		is_moving = true

	# Dodge input and direction
	if Input.is_action_just_pressed("dodge") and not is_attacking and dodge_timer <= 0 and current_stamina > 9 and dodge_move_recovery_timer <= 0:
		dodge_timer = dodge_duration  # Start dodge timer
		dodge_direction = (mouse_pos - global_position).normalized()  # Set direction
		collision_shape.disabled = true  # Disable collision during dodge
		animated_sprite.play("dodge")
		dodgeSFX.pitch_scale = randf_range(0.6, 0.8)
		dodgeSFX.play()
		current_stamina -= dodge_stamina_cost
		return  # Skip further processing during dodge

	# Attack input and animations
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_bashing and dodge_timer <= 0 and current_stamina > 9:  # #stamina: Only attack if stamina is available
		if Input.is_action_pressed("defend") and Input.is_action_pressed("sprint") and current_stamina > 30:
			animated_sprite.play("shield_bash")
			$BashParticles.restart()
			shield_bash.pitch_scale = randf_range(0.7, 0.9)
			shield_bash.play()  # Play the sound effect
			lunge_timer = lunge_duration  # Set lunge timer for sprint attack
			current_stamina -= sprint_attack_stamina_cost
			current_stamina -= attack_stamina_cost
			feint_timer = feint_duration  # Set feint timer for shield
			is_bashing = true
			bash_box.monitoring = true
			attack_recovery_timer = attack_recovery_time
			await get_tree().create_timer(0.1).timeout
			bash_box.monitoring = false
		elif Input.is_action_pressed("sprint") and current_stamina > 20 and not is_attacking and not is_bashing:
			animated_sprite.play("sprint_attack")
			audio_player.pitch_scale = randf_range(0.9, 1.1)
			audio_player.play()  # Play the sound effect
			current_stamina -= sprint_attack_stamina_cost
			lunge_timer = lunge_duration  # Set lunge timer for sprint attack
			is_attacking = true
			attack_move_recovery_timer = attack_move_recovery_time  # Start recovery phase
		elif Input.is_action_pressed("defend") and current_stamina > 20 and attack_recovery_timer <= 0 and not is_attacking and not is_bashing:
			animated_sprite.play("shield_bash")
			$BashParticles.restart()
			shield_bash.pitch_scale = randf_range(0.7, 0.9)
			shield_bash.play()  # Play the sound effect
			current_stamina -= bash_stamina_cost
			feint_timer = feint_duration  # Set feint timer for shield
			is_bashing = true
			bash_box.monitoring = true
			attack_recovery_timer = attack_recovery_time
			await get_tree().create_timer(0.1).timeout
			bash_box.monitoring = false
		elif not is_attacking and not is_bashing: 
			animated_sprite.play("swing")
			audio_player.pitch_scale = randf_range(0.9, 1.1)
			audio_player.play()  # Play the sound effect
			current_stamina -= attack_stamina_cost
			basic_attack_lunge_timer = basic_attack_lunge_duration  # Set lunge timer for basic attack
			is_attacking = true
			attack_move_recovery_timer = attack_move_recovery_time  # Start recovery phase
		if current_stamina < 0:  # Prevent going negative
			current_stamina = 0
		return  # Skip movement during attack

	# Lunge movement during sprint attack
	if lunge_timer > 0:
		var lunge_direction = (mouse_pos - global_position).normalized()
		velocity = lunge_direction * (lunge_distance / lunge_duration)
		move_and_slide()  # Apply lunge movement
		is_moving = true
		return  # Skip further processing

	# Lunge movement during basic attack
	if basic_attack_lunge_timer > 0:
		var basic_lunge_direction = (mouse_pos - global_position).normalized()
		velocity = basic_lunge_direction * (basic_attack_lunge_distance / basic_attack_lunge_duration)
		move_and_slide()  # Apply lunge movement
		is_moving = true
		return  # Skip further processing

# feint movement during bash 
	if feint_timer > 0:
		var feint_direction = (global_position - mouse_pos).normalized()
		velocity = feint_direction * (feint_distance / feint_duration)
		move_and_slide()
		is_moving = true
		return

	# Check if the "move hold direction" action is pressed
	if Input.is_action_pressed("move_hold_direction"):
		rotation_speed = 0
	else:
		# Reset the locked target when the button is released
		#locked_target = null
		rotation_speed = 8

		# Rotate to face the mouse, except during recovery
		if attack_move_recovery_timer <= 0 and lunge_timer <= 0 and dodge_timer <= 0 and basic_attack_lunge_timer <= 0:
			var target_angle = (mouse_pos - global_position).angle()
			rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

	# Movement reduction and rotation disable during recovery
	if attack_move_recovery_timer > 0:
		current_speed = move_speed * attack_move_recovery_speed  # Set to 10% of normal speed
		is_moving = true  # Allow reduced movement
	else:
		# Basic movement towards mouse
		if distance_to_mouse > stop_threshold:
			var direction = (mouse_pos - global_position).normalized()
			velocity = direction * current_speed
			move_and_slide()  # Move character
		else:
			velocity = Vector2.ZERO  # Stop movement if close enough

	# Set animations based on current states
	if not is_attacking and dodge_timer <= 0:
		if is_defending:
			animated_sprite.play("defend")
		elif is_moving:
			animated_sprite.play("sprint" if Input.is_action_pressed("sprint") else "move")
		else:
			animated_sprite.play("idle")

	# Reset the attack state when the animation finishes
	if is_attacking and animated_sprite.animation == "swing" and animated_sprite.frame == 5:
		is_attacking = false
	elif is_attacking and animated_sprite.animation == "sprint_attack" and animated_sprite.frame == 6:
		is_attacking = false
	elif is_attacking and animated_sprite.animation == "shield_bash" and animated_sprite.frame == 6:
		is_attacking = false
		is_bashing = false

	# Check for collision with goblin and deal damage
	if is_attacking:
		# Get overlapping bodies from the attack area
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.has_method("take_damage"):
				body.take_damage(50)  # Deal 25 damage (adjust as needed)

func _on_bash_box_body_entered(body: Node2D) -> void:
	if body.has_method("take_bash"):
		body.take_bash(bash_damage)
	# Apply knockback force over the specified duration
		var knockback_vector = (body.global_position - global_position).normalized() * bashback_distance
		var target_position = body.global_position + knockback_vector
	# Create the tween using the `create_tween()` method
		var tween = body.create_tween()
		tween.tween_property(body, "global_position", target_position, bashback_duration)
		await get_tree().create_timer(0.2).timeout
		bash_box.monitoring = false
