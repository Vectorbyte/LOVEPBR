----------------------------
    -- Initialization
----------------------------
-- Require modules
iqm      = require "iqm"
cpml     = require "cpml"
scene    = require "scene"
love3d   = require "love3d"
renderer = require "renderer"

----------------------------
    -- Main Functions
----------------------------
function love.load()
    -- Load scene data ont renderer
    renderer:init(scene)
end

function love.update(dt)

end

function love.draw()
    -- Clear last frame
    love.graphics.clear(love.graphics.getBackgroundColor())
    love.graphics.origin()
    love.graphics.push("all")

    -- Draw scene
    renderer:draw(scene)
    
    -- Display frame
    love.graphics.pop()
    love.graphics.present()
end

----------------------------
    -- Keyboard Events
----------------------------
function love.keypressed(k)
end

function love.keyreleased(k)
end

----------------------------
    -- Main Loop
----------------------------
function love.run()
    -- RNG seed
    love.math.setRandomSeed(os.time())
    
    -- Load contents
    love.load(arg)
    
	-- We don't want the first frame's dt to include time taken by love.load.
    love.timer.step()
    
	-- Main loop
	while true do
        -- Process events if outside of a transition
        love.event.pump()
        for name, a,b,c,d,e,f in love.event.poll() do
            if name == "quit" then
                if not love.quit or not love.quit() then
                    return a
                end
            end
            love.handlers[name](a,b,c,d,e,f)
        end
        
        -- Delta time step
        local dt = love.timer.step()
        
        -- Update routine
        love.update(dt)
        
        -- Draw the scene
        love.draw()
        
        -- Framelock
        love.timer.sleep(0.001)
	end
end