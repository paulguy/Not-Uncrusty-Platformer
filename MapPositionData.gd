class_name MapPositionData

var index : int
var area : Rect2i
var adjusted_area : Rect2i
var pos : Vector2i
var area_node : Area2D

func _init(index : int,
		   pos : Vector2i,
		   area_pos : Vector2i,
		   size : Vector2i) -> void:
	self.index = index
	self.pos = pos
	self.area = Rect2i(area_pos, size)
	self.adjusted_area = Rect2i(self.area)

func area_intersects(other : Rect2i) -> bool:
	return self.adjusted_area.intersects(other)

func adjust(player_offset : Vector2i) -> void:
	self.adjusted_area.position = area.position - player_offset
