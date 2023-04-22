extends Polygon2D

@onready var parent = get_parent()

var left_bottom
var right_bottom
var left_size
var right_size

# Called when the node enters the scene tree for the first time.
func _ready():
	if len(polygon) != 4:
		push_error("Background polygon without 4 sizes.")
	# find horizontal range
	var lowest = polygon[0].x
	var highest = polygon[0].x
	var left_top = polygon[0].y
	left_bottom = polygon[0].y
	var right_top = polygon[0].y
	right_bottom = polygon[0].y
	for corner in polygon:
		if corner.x < lowest:
			# check if values are close
			if absf(corner.x - lowest) < 1:
				# prefer an integer
				if round(corner.x) == corner.x:
					lowest = corner.x
			else:
				lowest = corner.x
				left_top = corner.y
				left_bottom = corner.y
		elif corner.x > highest:
			# check if values are close
			if absf(corner.x - highest) < 1:
				# prefer an integer
				if round(corner.x) == corner.x:
					highest = corner.x
			else:
				highest = corner.x
				right_top = corner.y
				right_bottom = corner.y
	# Fix any oddball values, flag bad values
	for corner in polygon:
		if absf(corner.x - lowest) < 1:
			corner.x = lowest
		elif absf(corner.x - highest) < 1:
			corner.x = highest
		else:
			push_error("Background polygon without straight edges.")
	# find the ranges of the left and right sides
	for corner in polygon:
		if corner.x == lowest:
			if corner.y < left_top:
				left_top = corner.y
			elif corner.y > left_bottom:
				left_bottom = corner.y
		elif corner.x == highest:
			if corner.y < right_top:
				right_top = corner.y
			elif corner.y > right_bottom:
				right_bottom = corner.y
	left_size = left_bottom - left_top
	right_size = right_bottom - right_top
	# rebuild the polygon
	polygon = PackedVector2Array([
		Vector2(lowest, left_top),
		Vector2(highest, right_top),
		Vector2(highest, right_bottom),
		Vector2(lowest, left_bottom)
	])
	uv = PackedVector2Array([
		Vector2(0, 0),
		Vector2(highest-lowest, right_top-left_top),
		Vector2(highest-lowest, right_bottom-left_top),
		Vector2(0, left_bottom-left_top)
	])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# get the position relative to the center and scale it
	var screen_center = get_viewport_transform().origin.y / get_screen_transform().get_scale().y - 150.0
	var center_dist_left = (screen_center + (parent.position.y + left_bottom)) / 150.0
	var center_dist_right = (screen_center + (parent.position.y + right_bottom)) / 150.0
	center_dist_left = clampf(center_dist_left, 0.0, 2.0)
	center_dist_right = clampf(center_dist_right, 0.0, 2.0)
	polygon[0].y = polygon[3].y + left_size * center_dist_left * -2.0
	polygon[1].y = polygon[2].y + right_size * center_dist_right * -2.0
