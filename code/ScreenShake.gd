extends Node

var shake_duration: float = 0.5  # Total duration of the shake
var shake_magnitude: float = 5.0  # Initial magnitude of the shake
var shake_timer: float = 0.0
var original_position: Vector2

func _ready():
	original_position = get_tree().get_root().get_child(0).position  # Get the original position of the root node

func _process(delta: float) -> void:
	if shake_timer > 0:
		shake_timer -= delta
		
		# Calculate the amount to shake based on time left
		var shake_amount = shake_magnitude * (shake_timer / shake_duration) * Vector2(randf_range(-1, 1), randf_range(-1, 1))
		get_tree().get_root().get_child(0).position = original_position + shake_amount

		# Gradually reduce the shake magnitude over time for a smoother effect
		shake_magnitude = max(0, shake_magnitude - (shake_duration / 4.0))  # Adjust 20.0 to change the rate of decay

	else:
		get_tree().get_root().get_child(0).position = original_position  # Reset position

func shake(duration: float, magnitude: float) -> void:
	shake_duration = duration
	shake_magnitude = magnitude
	shake_timer = duration
