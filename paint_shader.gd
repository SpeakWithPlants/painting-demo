extends SubViewportContainer

const paint_colors : Array[Color] = [
	Color("f63f5b"),
	Color("ff975b"),
	Color("ffce59"),
	Color("81d768"),
	Color("6dacff"),
	Color("ab70ff")
];
const brush_radius : int = 10
const scaling_factor : float = 1.0

@export var surface_node : TileMapLayer

var mouse_pos : Vector2
var last_mouse_pos : Vector2
var paint_image : Image
var paint_color_idx : int = 0


func _ready() -> void:
	mouse_pos = get_global_mouse_position() / stretch_shrink
	last_mouse_pos = mouse_pos
	if surface_node == null:
		assert(false, "Surface node must not be null")
	_reset_canvas()
	pass


func _process(_delta: float) -> void:
	_handle_input()
	var resized_image = paint_image.duplicate()
	resized_image.resize(1920, 1080, Image.INTERPOLATE_NEAREST)
	var paint_texture = ImageTexture.create_from_image(resized_image)
	material.set_shader_parameter("paint_texture", paint_texture)
	pass


func _handle_input() -> void:
	last_mouse_pos = mouse_pos
	mouse_pos = get_global_mouse_position() / stretch_shrink
	if Input.is_action_pressed("mouse_left"):
		var paint_color : Color = paint_colors[paint_color_idx]
		if last_mouse_pos.distance_squared_to(mouse_pos) < 1:
			_paint_circle(mouse_pos, paint_color)
			pass
		else:
			_paint_segment3(last_mouse_pos, mouse_pos, paint_color)
			pass
	elif Input.is_action_just_pressed("mouse_right"):
		paint_color_idx = (paint_color_idx + 1) % paint_colors.size()
	#elif Input.is_action_just_pressed("ui_accept"):
		#_reset_canvas()
	pass


# Optimized solution:
# Perform a linear transformation on the incoming coordinates so that the midpoint between
# start_pos and end_pos is centered on the origin and parallel with the x-axis, then paint a
# capsule onto the transformed coordinates.
func _paint_segment3(start_pos: Vector2, end_pos: Vector2, paint_color: Color):
	var theta = start_pos.angle_to_point(end_pos)
	var s = (brush_radius + 1) * Vector2.ONE
	var c1 = start_pos.min(end_pos) - s
	var c2 = start_pos.max(end_pos) + s
	var seg_dist = start_pos.distance_to(end_pos)
	var midpoint = (start_pos + end_pos) / 2
	for x in range(c1.x, c2.x):
		for y in range(c1.y, c2.y):
			if x < 0 or x >= paint_image.get_width():
				continue
			if y < 0 or y >= paint_image.get_height():
				continue
			var current_color = paint_image.get_pixel(x, y)
			if paint_color == current_color:
				continue
			# Linear transformation
			var tx = x - midpoint.x
			var ty = y - midpoint.y
			var ax = tx * cos(theta) + ty * sin(theta)
			var ay = tx * sin(theta) - ty * cos(theta)
			var dist = _distance_to_capsule(seg_dist, ax, ay)
			# Use the distance to the transformed capsule to determine the alpha of the pixels
			var alpha = clamp(inverse_lerp(brush_radius + 1, brush_radius, dist), 0.0, 1.0)
			paint_color.a = 1.0 if (alpha >= 0.5) else 0.0 # lock to full alpha or transparent
			if paint_color.a > 0.0:
				var final_color
				if paint_color.a < 1.0:
					final_color = current_color.blend(paint_color)
				else:
					final_color = paint_color
				paint_image.set_pixel(x, y, final_color)
	pass


func _paint_circle(center_pos : Vector2, paint_color : Color) -> void:
	var start_pos = center_pos - (Vector2.ONE * brush_radius)
	var end_pos = center_pos + (Vector2.ONE * brush_radius)
	for x in range(start_pos.x - 2, end_pos.x + 2):
		for y in range(start_pos.y - 2, end_pos.y + 2):
			if x < 0 or x >= paint_image.get_width():
				continue
			if y < 0 or y >= paint_image.get_height():
				continue
			var current_color = paint_image.get_pixel(x, y)
			if paint_color == current_color:
				continue
			var dist = Vector2(x, y).distance_to(center_pos)
			if dist <= brush_radius:
				paint_image.set_pixel(x, y, paint_color)
	pass


func _distance_to_capsule(seg_dist: float, x: float, y: float) -> float:
	var half_seg_dist = seg_dist / 2
	if abs(x) >= half_seg_dist:
		var half_seg = Vector2.RIGHT * half_seg_dist
		var left_dist = Vector2(x, y).distance_to(-half_seg)
		var right_dist = Vector2(x, y).distance_to(half_seg)
		return min(left_dist, right_dist)
	return abs(y)


func _reset_canvas():
	paint_image = Image.create_empty(640, 360, true, Image.FORMAT_RGBA8)
	pass
