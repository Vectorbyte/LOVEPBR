#pragma language glsl3

#ifdef VERTEX
	attribute vec4 VertexWeight;
	attribute vec4 VertexBone;

	uniform mat4 u_view, u_model, u_projection;
	uniform mat4 u_bone_matrices[32];
	uniform int u_skinning;

	mat4 getDeformMatrix() 
    {
		if (u_skinning != 0) 
        {
			return
				u_bone_matrices[int(VertexBone.x*255.0)] * VertexWeight.x +
				u_bone_matrices[int(VertexBone.y*255.0)] * VertexWeight.y +
				u_bone_matrices[int(VertexBone.z*255.0)] * VertexWeight.z +
				u_bone_matrices[int(VertexBone.w*255.0)] * VertexWeight.w;
		}
		return mat4(1.0);
	}
    
	vec4 position(mat4 mvp, vec4 v_position)
    {
		return u_projection * u_view * u_model * getDeformMatrix() * v_position;
	}
#endif

#ifdef PIXEL
	void effect()
    {
		gl_FragDepth = gl_FragCoord.z;
	}
#endif