extends Timer

var game_time_elapsed: float = 0.0

func _ready():
	start()  # Starts the timer

func _on_timeout():
	game_time_elapsed += wait_time  # Increment elapsed time
