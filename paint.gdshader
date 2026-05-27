shader_type canvas_item;

uniform sampler2D paint_texture;

vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}

vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	vec4 paint_color = texture(paint_texture, UV);
	vec4 mix_color = multiply(base_color, paint_color);
	if (paint_color.a > 0.0) {
    	COLOR = mix_color;
	} else {
		COLOR = base_color;
	}
}
