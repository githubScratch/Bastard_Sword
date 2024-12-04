extends RigidBody2D

class_name TNT  # This makes the class globally accessible

# Set constants for the explosion delay, movement distance, speed, rotation speed, scaling speed, damage, and knockback distance
@export var explosion_delay := 3.5
@export var max_travel_distance := 300.0   # Maximum distance the TNT will travel
@export var move_speed := 200.0            # Speed at which the TNT moves toward the player
@export var rotation_speed := 8.0          # Rotation speed in degrees per second
@export var pulse_speed := 1.0             # Speed of the pulsing effect
@export var explosion_damage := 50         # Damage dealt by the explosion
@export var knockback_distance := 250.0    # Knockback distance for affected units
@export var knockback_duration := 0.3      # Duration of knockback effect
@onready var fuse = $fuse  # Reference to the AudioStreamPlayer node
@onready var boom = $boom  # Reference to the AudioStreamPlayer node
@onready var crosshairs: PointLight2D = %crosshairs

# References to nodes
@onready var animated_sprite = $AnimatedSprite2D
@onready var zone_light = $ZoneLight       # Reference to the PointLight2D node
@onready var explosion_area = $ExplosionArea2D  # Area2D node for detecting units in explosion radius

# Store a reference to the player node and the direction to move in
var player: Node
var target_position: Vector2
var is_moving = true
var pulse_direction = 1.0  # Controls whether the sprite is scaling up or down
var bashback_force = 450.0
var is_bashed = false

func _ready():
	explosion_area.body_entered.connect(_on_ExplosionArea2D_body_entered)
	animated_sprite.play("thrown")
	zone_light.visible = true  # Ensure the light is off initially
	explosion_area.monitoring = false  # Disable the explosion area until ready to explode
	fuse.pitch_scale = randf_range(0.9, 1.1)
	fuse.play()  # Play the sound effect
	crosshairs.enabled = false
	# Find the player in the scene (assuming the player is a Node2D)
	player = get_tree().get_root().get_node("amorphous2/playerKnight") 

	if player:
		# Calculate the distance and direction to the player
		var direction = (player.global_position - global_position).normalized()
		var distance_to_player = global_position.distance_to(player.global_position)
		
		# Set the target position to a maximum of max_travel_distance
		var travel_distance = min(distance_to_player, max_travel_distance)
		target_position = global_position + direction * travel_distance
		
		# Start the explosion timer
		await get_tree().create_timer(explosion_delay).timeout
		
		# Stop movement and trigger the explosion
		is_moving = false
		explode()

# Move smoothly toward the target position, apply rotation, and scale effect
func _process(delta):
	if is_moving and global_position.distance_to(target_position) > 1.0:
		# Move toward the target position at the defined speed
		var move_step = (target_position - global_position).normalized() * move_speed * delta
		global_position += move_step
		
		# Rotate the TNT while moving
		rotation += rotation_speed * delta
		
		# Apply a pulsing scale effect between x1 and x2
		animated_sprite.scale += Vector2(pulse_speed * pulse_direction * delta, pulse_speed * pulse_direction * delta)
		
		# Reverse scaling direction if limits are reached
		if animated_sprite.scale.x >= 3.0:
			pulse_direction = -2.0  # Scale back down
		elif animated_sprite.scale.x <= 2.0:
			pulse_direction = 2.0  # Scale back up
		
		# Stop moving if close to the target position
		if global_position.distance_to(target_position) <= move_step.length() or is_bashed:
			global_position = target_position
			is_moving = false
			crosshairs.enabled = true
	else:
		animated_sprite.scale += Vector2(pulse_speed * pulse_direction * delta, pulse_speed * pulse_direction * delta)
		if animated_sprite.scale.x > 2.5:
				pulse_direction = -2.0  # Scale back down
		if animated_sprite.scale.x <= 2.5:
				pulse_direction = 0  # Scale back down

# Function to play explosion animation, activate light, and apply explosion effects
func explode():
	zone_light.visible = true  # Activate the light when movement stops
	animated_sprite.play("boom")
	boom.pitch_scale = randf_range(0.9, 1.1)
	boom.play()  # Play the sound effect
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 40.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	explosion_area.monitoring = true  # Enable the explosion area for detecting overlaps

	# Wait a short delay for animation and knockback to complete before cleaning up
	await get_tree().create_timer(0.4).timeout
	queue_free()

# Function to apply damage and knockback to any unit in the explosion area
func _on_ExplosionArea2D_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(explosion_damage)

	# Apply knockback force over the specified duration
	var knockback_vector = (body.global_position - global_position).normalized() * knockback_distance
	var target_position = body.global_position + knockback_vector
	
	# Create the tween using the `create_tween()` method
	var tween = body.create_tween()
	tween.tween_property(body, "global_position", target_position, knockback_duration)

func take_bash(_amount):
	is_bashed = true
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 4.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	# Calculate the knockback direction
	var knockback_direction = global_position.direction_to(get_node("/root/amorphous2/playerKnight").global_position) * -bashback_force
	# Apply impulse for the knockback effect
	apply_impulse(Vector2.ZERO, knockback_direction)
