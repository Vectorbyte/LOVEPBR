----------------------------
    -- Configuration
---------------------------- 
cvar = {
    anti_alias = 16,
    shadow_res = 2048,
}

----------------------------
    -- Love configuration
----------------------------
function love.conf(t)
    t.identity              = "LÖVE PBR"
    t.version               = "0.11.0"
    t.console               = true
    t.accelerometerjoystick = false
    t.externalstorage       = false
    t.gammacorrect          = false
    
    t.window.title          = "LÖVE PBR"
    t.window.icon           = nil
    t.window.width          = 1280
    t.window.height         = 720
    t.window.borderless     = false
    t.window.resizable      = false
    t.window.fullscreen     = false
    t.window.fullscreentype = "desktop"
    t.window.vsync          = 1
    t.window.msaa           = cvar.anti_alias
    t.window.display        = 1
    t.window.highdpi        = false
    
    -- Disable unneccesary modules
    t.modules.physics       = false
    t.modules.touch         = false
    t.modules.video         = false
end