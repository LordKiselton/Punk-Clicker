shader_type canvas_item;

// Soft circular crop so square icon corners never sit on the ring border.
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 p = UV - vec2(0.5);
	float d = length(p);
	float a = 1.0 - smoothstep(0.48, 0.50, d);
	col.a *= a;
	COLOR = col;
}
