extends Node2D

const paint_colors : Array[Color] = [Color.CRIMSON, Color.CORAL, Color(1.0, 0.8, 0.2, 1), Color.MEDIUM_SEA_GREEN, Color(0.12, 0.56, 0.95, 1), Color.PURPLE];
const brush_radius : int = 10
const scaling_factor : float = 1.0

@export var paint_color_idx : int = 0

var mouse_pos : Vector2
var last_mouse_pos : Vector2
var paint_image : Image
var output_texture : ImageTexture


func _ready() -> void:
	mouse_pos = get_local_mouse_position()
	last_mouse_pos = mouse_pos
	_reset_canvas()
	pass


func _process(_delta: float) -> void:
	queue_redraw()
	_handle_input()
	pass


func _draw() -> void:
	var output_image = paint_image.duplicate()
	output_image.resize(1920, 1080, Image.INTERPOLATE_NEAREST)
	output_texture = ImageTexture.create_from_image(output_image)
	draw_texture(output_texture, Vector2.ZERO)
	pass


func _update_mouse_pos() -> void:
	last_mouse_pos = mouse_pos
	mouse_pos = get_local_mouse_position() / scaling_factor
	pass


func _reset_canvas():
	var width = 1920 / scaling_factor
	var height = 1080 / scaling_factor
	paint_image = Image.create_empty(width, height, true, Image.FORMAT_RGBA8)
	pass


func _handle_input() -> void:
	_update_mouse_pos()
	if Input.is_action_pressed("mouse_left"):
		var paint_color : Color = paint_colors[paint_color_idx]
		_paint_circle(mouse_pos, paint_color)
		if last_mouse_pos.distance_squared_to(mouse_pos) < 1:
			#_paint_circle(mouse_pos, paint_color)
			pass
		else:
			#_paint_segment3(last_mouse_pos, mouse_pos, paint_color)
			pass
	elif Input.is_action_just_pressed("mouse_right"):
		paint_color_idx = (paint_color_idx + 1) % paint_colors.size()
	elif Input.is_action_just_pressed("ui_accept"):
		_reset_canvas()
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
			#if dist > brush_radius + 1:
				#continue
			#var alpha = clamp(inverse_lerp(brush_radius + 1, brush_radius, dist), 0.0, 1.0)
			#paint_color.a = 1.0 if (alpha > 0.5) else 0.0 # lock to full alpha or transparent
			#if paint_color.a > 0.0:
				#var final_color
				#if paint_color.a < 1.0:
					#final_color = current_color.blend(paint_color)
				#else:
					#final_color = paint_color
				#paint_image.set_pixel(x, y, final_color)
	pass
