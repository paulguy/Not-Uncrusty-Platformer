class_name TilemapArea
extends TileMap

var mobs = []
var onscreen = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in self.get_children():
		if child is Mob:
			mobs.append(child)

func on_screen():
	for mob in mobs:
		mob.activate()
		self.add_child(mob)
	onscreen = true

func off_screen(onscreenMobs):
	for mob in mobs:
		if mob in onscreenMobs:
			continue
		self.remove_child(mob)
		mob.deactivate()
	onscreen = false
