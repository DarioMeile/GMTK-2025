shader_type spatial;
render_mode skip_vertex_transform;

uniform bool billboard = false;

uniform sampler2D color_texture : source_color, filter_nearest, repeat_disable;

uniform vec3 tint : source_color = vec3(1);

uniform bool vertex_snapping = true;
uniform bool affine_texture_mapping = true;

group_uniforms Fog;
uniform bool add_fog = false;
uniform vec3 fog_color : source_color = vec3(0.42, 0.42, 0.45);
uniform vec2 fog_start_end = vec2(10, 100);
group_uniforms;

group_uniforms Light;
uniform bool add_dynamic_vertex_lighting = false;
uniform vec3 light_direction = vec3(0, 1, 0);
uniform float light_intensity = 1.0;
uniform vec3 ambient_light : source_color = vec3(0);
group_uniforms;

group_uniforms Dither;
uniform bool add_dither = true;
uniform float dither_spread = 1.0;
uniform float dither_gamma = 1.0;
group_uniforms;

varying vec4 clip_pos;
varying float FOG_FACTOR;

void vertex() {
	mat4 model_matrix = MODEL_MATRIX;

	if (billboard) {
		mat4 mat_world = mat4(
				normalize(INV_VIEW_MATRIX[0]),
				vec4(0, 1, 0, 0),
				normalize(INV_VIEW_MATRIX[2]),
				MODEL_MATRIX[3]);

		model_matrix = mat_world;

		MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;

		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}

	vec4 world_space = model_matrix * vec4(VERTEX, 1);

	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * world_space;

	vec4 vertex = clip;

	// Snap to nearest pixel
	if (vertex_snapping) {
		vertex.xy = round(clip.xy / clip.w * VIEWPORT_SIZE.xy) / VIEWPORT_SIZE.xy * clip.w;
	}

	POSITION = vertex;

	// Need to hold on to clip.w to reverse perspective corrections
	clip_pos = vertex;

	// Calculate vertex distance from camera for fog
	float view_distance = length(CAMERA_POSITION_WORLD - world_space.xyz);
	FOG_FACTOR = (fog_start_end.y - (view_distance)) / (fog_start_end.y - fog_start_end.x);
	FOG_FACTOR = 1.0 - clamp(FOG_FACTOR, 0.0, 1.0);


	NORMAL = MODEL_NORMAL_MATRIX * NORMAL;

	if (add_dynamic_vertex_lighting) {
		float direct_light = clamp(dot(NORMAL, normalize(light_direction)), 0, 1);

		vec3 light = ambient_light + direct_light * light_intensity;
		COLOR.rgb *= clamp(light, vec3(0), vec3(1));
	}

	// Multiply by perspective correction to undo it in fragment shader
	if (affine_texture_mapping) {
		UV = UV * clip_pos.w;
		COLOR *= clip_pos.w;
		FOG_FACTOR *= clip_pos.w;
	}
}

void fragment() {
	vec2 uv = UV;
	vec3 vertex_color = COLOR.rgb;
	float fog_factor = FOG_FACTOR;

	// Undo perspective correction
	if (affine_texture_mapping) {
		uv /= clip_pos.w;
		vertex_color /= clip_pos.w;
		fog_factor /= clip_pos.w;
	}

	vec3 texture_color = texture(color_texture, uv).rgb;

	vec3 albedo = texture_color * vertex_color * tint;

	vec3 fogged = albedo;

	if (add_fog) {
		fogged = mix(albedo, fog_color, fog_factor);
		fogged = clamp(fogged, vec3(0), vec3(1));
	}

	vec3 quantized = fogged;

	if (add_dither) {
		int ps1_dither_matrix[16] = {
	    		-4, 0, -3, 1,
	    		2, -2, 3, -1,
	    		-3, 1, -4, 0,
	    		3, -1, 2, -2
		};

		// Index 1D dither matrix based on 2D screen coordinates
		float noise = float(ps1_dither_matrix[(int(FRAGCOORD.x) % 4) + (int(FRAGCOORD.y) % 4) * 4]);

		// Apply dithering and quantize 24 bit srgb to 15 bit srgb according to https://psx-spx.consoledev.net/graphicsprocessingunitgpu/
		quantized = pow(fogged, vec3(1.0 / dither_gamma)); // Convert to srgb cause it imo looks better and is probably correct idk looks more correct than linear quantization
		quantized = round(quantized * 255.0 + noise); // Convert to 0-255 and add dither noise
		quantized = clamp(round(quantized), vec3(0), vec3(255)); // Clamp to 0-255 in case of overflow
		quantized = clamp(quantized / 8.0, vec3(0), vec3(31)); // Convert to 0-31 range
		quantized /= 31.0; // Convert back to 0-1 range

		quantized = pow(quantized, vec3(dither_gamma)); // Convert back to linear
	}

	ALBEDO = quantized;
}

void light() {
	DIFFUSE_LIGHT = vec3(1);
	SPECULAR_LIGHT = vec3(0);
}
