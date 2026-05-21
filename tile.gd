extends Node2D
class_name Tile

const light_colors : Array[Color] = [Color("ffffff"), Color("f3f3f3")]
const dark_colors : Array[Color] = [Color("cccccc"), Color("bcbcbc")]

@onready var sprite : Sprite2D = $Sprite2D

func _ready():
	sprite.frame = randi() % sprite.hframes
	pass


func updated_metadata():
	var tile_coords : Vector2i = get_meta("tile_coords")
	if (tile_coords.x + tile_coords.y) % 2 == 0:
		modulate = light_colors[randi() % light_colors.size()]
	else:
		modulate = dark_colors[randi() % dark_colors.size()]
	pass
