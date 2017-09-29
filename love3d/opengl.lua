local ffi = require("ffi")

local function import_gl(openGL)
    local glheader = [[
        typedef double GLdouble;
        typedef unsigned int GLenum;
        typedef unsigned char GLboolean;
        typedef void (APIENTRYP PFNGLDEPTHMASKPROC) (GLboolean flag);
        typedef void (APIENTRYP PFNGLDISABLEPROC) (GLenum cap);
        typedef void (APIENTRYP PFNGLCLEARDEPTHPROC) (GLdouble depth);
        typedef void (APIENTRYP PFNGLDEPTHFUNCPROC) (GLenum func);
        typedef void (APIENTRYP PFNGLDEPTHRANGEPROC) (GLdouble near, GLdouble far);
        typedef void (APIENTRYP PFNGLENABLEPROC) (GLenum cap);
        typedef void (APIENTRYP PFNGLCULLFACEPROC) (GLenum mode);
        typedef void (APIENTRYP PFNGLFRONTFACEPROC) (GLenum mode);
    ]]

    if ffi.os == "Windows" then
        glheader = glheader:gsub("APIENTRYP", "__stdcall *")
    else
        glheader = glheader:gsub("APIENTRYP", "*")
    end
    ffi.cdef(glheader)

    return {
        __index = function(self, name)
            local glname = "gl" .. name
            local procname = "PFNGL" .. name:upper() .. "PROC"
            local func = ffi.cast(procname, openGL.loader(glname))
            rawset(self, name, func)
            return func
        end
    }
end
    
local function import_gles(openGL)
    local glheader = [[
        typedef float GLfloat;
        typedef unsigned int GLenum;
        typedef unsigned char GLboolean;
        GL_APICALL void GL_APIENTRY glClearDepthf (GLfloat d);
        GL_APICALL void GL_APIENTRY glCullFace (GLenum mode);
        GL_APICALL void GL_APIENTRY glDepthFunc (GLenum func);
        GL_APICALL void GL_APIENTRY glDepthMask (GLboolean flag);
        GL_APICALL void GL_APIENTRY glDepthRangef (GLfloat n, GLfloat f);
        GL_APICALL void GL_APIENTRY glDisable (GLenum cap);
        GL_APICALL void GL_APIENTRY glEnable (GLenum cap);
        GL_APICALL void GL_APIENTRY glFrontFace (GLenum mode);
    ]]

    if ffi.os == "Windows" then
        glheader = glheader:gsub("GL_APICALL", "__stdcall")
    else
        glheader = glheader:gsub("GL_APICALL", "")
        glheader = glheader:gsub("GL_APIENTRY", "")
    end
    ffi.cdef(glheader)

    local gles2 = ffi.load(ffi_OpenGLES2_lib or "GLESv2")
    return {
        __index = function(self, name)
            local glname = "gl" .. name
            local func = gles2[glname]
            rawset(self, name, func)
            return func
        end
    }
end

local openGL = {
	GL = {
        EQUAL      = 0x0202, 
        LEQUAL     = 0x0203,
        GEQUAL     = 0x0206,
        FRONT      = 0x0404,
        BACK       = 0x0405,
        CW         = 0x0900,
        CCW        = 0x0901,
        CULL_FACE  = 0x0B44,
        DEPTH_TEST = 0x0B71,
    },
	gl = {},
	import = function(self, use_gles, loader)
        self.loader = loader
		rawset(_G, "GL", self.GL)
		rawset(_G, "gl", self.gl)
        setmetatable(self.gl, (use_gles and import_gles or import_gl)(self))
	end
}

return openGL