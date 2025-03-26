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
    ui:draw()
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
    end
    
    ui:keypressed(key)
end 