extends ColorRect

var camera : Camera2D  # Declare a variable to store the reference

func _ready():
	# Find the Camera2D node in the scene tree
	camera = get_tree().current_scene.get_node("Camera2D")
	if camera == null:
		print("Camera2D not found!")  # Print an error message if the camera is not found

func _process(_delta):
	if camera:
		# Set the position of the ColorRect to the camera's position
		position = camera.position
