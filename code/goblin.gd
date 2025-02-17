extends CharacterBody2D

class_name Goblin  # This makes the class globally accessible

signal killed(score_value: int)  # Modified signal to include score value
signal enemy_defeated  # New signal for tracking actual defeats

# Goblin variables
@onready var animated_sprite = $AnimatedSprite2D  # Reference to the AnimatedSprite2D node
@onready var attack_area = $AttackArea  # Reference to the Area2D node
@onready var audio_player = $AudioStreamPlayer2D  # Reference to the AudioStreamPlayer node
@onready var audio_player2 = $AudioStreamPlayer2D2  # Reference to the AudioStreamPlayer node
@onready var hurt_player = $hurtplayer  # Reference to the AudioStreamPlayer node
@onready var frenziedFlame = $frenziedFlame 
@onready var hitWarning = $hitWarning 
@onready var collision_shape = $CollisionShape2D
@export var rotation_speed = 4.0  # Speed at which the goblin rotates
@onready var raycasts = [$RayCast2D, $RayCast2D2, $RayCast2D3]  
@onready var torch_flame: PointLight2D = $torchFlame

var health = 100  # Initial health of the goblin
var attack_damage = 50  # Damage dealt by the goblin
var can_attack = true  # Flag to check if the goblin can attack
var is_dead = false  # State to track if the goblin is dead
var is_hurt = false
var knockback_force = 450.0  # Strength of the knockback effect
var bashback_force = 100.0
var knockback_duration = 0.1  # Duration of the knockback effect
var knockback_timer = 0.0  # Timer to track knockback duration
var damage_delay = 0.2  # Delay before applying damage
var attack_cooldown = 1.0  # Cooldown duration between attacks !!!!!!!!!!!!
var attack_timer = 0.0  # Timer to track the attack cooldown
var prepare_duration = 1.0  # Duration of the prepare animation
var prepare_interrupt = 1.5  # Duration of the interrupt animation
var prepare_timer = 0.0  # Timer for the prepare phase
var lunge_distance = 400.0  # Distance to lunge towards the player
var lunge_duration = 1.4  # Duration of the lunge
var lunge_timer = 0.0  # Timer for the lunge
var state = "idle"  # Current state of the goblin
var last_known_player_position: Vector2  # Store the player's last position
var last_damage_time = 0.0  # Store the last time damage was dealt
var current_time = Time.get_ticks_msec()
var move_speed = 125
var aggro_range = 200
var is_frenzied = false  # Flag to track if speed boost has been applied
var blood = load("res://scenes/blood.tscn")
var player: Node
var target_lunge_position: Vector2
@export var lunge_speed = 500.0  # Maximum speed of the lunge
var current_lunge_speed = 0.0    # Current tweened speed value
var tween: Tween
#var target_position: Vector2 = Vector2.ZERO
var target_offset: Vector2 = Vector2.ZERO # Offset from the player's position

func _ready():
	player = get_tree().get_root().get_node("amorphous2/playerKnight")  # Adjust the path as needed
	attack_area.set_deferred("monitoring", false)  # ADDED
	attack_area.area_entered.connect(_on_AttackArea_area_entered)
	var game_timer = get_node("/root/amorphous2/globalTimer")  # Adjust the path
	_adjust_stats_based_on_time(game_timer.game_time_elapsed)
	hitWarning.enabled = false

func _adjust_stats_based_on_time(elapsed_time: float):
	if elapsed_time > 100.0: 
		self.move_speed += 100
		animated_sprite.modulate = Color(0.4, 0.6, 0.6, 1.0)
	#if elapsed_time > 200.0: 
		#self.lunge_duration -= 0.2
		#animated_sprite.scale = Vector2(1.25,1.25)
		#animated_sprite.modulate = Color(0.7, 0.4, 0.4, 1.0)

func _on_AttackArea_area_entered(area):
	if area.is_in_group("player") and (current_time - last_damage_time) > 1000 and health > 0:  # 1-second cooldown
		last_damage_time = current_time
		var player = area.get_parent()
		player.take_damage(attack_damage)

func take_bash(_amount):
	attack_area.set_deferred("monitoring", false)
	if state == "preparing":
		prepare_timer = prepare_duration
		#state = "idle"
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	animated_sprite.play("hurt")  # Play the hurt animation
	velocity = (global_position.direction_to(get_node("/root/amorphous2/playerKnight").global_position) * -bashback_force)  # Apply knockback
	start_shake_effect() # Trigger the shake effect
	start_flash_effect()  # Call the flash effect coroutine
	knockback_timer = knockback_duration
	if health <= 0:
		die()

func take_damage(amount):
	attack_area.set_deferred("monitoring", false)
	if is_dead:
		return
	if is_hurt:
		return
	if state == "preparing":
		prepare_timer = prepare_interrupt
	is_hurt = true
	await get_tree().create_timer(damage_delay).timeout  # Wait for the specified delay
	health -= amount
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	var blood_instantiate = blood.instantiate() #bloodpslatter
	get_tree().current_scene.add_child(blood_instantiate)
	blood_instantiate.global_position = global_position
	blood_instantiate.rotation = global_position.angle_to_point(player.global_position) - 180
	audio_player.pitch_scale = randf_range(0.6, 0.8)
	audio_player.play()  # Play the sound effect
	#animated_sprite.play("hurt")  # Play the hurt animation
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
	attack_area.set_physics_process(false)
	hitWarning.enabled = false
	frenziedFlame.enabled = false
	collision_shape.disabled = true
	animated_sprite.play("death")
	killed.emit(2)
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

	if health < 100 and not is_frenzied:
		move_speed += 200
		#prepare_duration -= 0.2
		lunge_duration -= 0.2
		#lunge_distance += 200.0
		#aggro_range -= 75
		frenziedFlame.enabled = true
		is_frenzied = true

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
			attack_area.set_deferred("monitoring", false)
			# Iterate through each RayCast2D in the array
			for raycast in raycasts:
				if raycast.is_colliding():
					var target = raycast.get_collider()
					if target != null and target.is_in_group("player") and attack_timer <= 0:
						state = "preparing"
						prepare_timer = prepare_duration
						animated_sprite.play("prepare")
						velocity = Vector2.ZERO
						last_known_player_position = target.global_position
						break  # Exit the loop once a player is detected


		"preparing":
			hitWarning.enabled = true
			attack_area.set_deferred("monitoring", false)
			prepare_timer -= delta
			if prepare_timer <= 0:
				state = "lunging"
				lunge_timer = lunge_duration
				animated_sprite.play("attack")
				audio_player2.pitch_scale = randf_range(0.9, 1.1)
				audio_player2.play()
				velocity = Vector2.ZERO

		"lunging":
			attack_timer = attack_cooldown
			hitWarning.enabled = false
			if lunge_timer > 0:
				if lunge_timer == lunge_duration:
					var lunge_direction = global_position.direction_to(last_known_player_position).normalized()
					target_lunge_position = global_position + (lunge_direction * lunge_distance)
					
					# Create tween for the speed value
					tween = create_tween()
					tween.set_ease(Tween.EASE_OUT)
					tween.set_trans(Tween.TRANS_CUBIC)
					# Start at full speed and tween down to 0
					tween.tween_property(self, "current_lunge_speed", 0.0, lunge_duration).from(lunge_speed)
					
				var current_direction = global_position.direction_to(target_lunge_position).normalized()
				velocity = current_direction * current_lunge_speed
				move_and_slide()
				
				lunge_timer -= delta
				await get_tree().create_timer(0.1).timeout
				attack_area.set_deferred("monitoring", true)

				if !animated_sprite.is_playing():
					animated_sprite.play("attack")
				if lunge_timer < 1:
					attack_area.set_deferred("monitoring", false)
			else:
				velocity = Vector2.ZERO
				attack_area.set_deferred("monitoring", false)
				if animated_sprite.animation == "attack" and animated_sprite.is_playing():
					return
				else:
					state = "idle"
					animated_sprite.play("idle")
					attack_area.set_deferred("monitoring", false)

	if attack_timer > 0:
		attack_timer -= delta


	if state == "idle" and attack_timer <= 0:
		# If no offset has been set or the goblin has reached the target, choose a new offset
		if target_offset == Vector2.ZERO or global_position.distance_to(player.global_position + target_offset) < 10:
		# Generate a random offset within a 300-unit radius of the player
			var random_angle = randf() * TAU # Random angle in radians
			var random_distance = randf_range(0, 0) # Random distance within 150 units
			target_offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	
	# Recalculate the target position based on the player's current position and the stored offset
		var target_position = player.global_position + target_offset
	
	# Move towards the target position
		var direction = global_position.direction_to(target_position)
		velocity = direction * move_speed
		move_and_slide()
		animated_sprite.play("idle")
	
		if velocity.length() > 0:
			var target_rotation = direction.angle()
			rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

	# Collision handling during lunge attack
	if lunge_timer > 0 and attack_area.monitoring:
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("player") and health > 0:
				body.take_damage(0)
				hurt_player.pitch_scale = randf_range(0.7, 0.9)
				hurt_player.play()
				
