extends Node2D

const MAX_CURSOR_SPEED = 20.0
const WIN_CHANCE = 10
const ALMOST_WIN_CHANCE = 2
const LUIGI_CHANCE = 10
const LUIGI_POSITION = 10
const GUIGI_POSITION = 11
const UNSET_POSITION = 12
const PRIZES = [2, 5, 10, 20, 69, 420, 1337, 69420]
const SPACE_POSITION = 16
const DOLLAR_POSITION = 17
const FREE_POSITION = 18

@onready var overlay_gfx : Image = load("res://scratch-off-overlay.png").get_image()
@onready var cursorpos : Vector2 = get_viewport_rect().size / 2.0

var lastpos : Vector2 = Vector2.UP # negative would be invalid
var cur_image : Image
var cur_texture : ImageTexture
var scratch_area : bool = false
var number_spaces : Array
var prize_digits : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent() is Window:
		$"Test Camera".make_current()
	else:
		remove_child($"Test Camera")

	# gather display elements
	number_spaces = Array()
	number_spaces.resize(9)
	prize_digits = Array()
	prize_digits.resize(6)
	for child in get_children():
		var childname = child.name.split(" ")
		if childname[0] == "Number":
			number_spaces[int(childname[2])*3+int(childname[1])] = child
		elif childname[0] == "Prize":
			prize_digits[int(childname[1])] = child

func _input(event):
	if event is InputEventMouse:
		cursorpos = event.position - (get_viewport_transform().origin / get_viewport_transform().get_scale())

func put_number(x : int, y : int, num : int):
	var number = number_spaces[x*3+y]
	number.texture.region.position.x = number.texture.region.size.x * num

func get_number(x : int, y : int) -> int:
	var number = number_spaces[x*3+y]
	return number.texture.region.position.x / number.texture.region.size.x

func free_prize():
	var digit = prize_digits[5]
	digit.texture.region.position.x = digit.texture.region.size.x * SPACE_POSITION
	digit = prize_digits[4]
	digit.texture.region.position.x = digit.texture.region.size.x * FREE_POSITION
	digit = prize_digits[3]
	digit.texture.region.position.x = digit.texture.region.size.x * (FREE_POSITION + 1)
	digit = prize_digits[2]
	digit.texture.region.position.x = digit.texture.region.size.x * (FREE_POSITION + 2)
	digit = prize_digits[1]
	digit.texture.region.position.x = digit.texture.region.size.x * (FREE_POSITION + 3)
	digit = prize_digits[0]
	digit.texture.region.position.x = digit.texture.region.size.x * SPACE_POSITION

func generate_ticket():
	for number in number_spaces:
		number.texture.region.position.x = number.texture.region.size.x * UNSET_POSITION

	var winning = (randi_range(0, WIN_CHANCE) == 0)
	if winning:
		var direction = randi_range(0, 2)
		match direction:
			0:
				var row = randi_range(0, 2)
				put_number(0, row, 7)
				put_number(1, row, 7)
				put_number(2, row, 7)
			1:
				var column = randi_range(0, 2)
				put_number(column, 0, 7)
				put_number(column, 1, 7)
				put_number(column, 2, 7)
			2:
				var slant = (randi_range(0, 1) == 0)
				if slant:
					put_number(0, 0, 7)
					put_number(1, 1, 7)
					put_number(2, 2, 7)
				else:
					put_number(2, 0, 7)
					put_number(1, 1, 7)
					put_number(0, 2, 7)

		var whichguigi = randi_range(0, 5)
		for number in number_spaces:
			if number.texture.region.position.x / number.texture.region.size.x == UNSET_POSITION:
				whichguigi -= 1
				if whichguigi < 0:
					number.texture.region.position.x = number.texture.region.size.x * GUIGI_POSITION
					break

		var luigi = (randi_range(0, LUIGI_CHANCE) == 0)
		if luigi:
			var whichluigi = randi_range(0, 2)
			for number in number_spaces:
				if number.texture.region.position.x / number.texture.region.size.x == 7:
					whichluigi -= 1
					if whichluigi == 0:
						number.texture.region.position.x = number.texture.region.size.x * LUIGI_POSITION
						break
		
		for number in number_spaces:
			if number.texture.region.position.x / number.texture.region.size.x == UNSET_POSITION:
				number.texture.region.position.x = number.texture.region.size.x * randi_range(0, 9)
	else:
		for number in number_spaces:
			number.texture.region.position.x = number.texture.region.size.x * randi_range(0, 9)
		var almost_winning = (randi_range(0, ALMOST_WIN_CHANCE) == 0)
		if almost_winning:
			var startpos = randi_range(0, 1)
			var direction = randi_range(0, 2)
			match direction:
				0:
					var row = randi_range(0, 2)
					put_number(startpos+0, row, 7)
					put_number(startpos+1, row, 7)
				1:
					var column = randi_range(0, 2)
					put_number(column, startpos+0, 7)
					put_number(column, startpos+1, 7)
				2:
					var slant = (randi_range(0, 1) == 0)
					if slant:
						put_number(startpos+0, startpos+0, 7)
						put_number(startpos+1, startpos+1, 7)
					else:
						put_number(2-startpos, startpos+0, 7)
						put_number(1-startpos, startpos+1, 7)

		for digit in prize_digits:
			digit.texture.region.position.x = digit.texture.region.size.x * SPACE_POSITION

		var prize = PRIZES[randi_range(0, PRIZES.size()-1)]
		var prizedigit = 0
		var digit
		while prize > 0:
			digit = prize_digits[prizedigit]
			digit.texture.region.position.x = digit.texture.region.size.x * (prize % 10)
			prize /= 10
			prizedigit += 1
			assert(prizedigit != prize_digits.size(), "prize number too long!")
		digit = prize_digits[prizedigit]
		digit.texture.region.position.x = digit.texture.region.size.x * DOLLAR_POSITION

		# Scan for winning conditions
		for row in 3:
			if(get_number(0, row) == 7 and
			   get_number(1, row) == 7 and 
			   get_number(2, row) == 7):
				free_prize()
		for column in 3:
			if(get_number(column, 0) == 7 and
			   get_number(column, 1) == 7 and 
			   get_number(column, 2) == 7):
				free_prize()
		if(get_number(0, 0) == 7 and
		   get_number(1, 1) == 7 and 
		   get_number(2, 2) == 7):
			free_prize()
		if(get_number(2, 0) == 7 and
		   get_number(1, 1) == 7 and 
		   get_number(0, 2) == 7):
			free_prize()

func _process(delta):
	if $Overlay.texture == null:
		cur_image = overlay_gfx.duplicate()
		cur_texture = ImageTexture.create_from_image(cur_image)
		$Overlay.texture = cur_texture
		generate_ticket()
	elif scratch_area:
		var scratch_pos = $Coin.position - $"Scratch Area".position
		if lastpos != Vector2.UP:
			var steps = max(abs(scratch_pos.x - lastpos.x), abs(scratch_pos.y - lastpos.y))
			for i in steps:
				cur_image.fill_rect(Rect2i(lerp(lastpos.x, scratch_pos.x, steps/i),
										   lerp(lastpos.y, scratch_pos.y, steps/i), 4, 4),
									Color(0, 0, 0, 0))
			cur_texture.update(cur_image)
		lastpos = scratch_pos

	cursorpos += Vector2(Input.get_axis("right_analog_left", "right_analog_right"),
						 Input.get_axis("right_analog_up", "right_analog_down")) * MAX_CURSOR_SPEED
	$Coin.position = cursorpos

func _on_scratch_area_body_entered(body):
	body = body.get_parent()
	if body == $Coin:
		body.texture.region.position.x = body.texture.region.size.y
		scratch_area = true

func _on_scratch_area_body_exited(body):
	body = body.get_parent()
	if body == $Coin:
		body.texture.region.position.x = 0
		scratch_area = false

func _on_ticket_button_area_body_entered(body):
	body = body.get_parent()
	if body == $Coin:
		$Overlay.texture = null
