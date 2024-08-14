extends Node2D

@onready var player : Player = $"Player"
@onready var area : Area2D = $"Screen Area"

# used as more of a set with some extended data
var maps : Dictionary = {}
var mobs : Dictionary = {}
var player_offset : Vector2i = Vector2i.ZERO
var rect_size : Vector2i = Vector2i.ZERO
var to_add : Array = []
var to_remove : Array = []

func adjust_player():
	# get the integer offset that everything should be adjusted to, then set the
	# player position to the fractional error to make sure the player starts as
	# near to the origin as possible without upsetting the value _too_ much
	var player_pos = Vector2i(player.position)
	player.position -= Vector2(player_pos)
	player_offset += player_pos

func adjust_player_and_maps():
	adjust_player()

	# adjust active map positions
	for map in $'Maps'.get_children():
		map.position = Vector2(maps[map].pos - player_offset)
		# update the mobs node too
		$'Mobs'.get_node(NodePath(map.name)).position = map.position

	# adjust area positions
	for map in maps.keys():
		maps[map].adjust(player_offset)

func add_mob(mobs_node : Node2D, mob : Node2D):
	mob.activate()
	mobs_node.add_child(mob)

func remove_mob(mobs_node : Node2D, mob : Node2D):
	mobs_node.remove_child(mob)
	mob.deactivate()

func add_map_to_scene(map : Node2D):
	$'Maps'.add_child(map)
	# add the mobs too
	var mobs_node = $'Mobs'.get_node(NodePath(map.name))
	for mob in mobs[map]:
		if not mob.is_inside_tree():
			add_mob(mobs_node, mob)

func remove_map_from_scene(map : Node2D):
	$'Maps'.remove_child(map)
	# remove the mobs too
	var mobs_node = $'Mobs'.get_node(NodePath(map.name))
	for mob in mobs[map]:
		# Only remove mobs which are off screen
		if mob not in area.get_overlapping_bodies():
			remove_mob(mobs_node, mob)

func scan_area() -> Array:
	# probably a crummy way to do this but there'll never be a huge
	# amount of these, in the order of 10s.

	var found = []
	# get the screen rect and see which is colliding
	var screen_rect = Rect2i(Vector2i(player.position)
							 - rect_size / 2,
							 rect_size)
	for map in maps.keys():
		# if the map should be shown, add it to the scene
		if maps[map].area_intersects(screen_rect):
			found.append(map)

	return found

func update_active_maps():
	var visible_maps = scan_area()
	var active_maps = $'Maps'.get_children()

	for map in active_maps:
		if map not in visible_maps:
			remove_map_from_scene(map)

	var added : bool = false
	for map in visible_maps:
		if map not in active_maps:
			add_map_to_scene(map)
			added = true

	# clean up mobs which were previously visible from other maps but which have
	# gone off screen
	for map in maps:
		if map in visible_maps:
			continue
		var mobs_node = $'Mobs'.get_node(NodePath(map.name))
		for mob in mobs_node.get_children():
			if mob not in area.get_overlapping_bodies():
				remove_mob(mobs_node, mob)

	if added:
		# readjust everything with the player about the origin
		adjust_player_and_maps()

func _ready():
	# remove the player just to get it out of the way and
	# prevent things triggering
	remove_child(player)

	rect_size = area.get_node("Screen Shape").shape.size
	# don't need it
	#remove_child(area)

	var shape : CollisionShape2D
	# gather all the maps and map areas and mobs
	var i = 0
	for map in $'Maps'.get_children():
		var map_area : Area2D = map.get_node("Map Area")
		# won't need them
		map.remove_child(map_area)
		shape = map_area.get_node("Map Shape")
		# get the rectangles of the areas
		# Add up the position of the map with the local position of
		# the collision node and its shape
		# subtract half the size of the shape because the origin is
		# the shape's center
		var area_pos = Vector2i(map.position
								+ map_area.position
								+ shape.position
								- (shape.shape.size / 2.0))
		maps[map] = MapPositionData.new(i,
										map.position,
										area_pos, shape.shape.size)
		# give it a unique name
		map_area.name = map.name
		# get the mobs node from the map, remove it from there and take the mobs
		# and put them in a dictionary and reparent them to the new nodes for them
		var mobs_node = map.get_node("Mobs")
		map.remove_child(mobs_node)
		var new_mobs_node = Node2D.new()
		new_mobs_node.name = map.name
		$'Mobs'.add_child(new_mobs_node)
		mobs[map] = mobs_node.get_children()
		for mob in mobs_node.get_children():
			mob.reparent(new_mobs_node, false)
			new_mobs_node.remove_child(mob)
		i += 1

	# remove all for now, the relevant ones will be re-added
	for map in maps.keys():
		remove_map_from_scene(map)

	# Set everything up for the first time
	adjust_player_and_maps()
	update_active_maps()

	# put the player in place
	add_child(player)

func _process(_delta : float):
	update_active_maps()
	area.position = player.position

func pause(paused : bool):
	if paused:
		player.process_mode = PROCESS_MODE_DISABLED
	else:
		player.process_mode = PROCESS_MODE_INHERIT
