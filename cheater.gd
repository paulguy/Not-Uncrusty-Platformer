extends Node

var cur_code = ""
var codes = Dictionary()
var signals = Dictionary()

func _input(event):
	if event is InputEventKey and event.pressed:
		cur_code += String.chr(event.unicode).to_upper()
		var found = false
		for code in codes.keys():
			if code.begins_with(cur_code):
				found = true
				break
		if found:
			if cur_code in codes:
				for sig in codes[cur_code]:
					sig.emit(cur_code)
				cur_code = ""
		else:
				cur_code = ""

func register(code : String, thing : Node):
	var sig
	if thing in signals:
		sig = signals[thing]
	else:
		thing.add_user_signal("cheat", [{"name": "code", "type": TYPE_STRING}])
		sig = Signal(thing, "cheat")
		sig.connect(thing.cheat)
		signals[thing] = sig

	if code in codes:
		codes[code].appemd(sig)
	else:
		codes[code] = [sig]

func unregister(code : String):
	if code in codes:
		codes.erase(code)
