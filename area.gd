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
	onscreen = true
	for mob in mobs:
		mob.activate()
		# suppress an error, if the mob is already parented, there's nothing to
		# do as the only parent it could ever have is this node.
		if mob.get_parent() == null:
			self.add_child(mob)

func off_screen(onscreenMobs):
	onscreen = false
	for mob in mobs:
		if mob in onscreenMobs:
			continue
		self.remove_child(mob)
		mob.deactivate()
