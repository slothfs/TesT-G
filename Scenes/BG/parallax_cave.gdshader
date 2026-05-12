shader_type canvas_item;

// Wobble strength
uniform float amplitude : hint_range(0.0, 50.0) = 10000000;

// Wobble speed
uniform float speed : hint_range(0.0, 10.0) = 10000000;

// Wave frequency
uniform float frequency : hint_range(0.0, 20.0) = 1000000;

void fragment() {
    vec2 uv = UV;

    // Horizontal wobble using sine wave
    uv.x += sin((uv.y * frequency) + (TIME * speed)) * amplitude / 100.0;

    COLOR = texture(TEXTURE, uv);
}