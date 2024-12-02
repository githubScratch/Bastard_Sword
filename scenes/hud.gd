extends Control

@onready var score_label = $Score
@onready var high_score_label = $HighScore

var scale_factor = 1.0 # Tracks the cumulative scale factor
var is_animating = false # Tracks if an animation is currently running

func update_score(value: int, high_score: int) -> void:
	# Update the score text
	$Score.text = "Score: " + str(value)
	$HighScore.text = "High Score: " + str(high_score)
	# Increment the scale factor to stack the effect
	scale_factor += 0.1

	# If not animating, start the effect
	if not is_animating:
		_play_enlarge_effect()
		
# Inside HUD.gd
func update_high_score(value: int) -> void:
	$HighScore.text = "High Score: " + str(value)


func _play_enlarge_effect():
	is_animating = true

	# Calculate the enlarged scale based on the scale factor
	var original_scale = Vector2(1, 1)
	var enlarged_scale = original_scale * scale_factor

	# Create a tween
	var tween = create_tween()

	# Animate to the enlarged scale
	tween.tween_property(score_label, "scale", enlarged_scale, 0.1)

	# Animate back to the original scale
	tween.tween_property(score_label, "scale", original_scale, 0.2)

	# Reset the scale factor and animation flag after the animation completes
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished():
	scale_factor = 1.0 # Reset the scale factor to default
	is_animating = false
