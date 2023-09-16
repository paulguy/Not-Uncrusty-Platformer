extends Node2D

const TARGET_WIDTH = 400.0
const TARGET_HEIGHT = 300.0
const ASPECT_RATIO = TARGET_WIDTH / TARGET_HEIGHT
const RESETTLE_TIME = 0.5

@onready var player = self.get_node("Player")
@onready var camera = self.get_node("Player/Player Camera")
@onready var area = self.get_node("Screen Area")
var lastSize = Vector2.ZERO
var lastTime = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	lastSize = get_viewport_rect().size

func pause(paused : bool):
	if paused:
		player.process_mode = PROCESS_MODE_DISABLED
	else:
		player.process_mode = PROCESS_MODE_INHERIT

	area.pause_mobs(paused)

# no idea how to get text input events to a singleton
func _input(event):
	if event is InputEventKey and event.pressed:
		Cheater.key_pressed(String.chr(event.unicode).to_upper())
