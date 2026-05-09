shader_type canvas_item;
render_mode unshaded; // Important so it glows in the dark!

uniform float time_speed = 15.0;
uniform float distortion = 0.01; // very slight wobble

void fragment() {
    vec2 uv = UV;
    // Add a tiny sine-wave wobble
    uv.x += sin(TIME * time_speed + uv.y * 10.0) * distortion;
    
    vec4 tex_color = texture(TEXTURE, uv);
    
    COLOR = tex_color;
}