----------------------------
    -- Camera
----------------------------
local camera = {
    -- Horizontal field of view
    fov = 75,
    
    -- Main canvas
    canvas = love3d.new_canvas(love.graphics.getWidth(), love.graphics.getHeight(), "rgba8", cvar.antialias),
    
	-- Spatial data
    position = cpml.vec3(0, 0, 0),
    rotation = cpml.vec3(0, 0, 0),
    look_at  = cpml.vec3(0, 0, 0),
}

----------------------------
    -- Shader Functions
----------------------------
function camera:send_to_shader(shader)
	-- View Matrix and rotation angles
    local v = cpml.mat4()
    local d = self.look_at - self.position
    v:look_at(v, self.position, self.look_at, -cpml.vec3.unit_y)
    v:translate(v, -self.position)
    
	-- Projection matrix
	local w, h = love.graphics.getDimensions()
	local p = cpml.mat4.from_perspective(self.fov, w/h, 0.1, 1000.0)
    
	-- Update shader uniforms
	shader:send("u_view"      , true, v)
	shader:send("u_projection", true, p)
	shader:send("u_view_direction", {d.x, d.y, d.z})
    
    -- Testing code
    t = (t or 0) + love.timer.getDelta()
    self.position.x = math.sin(t)*4
    self.position.z = math.cos(t)*4
    self.position.y = math.pi/1.5
end

function camera:send_to_skybox(shader)
	-- View Matrix and rotation angles
    local v = cpml.mat4()
    v:look_at(v, self.position, self.look_at, -cpml.vec3.unit_y)
    
	-- Projection matrix
	local w, h = love.graphics.getDimensions()
	local p = cpml.mat4.from_perspective(self.fov, w/h, 0.1, 10.0)
    
	-- Update shader uniforms
    shader:send("u_view", true, v)
	shader:send("u_projection", true, p)
end

return camera