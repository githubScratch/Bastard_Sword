extends Control

var score = 0
@onready var scoreLabel = $Score

func _ready() -> void:
	pass
	
func _process(_delta) -> void:
	pass

func _on_goblin_goblin_died() -> void:
	score += 1
	scoreLabel.text = "Kills : %d" %score
