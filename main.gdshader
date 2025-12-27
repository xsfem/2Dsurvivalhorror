shader_type canvas_item;

uniform float glitch_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_speed = 5.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float time = TIME * glitch_speed;
    
    // Horizontal glitch lines
    float glitch_line = step(0.99, random(vec2(time, floor(uv.y * 10.0))));
    
    // RGB split
    if (glitch_strength > 0.0) {
        float offset = glitch_line * glitch_strength * 0.05;
        float r = texture(screen_texture, uv + vec2(offset, 0.0)).r;
        float g = texture(screen_texture, uv).g;
        float b = texture(screen_texture, uv - vec2(offset, 0.0)).b;
        
        // Random displacement
        float displacement = (random(vec2(time, uv.y)) - 0.5) * glitch_strength * 0.1;
        uv.x += displacement * glitch_line;
        
        vec3 color = vec3(r, g, b);
        COLOR = vec4(color, 1.0);
    } else {
        COLOR = texture(screen_texture, uv);
    }
}