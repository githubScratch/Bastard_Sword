extends AudioStreamPlayer2D

# Use @export for the next_song variable so it appears in the Inspector
#@export var next_song: AudioStream

#func _ready():
	# Connect the `finished` signal to the `_on_song_finished` function
	#connect("finished", Callable(self, "_on_song_finished"))

#func _on_song_finished():
	#if next_song:  # Check if a next song is assigned
		#stream = next_song  # Assign the next song to the stream
		#play()  # Play the new song
