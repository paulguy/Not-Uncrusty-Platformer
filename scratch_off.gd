extends Node2D
signal want_exit
signal new_ticket

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
var seed_digits : Array
var animating : bool = false
var rand_seed : int = 0

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
	seed_digits = Array()
	seed_digits.resize(16)
	for child in $Ticket.get_children():
		var childname = child.name.split(" ")
		if childname[0] == "Number":
			number_spaces[int(childname[2])*3+int(childname[1])] = child
		elif childname[0] == "Prize":
			prize_digits[int(childname[1])] = child
		elif childname[0] == "Seed":
			seed_digits[int(childname[1])] = child

func _input(event):
	if event is InputEventMouse:
		cursorpos = event.position - (get_viewport_rect().size / 2.0)

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

func set_seed():
	rand_seed = randi() | (randi() << 32)
	return rand_seed

func rand_int(low : int, high : int):
	var seedarr = rand_from_seed(rand_seed)
	rand_seed = seedarr[0]
	return (rand_seed % (high - low)) + low

func generate_ticket():
	var digit

	var rseed = set_seed()
	for number in 16:
		digit = seed_digits[number]
		digit.texture.region.position.x = digit.texture.region.size.x * (rseed & 0xF)
		rseed >>= 4

	for number in number_spaces:
		number.texture.region.position.x = number.texture.region.size.x * UNSET_POSITION

	var winning = (rand_int(0, WIN_CHANCE) == 0)
	if winning:
		var direction = rand_int(0, 2)
		match direction:
			0:
				var row = rand_int(0, 2)
				put_number(0, row, 7)
				put_number(1, row, 7)
				put_number(2, row, 7)
			1:
				var column = rand_int(0, 2)
				put_number(column, 0, 7)
				put_number(column, 1, 7)
				put_number(column, 2, 7)
			2:
				var slant = (rand_int(0, 1) == 0)
				if slant:
					put_number(0, 0, 7)
					put_number(1, 1, 7)
					put_number(2, 2, 7)
				else:
					put_number(2, 0, 7)
					put_number(1, 1, 7)
					put_number(0, 2, 7)

		var whichguigi = rand_int(0, 5)
		for number in number_spaces:
			if number.texture.region.position.x / number.texture.region.size.x == UNSET_POSITION:
				whichguigi -= 1
				if whichguigi < 0:
					number.texture.region.position.x = number.texture.region.size.x * GUIGI_POSITION
					break

		var luigi = (rand_int(0, LUIGI_CHANCE) == 0)
		if luigi:
			var whichluigi = rand_int(0, 2)
			for number in number_spaces:
				if number.texture.region.position.x / number.texture.region.size.x == 7:
					whichluigi -= 1
					if whichluigi == 0:
						number.texture.region.position.x = number.texture.region.size.x * LUIGI_POSITION
						break
		
		for number in number_spaces:
			if number.texture.region.position.x / number.texture.region.size.x == UNSET_POSITION:
				number.texture.region.position.x = number.texture.region.size.x * rand_int(0, 9)
	else:
		for number in number_spaces:
			number.texture.region.position.x = number.texture.region.size.x * rand_int(0, 9)
		var almost_winning = (rand_int(0, ALMOST_WIN_CHANCE) == 0)
		if almost_winning:
			var startpos = rand_int(0, 1)
			var direction = rand_int(0, 2)
			match direction:
				0:
					var row = rand_int(0, 2)
					put_number(startpos+0, row, 7)
					put_number(startpos+1, row, 7)
				1:
					var column = rand_int(0, 2)
					put_number(column, startpos+0, 7)
					put_number(column, startpos+1, 7)
				2:
					var slant = (rand_int(0, 1) == 0)
					if slant:
						put_number(startpos+0, startpos+0, 7)
						put_number(startpos+1, startpos+1, 7)
					else:
						put_number(2-startpos, startpos+0, 7)
						put_number(1-startpos, startpos+1, 7)

		for sprite in prize_digits:
			sprite.texture.region.position.x = sprite.texture.region.size.x * SPACE_POSITION

		var prize = PRIZES[rand_int(0, PRIZES.size()-1)]
		var prizedigit = 0
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

func _process(_delta):
	if $Ticket/Overlay.texture == null:
		cur_image = overlay_gfx.duplicate()
		cur_texture = ImageTexture.create_from_image(cur_image)
		$Ticket/Overlay.texture = cur_texture
		generate_ticket()
	elif not animating and scratch_area:
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
	if not animating and body == $Coin:
		animating = true
		$"New Ticket Animation".play("new ticket")

func _on_new_ticket_animation_animation_finished(anim_name):
	if anim_name == "new ticket":
		$Ticket/Overlay.texture = null
		$"New Ticket Animation".play("new ticket 2")
		emit_signal("new_ticket")
	elif anim_name == "new ticket 2":
		animating = false

func _on_exit_button_area_body_entered(body):
	body = body.get_parent()
	if not animating and body == $Coin:
		emit_signal("want_exit")
