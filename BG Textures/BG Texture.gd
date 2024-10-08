class_name BG_Texture
extends Node2D

@onready var parent = get_parent()
@export var stretch_max : float = 2.0
@export var y_edge_overlap : float = 0.0

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
			Vector2(left_uv, p.uv[0].y),
			Vector2(left_uv+tex_width, p.uv[1].y),
			Vector2(left_uv+tex_width, p.uv[2].y),
			Vector2(left_uv, p.uv[3].y)
		])
		if p.get_child_count() > 0:
			var p_top = min(left_top, right_top)
			var p_bottom = max(left_bottom[i], right_bottom[i])
			var p_size = Vector2(highest - lowest, p_bottom - p_top)
			child_offset[i] = []
			child_offset[i].resize(p.get_child_count())
			child_y_position[i] = []
			child_y_position[i].resize(p.get_child_count())
			child_y_size[i] = []
			child_y_size[i].resize(p.get_child_count())
			var j = 0
			for pc in p.get_children():
				if pc is Sprite2D:
					var pc_bottom_center = Vector2(pc.position.x, pc.position.y - ((p_top - parent_pos.y) * pc.scale.y) + (pc.texture.get_height() * pc.scale.y * 0.5))
					var pc_x_offset = pc_bottom_center.x/p_size.x
					var pc_y_offset = ((right_bottom[i]-left_bottom[i])*pc_x_offset)
					var pc_y_pos = p_bottom - pc_y_offset
					child_offset[i][j] = Vector2(pc_x_offset, p_size.y - pc_y_offset - pc_bottom_center.y)
					pc.offset = -pc.texture.get_size() * Vector2(0.5, 1.0) + Vector2(0.0, y_edge_overlap)
					pc.centered = false
					pc.region_rect = Rect2(Vector2.ZERO, pc.texture.get_size())
					pc.region_enabled = true
					child_y_size[i][j] = pc.region_rect.size.y
					child_y_position[i][j] = pc_y_pos
					pc.position.x = parent_pos.x + pc_bottom_center.x
					pc.y_sort_enabled = true
					j += 1
		i += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var vport = get_viewport_transform()
	var screen_center = (vport.origin.y / vport.get_scale().y) - (get_viewport_rect().size.y / 2.0)
	var i = 0
	for p in get_children():
		# get the position relative to the center and scale it
		var center_dist_left = (screen_center + (parent.position.y + left_bottom[i])) / 150.0
		var center_dist_right = (screen_center + (parent.position.y + right_bottom[i])) / 150.0
		var center_dist_left_pc = center_dist_left * -2.0
		var center_dist_right_pc = center_dist_right * -2.0
		if stretch_max < 0.0:
			center_dist_left_pc = max(center_dist_left_pc, stretch_max)
			center_dist_right_pc = max(center_dist_right_pc, stretch_max)
			center_dist_left = clampf(center_dist_left, stretch_max, 0.0) * -2.0
			center_dist_right = clampf(center_dist_right, stretch_max, 0.0) * -2.0
		else:
			center_dist_left_pc = min(center_dist_left_pc, stretch_max)
			center_dist_right_pc = min(center_dist_right_pc, stretch_max)
			center_dist_left = clampf(center_dist_left, 0.0, stretch_max) * -2.0
			center_dist_right = clampf(center_dist_right, 0.0, stretch_max) * -2.0
		p.polygon[0].y = p.polygon[3].y + center_dist_left * left_size[i]
		p.polygon[1].y = p.polygon[2].y + center_dist_right * right_size[i]
		var j = 0
		for pc in p.get_children():
			if pc is Sprite2D:
				var y_offset = center_dist_left_pc + ((center_dist_right_pc-center_dist_left_pc) * child_offset[i][j].x)
				pc.position.y = child_y_position[i][j] + (child_offset[i][j].y * y_offset)
				# this stopped working with the dynamic scene loading so just disable it, it's unnecessary
				#if pc.position.y + y_edge_overlap > child_y_position[i][j]:
				#	pc.region_rect.size.y = max((child_y_size[i][j] * pc.scale.y) - (pc.position.y + y_edge_overlap - child_y_position[i][j]), 0.0)
				j += 1
		i += 1
