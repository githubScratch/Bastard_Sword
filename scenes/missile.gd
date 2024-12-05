extends CharacterBody2D

# Missile properties (adding health to existing properties)
@export var speed: float = 300.0
@export var acceleration: float = 250.0
@export var turn_rate: float = 2.0
@export var tracking_time: float = 3.0
@export var detection_range: float = 800.0
@export var lifetime: float = 5.0
@export var max_health: float = 100.0  # New: Maximum health value

# Node references (unchanged)
@onready var player = get_node("/root/amorphous2/playerKnight")
@onready var lifetime_timer = Timer.new()
@onready var animated_sprite = $AnimatedSprite2D

# Internal variables (adding health to existing variables)
var current_speed: float = 0.0
var elapsed_time: float = 0.0
var is_tracking: bool = true
var is_returning: bool = false
var current_direction: Vector2 = Vector2.ZERO
var current_health: float  # New: Current health tracker

@export var explosion_damage := 50
@export var knockback_distance := -250.0
@export var knockback_duration := 0.5
@onready var boombox_area = $boombox
var bashback_force = 450.0
var is_bashed = false
var is_exploding: bool = false
var affected_units = [] 

func _ready():
	# Initialize health
	current_health = max_health
	
	# Rest of the original _ready code
	add_child(lifetime_timer)
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(explode)
	lifetime_timer.start()
	
	boombox_area.monitoring = false
	
	if player and player.global_position.distance_to(global_position) <= detection_range:
		current_direction = (player.global_position - global_position).normalized()
	else:
		current_direction = Vector2.RIGHT.rotated(rotation)
		is_tracking = false

# New function to handle taking damage
func take_damage(amount: float) -> void:
	current_health -= amount
	if not is_exploding:
		animated_sprite.play("deflect")
	start_flash_effect()  # Call the flash effect coroutine
	if current_health < max_health:  # If health drops below maximum
		# Stop tracking and set short lifetime
		is_tracking = false
		lifetime_timer.stop()  # Stop the existing timer
		lifetime_timer.wait_time = 0.45  # Set new short lifetime
		lifetime_timer.start()  # Start the new timer
		
		# Send missile flying away from player
		if player:
			var away_direction = (global_position - player.global_position).normalized()
			current_direction = away_direction
			current_speed = speed * 4.5  # Increase speed for dramatic effect
			
func start_flash_effect():
	# Start the flash effect
	Engine.time_scale = 0.6  # Set time scale to 0.1 for slow motion
	animated_sprite.modulate = Color(0, 0, 1, 0.35)  # Red with 50% transparency
	await get_tree().create_timer(0.1).timeout  # Wait for a short duration
	animated_sprite.modulate = Color(1, 1, 1, 1)  # Red with 50% transparency
	Engine.time_scale = 1
	
func _physics_process(delta):
	if is_exploding:  # Skip all movement processing if exploding
		return
	# Only track if health is at maximum
	if is_tracking and current_health >= max_health:
		animated_sprite.play("seeking")
		elapsed_time += delta
		
		if elapsed_time >= tracking_time:
			is_tracking = false
		
		if player:
			var to_player = player.global_position - global_position
			var distance_to_player = to_player.length()
			
			if distance_to_player <= detection_range:
				var desired_direction = to_player.normalized()
				var angle_to_target = current_direction.angle_to(desired_direction)
				var turn_amount = sign(angle_to_target) * min(abs(angle_to_target), turn_rate * delta)
				current_direction = current_direction.rotated(turn_amount)
	if current_health < max_health:
		is_tracking = false
		is_returning = true
		animated_sprite.play("returning")
	current_speed = move_toward(current_speed, speed, acceleration * delta)
	velocity = current_direction * current_speed
	
	move_and_slide()
	rotation = current_direction.angle()

# Modified take_bash to use the new damage system
func take_bash(amount):
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 4.0)
	#animated_sprite.play("idle")
	#take_damage(amount)  # Add damage when bashed
	velocity = (global_position.direction_to(player.global_position) * -bashback_force)



# Rest of the functions remain unchanged
func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		explode()
	elif body.is_in_group("trees"):
		explode()

func _on_boombox_body_entered(body):
	if body in affected_units:  # Skip if already affected
		return
		
	affected_units.append(body)  # Add to affected units list
	
	if body.has_method("take_damage"):
		body.take_damage(explosion_damage)
	
	# Apply knockback force
	var knockback_vector = (body.global_position - global_position).normalized() * knockback_distance
	var target_position = body.global_position + knockback_vector
	
	var tween = body.create_tween()
	tween.tween_property(body, "global_position", target_position, knockback_duration)

# Modify explode function to clear the list when done
func explode():
	is_exploding = true
	current_speed = 0
	velocity = Vector2.ZERO
	var screen_shake = get_node("/root/amorphous2/ScreenShake")
	screen_shake.shake(0.5, 10.0)  # Screenshake for 0.5 seconds with a magnitude of 10
	boombox_area.monitoring = true
	if is_returning:
		animated_sprite.play("detonate_b")
	else:
		animated_sprite.play("detonate_p")
	animated_sprite.scale = Vector2(3,3)
	await get_tree().create_timer(0.10).timeout
	boombox_area.monitoring = false
	await get_tree().create_timer(1.0).timeout
	affected_units.clear()  # Clear the list after explosion is done
	queue_free()
