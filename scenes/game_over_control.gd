extends Control

@export var fade_duration: float = 3.0  # Duration of fade in seconds
var fade_timer: float = 0.0  # Tracks elapsed time
var has_faded_in: bool = false  # Tracks if fade-in has occurred

func _ready():
	modulate.a = 0.0  # Start fully transparent
	visible = false
	
func fade_in():
	if has_faded_in:
		return  # Prevent multiple calls
	has_faded_in = true  # Mark as triggered
	fade_timer = 0.0
	set_process(true)
	await get_tree().create_timer(0.25).timeout
	visible = true

func _process(delta):
	if fade_timer < fade_duration:
		fade_timer += delta
		# Calculate alpha based on elapsed time
		modulate.a = clamp(fade_timer / fade_duration, 0.0, 1.0)
	else:
		set_process(false)
