shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.45, 1.0, 0.32, 1.0);
uniform float line_thickness : hint_range(0.0, 40.0) = 14.0;
uniform float pulse : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * line_thickness * pulse;
	float outline = 0.0;
	outline = max(outline, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	outline = max(outline, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);
	vec4 ring = vec4(line_color.rgb, outline * pulse);
	COLOR = mix(ring, col, col.a);
}
