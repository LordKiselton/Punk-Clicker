// Затемнение + лёгкий blur задника под прозрачной рамкой модалки.
// Вешать на ColorRect / Panel внутри окна (под контентом).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_px : hint_range(0.0, 8.0) = 2.5;
uniform float dim : hint_range(0.0, 1.0) = 0.72; // 0 = без затемнения, 1 = почти чёрный
uniform vec4 tint : source_color = vec4(0.08, 0.05, 0.12, 1.0);

void fragment() {
	vec2 px = vec2(blur_px) / vec2(textureSize(screen_tex, 0));
	vec3 acc = vec3(0.0);
	// 9-tap box blur
	acc += texture(screen_tex, SCREEN_UV + vec2(-px.x, -px.y)).rgb;
	acc += texture(screen_tex, SCREEN_UV + vec2(0.0, -px.y)).rgb;
	acc += texture(screen_tex, SCREEN_UV + vec2(px.x, -px.y)).rgb;
	acc += texture(screen_tex, SCREEN_UV + vec2(-px.x, 0.0)).rgb;
	acc += texture(screen_tex, SCREEN_UV).rgb;
	acc += texture(screen_tex, SCREEN_UV + vec2(px.x, 0.0)).rgb;
	acc += texture(screen_tex, SCREEN_UV + vec2(-px.x, px.y)).rgb;
	acc += texture(screen_tex, SCREEN_UV + vec2(0.0, px.y)).rgb;
	acc += texture(screen_tex, SCREEN_UV + vec2(px.x, px.y)).rgb;
	acc /= 9.0;
	vec3 col = mix(acc, tint.rgb, dim);
	COLOR = vec4(col, 1.0);
}
