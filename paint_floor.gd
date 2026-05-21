extends Node2D

@export var background_color: Color = Color.ALICE_BLUE
@export var paint_color_idx: int = 0
@export var paint_surface: SubViewportContainer

const paint_colors = [Color.CRIMSON, Color.CORAL, Color(1.0, 0.8, 0.2, 1), Color.MEDIUM_SEA_GREEN, Color(0.12, 0.56, 0.95, 1), Color.PURPLE];
const brush_radius = 30.0

var paint_image: Image
var paint_texture: ImageTexture
var mouse_pos: Vector2
var last_mouse_pos: Vector2


func _ready() -> void:
	_reset_canvas()
	mouse_pos = get_local_mouse_position()
	last_mouse_pos = mouse_pos
	pass


func _process(_delta: float) -> void:
	queue_redraw()
	_handle_input()
	if paint_surface != null:
		paint_texture.update(paint_image)
		paint_surface.material.set_shader_parameter("paint_texture", paint_texture)
	pass


func _draw() -> void:
	draw_rect(get_viewport_rect(), background_color)
	paint_texture.update(paint_image)
	#draw_texture(paint_texture, Vector2.ZERO)
	$TextureRect.texture = paint_texture
	var paint_color: Color = paint_colors[paint_color_idx]
	draw_circle(mouse_pos, brush_radius, paint_color)
	pass


func _reset_canvas():
	paint_image = Image.create_empty(640, 360, true, Image.FORMAT_RGBA8)
	paint_texture = ImageTexture.create_from_image(paint_image)
	pass


func _handle_input():
	_update_mouse_pos()
	if Input.is_action_pressed("mouse_left"):
		var paint_color: Color = paint_colors[paint_color_idx]
		if last_mouse_pos.distance_squared_to(mouse_pos) < 1:
			_paint_circle(mouse_pos, paint_color)
		else:
			_paint_segment3(last_mouse_pos, mouse_pos, paint_color)
	elif Input.is_action_just_pressed("mouse_right"):
		paint_color_idx = (paint_color_idx + 1) % paint_colors.size()
	elif Input.is_action_just_pressed("ui_accept"):
		_reset_canvas()
	pass


func _update_mouse_pos():
	last_mouse_pos = mouse_pos
	mouse_pos = get_local_mouse_position()
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


# Iterate once over the smallest possible bounding box of the segment and color pixels
# according to their distance to the segment.  Then, draw two circles on the ends to round it off.
func _paint_segment2(start_pos: Vector2, end_pos: Vector2, paint_color: Color):
	var theta = start_pos.angle_to_point(end_pos)
	var s = brush_radius * Vector2.UP.rotated(theta)
	# c1 and c2 are the top-left and bottom-right corners of the segment's bounding box
	var c1 = (start_pos - s).min(start_pos + s).min(end_pos - s).min(end_pos + s)
	var c2 = (start_pos - s).max(start_pos + s).max(end_pos - s).max(end_pos + s)
	for x in range(c1.x, c2.x):
		for y in range(c1.y, c2.y):
			if x < 0 or x > paint_image.get_width():
				continue
			if y < 0 or y > paint_image.get_height():
				continue
			var current_color = paint_image.get_pixel(x, y)
			if paint_color == current_color:
				continue
			var dist = _distance_to_line(start_pos, end_pos, x, y)
			var alpha = clamp(inverse_lerp(brush_radius + 1, brush_radius, dist), 0.0, 1.0)
			paint_color.a = alpha
			var blend_color = current_color.blend(paint_color)
			paint_image.set_pixel(x, y, blend_color)
	_paint_circle(start_pos, paint_color)
	_paint_circle(end_pos, paint_color)
	pass


# Iterate over each pixel of the line segment and draw a circle of brush radius
# centered on that pixel.
func _paint_segment(start_pos: Vector2, end_pos: Vector2, paint_color: Color):
	var c1 = start_pos.min(end_pos)
	var c2 = start_pos.max(end_pos)
	for x in range(c1.x, c2.x):
		for y in range(c1.y, c2.y):
			if x < 0 or x > paint_image.get_width():
				continue
			if y < 0 or y > paint_image.get_height():
				continue
			var current_color = paint_image.get_pixel(x, y)
			if paint_color == current_color:
				continue
			var dist = _distance_to_line(start_pos, end_pos, x, y)
			var alpha = clamp(inverse_lerp(brush_radius + 1, brush_radius, dist), 0.0, 1.0)
			paint_color.a = alpha
			var blend_color = current_color.blend(paint_color)
			paint_image.set_pixel(x, y, blend_color)
	pass


func _paint_circle(center_pos, paint_color):
	var start_pos = center_pos - (Vector2.ONE * brush_radius)
	var end_pos = center_pos + (Vector2.ONE * brush_radius)
	for x in range(start_pos.x - 2, end_pos.x + 2):
		for y in range(start_pos.y - 2, end_pos.y + 2):
			if x < 0 or x > paint_image.get_width():
				continue
			if y < 0 or y > paint_image.get_height():
				continue
			var current_color = paint_image.get_pixel(x, y)
			if paint_color == current_color:
				continue
			var dist = Vector2(x, y).distance_to(center_pos)
			if dist > brush_radius + 1:
				continue
			var alpha = clamp(inverse_lerp(brush_radius + 1, brush_radius, dist), 0.0, 1.0)
			paint_color.a = 1.0 if (alpha > 0.5) else 0.0 # lock to full alpha or transparent
			if paint_color.a > 0.0:
				var final_color
				if paint_color.a < 1.0:
					final_color = current_color.blend(paint_color)
				else:
					final_color = paint_color
				paint_image.set_pixel(x, y, final_color)
	pass


# unused
func _is_in_capsule(dist: float, x: float, y: float) -> bool:
	var half_dist = dist / 2
	var y_dist_fac = sqrt(brush_radius * brush_radius - y * y)
	var x_min_fac = x - half_dist - y_dist_fac
	var x_max_fac = x + half_dist + y_dist_fac
	var y_min_rad = y - brush_radius
	var y_max_rad = y + brush_radius
	var capsule = x_min_fac * x_max_fac * y_min_rad * y_max_rad
	return capsule >= 0


func _distance_to_capsule(seg_dist: float, x: float, y: float) -> float:
	var half_seg_dist = seg_dist / 2
	if abs(x) >= half_seg_dist:
		var half_seg = Vector2.RIGHT * half_seg_dist
		var left_dist = Vector2(x, y).distance_to(-half_seg)
		var right_dist = Vector2(x, y).distance_to(half_seg)
		return min(left_dist, right_dist)
	return abs(y)


func _distance_to_line(c1, c2, px, py) -> float:
	var x_diff = c2.x - c1.x
	var y_diff = c2.y - c1.y
	var num = abs(y_diff * px - x_diff * py + c2.x * c1.y - c2.y * c1.x)
	var den = sqrt(pow(y_diff, 2) + pow(x_diff, 2))
	return num / den;
