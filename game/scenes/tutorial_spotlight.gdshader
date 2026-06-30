// Прожектор туториала: мягко затемняет всё, кроме окна на цели,
// + золотое пульсирующее кольцо по краю. Форма — скруглённый прямоугольник
// (radius = half_size даёт круг). Координаты в дизайн-пикселях.
shader_type canvas_item;

uniform vec2 vp = vec2(720.0, 1280.0);   // размер вьюпорта (дизайн-пиксели)
uniform vec2 t_center = vec2(360.0, 400.0);
uniform vec2 t_half = vec2(150.0, 150.0);
uniform float t_radius = 150.0;
uniform float feather = 36.0;
uniform float dim = 0.66;
uniform float pulse = 0.5;                // 0..1 — яркость кольца

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 px = SCREEN_UV * vp;
	float d = sd_round_box(px - t_center, t_half, t_radius);
	// затемнение снаружи окна
	float a = smoothstep(0.0, feather, d) * dim;
	// золотое кольцо по краю окна
	float ring = (1.0 - smoothstep(0.0, 5.0, abs(d))) * step(-3.0, d);
	ring *= (0.55 + 0.45 * pulse);
	vec3 gold = vec3(0.88, 0.76, 0.25);
	vec3 col = gold * ring;
	float alpha = max(a, ring * 0.9);
	COLOR = vec4(col, alpha);
}
