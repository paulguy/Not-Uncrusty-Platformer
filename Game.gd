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

@onready var CODES = {
	"THRUSSY": player,
	"TEXTJSON": player
}

var cur_code = ""

func _input(event):
	if event is InputEventKey and event.pressed:
		cur_code += String.chr(event.unicode).to_upper()
		var found = false
		for code in CODES.keys():
			if code.begins_with(cur_code):
				found = true
				break
		if found:
			if cur_code in CODES:
				CODES[cur_code].cheat(cur_code)
				cur_code = ""
		else:
			cur_code = ""
