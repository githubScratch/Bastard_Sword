extends AnimatedSprite2D

@onready var animated_sprite = %AnimatedSprite2D  # Ensure this path is correct and the node exists
@onready var player = get_node("/root/amorphous2/playerKnight")  # Adjust the path to your player node
var rotation_speed = 5.0  # Adjust this value for faster/slower rotation

func _ready():
	# Play the default animation when the node is ready
	animated_sprite.play("default")  # # Ensure "default" is the correct animation name

func _process(delta):
	# Calculate the direction from the tree to the player
	var direction_to_player = (player.global_position - global_position).normalized()
	
	# Calculate the angle to face away from the player, correcting by 90 degrees
	var angle_away_from_player = direction_to_player.angle() + PI + (PI / 2)  # Add PI and 90 degrees

	# Interpolate the rotation smoothly
	rotation = lerp_angle(rotation, angle_away_from_player, rotation_speed * delta)
	
	# Update z_index based on distance from the player
	var distance_from_player = global_position.distance_to(player.global_position)
	z_index = -int(distance_from_player)  # Invert the distance for layering
