// VHS / панк-клип грейд для режима ПОЛНЫЙ ПАНК-РОК.
// Полноэкранный пас поверх кадра: хром-аберрация, скан-линии, красный грейд,
// джиттер ПО БИТУ (ритмично, не случайно → читается как клип, а не баг).
// intensity=0 → кадр без изменений (для плавных вход/выход).
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float beat : hint_range(0.0, 1.0) = 0.0;        // 0..1 пульс на бит
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

void fragment() {
	vec2 uv = SCREEN_UV;

	// Горизонтальный джиттер на бит (синус по строкам — «дрожащая лента»)
	float jitter = (beat * 0.012) * sin(uv.y * 60.0 + TIME * 28.0);
	uv.x += jitter * intensity;

	// Хром-аберрация: плавный сдвиг RGB, с потолком
	float ab = (0.004 + beat * 0.006) * intensity;
	float r = texture(screen_tex, uv - vec2(ab, 0.0)).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv + vec2(ab, 0.0)).b;
	vec3 col = vec3(r, g, b);

	// Скан-линии (статичный фильтр = намеренно)
	float scan = 0.85 + 0.15 * sin(uv.y * 720.0);
	col *= mix(1.0, scan, intensity * 0.6);

	// Панк-красный грейд + контраст
	vec3 punk = col * vec3(1.25, 0.55, 0.62) + vec3(0.06, 0.0, 0.0);
	col = mix(col, punk, intensity * 0.6);

	// Виньетка
	float d = distance(uv, vec2(0.5));
	float vig = smoothstep(0.85, 0.4, d);
	col *= mix(1.0, mix(0.55, 1.0, vig), intensity);

	COLOR = vec4(col, 1.0);
}
