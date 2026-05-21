shader_type canvas_item;

uniform sampler2D paint_texture;

vec4 overlay(vec4 base, vec4 blend) {
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	vec4 paint_color = texture(paint_texture, UV);
	vec3 mix_color = mix(base_color.rgb, paint_color.rgb, paint_color.a);
    COLOR = vec4(mix_color, max(base_color.a, paint_color.a));
}
