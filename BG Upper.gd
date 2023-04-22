extends Polygon2D

# Called when the node enters the scene tree for the first time.
func _ready():
	if len(polygon) != 4:
		push_error("Background polygon without 4 sizes.")
	# find horizontal range
	var lowest = polygon[0].x
	var highest = polygon[0].x
	var left_top = polygon[0].y
	var left_bottom = polygon[0].y
	var right_top = polygon[0].y
	var right_bottom = polygon[0].y
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
	vertex_colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 1.0)
	])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
