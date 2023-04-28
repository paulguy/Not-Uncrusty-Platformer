class_name BG_Texture
extends Node2D

@onready var parent = get_parent()
@export var stretch_max : float = 2.0

var left_bottom = []
var right_bottom = []
var left_size = []
var right_size = []
var child_offset = []
var child_y_position = []
var child_y_size = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var count = get_child_count()
	left_bottom.resize(count)
	right_bottom.resize(count)
	left_size.resize(count)
	right_size.resize(count)
	child_offset.resize(count)
	child_y_position.resize(count)
	child_y_size.resize(count)
	var i = 0
	for p in get_children():
		if len(p.polygon) != 4:
			push_error("Background polygon without 4 sizes.")
		# make all polygon coords map-relative
		p.polygon[0] += p.position
		p.polygon[1] += p.position
		p.polygon[2] += p.position
		p.polygon[3] += p.position
		var parent_pos = p.position
		p.position = Vector2.ZERO
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
		var tex_width = highest-lowest
		var left_uv = fmod(lowest, p.texture.get_width())
		p.uv = PackedVector2Array([
			Vector2(left_uv, 0),
			Vector2(left_uv+tex_width, 0),
			Vector2(left_uv+tex_width, right_bottom[i]-right_top),
			Vector2(left_uv, left_bottom[i]-left_top)
		])
		if p.get_child_count() > 0:
			child_offset[i] = []
			child_offset[i].resize(p.get_child_count())
			child_y_position[i] = []
			child_y_position[i].resize(p.get_child_count())
			child_y_size[i] = []
			child_y_size[i].resize(p.get_child_count())
			var j = 0
			for pc in p.get_children():
				if pc is Sprite2D:
					var p_width = highest - lowest
					var pc_x_offset = pc.position.x + parent_pos.x - lowest
					pc.position += parent_pos
					pc.position -= pc.texture.get_size() * pc.scale / 2.0
					pc.centered = false
					pc.region_rect = Rect2(Vector2.ZERO, pc.texture.get_size())
					pc.region_enabled = true
					child_y_size[i][j] = pc.region_rect.size.y
					child_y_position[i][j] = pc.position.y
					child_offset[i][j] = Vector2.ZERO
					child_offset[i][j].x = pc_x_offset/p_width
					child_offset[i][j].y = left_bottom[i] + ((right_bottom[i]-left_bottom[i])*child_offset[i][j].x) - child_y_position[i][j] - (child_y_size[i][j] * pc.scale.y)
					child_y_position[i][j] += child_offset[i][j].y
				else:
					push_error("BG Texture child isn't a Sprite2D nor a Polygon2D.")
				j += 1
		i += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var screen_center = get_viewport_transform().origin.y / get_screen_transform().get_scale().y - 150.0
	var i = 0
	for p in get_children():
		# get the position relative to the center and scale it
		var center_dist_left = (screen_center + (parent.position.y + left_bottom[i])) / 150.0
		var center_dist_right = (screen_center + (parent.position.y + right_bottom[i])) / 150.0
		var j = 0
		for pc in p.get_children():
			var y_offset = child_offset[i][j].y * (center_dist_left + (center_dist_right-center_dist_left)) * child_offset[i][j].x / pc.scale.y * 2.0
			if y_offset < 0.0:
				pc.region_rect.size.y = child_y_size[i][j] + y_offset
			pc.position.y = child_y_position[i][j] - y_offset
			j += 1
		if stretch_max < 0.0:
			center_dist_left = clampf(center_dist_left, stretch_max, 0.0) * -2.0
			center_dist_right = clampf(center_dist_right, stretch_max, 0.0) * -2.0
		else:
			center_dist_left = clampf(center_dist_left, 0.0, stretch_max) * -2.0
			center_dist_right = clampf(center_dist_right, 0.0, stretch_max) * -2.0
		p.polygon[0].y = p.polygon[3].y + center_dist_left * left_size[i]
		p.polygon[1].y = p.polygon[2].y + center_dist_right * right_size[i]
		i += 1
