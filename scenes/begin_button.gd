extends Button

func _on_start_button_pressed():
	get_tree().paused = false
	# Optionally, change scenes or hide the startup screen
	queue_free()  # or `hide()` if you want to keep the screen in memory
	hide()
