extends NinePatchRect

@onready var textbox = $"Dialog Box Text"
var font
var border_margin
var text_cache = Dictionary()

func set_text(text : String):
	# don't show the process
	visible = false
	# get the maximum width of the string
	textbox.autowrap_mode = TextServer.AUTOWRAP_OFF
	textbox.fit_content = false
	textbox.text = text
	# try to fetch result from cache
	if text in text_cache:
		textbox.size.x = text_cache[text]
		textbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox.fit_content = true
	else:
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
			if textbox.get_content_width() < textbox.get_content_height():
				low = textbox.size.x
			else:
				high = textbox.size.x
		# save result
		text_cache[text] = textbox.size.x
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
