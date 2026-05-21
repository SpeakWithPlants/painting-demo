extends TileMapLayer

var scene_coords : Dictionary[Vector2i, Node] = {}


func _enter_tree() -> void:
	child_entered_tree.connect(_register_child)
	child_exiting_tree.connect(_unregister_child)
	pass


func _register_child(child : Node) -> void:
	await child.ready
	var coords = local_to_map(to_local(child.global_position))
	scene_coords[coords] = child
	child.set_meta("tile_coords", coords)
	if child.has_method("updated_metadata"):
		child.updated_metadata()
	pass


func _unregister_child(child : Node) -> void:
	scene_coords.erase(child.get_meta("tile_coords"))
	pass


func get_cell_scene(coords : Vector2i) -> Node:
	return scene_coords.get(coords, null)
