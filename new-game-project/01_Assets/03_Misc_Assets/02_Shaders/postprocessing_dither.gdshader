// Based on: https://www.shadertoy.com/view/WstXR8
shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

group_uniforms Parameters;
uniform float gamma = 2.2;
uniform float blend = 1.0;
uniform float dither_spread = 0.5;
group_uniforms;

void fragment() {
    // sample the texture
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = FRAGCOORD.xy/iResolution.xy;
    vec4 col = texture(SCREEN_TEXTURE,uv);
    vec4 original = col;

	float scale = max(0.1, dither_spread);

    // gamma correction
    col = vec4(pow(col.rgb, (vec3(gamma)) - 0.004), col.a);

    // find bayer matrix entry based on fragment position
    mat4 bayerIndex =  mat4(
        vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
        vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
        vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
        vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));
	int bx = int(FRAGCOORD.x / scale) % 4;
	int by = int(FRAGCOORD.y / scale) % 4;
    float bayerValue = bayerIndex[bx][by];
     col = vec4(
         step(bayerValue,col.r),
         step(bayerValue,col.g),
         step(bayerValue,col.b),
         col.a);
     // output
     COLOR = (col * blend) + (original * (blend - 1.0));
}