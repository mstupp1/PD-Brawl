-- PD Brawl - A Public Domain Character Trading Card Game
-- Built with LÖVE2D

-- Import modules
local Game = require("src.game")
local UI = require("src.ui")
local AIOpponent = require("src.ai_opponent")

-- Game variables
local game
local ui
local ai
local assets
local isFullscreen = true -- Start in fullscreen mode as set in conf.lua
local vsyncEnabled = true -- Start with vsync enabled as set in conf.lua

function love.load()
    -- Set random seed
    math.randomseed(os.time())
    
    -- Initialize game state
    game = Game.new()
    ui = UI.new(game)
    ai = AIOpponent.new(game)
    
    -- Load assets
    love.graphics.setDefaultFilter("nearest", "nearest")
    assets = {
        fonts = {
            small = love.graphics.newFont(14),
            medium = love.graphics.newFont(20),
            large = love.graphics.newFont(32)
        }
    }
    
    -- Occasionally show AI fourth wall breaking message
    if math.random() < 0.3 then
        ui:showFourthWallMessage(ai:getFourthWallMessage())
    end
end

function love.update(dt)
    game:update(dt)
    ui:update(dt)
    ai:update(dt)
end

function love.draw()
    -- Apply screen shake if active
    if ui.screenShake then
        -- Screen shake effect is handled in the UI
        -- Pass a small dt value to ensure proper decay
        ui:updateScreenShake(0.016) -- Approximately 60fps
    end
    
    -- Draw the UI
    ui:draw()
    
    -- Draw FPS counter in debug mode
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end

function love.mousepressed(x, y, button)
    ui:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    ui:mousereleased(x, y, button)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f" then
        toggleFullscreen()
    elseif key == "v" then
        toggleVsync()
    end
    
    ui:keypressed(key)
end

-- Toggle fullscreen mode
function toggleFullscreen()
    isFullscreen = not isFullscreen
    love.window.setFullscreen(isFullscreen)
    
    -- Resize window to default if exiting fullscreen
    if not isFullscreen then
        love.window.setMode(1280, 720, {resizable = true, vsync = vsyncEnabled and 1 or 0})
    end
    
    -- Update UI for new screen dimensions
    ui:updateCardPositions()
    ui:showMessage(isFullscreen and "Fullscreen mode" or "Windowed mode")
end

-- Toggle vsync
function toggleVsync()
    vsyncEnabled = not vsyncEnabled
    love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {
        fullscreen = isFullscreen,
        fullscreentype = "desktop",
        resizable = true,
        vsync = vsyncEnabled and 1 or 0
    })
    ui:showMessage(vsyncEnabled and "VSync enabled" or "VSync disabled")
end

-- Handle window resize
function love.resize(w, h)
    -- Update UI for new screen dimensions
    ui:updateCardPositions()
end 