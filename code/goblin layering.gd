extends AnimatedSprite2D

@onready var player = get_node("/root/amorphous2/playerKnight")  # Adjust the path to your player node

func _process(_delta):
	#Update z_index based on distance from the player
	var distance_from_player = global_position.distance_to(player.global_position)
	z_index = -int(distance_from_player)  # Invert the distance for layering
