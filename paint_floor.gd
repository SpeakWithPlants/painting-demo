extends Node2D

@export var background_color: Color = Color.ALICE_BLUE
@export var paint_color_idx: int = 0

const paint_colors = [Color.CRIMSON, Color.CORAL, Color(1.0, 0.8, 0.2, 1), Color.MEDIUM_SEA_GREEN, Color.DODGER_BLUE, Color.PURPLE];
const brush_radius = 30.0

var paint_image: Image
var paint_texture: ImageTexture
var mouse_pos: Vector2
var last_mouse_pos: Vector2


func _ready() -> void:
	paint_image = Image.create_empty(1920, 1080, true, Image.FORMAT_RGBA8)
	paint_texture = ImageTexture.create_from_image(paint_image)
	mouse_pos = get_local_mouse_position()
	last_mouse_pos = mouse_pos
	pass


func _process(_delta: float) -> void:
	queue_redraw()
	_handle_input()
	pass


func _draw() -> void:
	draw_rect(get_viewport_rect(), background_color)
	paint_texture.update(paint_image)
	draw_texture(paint_texture, Vector2.ZERO)
	var paint_color: Color = paint_colors[paint_color_idx]
	draw_circle(mouse_pos, brush_radius, paint_color, true, -1.0, true)
	pass


func _handle_input():
	last_mouse_pos = mouse_pos
	mouse_pos = get_local_mouse_position()
	if Input.is_action_pressed("mouse_left"):
		if last_mouse_pos.distance_squared_to(mouse_pos) < 1:
			return
		var paint_color: Color = paint_colors[paint_color_idx]
		_paint_segment2(last_mouse_pos, mouse_pos, paint_color)
	elif Input.is_action_just_pressed("mouse_right"):
		paint_color_idx = (paint_color_idx + 1) % paint_colors.size()
	elif Input.is_action_just_pressed("ui_accept"):
		paint_image = Image.create_empty(1920, 1080, true, Image.FORMAT_RGBA8)
	pass


# Optimized solution:
# Drawing circles over the length of the segment covered by the mouse in one frame results in
# a large portion of the iterated pixels being repeated (i.e. unnecessary). This is slow.
# Instead, iterate once over the smallest possible bounding box of the segment and color pixels
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
			paint_color.a = alpha
			var blend_color = current_color.blend(paint_color)
			paint_image.set_pixel(x, y, blend_color)
	pass


func _distance_to_line(c1, c2, px, py) -> float:
	var x_diff = c2.x - c1.x
	var y_diff = c2.y - c1.y
	var num = abs(y_diff * px - x_diff * py + c2.x * c1.y - c2.y * c1.x)
	var den = sqrt(pow(y_diff, 2) + pow(x_diff, 2))
	return num / den;
