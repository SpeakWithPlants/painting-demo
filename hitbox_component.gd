extends Node2D
class_name HitboxComponent
## A component comprised of an Area2D with a collision shape. Can detect collisions between other HitboxComponents.
##
## Has an exported root_node that should be set as the root of the tree the component is in. This node will be sent
## to other colliding HitboxComponents. Don't forget to attach its signals!
# NOTE in the future, it might be best to have wisps' hitboxes be farther right and enemies' hitboxes farther left

signal area_entered(node : Node2D)
signal area_exited(node: Node2D)
# Should be set to the root node of the tree.
@export var root_node : Node2D 

## Will emit a signal containing the root node of a colliding HitboxComponent
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent() is HitboxComponent:
		var other_hitbox_component : HitboxComponent = area.get_parent()
		var other_root_node = other_hitbox_component.root_node
		area_entered.emit(other_root_node)


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.get_parent() is HitboxComponent:
		var other_hitbox_component : HitboxComponent = area.get_parent()
		var other_root_node = other_hitbox_component.root_node
		area_exited.emit(other_root_node)
