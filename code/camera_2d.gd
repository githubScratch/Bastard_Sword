extends Camera2D

@export var follow_speed = 3.0  # Speed at which the camera follows the mouse
@export var max_offset_distance = 270.0  # Maximum distance the camera can offset from the player
@onready var player = get_parent().get_node("playerKnight")  # Adjust the path if necessary
# Zoom range
const ZOOM_MIN = 1.0
const ZOOM_MAX = 2.0
var zoom_level := 1.0

func _process(delta):
	
	if player:  # Check if the player node is valid
		# Get the mouse position in the world
		var mouse_position = get_global_mouse_position()
		
		# Get the player's position
		var player_position = player.global_position

		# Calculate the offset direction and distance
		var offset_direction = (mouse_position - player_position).normalized()
		var offset_distance = (mouse_position - player_position).length()

		# Clamp the offset distance to the maximum allowed distance
		offset_distance = clamp(offset_distance, 0, max_offset_distance)

		# Determine the target position for the camera
		var target_position = player_position + offset_direction * offset_distance

		# Interpolate the camera position towards the target position
		position = position.lerp(target_position, follow_speed * delta)

	zoom = Vector2(zoom_level, zoom_level) # Initialize zoom level

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clamp(zoom_level - 0.1, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clamp(zoom_level + 0.1, ZOOM_MIN, ZOOM_MAX)
		
		# Apply the zoom
		zoom = Vector2(zoom_level, zoom_level)
