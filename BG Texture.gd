class_name BG_Texture
extends Node2D

@onready var parent = get_parent()
@export var stretch_min : float = 0.0
@export var stretch_max : float = 2.0

var left_bottom = []
var right_bottom = []
var left_size = []
var right_size = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var count = get_child_count()
	left_bottom.resize(count)
	right_bottom.resize(count)
	left_size.resize(count)
	right_size.resize(count)
	var i = 0
	for p in get_children():
		if len(p.polygon) != 4:
			push_error("Background polygon without 4 sizes.")
		# find horizontal range
		var lowest = p.polygon[0].x
		var highest = p.polygon[0].x
		var left_top = p.polygon[0].y
		left_bottom[i] = p.polygon[0].y
		var right_top = p.polygon[0].y
		right_bottom[i] = p.polygon[0].y
		for corner in p.polygon:
			if corner.x < lowest:
				# check if values are close
				if absf(corner.x - lowest) < 1:
					# prefer an integer
					if round(corner.x) == corner.x:
						lowest = corner.x
				else:
					lowest = corner.x
					left_top = corner.y
					left_bottom[i] = corner.y
			elif corner.x > highest:
				# check if values are close
				if absf(corner.x - highest) < 1:
					# prefer an integer
					if round(corner.x) == corner.x:
						highest = corner.x
				else:
					highest = corner.x
					right_top = corner.y
					right_bottom[i] = corner.y
		# Fix any oddball values, flag bad values
		for corner in p.polygon:
			if absf(corner.x - lowest) < 1:
				corner.x = lowest
			elif absf(corner.x - highest) < 1:
				corner.x = highest
			else:
				push_error("Background polygon without straight edges.")
		# find the ranges of the left and right sides
		for corner in p.polygon:
			if corner.x == lowest:
				if corner.y < left_top:
					left_top = corner.y
				elif corner.y > left_bottom[i]:
					left_bottom[i] = corner.y
			elif corner.x == highest:
				if corner.y < right_top:
					right_top = corner.y
				elif corner.y > right_bottom[i]:
					right_bottom[i] = corner.y
		left_size[i] = left_bottom[i] - left_top
		right_size[i] = right_bottom[i] - right_top
		# rebuild the polygon
		p.polygon = PackedVector2Array([
			Vector2(lowest, left_top),
			Vector2(highest, right_top),
			Vector2(highest, right_bottom[i]),
			Vector2(lowest, left_bottom[i])
		])
		p.uv = PackedVector2Array([
			Vector2(lowest, 0),
			Vector2(highest, 0),
			Vector2(highest, right_bottom[i]-right_top),
			Vector2(lowest, left_bottom[i]-left_top)
		])
		i += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var screen_center = get_viewport_transform().origin.y / get_screen_transform().get_scale().y - 150.0
	var i = 0
	for p in get_children():
		# get the position relative to the center and scale it
		var center_dist_left = (screen_center + (parent.position.y + left_bottom[i])) / 150.0
		var center_dist_right = (screen_center + (parent.position.y + right_bottom[i])) / 150.0
		center_dist_left = clampf(center_dist_left, stretch_min, stretch_max)
		center_dist_right = clampf(center_dist_right, stretch_min, stretch_max)
		p.polygon[0].y = p.polygon[3].y + left_size[i] * center_dist_left * -2.0
		p.polygon[1].y = p.polygon[2].y + right_size[i] * center_dist_right * -2.0
		i += 1
