#pragma language glsl3

// Cubemap data
uniform CubeImage skybox;
varying vec3 cube_coords;

#ifdef VERTEX
	uniform mat4 u_view, u_model, u_projection;
	uniform mat4 u_bone_matrices[32];
	uniform int u_skinning;

	vec4 position(mat4 mvp, vec4 v_position)
    {
        cube_coords = normalize(v_position.xyz);
		return u_projection * u_view * u_model * v_position;
	}
#endif

#ifdef PIXEL
    vec4 effect(vec4 pixel_color, Image tex, vec2 texture_coords, vec2 screen_coords) 
    {
        return texture(skybox, cube_coords);
	}
#endif