class_name AreaInfo

var name : String
var area : Rect2i
var adjusted_area : Rect2i
var pos : Vector2i
var area_node : Area2D
var new_mobs_node : Node2D
var mobs : Array[Node] = []
var groups : Array[Node] = []

func _init(map : Node2D) -> void:
	# get the map area node
	var map_area : Area2D = map.get_node("Map Area")
	# ultimately, the map is going to be an empty Node2D that's just
	# used consistently as a handle for the caller to use as a key so
	# just make it as light as possible
	map.remove_child(map_area)

	# get the shape
	var shape : CollisionShape2D = map_area.get_node("Map Shape")
	# get the rectangles of the areas
	# Add up the position of the map with the local position of
	# the collision node and its shape
	# subtract half the size of the shape because the origin is
	# the shape's center
	var area_pos = Vector2i(map.position
						   + map_area.position
						   + shape.position
						   - (shape.shape.size / 2.0))

	# get the mobs node from the map and take the mobs
	# put them in an array and reparent them to the new node for them
	var mobs_node : Node2D = map.get_node("Mobs")
	map.remove_child(mobs_node)
	self.new_mobs_node = Node2D.new()
	self.new_mobs_node.name = map.name
	self.mobs = mobs_node.get_children()
	var node_mobs = mobs_node.get_children()
	for mob in node_mobs:
		mobs_node.remove_child(mob)
		#mob.reparent(new_mobs_node, false)
		#new_mobs_node.remove_child(mob)

	# Take the remaining map nodes, ignore/remove the BackBufferCopys
	# and add the rest of the nodes to an Array
	var nodes : Array[Node] = map.get_children()
	for node in nodes:
		map.remove_child(node)
		if node.get_child(0) is BackBufferCopy:
			node.remove_child(node.get_child(0))
		self.groups.append(node)

	self.pos = map.position
	self.area = Rect2i(area_pos, shape.shape.size)
	self.adjusted_area = Rect2i(self.area)
	self.name = map.name

func area_intersects(other : Rect2i) -> bool:
	return self.adjusted_area.intersects(other)

func adjust(player_offset : Vector2i) -> Vector2:
	self.adjusted_area.position = area.position - player_offset

	for group in self.groups:
		group.position = self.pos - player_offset

	return self.pos - player_offset
