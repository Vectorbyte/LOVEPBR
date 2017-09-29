----------------------------
    -- Scene
----------------------------
return {
    -- Light defs
    ["directional_light"] = {
        position = {1, 1, 1},
        color = {1, 1, 1, 1},
    },
    
    ["light_probe"] = {
        position = {0, 0, 0},
    
        -- Light probe cubemaps
        reflection = "",
        irradiance = "",
    },
    
    -- Skybox defs
    ["skybox"] = "skybox.jpg",
    
    -- Model defs
    ["model"] = {
        ["utah_teapot"] = {
            -- Mesh data
            mesh = "teapot.iqm",
            
            -- Texture maps
            diffuse   = "default_diffuse.png",
            normal    = "default_normal.png",
            emmissive = "default_emmissive.png",
            material  = "default_material.png",
            
            -- Spatial properties
            position = cpml.vec3(0, 0, 0),
            rotation = cpml.vec3(0, 0, 0),
            scale    = cpml.vec3(1, 1, 1),
        }
    },
}