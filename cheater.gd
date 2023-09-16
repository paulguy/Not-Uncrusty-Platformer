extends Node

var cur_code = ""
var codes = Dictionary()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func key_pressed(char : String):
	cur_code += char
	var found = false
	for code in codes.keys():
		if code.begins_with(cur_code):
			found = true
			break
	if found:
		if cur_code in codes:
			codes[cur_code].cheat(cur_code)
			cur_code = ""
	else:
			cur_code = ""

func register(code : String, thing : Node):
	if code in codes:
		print_debug("Got duplicate cheat code {0} from node {1}!".format([code, thing]))
	else:
		codes[code] = thing

func unregister(code : String):
	if code in codes:
		codes.erase(code)
