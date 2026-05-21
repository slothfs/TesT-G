shader_type canvas_item;

uniform float time_speed = 1.0;

// base blood color
uniform vec3 blood_color : source_color = vec3(0.6, 0.0, 0.0);

// subtle darkness variation
uniform float pulse_strength = 0.08;

void fragment() {
    vec2 uv = UV;
    float t = TIME * time_speed;

    // soft pulsing (like breathing / heartbeat mood)
    float pulse = sin(t * 2.0) * 0.5 + 0.5;

    // vertical dark gradient
    float vignette = smoothstep(0.8, 0.2, length(uv - 0.5));

    // slight grain (very subtle)
    float noise = fract(sin(dot(uv * 200.0, vec2(12.9898, 78.233))) * 43758.5453);

    vec3 col = blood_color;

    // apply pulse + vignette
    col *= (1.0 - pulse * pulse_strength);
    col *= vignette + 0.4;

    // tiny gritty noise (horror feel)
    col += (noise - 0.5) * 0.03;

    COLOR = vec4(col, 1.0);
}