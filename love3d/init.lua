--- LÖVE3D.
-- Utilities for working in 3D with LÖVE.
local use_gles       = select(1, love.graphics.getRendererInfo()) == "OpenGL ES"
local opengl         = require((...) .. "/opengl")
local ffi            = require "ffi"

-- Windows needs to use an external SDL, on other systems, we get the symbols for free.
local path = (love.filesystem.isFused() and love.filesystem.getInfo("bin/SDL2.dll")) and "bin/SDL2" or "SDL2"
local sdl  = (love.system.getOS() == "Windows") and ffi.load(path) or ffi.C

-- Get handles for OpenGL
ffi.cdef("void *SDL_GL_GetProcAddress(const char *proc);")
opengl:import(use_gles, sdl.SDL_GL_GetProcAddress)

local l3d = {}

--- Reset LOVE3D state.
function l3d.reset()
	l3d.set_depth_test()
	l3d.set_depth_write()
	l3d.set_culling()
	l3d.set_front_face()
end

--- Set depth writing.
function l3d.set_depth_write(mask)
    local mask = (mask == nil) and true or mask
    assert(type(mask) == "boolean", "set_depth_write expects one parameter of type 'boolean'")
	gl.DepthMask(mask and 1 or 0)
end

--- Set depth test method.
function l3d.set_depth_test(method)
	if not method then
        gl.Disable(GL.DEPTH_TEST)
        return
	end
    
    local methods = {
        greater = GL.GEQUAL,
        equal   = GL.EQUAL,
        less    = GL.LEQUAL,
    }
    assert(methods[method], "Invalid depth test method. Parameter must be one of: 'greater', 'equal', 'less' or unspecified.")
    gl.Enable(GL.DEPTH_TEST)
    gl.DepthFunc(methods[method])
    ;(use_gles and gl.DepthRangef or gl.DepthRange)(0,1)
    ;(use_gles and gl.ClearDepthf or gl.ClearDepth)(1.0)
end

--- Set front face winding.
function l3d.set_front_face(facing)
	if not facing or facing == "ccw" then
		gl.FrontFace(GL.CCW)
		return
	elseif facing == "cw" then
		gl.FrontFace(GL.CW)
		return
	end

	error("Invalid face winding. Parameter must be one of: 'cw', 'ccw' or unspecified.")
end

--- Set culling method.
function l3d.set_culling(method)
	if not method then
		gl.Disable(GL.CULL_FACE)
		return
	end
    
    local methods = {
        back  = GL.BACK,
        front = GL.FRONT,
    }
    assert(methods[method], "Invalid culling method: Parameter must be one of: 'front', 'back' or unspecified")
	gl.Enable(GL.CULL_FACE)
    gl.CullFace(methods[method])
end

--- Create a canvas with a depth buffer.
function l3d.new_canvas(width, height, format, msaa)
	local w, h  = width or love.graphics.getWidth(), height or love.graphics.getHeight()
	local color = love.graphics.newCanvas(w, h, {format = format, msaa = msaa})
	local depth = love.graphics.newCanvas(w, h, {format = "depth24", msaa = msaa})
	return {
        color = color,
        depth = depth,
    }
end

--- Write to a canvas with a depth buffer
function l3d.set_canvas(canvas)
    local arg = canvas and {canvas.color, depthstencil = canvas.depth} or nil
    love.graphics.setCanvas(arg)
end

return l3d