shader_type canvas_item;

uniform float hit_effect : hint_range(0,1) = 0.0;
uniform float shake_intensity = 10.0;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

void vertex() {
    if (hit_effect > 0.0) {
        float time = TIME * 30.0;
        vec2 random_offset = vec2(
            rand(vec2(time, 0.0)) * 2.0 - 1.0,
            rand(vec2(time, 10.0)) * 2.0 - 1.0
        );
        VERTEX += random_offset * shake_intensity * hit_effect;
    }
}