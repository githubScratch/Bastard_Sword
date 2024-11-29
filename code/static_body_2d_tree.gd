extends StaticBody2D

@onready var player = get_node("/root/amorphous2/playerKnight")  # Adjust the path to your player node
var rotation_speed = 1.0  # Adjust this value for faster/slower rotation
var min_z = -100  # Minimum z_index value, adjust as needed
var max_z = 100  # Maximum z_index value, adjust as needed

func _process(delta):
	# Calculate the direction from the tree to the player
	var direction_to_player = (player.global_position - global_position).normalized()
	
	# Calculate the angle to face away from the player, correcting by 90 degrees
	var angle_away_from_player = direction_to_player.angle() + PI + (PI / 2)  # Add PI and 90 degrees

	# Interpolate the rotation smoothly
	rotation = lerp_angle(rotation, angle_away_from_player, rotation_speed * delta)
	
	# Update z_index based on distance from the player, clamped within min_z and max_z
	var distance_from_player = (player.global_position - global_position).length()
	if distance_from_player != null:
		z_index = -int(clamp(distance_from_player, min_z, max_z))
