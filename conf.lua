-- Configuration for PD Brawl
-- Built with LÖVE2D

function love.conf(t)
    t.window.title = "PD Brawl - Public Domain Trading Card Game"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    
    t.version = "11.4" -- Minimum LÖVE version
    
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
    t.modules.thread = false
end 