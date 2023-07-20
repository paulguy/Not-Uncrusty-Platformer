extends NinePatchRect

@onready var textbox = $"Dialog Box Text"
var font
var border_margin

func set_text(player : Player, jsonstr : String):
	# set some defaults
	var text = jsonstr
	var ratio = 1.0
	var width = -1.0

	var json = JSON.parse_string(jsonstr)
	var text_cache = player.get_cache()

	# if the string isn't json, treat it as just a string
	if json != null:
		text = json['text']
		if 'ratio' in json:
			ratio = json['ratio']
		if 'width' in json:
			width = json['width']
	# produce the key for caching purposes
	var key = [text, ratio]

	# don't show the process
	visible = false
	# get the maximum width of the string
	textbox.autowrap_mode = TextServer.AUTOWRAP_OFF
	textbox.fit_content = false
	textbox.text = text

	# if a width wasn't provided, see if it's cached
	if width <= 0.0:
		if key in text_cache:
			width = text_cache[key]

	# if a width still wasn't found in the cache, calculate it
	if width <= 0.0:
		var text_width = textbox.get_content_width()
		# set max width to prevent wrapping
		textbox.size.x = text_width
		# set wrapping mode to start 
		textbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox.fit_content = true
		# binary search for the most "square" ratio
		var low = 0.0
		var high = text_width
		# this feels fragile...
		while abs(low - high) > 1.0:
			textbox.size.x = low + ((high - low) / 2)
			if textbox.get_content_width() / textbox.get_content_height() < ratio:
				low = textbox.size.x
			else:
				high = textbox.size.x
		# save result
		text_cache[key] = textbox.size.x
	else:
		textbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox.fit_content = true
		textbox.size.x = width

	# set the box width around the border
	size = Vector2(textbox.get_content_width(), textbox.get_content_height()) + border_margin
	# make it visible again
	visible = true
	return size

func disappear():
	visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# get the fixed border size
	border_margin = Vector2(patch_margin_left + patch_margin_right,
							patch_margin_top + patch_margin_bottom)
	textbox.position = Vector2(patch_margin_left, patch_margin_top)
