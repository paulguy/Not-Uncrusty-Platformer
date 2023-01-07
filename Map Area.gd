extends Area2D

var area = null
var game = null
var screen = null

func _ready():
	area = self.get_parent()
	game = self.get_node("../..")
	screen = game.get_node("Screen Area")

func _on_body_entered(body):
	if body == screen:
		game.screen_entered_map(area)

func _on_body_exited(body):
	if body == screen:
		game.screen_left_map(area)
