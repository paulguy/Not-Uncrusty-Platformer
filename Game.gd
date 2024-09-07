extends Node2D

@onready var player : Player = $"Player"
@onready var screen : Area2D = $"Screen Area"
@onready var maps_node : Node2D = $"Maps"
@onready var mobs_node : Node2D = $"Mobs"

# used as more of a set with some extended data
var areas : Dictionary = {}
var groups : Dictionary = {}
var player_offset : Vector2i = Vector2i.ZERO
var rect_size : Vector2i = Vector2i.ZERO
var active_areas : Dictionary = {}
var copies : Dictionary = {Vector2i(0, 0): [0, null]}

func adjust_player():
	# get the integer offset that everything should be adjusted to, then set the
	# player position to the fractional error to make sure the player starts as
	# near to the origin as possible without upsetting the value _too_ much
	var player_pos = Vector2i(player.position)
	player.position -= Vector2(player_pos)
	player_offset += player_pos

func adjust_player_and_maps():
	adjust_player()

	# adjust area positions
	for area in areas:
		var pos : Vector2 = areas[area].adjust(player_offset)
		mobs_node.get_node(NodePath(area.name)).position = pos

func add_mob(node : Node2D, mob : Node2D):
	node.add_child(mob)
	mob.activate()

func remove_mob(node : Node2D, mob : Node2D):
	mob.deactivate()
	node.remove_child(mob)

func find_copy_index(num : int, find_z_index : int) -> int:
	var found : int = -1

	var i : int = 0
	for node in maps_node.get_children():
		if node is BackBufferCopy and (found >= 0 or
									  find_z_index < 0 or
									  node.z_index == find_z_index):
			num -= 1
			if num == 0:
				if find_z_index < 0:
					return i
				if found >= 0:
					return found
				found = i
		i += 1

	# if one was found, but the end was reached, just return the end
	if found >= 0:
		return i

	return -1

func add_area_to_scene(area : AreaInfo):
	# add all the map groups
	var i : int = 0
	for group : Node2D in area.groups:
		if i == 0 and group.z_index == 0:
			# if it's the first group, just add it without a copy
			var copy = copies[Vector2i(0, 0)]
			maps_node.add_child(group)
			maps_node.move_child(group, copy[0])
			copy[0] += 1
		else:
			var criteria : Vector2i = Vector2i(i, group.z_index)
			if criteria not in copies:
				# if this group doesn't exist, create it
				var new_copy : BackBufferCopy = BackBufferCopy.new()
				new_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
				new_copy.z_index = group.z_index
				maps_node.add_child(new_copy)
				maps_node.add_child(group)
				copies[criteria] = [1, new_copy]
			else:
				# if it does exist, add to the end of it
				# get the position of the end of this section
				var pos = copies[criteria][1].get_index() + copies[criteria][0]
				maps_node.add_child(group)
				maps_node.move_child(group, pos)
				copies[criteria][0] += 1
		i += 1

	# add the mobs too
	var area_mobs_node = mobs_node.get_node(NodePath(area.name))
	for mob in area.mobs:
		if not mob.is_inside_tree():
			add_mob(area_mobs_node, mob)
	# mark it active
	active_areas[area] = null

func remove_area_from_scene(area : AreaInfo):
	# remove the mobs
	var area_mobs_node : Node2D = mobs_node.get_node(NodePath(area.name))
	for mob in area.mobs:
		# Only remove mobs which are in place and off screen
		if mob.get_parent() == area_mobs_node and mob not in screen.get_overlapping_bodies():
			remove_mob(area_mobs_node, mob)

	# and the rest of the map groups
	var i : int = 0
	for group : Node2D in area.groups:
		maps_node.remove_child(group)
		var criteria : Vector2i = Vector2i(i, group.z_index)
		copies[criteria][0] -= 1
		if copies[criteria][0] == 0:
			if i == 0 and group.z_index == 0:
				continue
			maps_node.remove_child(copies[criteria][1])
			copies.erase(criteria)
		i += 1

	# mark it inactive
	active_areas.erase(area)

func scan_area() -> Array[AreaInfo]:
	# probably a crummy way to do this but there'll never be a huge
	# amount of these, in the order of 10s.

	var found : Array[AreaInfo] = []
	# get the screen rect and see which is colliding
	var screen_rect = Rect2i(Vector2i(player.position)
							 - rect_size / 2,
							 rect_size)
	for area in areas:
		# if the map should be shown, add it to the scene
		if areas[area].area_intersects(screen_rect):
			found.append(areas[area])

	return found

func update_active_maps():
	var visible_areas : Array[AreaInfo] = scan_area()

	for area in active_areas:
		if area not in visible_areas:
			remove_area_from_scene(area)

	var added : bool = false
	for area in visible_areas:
		if area not in active_areas:
			add_area_to_scene(area)
			added = true

	# clean up mobs which were previously visible from other maps but which have
	# gone off screen
	for area in areas:
		if areas[area] in visible_areas:
			continue
		var area_mobs_node = mobs_node.get_node(NodePath(area.name))
		for mob in area_mobs_node.get_children():
			if mob not in screen.get_overlapping_bodies():
				remove_mob(area_mobs_node, mob)

	if added:
		# readjust everything with the player about the origin
		adjust_player_and_maps()

func _ready():
	# remove the player just to get it out of the way and
	# prevent things triggering
	remove_child(player)

	rect_size = screen.get_node("Screen Shape").shape.size

	var maps : Array[Node] = maps_node.get_children()

	# process all maps in to areainfos
	for map in maps:
		areas[map] = AreaInfo.new(map)
		# add the mobs nodes 
		mobs_node.add_child(areas[map].new_mobs_node)

	# remove them now
	for map in maps:
		maps_node.remove_child(map)

	# Set everything up for the first time
	adjust_player_and_maps()
	update_active_maps()

	# put the player in place
	add_child(player)

# from <https://stackoverflow.com/questions/77586404/take-screenshots-in-godot-4-1-stable>
func take_screenshot() -> void: # Function for taking screenshots and saving them
	var date = Time.get_date_string_from_system().replace(".","_") 
	var time :String = Time.get_time_string_from_system().replace(":","")
	var screenshot_path = "user://" + "screenshot_" + date+ "_" + time + ".jpg" # the path for our screenshot.
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.resize(image.get_width() * 2,
				 image.get_height() * 2,
				 Image.Interpolation.INTERPOLATE_NEAREST)
	image.save_png(screenshot_path)

func _process(_delta : float):
	if Input.is_action_just_pressed("screenshot"):
		take_screenshot()

	update_active_maps()
	screen.position = player.position
