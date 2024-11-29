extends Control

@onready var score_label = $Score	# Reference to the score Label node

func update_score(value: int) -> void:
	# Update the score text
	score_label.text = "Score: " + str(value)
	
	# Play the enlarging effect
	_play_enlarge_effect()

func _play_enlarge_effect():
	# Save the original and enlarged scales
	var original_scale = score_label.scale
	var enlarged_scale = original_scale * 1.1	# Enlarge by 50%

	# Create a tween
	var tween = create_tween()

	# Animate to the enlarged scale
	tween.tween_property(score_label, "scale", enlarged_scale, 0.1)


	# Animate back to the original scale after enlarging
	tween.tween_property(score_label, "scale", original_scale, 0.2)
