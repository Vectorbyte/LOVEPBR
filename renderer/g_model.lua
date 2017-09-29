----------------------------
    -- Model Handler
----------------------------
local Model = {
    -- 3D data
    position = cpml.vec3(0, 0, 0),
    rotation = cpml.vec3(0, 0, 0),
    scale    = cpml.vec3(1, 1, 1),
    
    set_position = function(self, x, y, z)
        self.position.x = x or self.position.x
        self.position.y = y or self.position.y
        self.position.z = z or self.position.z
    end,
    
    set_rotation = function(self, x, y, z)
        self.rotation.x = x or self.rotation.x
        self.rotation.y = y or self.rotation.y
        self.rotation.z = z or self.rotation.z
    end,
}
Model.__index = Model

----------------------------
    -- Main Functions
----------------------------
local function send_animation(shader, animation)
    if animation then
		--animation:send_pose(shader, "u_bone_matrices", "u_skinning")
	else
		shader:send("u_skinning", 0)
	end
end

function Model:draw(shader, untextured, animation)
    -- Send animation
    send_animation(shader, animation)
    
	local m = cpml.mat4():identity()
    m:translate(m, self.position)
	m:rotate(m, self.rotation.x, cpml.vec3.unit_x)
	m:rotate(m, self.rotation.y, cpml.vec3.unit_x)
	m:rotate(m, self.rotation.z, cpml.vec3.unit_z)
    m:scale(m, self.scale)
    
	shader:send("u_model", true, m)
    
	for i, buffer in ipairs(self.model) do
        -- Set texture for mesh
        if self.diffuse[i] and not untextured then
            self.model.mesh:setTexture(self.diffuse[i])
            shader:send("normal_map", self.normal[i])
            shader:send("material_map", self.material[i])
            --shader:send("emmissive_map", self.emmissive[i])
        end
		self.model.mesh:setDrawRange(buffer.first, buffer.last)
		love.graphics.draw(self.model.mesh)
	end
end

----------------------------
    -- Constructor
----------------------------
local function new(self, data)
    local model = setmetatable({}, Model)

    model.model     = iqm.load("media/model/" .. data.mesh)
    model.normal    = (type(data.normal) == "table") and data.normal or {data.normal}
    model.diffuse   = (type(data.diffuse) == "table") and data.diffuse or {data.diffuse}
    model.material  = (type(data.material) == "table") and data.material or {data.material}
    model.emmissive = (type(data.emmissive) == "table") and data.emmissive or {data.emmissive}
    
    model.position = data.position
    model.rotation = data.rotation
    model.scale    = data.scale
    
    -- Load images
    local texture = {"normal", "diffuse", "material", "emmissive"}
    for _, k in ipairs(texture) do
        for i, v in ipairs(model[k]) do
            model[k][i] = love.graphics.newImage("media/image/" .. v)
        end
    end
    
    -- Return object
    return model
end

return setmetatable(
	{
		new = new,
	},
	{
        __call = function(...) return new(...) end 
    }
)