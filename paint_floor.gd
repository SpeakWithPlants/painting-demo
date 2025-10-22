extends Node2D

@export var background_color: Color = Color.ALICE_BLUE
@export var paint_color_idx: int = 0

const paint_colors = [Color.CRIMSON, Color.CORAL, Color(1.0, 0.8, 0.2, 1), Color.MEDIUM_SEA_GREEN, Color.DODGER_BLUE, Color.PURPLE];
const brush_radius = 30.0

var paint_image: Image
var paint_texture: ImageTexture


func _ready() -> void:
	paint_image = Image.create_empty(1920, 1080, true, Image.FORMAT_RGBA8)
	paint_texture = ImageTexture.create_from_image(paint_image)
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
	var mouse_pos = get_local_mouse_position()
	draw_circle(mouse_pos, brush_radius, paint_color, true, -1.0, true)
	pass


func _handle_input():
	if Input.is_action_pressed("mouse_left"):
		var paint_color: Color = paint_colors[paint_color_idx]
		var mouse_pos = get_local_mouse_position()
		var start_pos = mouse_pos - (Vector2.ONE * brush_radius)
		var end_pos = mouse_pos + (Vector2.ONE * brush_radius)
		for x in range(start_pos.x - 2, end_pos.x + 2):
			for y in range(start_pos.y - 2, end_pos.y + 2):
				if x < 0 or x > paint_image.get_width():
					continue
				if y < 0 or y > paint_image.get_height():
					continue
				var dist = Vector2(x, y).distance_to(mouse_pos)
				if dist > brush_radius + 1:
					continue
				var current_color = paint_image.get_pixel(x, y)
				var alpha = clamp(inverse_lerp(brush_radius + 1, brush_radius, dist), 0.0, 1.0)
				paint_color.a = alpha
				var blend_color = current_color.blend(paint_color)
				paint_image.set_pixel(x, y, blend_color)
	elif Input.is_action_just_pressed("mouse_right"):
		paint_color_idx = (paint_color_idx + 1) % paint_colors.size()
	pass
