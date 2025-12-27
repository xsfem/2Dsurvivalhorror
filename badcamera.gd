extends ColorRect

# Параметры эффекта старой камеры
@export var noise_strength: float = 0.15
@export var vignette_strength: float = 0.4
@export var scanline_count: float = 200.0
@export var grain_speed: float = 1.0
@export var jitter_amount: float = 0.002
@export var color_aberration: float = 0.003
@export var flicker_speed: float = 0.5
@export var scratch_probability: float = 0.02

var time: float = 0.0
var shader_material: ShaderMaterial

func _ready():
	# Создаем шейдер для эффекта
	var shader = Shader.new()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	shader.code = """
shader_type canvas_item;

uniform float noise_strength : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float scanline_count : hint_range(0.0, 500.0) = 200.0;
uniform float time = 0.0;
uniform float jitter = 0.0;
uniform float color_aberration : hint_range(0.0, 0.01) = 0.003;
uniform float flicker = 1.0;
uniform float scratch_alpha = 0.0;
uniform float scratch_pos = 0.0;

// Генератор случайных чисел
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Шум
float noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	
	// Добавляем дрожание
	uv.x += sin(time * 10.0 + uv.y * 100.0) * jitter;
	uv.y += cos(time * 8.0 + uv.x * 80.0) * jitter * 0.5;
	
	// Хроматическая аберрация
	float r = texture(TEXTURE, uv + vec2(color_aberration, 0.0)).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - vec2(color_aberration, 0.0)).b;
	vec3 col = vec3(r, g, b);
	
	// Зернистость (grain)
	float grain = noise(uv * 500.0 + time * 20.0);
	col += (grain - 0.5) * noise_strength;
	
	// Строчная развертка (scanlines)
	float scanline = sin(uv.y * scanline_count) * 0.1;
	col -= scanline;
	
	// Виньетка
	vec2 vign_uv = uv * (1.0 - uv);
	float vignette = vign_uv.x * vign_uv.y * 15.0;
	vignette = pow(vignette, vignette_strength);
	col *= vignette;
	
	// Мерцание
	col *= flicker;
	
	// Царапины
	if (abs(uv.x - scratch_pos) < 0.001) {
		col = mix(col, vec3(1.0), scratch_alpha * random(vec2(uv.y, time)));
	}
	
	// Небольшое выцветание цвета (сепия эффект)
	float gray = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(gray) * vec3(1.0, 0.95, 0.85), 0.3);
	
	// Контраст
	col = (col - 0.5) * 1.2 + 0.5;
	
	COLOR = vec4(col, 1.0);
}
"""
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	material = shader_material
	
	# Устанавливаем начальные параметры
	update_shader_params()

func _process(delta):
	time += delta * grain_speed
	
	# Обновляем параметры шейдера
	update_shader_params()
	
	# Случайное дрожание
	var jitter = randf_range(-jitter_amount, jitter_amount) if randf() > 0.9 else 0.0
	shader_material.set_shader_parameter("jitter", jitter)
	
	# Мерцание
	var flicker = 1.0 - randf_range(0.0, 0.15) * flicker_speed if randf() > 0.95 else 1.0
	shader_material.set_shader_parameter("flicker", flicker)
	
	# Царапины
	if randf() < scratch_probability:
		shader_material.set_shader_parameter("scratch_alpha", randf_range(0.3, 0.8))
		shader_material.set_shader_parameter("scratch_pos", randf())
	else:
		shader_material.set_shader_parameter("scratch_alpha", 0.0)

func update_shader_params():
	shader_material.set_shader_parameter("noise_strength", noise_strength)
	shader_material.set_shader_parameter("vignette_strength", vignette_strength)
	shader_material.set_shader_parameter("scanline_count", scanline_count)
	shader_material.set_shader_parameter("time", time)
	shader_material.set_shader_parameter("color_aberration", color_aberration)
