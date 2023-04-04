extends Node2D

const TARGET_WIDTH = 400.0
const TARGET_HEIGHT = 300.0
const ASPECT_RATIO = TARGET_WIDTH / TARGET_HEIGHT

@onready var camera = self.get_node("Player/Player Camera")
@onready var box = self.get_node("ScreenBox")
@onready var bg = self.get_node("Background")
@onready var area = self.get_node("Screen Area")

# Called when the node enters the scene tree for the first time.
func _ready():
	# bg is not needed, but just leave it around in case i want to add it back later, but remove it
	# from the tree so it doesn't do anything weird.
	self.remove_child(bg)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var size = get_viewport_rect().size
	var off = -get_viewport_transform().origin
	var zoom = 1.0
	if size.x / size.y > ASPECT_RATIO:
		zoom = size.y / TARGET_HEIGHT
		size /= zoom
		size.y += zoom
		off /= zoom
		var bar1 = (size.x - TARGET_WIDTH) / 2
		var bar2 = size.x - bar1
		box.polygon = PackedVector2Array([
			off,
			off + Vector2(bar1, 0),
			off + Vector2(bar1, size.y),
			off + Vector2(0, size.y),
			off + Vector2(bar2, 0),
			off + Vector2(size.x, 0),
			off + Vector2(size.x, size.y),
			off + Vector2(bar2, size.y)
		])
		off.x += bar1
	else:
		zoom = size.x / TARGET_WIDTH
		size /= zoom
		off /= zoom
		off.y += zoom
		var bar1 = (size.y - TARGET_HEIGHT) / 2
		var bar2 = size.y - bar1
		box.polygon = PackedVector2Array([
			off,
			off + Vector2(size.x, 0),
			off + Vector2(size.x, bar1),
			off + Vector2(0, bar1),
			off + Vector2(0, bar2),
			off + Vector2(size.x, bar2),
			off + Vector2(size.x, size.y),
			off + Vector2(0, size.y)
		])
		off.y += bar1
#	bg.polygon = PackedVector2Array([
#		off,
#		off + Vector2(size.x, 0),
#		off + Vector2(size.x, size.y),
#		off + Vector2(0, size.y)
#	])
	camera.zoom = Vector2(zoom, zoom)
	area.position = off
