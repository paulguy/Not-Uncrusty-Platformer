extends Node2D

const TARGET_WIDTH = 400.0
const TARGET_HEIGHT = 300.0
const ASPECT_RATIO = TARGET_WIDTH / TARGET_HEIGHT
const RESETTLE_TIME = 0.5

@onready var player : Player = $"Player"

# used as more of a set with some extended data
var maps : Dictionary = {}
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

	# adjust area positions
	for map in maps.keys():
		maps[map].adjust(player_offset)

func add_map_to_scene(map : Node2D):
	$'Maps'.add_child(map)

func remove_map_from_scene(map : Node2D):
	$'Maps'.remove_child(map)

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
			print("removing")
			print(map)
			remove_map_from_scene(map)

	var added : bool = false
	for map in visible_maps:
		if map not in active_maps:
			print("adding")
			print(map)
			add_map_to_scene(map)
			added = true

	if added:
		# readjust everything with the player about the origin
		adjust_player_and_maps()

func _ready():
	# remove the player just to get it out of the way and
	# prevent things triggering
	remove_child(player)

	var area : Area2D = $"Screen Area"
	rect_size = area.get_node("Screen Shape").shape.size
	# don't need it
	remove_child(area)

	var shape : CollisionShape2D
	# gather all the maps and map areas
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

func pause(paused : bool):
	if paused:
		player.process_mode = PROCESS_MODE_DISABLED
	else:
		player.process_mode = PROCESS_MODE_INHERIT
