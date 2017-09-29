#pragma language glsl3

#define SPECULAR_SHINE 32
#define PI 3.14159265

// Normal data
varying mat3 TBN;
varying vec3 frag_pos;
varying vec3 view_dir;

// Shadow data
uniform DepthImage shadow_canvas;
varying vec4 shadow_coords;

// Cubemap data
uniform CubeImage reflection;
uniform CubeImage irradiance;
varying vec4 eye_coord;
varying mat4 model_view;
varying mat4 inverse_view;

#ifdef VERTEX
    attribute vec3 VertexNormal;
    attribute vec4 VertexWeight;
    attribute vec4 VertexTangent;
    attribute vec4 VertexBone;
    
    uniform vec3 u_view_direction;
    uniform mat4 u_model, u_view, u_projection;
    uniform mat4 u_bone_matrices[32];
    uniform mat4 u_shadow_vp;
    uniform int  u_skinning;
    
    mat4 getDeformMatrix()
    {
        if (u_skinning != 0) 
        {
            return
                u_bone_matrices[int(VertexBone.x*1.0)] * VertexWeight.x +
                u_bone_matrices[int(VertexBone.y*1.0)] * VertexWeight.y +
                u_bone_matrices[int(VertexBone.z*1.0)] * VertexWeight.z +
                u_bone_matrices[int(VertexBone.w*1.0)] * VertexWeight.w;
        }
        return mat4(1.0);
    }

    vec4 position(mat4 mvp, vec4 v_position) 
    {
        mat4 transform = u_model * getDeformMatrix();
        
        // Convert model space normals onto screen space normals for normal mapping
        vec3 N = normalize((transform * vec4(VertexNormal, 0.0)).xyz);
        vec3 T = normalize((transform * vec4(VertexTangent.xyz, 0.0)).xyz);
        vec3 B = normalize((transform * vec4(cross(VertexNormal, VertexTangent.xyz) * VertexTangent.w, 0.0)).xyz);
        
        // TBN matrix
        TBN = mat3(T,B,N);
        
        // Variables for light direction
        frag_pos = (transform*v_position).xyz;
        view_dir = normalize(u_view_direction);
        
        // Reflection map calculation
        model_view   = transform*u_view;
        eye_coord    = model_view*v_position;
        inverse_view = inverse(u_view);
        
        // Shadow transformation
        shadow_coords = u_shadow_vp * transform * v_position;
        shadow_coords = shadow_coords*0.5 + 0.5;

        return u_projection * eye_coord;
    }
#endif

#ifdef PIXEL
    // Lighting
    uniform vec3 directional_light;
    uniform vec4 directional_color;
    
    uniform Image normal_map;
    uniform Image emmissive_map;
    uniform Image material_map;
    
    uniform float shadow_res;
    vec2 poisson_disk[16] = vec2[]( 
        vec2( -0.94201624, -0.39906216 ), 
        vec2( 0.94558609, -0.76890725 ), 
        vec2( -0.094184101, -0.92938870 ), 
        vec2( 0.34495938, 0.29387760 ), 
        vec2( -0.91588581, 0.45771432 ), 
        vec2( -0.81544232, -0.87912464 ), 
        vec2( -0.38277543, 0.27676845 ), 
        vec2( 0.97484398, 0.75648379 ), 
        vec2( 0.44323325, -0.97511554 ), 
        vec2( 0.53742981, -0.47373420 ), 
        vec2( -0.26496911, -0.41893023 ), 
        vec2( 0.79197514, 0.19090188 ), 
        vec2( -0.24188840, 0.99706507 ), 
        vec2( -0.81409955, 0.91437590 ), 
        vec2( 0.19984126, 0.78641367 ), 
        vec2( 0.14383161, -0.14100790 ) 
    );

    float oren_nayar_diffuse(vec3 light_dir, vec3 view_dir, vec3 normal, float roughness, float albedo) 
    {
        float LdotV = dot(light_dir, view_dir);
        float NdotL = dot(light_dir, normal);
        float NdotV = dot(normal, view_dir);

        float s = LdotV - NdotL * NdotV;
        float t = mix(1.0, max(NdotL, NdotV), step(0.0, s));

        float sigma2 = roughness * roughness;
        float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
        float B = 0.45 * sigma2 / (sigma2 + 0.09);

        return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
    }
    
    float ggx_distribution(vec3 normal, vec3 half_way_dir, float roughness)
    {
        float a2     = roughness*roughness;
        float NdotH  = max(dot(normal, half_way_dir), 0.0);
        float NdotH2 = NdotH*NdotH;
        
        float nom   = a2;
        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
        denom = PI * denom * denom;
        
        return nom / denom;
    }
    
    vec3 fresnel_schlick(vec3 normal, vec3 view_dir, vec3 F0)
    {
        float NdotV = dot(normal, view_dir);
        return F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0);
    }
    
    vec3 cubemap_reflect(CubeImage cube_map, vec3 normal, int miplevel)
    {
        vec3 eye_normal  = (model_view*vec4(normal, 0.0)).xyz;
        vec3 eye_reflect = reflect(eye_coord.xyz, eye_normal);
        vec3 cube_dir = (inverse_view * vec4(eye_reflect, 0.0)).xyz;
        return textureLod(cube_map, cube_dir, miplevel).xyz;
    }
    
    float random(vec3 seed, int i){
        vec4 seed4 = vec4(seed , i);
        float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
        return fract(sin(dot_product) * 43758.5453);
    }

    vec4 effect(vec4 pixel_color, Image tex, vec2 texture_coords, vec2 screen_coords) 
    {
        // PBR Pipeline:
        // Diffuse texture
        // Normal texture
        // Emmissive texture
        // Material texture:
        //  R channel: Roughness
        //  G channel: Metalness
        //  B channel: Fresnel
        vec3 diffuse    = texture2D(tex, texture_coords).rgb;
        vec3 normal     = TBN * normalize(texture2D(normal_map, texture_coords).rgb*2.0 - 1.0);
        vec3 emmissive  = texture2D(emmissive_map, texture_coords).rgb;
        float roughness = texture2D(material_map, texture_coords).r;
        float metalness = texture2D(material_map, texture_coords).g;
        float specular  = texture2D(material_map, texture_coords).b;
        
        // Diffuse and specular values mixed later
        vec3 diff;
        vec3 spec;
        
        // Light data
        vec3 light_dir    = normalize(directional_light);
        vec3 half_way_dir = normalize(light_dir - view_dir);
        
        // Shadow
        vec3 shade = vec3(1.0, 1.0, 1.0);
        for(int v = 0; v < 8; v++)
        {
            int index   = int(mod(16*random(frag_pos, v), 16));
            vec4 coords = vec4(shadow_coords.xy + poisson_disk[index]*(1/shadow_res), shadow_coords.zw);
            shade -= textureProj(shadow_canvas, coords)/8;
        }
        shade -= textureProj(shadow_canvas, shadow_coords)/4;
        shade = directional_color.rgb*max(shade, 0.0)*directional_color.a;
        
        // Diffuse and Specular pass
        diff += oren_nayar_diffuse(light_dir, view_dir, normal, roughness, 1.0)*shade;
        spec += ggx_distribution(normal, half_way_dir, 0.1)*shade;
        
        // Fresnel value
        vec3 fresnel = fresnel_schlick(normal, view_dir, vec3(1.05, 1.05, 1.05));
        fresnel = max(fresnel, 0.0);
        
        // Cubemap reflections
        vec3 reflection_texel = cubemap_reflect(reflection, normal, 8);
        //vec3 irradiance_texel = cubemap_reflect(irradiance, normal, 1);
        
        return vec4(reflection_texel*max(fresnel, 0.5), 1.0) + vec4(diffuse*diff + spec, 1.0);
    }
#endif