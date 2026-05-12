shader_type canvas_item;

uniform vec2 target_pos = vec2(0.0);
uniform float stretch_amount = 0.0;

void vertex() {
    float stretch_factor = clamp(-VERTEX.y / 20.0, 0.0, 1.0);
    vec2 new_vertex = mix(VERTEX, target_pos, stretch_factor);
    VERTEX = mix(VERTEX, new_vertex, stretch_amount);
}
