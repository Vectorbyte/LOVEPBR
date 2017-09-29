----------------------------
    -- Lighting World
----------------------------
local light = {
    directional_light = {},
}

----------------------------
    -- Light Source Functions
----------------------------
function light:init(scene)
    local light = self.directional_light

    -- Reset light tables
    light.position = scene["directional_light"].position or {0, 0, 0}
    light.color    = scene["directional_light"].color or {1, 1, 1, 1}
    light.shadow   = love.graphics.newCanvas(cvar.shadow_res, cvar.shadow_res, {format = "depth24", readable = true})
    light.dummy    = love.graphics.newCanvas(cvar.shadow_res, cvar.shadow_res, {format = "r8"})
    light.shadow:setDepthSampleMode("less")
    light.shadow:setFilter("linear", "linear")
end

----------------------------
    -- Main Functions
----------------------------
function light:send_to_shader(shader)
    -- Send directional light data
    shader:send("directional_light", self.directional_light.position)
    shader:send("directional_color", self.directional_light.color)
end

return light