-- UI module for PD Brawl
local UI = {}
UI.__index = UI

-- UI constants
local CARD_WIDTH = 120
local CARD_HEIGHT = 180
local CARD_CORNER_RADIUS = 10
local CARD_SPACING = 25
local HAND_Y_OFFSET = love.graphics.getHeight() - 220
local FIELD_Y_OFFSET = love.graphics.getHeight() / 2
local ESSENCE_DISPLAY_X = 40
local ESSENCE_DISPLAY_Y = love.graphics.getHeight() - 60
local DECK_DISPLAY_X = love.graphics.getWidth() - 140
local DECK_DISPLAY_Y = love.graphics.getHeight() - 60
local MESSAGE_X = love.graphics.getWidth() / 2
local MESSAGE_Y = love.graphics.getHeight() / 2
local TURN_DISPLAY_X = love.graphics.getWidth() / 2
local TURN_DISPLAY_Y = 30
local ESSENCE_ICON = "💧" -- Using emoji for now, would be replaced with graphic

-- Enhanced color constants with modern color palette
local COLORS = {
    background = {0.05, 0.07, 0.12, 1}, -- Dark blue-gray
    card = {0.9, 0.9, 0.9, 1},
    cardBack = {0.15, 0.2, 0.35, 1}, -- Deep blue
    cardBorder = {0.7, 0.7, 0.7, 1},
    cardShadow = {0, 0, 0, 0.5},
    character = {0.2, 0.6, 0.9, 1}, -- Bright blue
    action = {0.9, 0.4, 0.4, 1}, -- Red
    item = {0.4, 0.9, 0.4, 1}, -- Green
    text = {1, 1, 1, 1},
    textShadow = {0, 0, 0, 0.7},
    highlight = {1, 0.9, 0.2, 1}, -- Yellow
    button = {0.25, 0.35, 0.8, 1}, -- Royal blue
    buttonHover = {0.35, 0.45, 0.9, 1}, -- Lighter blue
    buttonText = {1, 1, 1, 1},
    buttonBorder = {0.4, 0.5, 1, 1},
    essence = {0.3, 0.7, 0.9, 1}, -- Cyan
    healthBar = {0.9, 0.3, 0.3, 1}, -- Red
    healthBarBg = {0.3, 0.3, 0.3, 0.5},
    tableBg = {0.1, 0.15, 0.25, 1}, -- Dark blue play area
    fusion = {0.9, 0.3, 0.9, 1} -- Purple for fusion effects
}

-- Rarity color coding with gradient options
local RARITY_COLORS = {
    common = {{0.8, 0.8, 0.8, 1}, {0.7, 0.7, 0.7, 1}},
    uncommon = {{0.2, 0.8, 0.2, 1}, {0.1, 0.6, 0.1, 1}},
    rare = {{0.2, 0.4, 0.9, 1}, {0.1, 0.2, 0.7, 1}},
    legendary = {{0.9, 0.4, 0.9, 1}, {0.7, 0.2, 0.7, 1}}
}

-- Card style constants
local CARD_TITLE_HEIGHT = 30
local CARD_IMAGE_HEIGHT = 100
local CARD_CONTENT_PADDING = 8

-- Initialize UI
function UI.new(game)
    local ui = {
        game = game,
        background = {
            stars = {},
            speed = 20
        },
        player1HandPositions = {},
        player2HandPositions = {},
        player1FieldPositions = {},
        player2FieldPositions = {},
        player1GraveyardPosition = { x = 50, y = love.graphics.getHeight() - 230 },
        player2GraveyardPosition = { x = love.graphics.getWidth() - 50 - CARD_WIDTH, y = 50 },
        selectedCardIndex = nil,
        selectedFieldIndex = nil,
        animations = {},
        messageTimer = 0,
        message = nil,
        fourthWallTimer = 0,
        fourthWallMessage = nil,
        fourthWallProbability = 0.15, -- Reduced frequency (was implicitly 1.0)
        dragging = {
            active = false,
            sourceType = nil,
            cardIndex = nil,
            card = nil,
            startX = 0,
            startY = 0,
            currentX = 0,
            currentY = 0,
            validDropTarget = nil
        },
        targetingMode = nil,
        fonts = {
            tiny = love.graphics.newFont(8),
            small = love.graphics.newFont(12),
            medium = love.graphics.newFont(16),
            large = love.graphics.newFont(24),
            title = love.graphics.newFont(36)
        },
        endTurnButton = {
            x = love.graphics.getWidth() - 150,
            y = 30,
            width = 120,
            height = 40,
            text = "End Turn",
            action = function() game:endTurn() end,
            hovered = false
        },
        instructionMessage = "Drag cards from hand to play them",
        hoveredCard = {
            active = false,
            type = nil,
            index = nil,
            card = nil
        },
        inspectMode = {
            active = false,
            card = nil
        }
    }
    
    -- Generate some stars for background
    for i = 1, 100 do
        table.insert(ui.background.stars, {
            x = love.math.random(0, love.graphics.getWidth()),
            y = love.math.random(0, love.graphics.getHeight()),
            size = love.math.random(1, 3) / 2
        })
    end
    
    local uiObject = setmetatable(ui, UI)
    
    -- Initialize card positions
    uiObject:updateCardPositions()
    
    return uiObject
end

-- Update card positions based on game state
function UI:updateCardPositions()
    -- Calculate hand positions for player 1
    local screenWidth = love.graphics.getWidth()
    local player1HandY = love.graphics.getHeight() - 150
    
    -- Clear previous positions
    self.player1HandPositions = {}
    
    -- Calculate spacing based on number of cards
    local player1 = self.game.players[1]
    local numCards = #player1.hand
    local totalWidth = numCards * CARD_WIDTH
    if numCards > 1 then
        totalWidth = totalWidth + (numCards - 1) * 20 -- Add spacing between cards
    end
    
    local startX = (screenWidth - totalWidth) / 2
    
    -- Set positions for each card in hand
    for i = 1, numCards do
        self.player1HandPositions[i] = {
            x = startX + (i - 1) * (CARD_WIDTH + 20),
            y = player1HandY
        }
    end
    
    -- Calculate hand positions for player 2 (AI)
    local player2HandY = 50
    
    -- Clear previous positions
    self.player2HandPositions = {}
    
    -- Calculate spacing based on number of cards
    local player2 = self.game.players[2]
    local numCards = #player2.hand
    local totalWidth = numCards * CARD_WIDTH
    if numCards > 1 then
        totalWidth = totalWidth + (numCards - 1) * 20 -- Add spacing between cards
    end
    
    startX = (screenWidth - totalWidth) / 2
    
    -- Set positions for each card in hand
    for i = 1, numCards do
        self.player2HandPositions[i] = {
            x = startX + (i - 1) * (CARD_WIDTH + 20),
            y = player2HandY
        }
    end
    
    -- Calculate field positions for player 1
    local player1FieldY = love.graphics.getHeight() - 300
    
    -- Clear previous positions
    self.player1FieldPositions = {}
    
    -- Calculate spacing for a maximum of 5 cards
    local maxFieldCards = 5
    local fieldCardSpacing = 20
    local totalFieldWidth = maxFieldCards * CARD_WIDTH + (maxFieldCards - 1) * fieldCardSpacing
    local fieldStartX = (screenWidth - totalFieldWidth) / 2
    
    -- Set positions for each potential field slot
    for i = 1, maxFieldCards do
        self.player1FieldPositions[i] = {
            x = fieldStartX + (i - 1) * (CARD_WIDTH + fieldCardSpacing),
            y = player1FieldY
        }
    end
    
    -- Calculate field positions for player 2
    local player2FieldY = 200
    
    -- Clear previous positions
    self.player2FieldPositions = {}
    
    -- Set positions for each potential field slot
    for i = 1, maxFieldCards do
        self.player2FieldPositions[i] = {
            x = fieldStartX + (i - 1) * (CARD_WIDTH + fieldCardSpacing),
            y = player2FieldY
        }
    end
end

-- Update UI state
function UI:update(dt)
    -- Update message timer
    if self.messageTimer > 0 then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then
            self.message = nil
        end
    end
    
    -- Update fourth wall message timer
    if self.fourthWallTimer > 0 then
        self.fourthWallTimer = self.fourthWallTimer - dt
        if self.fourthWallTimer <= 0 then
            self.fourthWallMessage = nil
        end
    end
    
    -- Update background stars (parallax effect)
    for _, star in ipairs(self.background.stars) do
        star.y = star.y + self.background.speed * dt * star.size
        if star.y > love.graphics.getHeight() then
            star.y = 0
            star.x = love.math.random(0, love.graphics.getWidth())
        end
    end
    
    -- Update screen shake effect
    if self.screenShake and self.screenShake.timer > 0 then
        self.screenShake.timer = self.screenShake.timer - dt
        if self.screenShake.timer <= 0 then
            self.screenShake = nil
        end
    end
    
    -- Update card positions if game state has changed
    self:updateCardPositions()
    
    -- Update animations
    local i = 1
    while i <= #self.animations do
        local anim = self.animations[i]
        anim.timer = anim.timer - dt
        if anim.timer <= 0 then
            table.remove(self.animations, i)
        else
            i = i + 1
        end
    end
    
    -- Update button states
    self:updateEndTurnButton()
    
    -- Update drag and drop feedback
    if self.dragging.active then
        self:updateDragAndDropState()
    end
    
    -- Update hover state
    self:updateHoverState()
    
    -- Reset inspect mode if clicking outside the card
    if love.mouse.isDown(1) and self.inspectMode.active then
        local mouseX, mouseY = love.mouse.getPosition()
        local cardRect = self:getInspectCardRect()
        if not self:pointInRect(mouseX, mouseY, cardRect) then
            self.inspectMode.active = false
        end
    end
end

-- Update end turn button state
function UI:updateEndTurnButton()
    -- Check if mouse is hovering over button
    local btn = self.endTurnButton
    local mouseX, mouseY = love.mouse.getPosition()
    btn.hovered = mouseX >= btn.x and mouseX <= btn.x + btn.width and
                  mouseY >= btn.y and mouseY <= btn.y + btn.height
end

-- Draw end turn button
function UI:drawEndTurnButton()
    local btn = self.endTurnButton
    
    -- Draw button background with hover effect
    if btn.hovered then
        love.graphics.setColor(0.3, 0.7, 0.3)
    else
        love.graphics.setColor(0.2, 0.5, 0.2)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5, 5)
    
    -- Draw button border
    love.graphics.setColor(0.1, 0.3, 0.1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5, 5)
    
    -- Draw button text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    
    local textX = btn.x + btn.width/2 - self.fonts.medium:getWidth(btn.text)/2
    local textY = btn.y + btn.height/2 - self.fonts.medium:getHeight()/2
    
    love.graphics.print(btn.text, textX, textY)
    
    -- Add pulsing effect if it's the player's turn and they have no more moves
    if self.game.currentPlayer == 1 and not self.dragging.active then
        local player = self.game.players[1]
        local hasPlayableCards = false
        
        -- Check if player has any playable cards based on essence cost
        for i, card in ipairs(player.hand) do
            local cost = card.essence or 0
            if player.essence >= cost then
                hasPlayableCards = true
                break
            end
        end
        
        -- Check if any cards on field can attack
        for _, card in ipairs(player.field) do
            if card.type == "character" and not card.hasAttacked then
                hasPlayableCards = true
                break
            end
        end
        
        -- If no more playable moves, add pulsing effect to end turn button
        if not hasPlayableCards then
            love.graphics.setColor(1, 1, 1, 0.2 + 0.1 * math.sin(love.timer.getTime() * 3))
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5, 5)
        end
    end
end

-- Draw the whole UI
function UI:draw()
    -- Draw starry background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw stars
    for _, star in ipairs(self.background.stars) do
        local size = star.size * 2
        love.graphics.setColor(1, 1, 1, star.size * 0.5)
        love.graphics.circle("fill", star.x, star.y, size)
    end
    
    -- Draw player and opponent areas
    love.graphics.setColor(0.15, 0.15, 0.2, 0.5)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 200, love.graphics.getWidth(), 200)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), 200)
    
    -- Draw mid-field divider (nicer styling)
    love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
    love.graphics.setLineWidth(3)
    love.graphics.line(0, love.graphics.getHeight() / 2, love.graphics.getWidth(), love.graphics.getHeight() / 2)
    
    -- Draw player stats
    self:drawPlayerStats(1) -- Player
    self:drawPlayerStats(2) -- AI opponent
    
    -- Draw player hands
    self:drawPlayerHand(1) -- Player
    self:drawPlayerHand(2) -- AI opponent
    
    -- Draw player fields
    self:drawPlayerField(1) -- Player
    self:drawPlayerField(2) -- AI opponent
    
    -- Draw graveyards
    self:drawGraveyard(1) -- Player
    self:drawGraveyard(2) -- AI opponent
    
    -- Draw end turn button
    self:drawEndTurnButton()
    
    -- Draw current player indicator
    self:drawCurrentPlayerIndicator()
    
    -- Draw instruction message
    self:drawInstructionMessage()
    
    -- Draw current message (if any)
    self:drawMessage()
    
    -- Draw fourth wall message (if any)
    self:drawFourthWallMessage()
    
    -- Draw game help and tips
    self:drawGameHelpPanel()
    
    -- Draw turn counter and essence reminder
    self:drawTurnCounter()
    
    -- Draw win condition reminder
    self:drawWinConditionReminder()
    
    -- Draw animations
    self:drawAnimations()
    
    -- Draw dragging feedback (if dragging)
    if self.dragging.active then
        self:drawDraggingCard()
    end
    
    -- Draw inspect mode if active (should be on top of everything)
    self:drawInspectMode()
end

-- Draw game help panel with controls and tips
function UI:drawGameHelpPanel()
    -- Only show help panel in first few turns
    if self.game.currentTurn <= 3 then
        local helpX = 10
        local helpY = love.graphics.getHeight() / 2 - 75
        local helpWidth = 200
        local helpHeight = 150
        
        -- Draw background panel
        love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
        love.graphics.rectangle("fill", helpX, helpY, helpWidth, helpHeight, 10, 10)
        
        -- Draw border
        love.graphics.setColor(0.3, 0.5, 0.8, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", helpX, helpY, helpWidth, helpHeight, 10, 10)
        
        -- Draw header
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.setFont(self.fonts.medium)
        love.graphics.print("Game Controls", helpX + 10, helpY + 10)
        
        -- Draw tips
        love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
        love.graphics.setFont(self.fonts.small)
        
        local tips = {
            "• Drag cards to play them",
            "• Drag character to field",
            "• Drag character onto opponent to attack",
            "• Drag character onto character to fuse",
            "• Items can be attached to characters",
            "• Press 'F' to toggle fullscreen",
            "• Defeat 3 enemy cards to win"
        }
        
        for i, tip in ipairs(tips) do
            love.graphics.print(tip, helpX + 15, helpY + 35 + (i - 1) * 15)
        end
    end
end

-- Draw turn counter
function UI:drawTurnCounter()
    local turn = self.game.currentTurn
    local turnX = love.graphics.getWidth() - 100
    local turnY = love.graphics.getHeight() / 2 - 15
    
    -- Draw turn counter background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
    love.graphics.rectangle("fill", turnX - 10, turnY - 5, 90, 30, 5, 5)
    
    -- Draw turn text
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.print("Turn: " .. turn, turnX, turnY)
end

-- Draw win condition reminder
function UI:drawWinConditionReminder()
    -- Place near the center
    local x = love.graphics.getWidth() - 220
    local y = love.graphics.getHeight() / 2 + 20
    
    -- Draw reminder  if it's the player's turn
    if self.game.currentPlayer == 1 then
        -- Draw win progress for player
        local defeatedCount = self.game.players[1].defeatedEnemyCount or 0
        local neededToWin = 3
        
        -- Draw progress background
        love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
        love.graphics.rectangle("fill", x - 10, y - 5, 210, 30, 5, 5)
        
        -- Draw progress text
        love.graphics.setColor(0.9, 0.9, 1, 0.9)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("Win progress: " .. defeatedCount .. "/" .. neededToWin .. " opponents", x, y)
        
        -- Draw progress bar
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        love.graphics.rectangle("fill", x, y + 20, 190, 10, 3, 3)
        
        -- Draw filled progress
        local fillWidth = (defeatedCount / neededToWin) * 190
        love.graphics.setColor(0.3, 0.6, 0.9, 0.8)
        love.graphics.rectangle("fill", x, y + 20, fillWidth, 10, 3, 3)
    end
end

-- Draw background starfield
function UI:drawBackground()
    for _, star in ipairs(self.background.stars) do
        love.graphics.setColor(1, 1, 1, star.alpha)
        love.graphics.rectangle("fill", star.x, star.y, star.size, star.size)
    end
end

-- Draw the game table
function UI:drawGameTable()
    -- Draw the main play area
    love.graphics.setColor(COLORS.tableBg)
    love.graphics.rectangle(
        "fill", 
        love.graphics.getWidth() * 0.05, 
        love.graphics.getHeight() * 0.15, 
        love.graphics.getWidth() * 0.9, 
        love.graphics.getHeight() * 0.7,
        20, 20
    )
    
    -- Draw player 1 area
    love.graphics.setColor(0.15, 0.2, 0.4, 0.3)
    love.graphics.rectangle(
        "fill",
        love.graphics.getWidth() * 0.05,
        FIELD_Y_OFFSET + 20,
        love.graphics.getWidth() * 0.9,
        love.graphics.getHeight() * 0.35,
        20, 20
    )
    
    -- Draw player 2 area
    love.graphics.setColor(0.4, 0.2, 0.15, 0.3)
    love.graphics.rectangle(
        "fill",
        love.graphics.getWidth() * 0.05,
        love.graphics.getHeight() * 0.15,
        love.graphics.getWidth() * 0.9,
        FIELD_Y_OFFSET - love.graphics.getHeight() * 0.15 - 20,
        20, 20
    )
    
    -- Draw dividing line
    love.graphics.setColor(0.6, 0.6, 0.6, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.line(
        love.graphics.getWidth() * 0.05,
        FIELD_Y_OFFSET,
        love.graphics.getWidth() * 0.95,
        FIELD_Y_OFFSET
    )
end

-- Draw text with shadow effect
function UI:drawTextWithShadow(text, x, y, color, shadowColor, align)
    -- Draw the shadow
    love.graphics.setColor(shadowColor)
    if align == "center" then
        love.graphics.printf(text, x - 200 + 2, y + 2, 400, align)
    else
        love.graphics.print(text, x + 2, y + 2)
    end
    
    -- Draw the text
    love.graphics.setColor(color)
    if align == "center" then
        love.graphics.printf(text, x - 200, y, 400, align)
    else
        love.graphics.print(text, x, y)
    end
end

-- Draw player hand
function UI:drawPlayerHand(playerIndex)
    local player = self.game.players[playerIndex]
    local positions = self["player" .. playerIndex .. "HandPositions"]
    
    for i, card in ipairs(player.hand) do
        local pos = positions[i]
        if pos then
            -- Check if this is the current player
            if playerIndex == self.game.currentPlayer then
                -- Check if card is hovered
                local isHovered = self.hoveredCard.active and 
                                  self.hoveredCard.type == "hand" and 
                                  self.hoveredCard.index == i
                
                -- Draw glow effect for hovered cards
                if isHovered then
                    for j = 1, 5 do
                        love.graphics.setColor(1, 1, 0.5, (5-j) * 0.05)
                        self:drawRoundedRectangle(
                            pos.x - j*2, 
                            pos.y - j*2 - 5, -- Lift card up slightly
                            CARD_WIDTH + j*4, 
                            CARD_HEIGHT + j*4, 
                            CARD_CORNER_RADIUS + j
                        )
                    end
                    
                    -- Draw magnifying glass icon
                    love.graphics.setColor(1, 1, 1, 0.9)
                    love.graphics.circle("line", pos.x + CARD_WIDTH - 20, pos.y + 20, 10)
                    love.graphics.setLineWidth(2)
                    love.graphics.line(pos.x + CARD_WIDTH - 14, pos.y + 26, pos.x + CARD_WIDTH - 7, pos.y + 33)
                end
                
                -- Determine if this card is selected
                local isSelected = (self.selectedCardIndex == i)
                
                -- Draw the card (use hover state for visual feedback)
                self:drawEnhancedCard(card, pos.x, pos.y, isHovered)
                
                -- Add essence cost indicator
                if card.essence then
                    local canPlay = player.essence >= (card.essence or 0)
                    local essenceColor = canPlay and {0.2, 0.8, 0.2} or {0.8, 0.2, 0.2}
                    
                    -- Draw essence indicator
                    love.graphics.setColor(essenceColor)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", pos.x + CARD_WIDTH - 15, pos.y + 15, 14)
                end
            else
                -- Draw card back for opponent
                love.graphics.setColor(0.3, 0.3, 0.6)
                self:drawRoundedRectangle(pos.x, pos.y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS)
                
                -- Draw pattern on back
                love.graphics.setColor(0.2, 0.2, 0.5)
                for y = pos.y + 10, pos.y + CARD_HEIGHT - 10, 10 do
                    love.graphics.line(pos.x + 10, y, pos.x + CARD_WIDTH - 10, y)
                end
                for x = pos.x + 10, pos.x + CARD_WIDTH - 10, 10 do
                    love.graphics.line(x, pos.y + 10, x, pos.y + CARD_HEIGHT - 10)
                end
                
                -- Draw border
                love.graphics.setColor(0.4, 0.4, 0.7)
                love.graphics.setLineWidth(2)
                self:drawRoundedRectangle(pos.x, pos.y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS, true)
            end
        end
    end
end

-- Draw opponent's hand (face down)
function UI:drawOpponentHand()
    for i, pos in ipairs(self.player2HandPositions) do
        self:drawCardBack(pos.x, pos.y)
    end
end

-- Draw an enhanced card with color and styling
function UI:drawEnhancedCard(card, x, y, highlighted)
    local cardWidth = CARD_WIDTH
    local cardHeight = CARD_HEIGHT
    
    -- If card is being hovered, lift it slightly
    if highlighted then
        y = y - 5
    end
    
    -- Draw card shadow with perspective
    love.graphics.setColor(0, 0, 0, 0.4)
    self:drawRoundedRectangle(x + 5, y + 7, cardWidth, cardHeight - 2, CARD_CORNER_RADIUS)
    
    -- Get card background color based on type
    local bgColor = {0.9, 0.9, 0.9}
    
    if card.type == "character" then
        bgColor = {0.7, 0.9, 1}  -- Blue for character
    elseif card.type == "action" then
        bgColor = {0.9, 0.7, 0.7}  -- Red for action
    elseif card.type == "item" then
        bgColor = {0.7, 0.9, 0.7}  -- Green for item
    end
    
    -- Apply rarity color modifiers
    if card.rarity == "rare" then
        -- Add a slight gold tint for rare cards
        bgColor[1] = math.min(1, bgColor[1] * 1.1)
        bgColor[2] = math.min(1, bgColor[2] * 1.05)
        bgColor[3] = math.max(0, bgColor[3] * 0.9)
    elseif card.rarity == "legendary" then
        -- Add a purple tint for legendary cards
        bgColor[1] = math.min(1, bgColor[1] * 1.05)
        bgColor[2] = math.max(0, bgColor[2] * 0.8)
        bgColor[3] = math.min(1, bgColor[3] * 1.1)
    end
    
    -- Brighten background color if highlighted
    if highlighted then
        bgColor[1] = math.min(1, bgColor[1] * 1.2)
        bgColor[2] = math.min(1, bgColor[2] * 1.2)
        bgColor[3] = math.min(1, bgColor[3] * 1.2)
    end
    
    -- Draw card background with gradient
    for i = 0, cardHeight do
        local t = i / cardHeight
        local r = bgColor[1] * (1 - t * 0.2)
        local g = bgColor[2] * (1 - t * 0.2)
        local b = bgColor[3] * (1 - t * 0.2)
        
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", x, y + i, cardWidth, 1)
    end
    
    -- Add rounded corners
    love.graphics.setColor(bgColor)
    self:drawRoundedRectangle(x, y, cardWidth, cardHeight, CARD_CORNER_RADIUS)
    
    -- Draw card border based on rarity
    local borderColor = {0.3, 0.3, 0.3} -- default
    
    if card.rarity == "uncommon" then
        borderColor = {0.2, 0.8, 0.2} -- green
    elseif card.rarity == "rare" then
        borderColor = {0.9, 0.8, 0.2} -- gold
    elseif card.rarity == "legendary" then
        borderColor = {0.8, 0.3, 0.9} -- purple
    end
    
    -- Brighten border if highlighted
    if highlighted then
        borderColor[1] = math.min(1, borderColor[1] * 1.3)
        borderColor[2] = math.min(1, borderColor[2] * 1.3) 
        borderColor[3] = math.min(1, borderColor[3] * 1.3)
    end
    
    -- Draw glowing border for legendary cards
    if card.rarity == "legendary" then
        for i = 3, 1, -1 do
            love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 0.3 - (i * 0.05))
            love.graphics.setLineWidth(2 + i)
            self:drawRoundedRectangle(x, y, cardWidth, cardHeight, CARD_CORNER_RADIUS, true)
        end
    end
    
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(2)
    self:drawRoundedRectangle(x, y, cardWidth, cardHeight, CARD_CORNER_RADIUS, true)
    
    -- Draw card title background (dark gradient bar)
    love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
    love.graphics.rectangle("fill", x, y, cardWidth, 26, CARD_CORNER_RADIUS, CARD_CORNER_RADIUS)
    
    -- Draw name with shadow for better readability
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.setFont(self.fonts.small)
    local nameWidth = cardWidth - 30
    love.graphics.printf(card.name, x + 11, y + 7, nameWidth, "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(card.name, x + 10, y + 6, nameWidth, "center")
    
    -- Draw card type with icon
    local typeIcons = {
        character = "♟",
        action = "⚡",
        item = "🧰"
    }
    
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(0.8, 0.8, 0.8)
    local typeText = (typeIcons[card.type] or "") .. " " .. card.type:gsub("^%l", string.upper)
    love.graphics.printf(typeText, x + 10, y + 30, nameWidth, "center")
    
    -- Draw essence cost with nice styling
    if card.essenceCost then
        -- Draw essence circle with glow effect
        love.graphics.setColor(0.9, 0.7, 0.2, 0.3)
        love.graphics.circle("fill", x + cardWidth - 15, y + 15, 15)
        
        love.graphics.setColor(0.9, 0.7, 0.2)
        love.graphics.circle("fill", x + cardWidth - 15, y + 15, 12)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("line", x + cardWidth - 15, y + 15, 12)
        
        -- Draw essence cost value
        love.graphics.setFont(self.fonts.medium)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(card.essenceCost, x + cardWidth - 25, y + 8)
        
        -- Draw essence cost value with shadow
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(card.essenceCost, x + cardWidth - 26, y + 7)
    elseif card.essence then
        -- For backward compatibility with cards using essence property
        -- Draw essence circle with glow effect
        love.graphics.setColor(0.9, 0.7, 0.2, 0.3)
        love.graphics.circle("fill", x + cardWidth - 15, y + 15, 15)
        
        love.graphics.setColor(0.9, 0.7, 0.2)
        love.graphics.circle("fill", x + cardWidth - 15, y + 15, 12)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.circle("line", x + cardWidth - 15, y + 15, 12)
        
        -- Draw essence cost value
        love.graphics.setFont(self.fonts.medium)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(card.essence, x + cardWidth - 25, y + 8)
        
        -- Draw essence cost value with shadow
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(card.essence, x + cardWidth - 26, y + 7)
    end
    
    -- Draw character portrait area with border
    love.graphics.setColor(0.2, 0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", x + 9, y + 44, cardWidth - 18, 52)
    
    love.graphics.setColor(0.85, 0.85, 0.85)
    love.graphics.rectangle("fill", x + 10, y + 45, cardWidth - 20, 50)
    
    -- Draw art variant indicator
    if card.artVariant then
        local artLabels = {
            standard = "",
            vintage = "VINTAGE",
            fusion = "FUSION",
            parody = "PARODY",
            classic = "CLASSIC"
        }
        
        if artLabels[card.artVariant] and artLabels[card.artVariant] ~= "" then
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", x + 10, y + 45, cardWidth - 20, 15)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.tiny)
            love.graphics.printf(artLabels[card.artVariant], x + 10, y + 47, cardWidth - 20, "center")
        end
        
        -- Draw placeholder portrait based on art variant
        love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
        if card.artVariant == "vintage" then
            -- Draw old film style dots
            for i = 0, 4 do
                for j = 0, 6 do
                    love.graphics.circle("fill", x + 18 + i * 20, y + 55 + j * 6, 1)
                end
            end
        elseif card.artVariant == "fusion" then
            -- Draw fusion energy pattern
            for i = 1, 5 do
                love.graphics.setColor(0.6, 0.2, 0.8, 0.2)
                local pulseSize = 3 + math.sin(love.timer.getTime() * 2 + i) * 2
                love.graphics.circle("fill", 
                    x + cardWidth/2, 
                    y + 70, 
                    25 + pulseSize
                )
            end
        elseif card.artVariant == "parody" then
            -- Draw comic style lines
            love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
            for i = 1, 7 do
                love.graphics.line(
                    x + 10, y + 50 + i * 7,
                    x + cardWidth - 20, y + 50 + i * 7
                )
            end
        end
    end
    
    -- Draw card stats for character cards
    if card.type == "character" then
        self:drawCardStats(card, x, y)
    end
    
    -- Draw abilities
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.fonts.tiny)
    
    -- Display actual abilities if present
    local textY = y + 105
    if card.abilities and #card.abilities > 0 then
        love.graphics.setColor(0.2, 0.2, 0.2)
        local abilitiesText = "Abilities: " .. table.concat(card.abilities, ", ")
        local wrappedText = self:wrapText(abilitiesText, cardWidth - 20, self.fonts.tiny)
        love.graphics.printf(wrappedText, x + 10, textY, cardWidth - 20, "left")
    elseif card.ability then
        -- Fallback to old ability text
        local wrappedText = self:wrapText(card.ability, cardWidth - 20, self.fonts.tiny)
        love.graphics.printf(wrappedText, x + 10, textY, cardWidth - 20, "left")
    end
    
    -- Draw flavor text at the bottom with quotation marks and styling
    if card.flavorText then
        love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
        local flavorY = y + cardHeight - 32
        
        -- Draw background for flavor text
        local flavorHeight = 25
        love.graphics.rectangle("fill", x + 5, flavorY - 2, cardWidth - 10, flavorHeight, 3, 3)
        
        love.graphics.setColor(0.8, 0.8, 0.8)
        local flavorText = '"' .. card.flavorText .. '"'
        local wrappedFlavorText = self:wrapText(flavorText, cardWidth - 20, self.fonts.tiny)
        love.graphics.printf(wrappedFlavorText, x + 10, flavorY, cardWidth - 20, "center")
    end
    
    -- If card has an attack indicator (for character cards that have already attacked)
    if card.type == "character" and card.hasAttacked then
        -- Draw attack used indicator
        love.graphics.setColor(0.7, 0.2, 0.2, 0.7)
        love.graphics.circle("fill", x + 20, y + 20, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.print("✗", x + 17, y + 14)
    end
    
    -- Draw rarity indicator with stars
    local rarityIcons = {
        common = "",
        uncommon = "★",
        rare = "★★",
        legendary = "★★★"
    }
    
    if card.rarity and rarityIcons[card.rarity] and rarityIcons[card.rarity] ~= "" then
        love.graphics.setColor(1, 0.9, 0.2)
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.print(rarityIcons[card.rarity], x + 8, y + 8)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw card stats (HP bar and attack value)
function UI:drawCardStats(card, x, y)
    -- Draw HP bar background with gradient border
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    local barY = y + 155
    love.graphics.rectangle("fill", x + 9, barY - 1, CARD_WIDTH - 18, 12, 4, 4)
    
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", x + 10, barY, CARD_WIDTH - 20, 10, 3, 3)
    
    -- Draw HP bar fill
    local hpPercent = card.hp / card.maxHp
    hpPercent = math.max(0, math.min(1, hpPercent))
    
    -- Color based on HP percentage with gradient
    local healthColor = {0.2, 0.8, 0.2} -- Green
    local healthColorEnd = {0.3, 0.9, 0.3} -- Lighter green
    
    if hpPercent < 0.3 then
        healthColor = {0.8, 0.2, 0.2} -- Red
        healthColorEnd = {1.0, 0.3, 0.3} -- Lighter red
    elseif hpPercent < 0.6 then
        healthColor = {0.8, 0.7, 0.2} -- Yellow
        healthColorEnd = {1.0, 0.9, 0.3} -- Lighter yellow
    end
    
    -- Draw gradient HP bar
    local barWidth = (CARD_WIDTH - 20) * hpPercent
    for i = 0, barWidth do
        local t = i / barWidth
        local r = healthColor[1] * (1-t) + healthColorEnd[1] * t
        local g = healthColor[2] * (1-t) + healthColorEnd[2] * t
        local b = healthColor[3] * (1-t) + healthColorEnd[3] * t
        
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", x + 10 + i, barY, 1, 10)
    end
    
    -- Add pulsing effect for low health
    if hpPercent < 0.25 then
        local pulseAlpha = 0.3 + 0.2 * math.sin(love.timer.getTime() * 5)
        love.graphics.setColor(0.9, 0.2, 0.2, pulseAlpha)
        love.graphics.rectangle("fill", x + 10, barY, barWidth, 10, 3, 3)
    end
    
    -- Draw HP text with background for better readability
    local hpText = math.floor(card.hp) .. "/" .. card.maxHp
    local hpTextWidth = self.fonts.tiny:getWidth("HP: " .. hpText)
    
    -- Draw text background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x + 15 - 2, barY - 15 - 2, hpTextWidth + 4, 14, 3, 3)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.print("HP: " .. hpText, x + 15, barY - 15)
    
    -- Draw attack power with icon and background
    local powerText = tostring(card.power)
    local powerTextWidth = self.fonts.tiny:getWidth("⚔️" .. powerText)
    
    -- Draw power text background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x + CARD_WIDTH - 38 - 2, barY - 15 - 2, powerTextWidth + 4, 14, 3, 3)
    
    -- Draw attack icon with animation for powerful characters
    if card.power >= 30 then
        local shineAlpha = 0.4 + 0.2 * math.sin(love.timer.getTime() * 3)
        love.graphics.setColor(1, 0.8, 0.2, shineAlpha)
        love.graphics.circle("fill", x + CARD_WIDTH - 30, barY - 8, 10)
    end
    
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("⚔️", x + CARD_WIDTH - 38, barY - 15)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(powerText, x + CARD_WIDTH - 25, barY - 15)
end

-- Draw card with gradient background
function UI:drawCardWithGradient(x, y, baseColor)
    -- Create gradient colors
    local topColor = {baseColor[1] * 1.2, baseColor[2] * 1.2, baseColor[3] * 1.2, baseColor[4]}
    local bottomColor = {baseColor[1] * 0.8, baseColor[2] * 0.8, baseColor[3] * 0.8, baseColor[4]}
    
    -- Clamp colors to valid range
    for i = 1, 3 do
        topColor[i] = math.min(1, topColor[i])
        bottomColor[i] = math.min(1, bottomColor[i])
    end
    
    -- Draw card base with rounded corners
    self:drawRoundedRectangle(x, y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS)
    
    -- Draw gradient overlay
    love.graphics.setColor(topColor)
    for i = 0, CARD_HEIGHT do
        local t = i / CARD_HEIGHT
        local r = topColor[1] * (1 - t) + bottomColor[1] * t
        local g = topColor[2] * (1 - t) + bottomColor[2] * t
        local b = topColor[3] * (1 - t) + bottomColor[3] * t
        local a = topColor[4] * (1 - t) + bottomColor[4] * t
        
        love.graphics.setColor(r, g, b, a)
        love.graphics.rectangle("fill", 
            x, 
            y + i, 
            CARD_WIDTH, 
            1
        )
    end
    
    -- Draw card border
    love.graphics.setColor(COLORS.cardBorder)
    love.graphics.setLineWidth(2)
    self:drawRoundedRectangle(x, y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS, true)
end

-- Draw card back (for opponent's hand)
function UI:drawCardBack(x, y)
    -- Draw card shadow
    love.graphics.setColor(COLORS.cardShadow)
    self:drawRoundedRectangle(x + 4, y + 4, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS)
    
    -- Draw card base
    love.graphics.setColor(COLORS.cardBack)
    self:drawRoundedRectangle(x, y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS)
    
    -- Draw card pattern
    love.graphics.setColor(0.2, 0.3, 0.5, 1)
    for i = 1, 5 do
        for j = 1, 7 do
            love.graphics.circle("fill", 
                x + (CARD_WIDTH / 6) * i, 
                y + (CARD_HEIGHT / 8) * j, 
                3
            )
        end
    end
    
    -- Draw card border
    love.graphics.setColor(COLORS.cardBorder)
    love.graphics.setLineWidth(2)
    self:drawRoundedRectangle(x, y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS, true)
    
    -- Draw PD Brawl logo placeholder
    love.graphics.setColor(0.8, 0.8, 0.9, 0.8)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf("PD Brawl", x, y + CARD_HEIGHT/2 - 10, CARD_WIDTH, "center")
end

-- Draw rounded rectangle
function UI:drawRoundedRectangle(x, y, width, height, radius, outline)
    local mode = outline and "line" or "fill"
    love.graphics.rectangle(mode, x, y, width, height, radius, radius)
end

-- Draw player field
function UI:drawPlayerField(playerIndex)
    local player = self.game.players[playerIndex]
    local positions = self["player" .. playerIndex .. "FieldPositions"]
    
    for i, card in ipairs(player.field) do
        local pos = positions[i]
        if pos then
            -- Determine if this card is selected
            local isSelected = (self.selectedFieldIndex == i and playerIndex == self.game.currentPlayer)
            
            -- Check if card is hovered
            local isHovered = self.hoveredCard.active and 
                              self.hoveredCard.type == ("field" .. playerIndex) and 
                              self.hoveredCard.index == i
            
            -- Hover effect
            if isHovered then
                -- Draw glow effect
                for j = 1, 5 do
                    love.graphics.setColor(1, 1, 0.5, (5-j) * 0.05)
                    self:drawRoundedRectangle(
                        pos.x - j*2, 
                        pos.y - j*2 - 5, -- Lift card up slightly
                        CARD_WIDTH + j*4, 
                        CARD_HEIGHT + j*4, 
                        CARD_CORNER_RADIUS + j
                    )
                end
                
                -- Draw magnifying glass icon
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.circle("line", pos.x + CARD_WIDTH - 20, pos.y + 20, 10)
                love.graphics.setLineWidth(2)
                love.graphics.line(pos.x + CARD_WIDTH - 14, pos.y + 26, pos.x + CARD_WIDTH - 7, pos.y + 33)
                
                -- Draw card at slightly elevated position
                self:drawEnhancedCard(card, pos.x, pos.y - 5, isHovered)
            else
                -- Draw card normally
                self:drawEnhancedCard(card, pos.x, pos.y, isSelected)
            end
            
            -- Add visual indicator if card has already attacked
            if card.hasAttacked then
                love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
                love.graphics.rectangle("fill", pos.x, pos.y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS)
                
                if playerIndex == 1 then
                    love.graphics.setColor(0.7, 0.2, 0.2, 0.8)
                    love.graphics.setFont(self.fonts.small)
                    love.graphics.printf("Already attacked", 
                        pos.x, pos.y + CARD_HEIGHT/2 - 10, CARD_WIDTH, "center")
                end
            end
        end
    end
end

-- Draw player resources (essence and deck)
function UI:drawPlayerResources(playerIndex)
    local player = self.game.players[playerIndex]
    local x, y
    
    if playerIndex == 1 then
        x, y = ESSENCE_DISPLAY_X, ESSENCE_DISPLAY_Y
    else
        x, y = ESSENCE_DISPLAY_X, 60
    end
    
    -- Draw essence count with glowing effect
    love.graphics.setFont(self.fonts.large)
    
    -- Glow effect
    love.graphics.setColor(COLORS.essence[1], COLORS.essence[2], COLORS.essence[3], 0.3)
    love.graphics.circle("fill", x + 15, y + 5, 30)
    
    -- Get max essence (defaults to 10 if not specified)
    local maxEssence = player.maxEssence or 10
    
    self:drawTextWithShadow(
        ESSENCE_ICON .. " " .. player.essence .. "/" .. maxEssence,
        x,
        y,
        COLORS.essence,
        COLORS.textShadow
    )
    
    -- Draw deck count
    if playerIndex == 1 then
        x, y = DECK_DISPLAY_X, DECK_DISPLAY_Y
    else
        x, y = DECK_DISPLAY_X, 60
    end
    
    -- Draw deck icon
    love.graphics.setColor(COLORS.cardBack)
    self:drawRoundedRectangle(x - 40, y - 10, 30, 40, 3)
    love.graphics.setColor(COLORS.cardBorder)
    love.graphics.setLineWidth(1)
    self:drawRoundedRectangle(x - 40, y - 10, 30, 40, 3, true)
    
    -- Draw count
    love.graphics.setFont(self.fonts.medium)
    self:drawTextWithShadow(
        "Deck: " .. #player.deck,
        x,
        y,
        COLORS.text,
        COLORS.textShadow
    )
end

-- Draw animations (simplified)
function UI:drawAnimations()
    -- Simplified animation system for now
end

-- Add click effect at the specified position
function UI:addClickEffect(x, y)
    -- Simplified for now
end

-- Add attack animation
function UI:addAttackAnimation(startX, startY, endX, endY, damage)
    -- Simplified for now
end

-- Add screen shake effect
function UI:addScreenShake(duration, intensity)
    -- Simplified for now
end

-- Show a message
function UI:showMessage(text, duration)
    self.message = text
    self.messageTimer = duration or 2
end

-- Show fourth wall message with reduced frequency
function UI:showFourthWallMessage(text, duration)
    -- Only show the message if random value is less than probability threshold
    if math.random() < self.fourthWallProbability then
        self.fourthWallMessage = text
        self.fourthWallTimer = duration or 3
    end
end

-- Add animation
function UI:addAnimation(animation)
    table.insert(self.animations, animation)
end

-- Handle mouse press
function UI:mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Handle inspect mode clicking
    if self.inspectMode.active then
        -- Check for close button click
        local cardRect = self:getInspectCardRect()
        local closeX = cardRect.x + cardRect.width - 20
        local closeY = cardRect.y + 20
        local closeRadius = 15
        
        local dx = closeX - x
        local dy = closeY - y
        local distSq = dx * dx + dy * dy
        
        if distSq <= closeRadius * closeRadius then
            self.inspectMode.active = false
            return
        end
        
        -- Clicking anywhere else in inspect mode just keeps it open
        return
    end
    
    -- Check magnifying glass icon click for hovered card
    if self.hoveredCard.active and self.hoveredCard.card then
        local pos
        if self.hoveredCard.type == "hand" then
            pos = self.player1HandPositions[self.hoveredCard.index]
        elseif self.hoveredCard.type == "field1" then
            pos = self.player1FieldPositions[self.hoveredCard.index]
        elseif self.hoveredCard.type == "field2" then
            pos = self.player2FieldPositions[self.hoveredCard.index]
        end
        
        if pos then
            -- Check if click is within magnifying glass icon area
            local iconX = pos.x + CARD_WIDTH - 20
            local iconY = pos.y + 20
            local radius = 15
            
            local dx = iconX - x
            local dy = iconY - y
            local distSq = dx * dx + dy * dy
            
            if distSq <= radius * radius then
                -- Activate inspect mode
                self.inspectMode = {
                    active = true,
                    card = self.hoveredCard.card
                }
                return
            end
        end
    end
    
    -- Check end turn button click
    local btn = self.endTurnButton
    if x >= btn.x and x <= btn.x + btn.width and
       y >= btn.y and y <= btn.y + btn.height then
        btn.action()
        self:addClickEffect(x, y)
        return
    end
    
    -- Handle targeting mode
    if self.targetingMode then
        self:handleTargeting(x, y)
        return
    end
    
    -- Check if clicking on a card in hand (for drag and drop)
    local handCardIndex = self:getClickedHandCardIndex(x, y)
    if handCardIndex and self.game.currentPlayer == 1 then
        -- Start dragging a card from hand
        local card = self.game.players[1].hand[handCardIndex]
        local pos = self.player1HandPositions[handCardIndex]
        
        self.dragging = {
            active = true,
            sourceType = "hand",
            cardIndex = handCardIndex,
            card = card,
            startX = pos.x + CARD_WIDTH/2,
            startY = pos.y + CARD_HEIGHT/2,
            currentX = x,
            currentY = y,
            validDropTarget = nil
        }
        
        self:addClickEffect(x, y)
        return
    end
    
    -- Check if clicking on a card in field (for drag and drop attacking)
    local fieldCardIndex = self:getClickedFieldCardIndex(x, y, 1)
    if fieldCardIndex and self.game.currentPlayer == 1 then
        -- Start dragging a card from field
        local card = self.game.players[1].field[fieldCardIndex]
        local pos = self.player1FieldPositions[fieldCardIndex]
        
        -- Only allow dragging if the card hasn't attacked yet
        if not card.hasAttacked then
            self.dragging = {
                active = true,
                sourceType = "field",
                cardIndex = fieldCardIndex,
                card = card,
                startX = pos.x + CARD_WIDTH/2,
                startY = pos.y + CARD_HEIGHT/2,
                currentX = x,
                currentY = y,
                validDropTarget = nil
            }
            
            self:addClickEffect(x, y)
            return
        else
            -- If card has already attacked, just show a message
            self:showMessage("This card has already attacked this turn")
            self:addClickEffect(x, y)
            return
        end
    end
    
    -- If clicking empty space, deselect
    self.selectedCardIndex = nil
    self.selectedFieldIndex = nil
    self.instructionMessage = "Drag cards from hand to play them"
end

-- Handle mouse release
function UI:mousereleased(x, y, button)
    if button ~= 1 then return end
    
    -- Handle drag and drop
    if self.dragging.active then
        -- Process the drop action
        if self.dragging.validDropTarget then
            if self.dragging.sourceType == "hand" and self.dragging.validDropTarget == "field" then
                -- Play the card from hand to field
                self:playSelectedCard(self.dragging.cardIndex)
            elseif self.dragging.sourceType == "field" and self.dragging.validDropTarget.type == "attack" then
                -- Attack with the card from field
                local targetData = self.dragging.validDropTarget
                self:attackWithSelectedCard(targetData.cardIndex, self.dragging.cardIndex)
            elseif self.dragging.sourceType == "hand" and self.dragging.validDropTarget.type == "fusion" then
                -- Perform fusion with the card from hand
                self:performFusion(self.dragging.cardIndex, self.dragging.validDropTarget.cardIndex)
            end
        end
        
        -- Clear dragging state
        self.dragging.active = false
        self.instructionMessage = "Drag cards from hand to play them"
        
        -- Make sure we clear any selections
        self.selectedCardIndex = nil
        self.selectedFieldIndex = nil
        
        return
    end
end

-- Update screen shake effect with reliable termination
function UI:updateScreenShake(dt)
    if self.screenShake then
        if dt == 0 then
            -- Just apply the effect without updating timer (for initial draw)
            local progress = self.screenShake.timer / self.screenShake.duration
            local intensity = self.screenShake.intensity * progress
            local offsetX = love.math.random(-intensity, intensity)
            local offsetY = love.math.random(-intensity, intensity)
            love.graphics.translate(offsetX, offsetY)
            return
        end
        
        -- Update timer
        self.screenShake.timer = self.screenShake.timer - dt
        
        -- Force terminate if timer has been active too long (failsafe)
        if self.screenShake.duration > 0.5 or self.screenShake.timer < -0.1 then
            self.screenShake = nil
            love.graphics.translate(0, 0)
            return
        end
        
        if self.screenShake.timer <= 0 then
            -- Clear the screen shake
            self.screenShake = nil
            love.graphics.translate(0, 0)
        else
            -- Apply the shake effect
            local progress = self.screenShake.timer / self.screenShake.duration
            local intensity = self.screenShake.intensity * progress
            local offsetX = love.math.random(-intensity, intensity)
            local offsetY = love.math.random(-intensity, intensity)
            love.graphics.translate(offsetX, offsetY)
        end
    end
end

-- Draw dragged card
function UI:drawDraggedCard()
    -- Draw a semi-transparent version of the card being dragged
    if self.dragging.card then
        love.graphics.setColor(1, 1, 1, 0.8)
        local centerX = self.dragging.currentX - CARD_WIDTH/2
        local centerY = self.dragging.currentY - CARD_HEIGHT/2
        
        -- Draw the card 
        self:drawEnhancedCard(self.dragging.card, centerX, centerY, false)
        
        -- Draw drop target indicator
        if self.dragging.validDropTarget then
            if self.dragging.validDropTarget == "field" then
                -- Draw highlight on player's field
                love.graphics.setColor(0.3, 0.9, 0.3, 0.5)
                love.graphics.rectangle(
                    "fill", 
                    love.graphics.getWidth() * 0.2, 
                    FIELD_Y_OFFSET + 50, 
                    love.graphics.getWidth() * 0.6, 
                    150,
                    10, 10
                )
            elseif self.dragging.validDropTarget.type == "attack" then
                -- Draw attack target highlight
                local targetIndex = self.dragging.validDropTarget.cardIndex
                local pos = self.player2FieldPositions[targetIndex]
                
                if pos then
                    love.graphics.setColor(1, 0.2, 0.2, 0.5)
                    self:drawRoundedRectangle(pos.x - 5, pos.y - 5, 
                        CARD_WIDTH + 10, CARD_HEIGHT + 10, CARD_CORNER_RADIUS + 2)
                    
                    -- Draw attack line
                    love.graphics.setColor(1, 0.5, 0, 0.7)
                    love.graphics.setLineWidth(3)
                    love.graphics.line(
                        self.dragging.startX, 
                        self.dragging.startY,
                        self.dragging.currentX,
                        self.dragging.currentY
                    )
                end
            elseif self.dragging.validDropTarget.type == "fusion" then
                -- Draw fusion target highlight
                local targetIndex = self.dragging.validDropTarget.cardIndex
                local pos = self.player1FieldPositions[targetIndex]
                
                if pos then
                    -- Purple glow for fusion target
                    love.graphics.setColor(COLORS.fusion[1], COLORS.fusion[2], COLORS.fusion[3], 0.5)
                    self:drawRoundedRectangle(pos.x - 5, pos.y - 5, 
                        CARD_WIDTH + 10, CARD_HEIGHT + 10, CARD_CORNER_RADIUS + 2)
                    
                    -- Draw fusion connection line
                    love.graphics.setColor(COLORS.fusion[1], COLORS.fusion[2], COLORS.fusion[3], 0.7)
                    love.graphics.setLineWidth(3)
                    
                    -- Draw zigzag fusion line
                    local startX = self.dragging.startX
                    local startY = self.dragging.startY
                    local endX = pos.x + CARD_WIDTH/2
                    local endY = pos.y + CARD_HEIGHT/2
                    local segments = 8
                    local amplitude = 10
                    
                    for i = 0, segments do
                        local t1 = i / segments
                        local t2 = (i + 1) / segments
                        local x1 = startX + (endX - startX) * t1
                        local y1 = startY + (endY - startY) * t1
                        local x2 = startX + (endX - startX) * t2
                        local y2 = startY + (endY - startY) * t2
                        
                        -- Add zigzag pattern
                        if i % 2 == 0 then
                            y1 = y1 + amplitude
                            y2 = y2 - amplitude
                        else
                            y1 = y1 - amplitude
                            y2 = y2 + amplitude
                        end
                        
                        love.graphics.line(x1, y1, x2, y2)
                    end
                end
            end
        end
    end
end

-- Handle targeting for action and item cards
function UI:handleTargeting(x, y)
    -- Check if clicked on a valid target
    local targetInfo = {}
    
    -- For player 1 field
    local fieldIndex = self:getClickedFieldCardIndex(x, y, 1)
    if fieldIndex then
        targetInfo.playerIndex = 1
        targetInfo.cardIndex = fieldIndex
        targetInfo.zone = "field"
    end
    
    -- For player 2 field
    if not targetInfo.cardIndex then
        fieldIndex = self:getClickedFieldCardIndex(x, y, 2)
        if fieldIndex then
            targetInfo.playerIndex = 2
            targetInfo.cardIndex = fieldIndex
            targetInfo.zone = "field"
        end
    end
    
    -- If no valid target was clicked, cancel targeting
    if not targetInfo.cardIndex then
        self.targetingMode = false
        self:showMessage("Targeting canceled")
        return
    end
    
    -- Make sure the card is still available
    if not self.selectedCardIndex or not self.game.players[1].hand[self.selectedCardIndex] then
        self.targetingMode = false
        self:showMessage("Card not available")
        return
    end
    
    -- Apply the card effect
    local card = self.game.players[1].hand[self.selectedCardIndex]
    local target = self.game.players[targetInfo.playerIndex].field[targetInfo.cardIndex]
    
    -- Make sure both card and target are valid
    if not card or not target then
        self.targetingMode = false
        self:showMessage("Invalid card or target")
        return
    end
    
    local success, message
    if card.type == "action" then
        -- Execute action card effect
        success, message = card.effect(card, target, self.game)
    elseif card.type == "item" then
        -- Attach item to target
        -- This is simplified; would need proper implementation
        success, message = card.effect(card, target, self.game)
    end
    
    if success then
        -- Remove card from hand
        self.game.players[1]:removeCardFromHand(self.selectedCardIndex)
        
        -- Deduct essence cost
        self.game.players[1]:useEssence(card.essenceCost)
        
        self:showMessage(message or "Card effect applied")
        
        -- Show fourth wall message if applicable
        local quote = card:getFourthWallQuote("play")
        if quote then
            self:showFourthWallMessage(quote)
        end
    else
        self:showMessage(message or "Unable to apply card effect")
    end
    
    -- Exit targeting mode
    self.targetingMode = false
    self.selectedCardIndex = nil
end

-- Enter fusion mode
function UI:enterFusionMode()
    local player = self.game.players[1]
    local baseCard = player.field[self.selectedFieldIndex]
    
    if not baseCard then
        self:showMessage("Select a base card first")
        return
    end
    
    -- Get valid fusion targets
    local validTargets = player:getValidFusionTargets(self.selectedFieldIndex)
    
    if #validTargets == 0 then
        self:showMessage("No valid fusion materials in hand")
        return
    end
    
    -- Here we would implement the interface for selecting fusion materials
    -- For simplicity, just use the first valid target
    local materialIndices = {validTargets[1]}
    
    -- Perform fusion
    local success, message = self.game:fusionSummon(1, self.selectedFieldIndex, materialIndices)
    
    if success then
        self:showMessage(message or "Fusion successful!")
        
        -- Show fourth wall message
        local fusedCard = player.field[self.selectedFieldIndex]
        local quote = fusedCard:getFourthWallQuote("fusion")
        if quote then
            self:showFourthWallMessage(quote)
        end
        
        self.selectedFieldIndex = nil
    else
        self:showMessage(message or "Fusion failed")
    end
end

-- Get index of card clicked in hand
function UI:getClickedHandCardIndex(x, y)
    for i, pos in ipairs(self.player1HandPositions) do
        if x >= pos.x and x <= pos.x + CARD_WIDTH and
           y >= pos.y and y <= pos.y + CARD_HEIGHT then
            return i
        end
    end
    return nil
end

-- Get index of card clicked in field
function UI:getClickedFieldCardIndex(x, y, playerIndex)
    local positions = playerIndex == 1 and self.player1FieldPositions or self.player2FieldPositions
    
    for i, pos in ipairs(positions) do
        if x >= pos.x and x <= pos.x + CARD_WIDTH and
           y >= pos.y and y <= pos.y + CARD_HEIGHT then
            return i
        end
    end
    return nil
end

-- Play the selected card
function UI:playSelectedCard(cardIndex)
    local player = self.game.players[1]
    local index = cardIndex or self.selectedCardIndex
    
    if not index or not player.hand[index] then return end
    
    local card = player.hand[index]
    local essenceCost = card.essenceCost or card.cost or 0
    
    -- Check if player has enough essence
    if player.essence < essenceCost then
        self:showMessage("Not enough essence to play this card!")
        return
    end
    
    -- Add card play animation
    local handPos = self.player1HandPositions[index]
    local fieldCount = #player.field
    local targetX, targetY
    
    if fieldCount > 0 then
        -- Calculate position based on where card would go on field
        local fieldWidth = (fieldCount + 1) * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING
        local startX = (love.graphics.getWidth() - fieldWidth) / 2
        targetX = startX + fieldCount * (CARD_WIDTH + CARD_SPACING)
        targetY = FIELD_Y_OFFSET + 120
    else
        -- First card on field
        targetX = love.graphics.getWidth()/2 - CARD_WIDTH/2
        targetY = FIELD_Y_OFFSET + 120
    end
    
    -- Add animation
    table.insert(self.animations, {
        type = "cardPlay",
        x = handPos.x,
        y = handPos.y,
        targetX = targetX,
        targetY = targetY,
        timer = 0.5,
        duration = 0.5
    })
    
    -- If card needs a target, enter targeting mode
    if card.type == "action" or card.type == "item" then
        self.targetingMode = true
        self.selectedCardIndex = index -- Make sure we track which card is being targeted
        self:showMessage("Select a target for " .. card.name)
        return
    end
    
    -- Otherwise play the card directly
    local success, message = self.game:playCard(1, index)
    
    if success then
        self:showMessage(message or "Card played successfully")
        
        -- Show fourth wall message if applicable
        local quote = card.getFourthWallQuote and card:getFourthWallQuote("play")
        if quote then
            self:showFourthWallMessage(quote)
        end
        
        self.selectedCardIndex = nil
        self.instructionMessage = "Drag cards from hand to play them"
    else
        self:showMessage(message or "Unable to play card")
    end
end

-- Attack with the selected card
function UI:attackWithSelectedCard(targetIndex, attackerIndex)
    local player = self.game.players[1]
    local cardIndex = attackerIndex or self.selectedFieldIndex
    
    if not cardIndex or not player.field[cardIndex] then return end
    
    local card = player.field[cardIndex]
    
    -- Check if card has already attacked
    if card.hasAttacked then
        self:showMessage("This card has already attacked this turn")
        return
    end
    
    -- Get positions for animation
    local startPos = self.player1FieldPositions[cardIndex]
    local endPos = self.player2FieldPositions[targetIndex]
    
    if startPos and endPos then
        -- Pass the attack damage to the animation
        self:addAttackAnimation(
            startPos.x + CARD_WIDTH/2, 
            startPos.y + CARD_HEIGHT/2,
            endPos.x + CARD_WIDTH/2,
            endPos.y + CARD_HEIGHT/2,
            card.power,
            0.5
        )
    end
    
    -- Perform attack
    local success, message = self.game:attackCard(
        1, 
        cardIndex, 
        2, 
        targetIndex
    )
    
    if success then
        card.hasAttacked = true
        self:showMessage(message or "Attack successful")
        
        -- Show fourth wall message if applicable
        local quote = card.getFourthWallQuote and card:getFourthWallQuote("attack")
        if quote then
            self:showFourthWallMessage(quote)
        end
        
        -- Screen shake effect (limited to 0.3 seconds)
        self:addScreenShake(0.3, 5)
        
        -- Check win condition
        if self.game:checkWinCondition() then
            self:showMessage("Player 1 wins!")
        end
        
        self.selectedFieldIndex = nil
        self.instructionMessage = "Drag cards from hand to play them"
    else
        self:showMessage(message or "Unable to attack")
    end
end

-- Update drag and drop state
function UI:updateDragAndDropState()
    local mouseX, mouseY = love.mouse.getPosition()
    self.dragging.currentX = mouseX
    self.dragging.currentY = mouseY
    
    -- Reset valid drop target
    self.dragging.validDropTarget = nil
    
    -- Check for valid drop targets
    if self.dragging.sourceType == "hand" then
        local card = self.dragging.card
        local essenceCost = card.essenceCost or card.essence or card.cost or 0
        
        -- First check if the card is being dragged onto another card for fusion
        local targetFieldIndex = self:getClickedFieldCardIndex(mouseX, mouseY, 1)
        if targetFieldIndex and self.game.players[1].essence >= 2 then
            -- Check if fusion is possible
            local fieldCard = self.game.players[1].field[targetFieldIndex]
            if fieldCard and fieldCard.type == "character" and card.type == "character" then
                -- This is a valid fusion target
                self.dragging.validDropTarget = {
                    type = "fusion",
                    cardIndex = targetFieldIndex
                }
                
                -- Check for specific fusion combinations to show better messages
                local specialCombos = {
                    ["Sailor Popeye"] = {
                        ["Can of Spinach"] = "Spinach-Power Fusion! Release to create Spinach-Powered Popeye"
                    },
                    ["Sherlock Holmes"] = {
                        ["Deerstalker Hat"] = "Elementary Fusion! Release to enhance Sherlock Holmes"
                    }
                }
                
                if specialCombos[fieldCard.name] and specialCombos[fieldCard.name][card.name] then
                    self.instructionMessage = specialCombos[fieldCard.name][card.name]
                else
                    self.instructionMessage = "Release to fuse cards: " .. fieldCard.name .. " + " .. card.name
                end
                
                -- Add particle effect to indicate fusion possibility 
                self:addFusionParticles(
                    self.player1FieldPositions[targetFieldIndex].x + CARD_WIDTH/2,
                    self.player1FieldPositions[targetFieldIndex].y + CARD_HEIGHT/2,
                    mouseX,
                    mouseY
                )
                
                return
            end
        end
        
        -- Special case for item cards
        if card.type == "item" and targetFieldIndex and self.game.players[1].essence >= essenceCost then
            local fieldCard = self.game.players[1].field[targetFieldIndex]
            if fieldCard and fieldCard.type == "character" then
                -- This is a valid item target
                self.dragging.validDropTarget = {
                    type = "attachment",
                    cardIndex = targetFieldIndex
                }
                self.instructionMessage = "Release to attach " .. card.name .. " to " .. fieldCard.name
                return
            end
        end
        
        -- Special case for action cards
        if card.type == "action" and self.game.players[1].essence >= essenceCost then
            -- Action cards can target either player's field
            local p1TargetIndex = self:getClickedFieldCardIndex(mouseX, mouseY, 1)
            local p2TargetIndex = self:getClickedFieldCardIndex(mouseX, mouseY, 2)
            
            if p1TargetIndex then
                self.dragging.validDropTarget = {
                    type = "action",
                    playerIndex = 1,
                    cardIndex = p1TargetIndex
                }
                self.instructionMessage = "Release to use " .. card.name .. " on your card"
                return
            elseif p2TargetIndex then
                self.dragging.validDropTarget = {
                    type = "action",
                    playerIndex = 2,
                    cardIndex = p2TargetIndex
                }
                self.instructionMessage = "Release to use " .. card.name .. " on opponent's card"
                return
            end
        end
        
        -- If not fusion or item/action, check if card can be played to field
        if self.game.players[1].essence >= essenceCost then
            -- Check if mouse is over the player's field area
            if mouseY > FIELD_Y_OFFSET + 50 and mouseY < FIELD_Y_OFFSET + 200 then
                -- Check for available field space (max 5 cards)
                if #self.game.players[1].field < 5 then
                    self.dragging.validDropTarget = "field"
                    
                    if card.type == "character" then
                        self.instructionMessage = "Release to play " .. card.name .. " to the field"
                    else
                        self.instructionMessage = "Release to play " .. card.name
                    end
                    
                    -- Add visual effect to show field placement
                    love.graphics.setColor(0.3, 0.9, 0.3, 0.5 + 0.2 * math.sin(love.timer.getTime() * 5))
                    love.graphics.circle("fill", mouseX, mouseY, 10)
                else
                    self.instructionMessage = "Field is full (max 5 cards)"
                end
            else
                if card.type == "character" then
                    self.instructionMessage = "Drag to your field to play character"
                else
                    self.instructionMessage = "Drag to a valid target"
                end
            end
        else
            self.instructionMessage = "Need " .. essenceCost .. " essence to play (you have " .. self.game.players[1].essence .. ")"
        end
    elseif self.dragging.sourceType == "field" then
        -- For cards on field, valid targets are opponent's cards
        local card = self.dragging.card
        
        -- Only allow dragging if the card hasn't attacked yet
        if not card.hasAttacked and self.game.currentPlayer == 1 then
            -- Check if mouse is over an opponent's card
            local targetIndex = self:getClickedFieldCardIndex(mouseX, mouseY, 2)
            if targetIndex then
                local targetCard = self.game.players[2].field[targetIndex]
                if targetCard then
                    self.dragging.validDropTarget = {
                        type = "attack",
                        playerIndex = 2,
                        cardIndex = targetIndex
                    }
                    
                    -- Show target's stats in the message for better feedback
                    self.instructionMessage = "Attack " .. targetCard.name .. " (" .. 
                        targetCard.hp .. " HP, " .. targetCard.power .. " ATK) with " .. 
                        card.name .. " (" .. card.power .. " ATK)"
                    
                    -- Add attack line with animation
                    love.graphics.setColor(1, 0.3, 0.2, 0.7)
                    love.graphics.setLineWidth(3)
                    
                    -- Draw zigzag attack line for visual flair
                    local startX = self.dragging.startX
                    local startY = self.dragging.startY
                    local segments = 6
                    local amplitude = 4 + 2 * math.sin(love.timer.getTime() * 10)
                    
                    for i = 0, segments - 1 do
                        local t1 = i / segments
                        local t2 = (i + 1) / segments
                        
                        local x1 = startX + (mouseX - startX) * t1
                        local y1 = startY + (mouseY - startY) * t1
                        
                        local x2 = startX + (mouseX - startX) * t2
                        local y2 = startY + (mouseY - startY) * t2
                        
                        -- Add zigzag effect
                        if i % 2 == 0 then
                            y1 = y1 + amplitude
                            y2 = y2 - amplitude
                        else
                            y1 = y1 - amplitude
                            y2 = y2 + amplitude
                        end
                        
                        love.graphics.line(x1, y1, x2, y2)
                    end
                    
                    -- Add attack sparkles
                    for i = 1, 3 do
                        local sparkX = mouseX + math.random(-15, 15)
                        local sparkY = mouseY + math.random(-15, 15)
                        local sparkSize = math.random(2, 5)
                        
                        love.graphics.setColor(1, 0.5, 0.2, 0.8)
                        love.graphics.circle("fill", sparkX, sparkY, sparkSize)
                    end
                end
            else
                self.instructionMessage = "Drag to an opponent's card to attack"
            end
        else
            self.instructionMessage = "This card has already attacked this turn"
        end
    end
end

-- Add fusion particle effects
function UI:addFusionParticles(x1, y1, x2, y2)
    -- Draw fusion energy particles between the cards
    love.graphics.setLineWidth(2)
    for i = 1, 5 do
        local t = love.timer.getTime() * 3 + i
        local dx = (x2 - x1) * 0.5
        local dy = (y2 - y1) * 0.5
        
        -- Create a pulsing effect
        local pulse = math.sin(t) * 0.4 + 0.6
        
        -- Draw energy lines
        love.graphics.setColor(0.8, 0.2, 0.9, pulse * 0.7)
        love.graphics.line(
            x1 + dx * math.sin(t * 0.7),
            y1 + dy * math.cos(t * 0.7),
            x2 - dx * math.cos(t * 0.7),
            y2 - dy * math.sin(t * 0.7)
        )
        
        -- Draw some sparkles
        love.graphics.setColor(1, 0.7, 1, pulse)
        local midX = (x1 + x2) / 2 + math.cos(t) * 15
        local midY = (y1 + y2) / 2 + math.sin(t) * 15
        love.graphics.circle("fill", midX, midY, 3 + math.sin(t * 2) * 2)
    end
end

-- Add fusion animation
function UI:addFusionAnimation(baseCardX, baseCardY, materialCardX, materialCardY, duration)
    local centerX = (baseCardX + materialCardX) / 2
    local centerY = (baseCardY + materialCardY) / 2
    
    -- Add particles flying from both cards to center
    for i = 1, 20 do
        table.insert(self.animations, {
            type = "fusionParticle",
            startX = baseCardX + love.math.random(0, CARD_WIDTH),
            startY = baseCardY + love.math.random(0, CARD_HEIGHT),
            endX = centerX,
            endY = centerY,
            speed = love.math.random(100, 300),
            size = love.math.random(3, 8),
            timer = duration or 1.0,
            duration = duration or 1.0
        })
        
        table.insert(self.animations, {
            type = "fusionParticle",
            startX = materialCardX + love.math.random(0, CARD_WIDTH),
            startY = materialCardY + love.math.random(0, CARD_HEIGHT),
            endX = centerX,
            endY = centerY,
            speed = love.math.random(100, 300),
            size = love.math.random(3, 8),
            timer = duration or 1.0,
            duration = duration or 1.0
        })
    end
    
    -- Add explosion at center
    table.insert(self.animations, {
        type = "fusionExplosion",
        x = centerX,
        y = centerY,
        size = 0,
        maxSize = 150,
        timer = duration or 1.0,
        duration = duration or 1.0
    })
    
    -- Add screen shake
    self:addScreenShake(0.3, 5)
end

-- Perform fusion
function UI:performFusion(handCardIndex, fieldCardIndex)
    local player = self.game.players[1]
    local handCard = player.hand[handCardIndex]
    local fieldCard = player.field[fieldCardIndex]
    
    -- Check if player has enough essence
    if player.essence < 2 then
        self:showMessage("Not enough essence for fusion (requires 2)")
        return
    end
    
    -- Check if fusion is valid
    if handCard.type ~= "character" or fieldCard.type ~= "character" then
        self:showMessage("Fusion requires two character cards")
        return
    end
    
    -- Get positions for fusion animation
    local handPos = self.player1HandPositions[handCardIndex]
    local fieldPos = self.player1FieldPositions[fieldCardIndex]
    
    -- Add fusion animation
    self:addFusionAnimation(
        handPos.x, 
        handPos.y, 
        fieldPos.x, 
        fieldPos.y, 
        1.0
    )
    
    -- Add screen shake effect
    self:addScreenShake(0.3, 5)
    
    -- Perform the fusion operation
    local materialIndices = {handCardIndex}
    local success, message = self.game:fusionSummon(1, fieldCardIndex, materialIndices)
    
    if success then
        -- Add more spectacular effects after fusion completes
        for i = 1, 30 do
            -- Add particles exploding outward
            local angle = math.random() * math.pi * 2
            local distance = math.random(50, 150)
            local speed = math.random(100, 300)
            local size = math.random(3, 10)
            
            table.insert(self.animations, {
                type = "fusionParticle",
                startX = fieldPos.x + CARD_WIDTH/2,
                startY = fieldPos.y + CARD_HEIGHT/2,
                endX = fieldPos.x + CARD_WIDTH/2 + math.cos(angle) * distance,
                endY = fieldPos.y + CARD_HEIGHT/2 + math.sin(angle) * distance,
                speed = speed,
                size = size,
                timer = 0.7,
                duration = 0.7
            })
        end
        
        self:showMessage(message or "Fusion successful!")
        
        -- Show fourth wall message
        local fusedCard = player.field[fieldCardIndex]
        local quote = fusedCard.getFourthWallQuote and fusedCard:getFourthWallQuote("fusion")
        if quote then
            self:showFourthWallMessage(quote)
        end
    else
        self:showMessage(message or "Fusion failed")
    end
end

-- Handle key press
function UI:keypressed(key)
    -- No action needed, space no longer ends turn
    -- We'll handle all game interactions through mouse now
end

-- Wrap text to fit within a given width
function UI:wrapText(text, width, font)
    if not text then return "" end
    
    local wrappedText = ""
    local spaceWidth = font:getWidth(" ")
    local line = ""
    local lineWidth = 0
    
    for word in text:gmatch("%S+") do
        local wordWidth = font:getWidth(word)
        
        if lineWidth + wordWidth < width then
            if lineWidth > 0 then
                line = line .. " " .. word
                lineWidth = lineWidth + spaceWidth + wordWidth
            else
                line = word
                lineWidth = wordWidth
            end
        else
            wrappedText = wrappedText .. line .. "\n"
            line = word
            lineWidth = wordWidth
        end
    end
    
    wrappedText = wrappedText .. line
    return wrappedText
end

-- Update hover state
function UI:updateHoverState()
    local x, y = love.mouse.getPosition()
    
    -- Skip if currently dragging
    if self.dragging.active then
        self.hoveredCard.active = false
        return
    end
    
    -- Check player hand
    if self.game.currentPlayer == 1 then
        for i, pos in ipairs(self.player1HandPositions) do
            if x >= pos.x and x <= pos.x + CARD_WIDTH and
               y >= pos.y and y <= pos.y + CARD_HEIGHT then
                self.hoveredCard = {
                    active = true,
                    type = "hand",
                    index = i,
                    card = self.game.players[1].hand[i]
                }
                return
            end
        end
    end
    
    -- Check player 1 field
    for i, pos in ipairs(self.player1FieldPositions) do
        if i <= #self.game.players[1].field and
           x >= pos.x and x <= pos.x + CARD_WIDTH and
           y >= pos.y and y <= pos.y + CARD_HEIGHT then
            self.hoveredCard = {
                active = true,
                type = "field1",
                index = i,
                card = self.game.players[1].field[i]
            }
            return
        end
    end
    
    -- Check player 2 field
    for i, pos in ipairs(self.player2FieldPositions) do
        if i <= #self.game.players[2].field and
           x >= pos.x and x <= pos.x + CARD_WIDTH and
           y >= pos.y and y <= pos.y + CARD_HEIGHT then
            self.hoveredCard = {
                active = true,
                type = "field2",
                index = i,
                card = self.game.players[2].field[i]
            }
            return
        end
    end
    
    -- If we get here, mouse is not over any card
    self.hoveredCard.active = false
end

-- Draw inspect mode overlay
function UI:drawInspectMode()
    if not self.inspectMode.active then return end
    
    -- Darken the background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Get the card rect
    local cardRect = self:getInspectCardRect()
    
    -- Draw enlarged card
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw card background
    local cardType = self.inspectMode.card.type
    local backgroundColor = {0.9, 0.9, 0.9}
    
    if cardType == "character" then
        backgroundColor = {0.7, 0.9, 1}  -- Blue for character
    elseif cardType == "action" then
        backgroundColor = {0.9, 0.7, 0.7}  -- Red for action
    elseif cardType == "item" then
        backgroundColor = {0.7, 0.9, 0.7}  -- Green for item
    end
    
    -- Draw shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    self:drawRoundedRectangle(cardRect.x + 10, cardRect.y + 10, cardRect.width, cardRect.height, 15)
    
    -- Draw card background
    love.graphics.setColor(backgroundColor)
    self:drawRoundedRectangle(cardRect.x, cardRect.y, cardRect.width, cardRect.height, 15)
    
    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setLineWidth(3)
    self:drawRoundedRectangle(cardRect.x, cardRect.y, cardRect.width, cardRect.height, 15, true)
    
    -- Draw card name
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.fonts.large)
    love.graphics.printf(self.inspectMode.card.name, 
        cardRect.x + 20, cardRect.y + 20, cardRect.width - 40, "center")
    
    -- Draw card type
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf(self.inspectMode.card.type:gsub("^%l", string.upper), 
        cardRect.x + 20, cardRect.y + 70, cardRect.width - 40, "center")
    
    -- Draw essence cost
    if self.inspectMode.card.essence then
        love.graphics.setFont(self.fonts.medium)
        love.graphics.printf("Essence Cost: " .. self.inspectMode.card.essence, 
            cardRect.x + 20, cardRect.y + 100, cardRect.width - 40, "center")
    end
    
    -- Draw HP for character cards
    if self.inspectMode.card.type == "character" then
        love.graphics.setFont(self.fonts.medium)
        love.graphics.printf("HP: " .. self.inspectMode.card.hp .. "/" .. self.inspectMode.card.maxHp, 
            cardRect.x + 20, cardRect.y + 130, cardRect.width - 40, "center")
        love.graphics.printf("Power: " .. self.inspectMode.card.power, 
            cardRect.x + 20, cardRect.y + 160, cardRect.width - 40, "center")
    end
    
    -- Draw card ability
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf("Ability:", 
        cardRect.x + 20, cardRect.y + 200, cardRect.width - 40, "left")
    
    love.graphics.setFont(self.fonts.small)
    local wrappedText = self:wrapText(self.inspectMode.card.ability or "None", cardRect.width - 60, self.fonts.small)
    love.graphics.printf(wrappedText, 
        cardRect.x + 30, cardRect.y + 230, cardRect.width - 60, "left")
    
    -- Draw flavor text
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.3, 0.3, 0.3)
    
    local flavorText = self.inspectMode.card.flavorText or ""
    local wrappedFlavorText = self:wrapText(flavorText, cardRect.width - 80, self.fonts.small)
    
    love.graphics.printf(wrappedFlavorText, 
        cardRect.x + 40, cardRect.y + cardRect.height - 100, cardRect.width - 80, "center")
    
    -- Draw close button
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.circle("fill", cardRect.x + cardRect.width - 20, cardRect.y + 20, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(
        cardRect.x + cardRect.width - 25, cardRect.y + 15,
        cardRect.x + cardRect.width - 15, cardRect.y + 25
    )
    love.graphics.line(
        cardRect.x + cardRect.width - 25, cardRect.y + 25,
        cardRect.x + cardRect.width - 15, cardRect.y + 15
    )
end

-- Get rectangle for the inspect card
function UI:getInspectCardRect()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local cardWidth = CARD_WIDTH * 3
    local cardHeight = CARD_HEIGHT * 3
    
    local x = (screenWidth - cardWidth) / 2
    local y = (screenHeight - cardHeight) / 2
    
    return {x = x, y = y, width = cardWidth, height = cardHeight}
end

-- Check if point is inside rectangle
function UI:pointInRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
           y >= rect.y and y <= rect.y + rect.height
end

-- Process fourth wall break message
function UI:maybeShowFourthWallMessage()
    -- Only show fourth wall messages at a reduced probability
    if math.random() > self.fourthWallProbability then
        return
    end
    
    local messages = {
        "I can see you, you know...",
        "Did you just click that? Hmm...",
        "This is just a game, right?",
        "Are you having fun yet?",
        "I wonder who's really in control here...",
        "What if I told you these cards were real?",
        "Have you noticed any glitches? Just curious...",
        "The developer is watching us, you know.",
        "Sometimes I wonder if we're all in a simulation.",
        "What if I decided not to follow the rules?",
        "I've seen things you wouldn't believe.",
        "I remember every card you've played.",
        "Don't worry, I won't tell anyone about your strategy."
    }
    
    -- Pick a random message
    local message = messages[math.random(#messages)]
    
    -- Display in a less intrusive position (top left corner)
    self.fourthWallMessage = message
    self.fourthWallTimer = 4 -- Show for 4 seconds
end

-- Draw a fourth wall message
function UI:drawFourthWallMessage()
    if not self.fourthWallMessage then return end
    
    -- Draw semi-transparent background in top left corner
    love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
    love.graphics.rectangle("fill", 10, 10, 300, 40, 5, 5)
    
    -- Draw text
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print(self.fourthWallMessage, 20, 20)
end

-- Draw player stats (essence, deck count, etc.)
function UI:drawPlayerStats(playerIndex)
    local player = self.game.players[playerIndex]
    
    -- Determine position based on player index
    local x, y
    if playerIndex == 1 then
        x = 20
        y = love.graphics.getHeight() - 190
    else
        x = 20
        y = 20
    end
    
    -- Draw player name
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.print("Player " .. playerIndex, x, y)
    
    -- Draw essence counter
    love.graphics.setColor(0.9, 0.7, 0.2)
    love.graphics.circle("fill", x + 20, y + 40, 15)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", x + 20, y + 40, 15)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.print("Essence: " .. player.essence, x + 40, y + 30)
    
    -- Draw deck count
    love.graphics.setColor(0.3, 0.3, 0.6)
    self:drawRoundedRectangle(x + 10, y + 60, 20, 30, 3)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Deck: " .. #player.deck, x + 40, y + 65)
    
    -- Draw turn indicator if it's this player's turn
    if self.game.currentPlayer == playerIndex then
        love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
        love.graphics.circle("fill", x - 10, y + 10, 5)
    end
end

-- Draw current player indicator
function UI:drawCurrentPlayerIndicator()
    local currentPlayer = self.game.currentPlayer
    local y = (currentPlayer == 1) and 
              (love.graphics.getHeight() - 30) or 
              30
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf("Player " .. currentPlayer .. "'s Turn", 
        0, y, love.graphics.getWidth(), "center")
end

-- Draw instruction message
function UI:drawInstructionMessage()
    if not self.instructionMessage then return end
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(self.fonts.small)
    love.graphics.printf(self.instructionMessage, 
        0, love.graphics.getHeight() / 2 - 15, 
        love.graphics.getWidth(), "center")
end

-- Draw current message
function UI:drawMessage()
    if not self.message then return end
    
    -- Draw semi-transparent background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
    local width = self.fonts.medium:getWidth(self.message) + 40
    local x = (love.graphics.getWidth() - width) / 2
    love.graphics.rectangle("fill", x, love.graphics.getHeight() / 2 - 60, width, 40, 10, 10)
    
    -- Draw message text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf(self.message, 
        0, love.graphics.getHeight() / 2 - 50, 
        love.graphics.getWidth(), "center")
end

-- Draw graveyard for a player
function UI:drawGraveyard(playerIndex)
    local player = self.game.players[playerIndex]
    local pos = self["player" .. playerIndex .. "GraveyardPosition"]
    
    -- Only draw if the graveyard has cards
    if #player.graveyard > 0 then
        -- Draw graveyard outline
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        self:drawRoundedRectangle(pos.x, pos.y, CARD_WIDTH, CARD_HEIGHT, CARD_CORNER_RADIUS)
        
        -- Draw count
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("Graveyard: " .. #player.graveyard, pos.x, pos.y + CARD_HEIGHT + 5)
        
        -- Draw top card if any
        if #player.graveyard > 0 then
            local topCard = player.graveyard[#player.graveyard]
            
            -- Draw at reduced opacity
            love.graphics.setColor(1, 1, 1, 0.7)
            self:drawEnhancedCard(topCard, pos.x, pos.y, false)
        end
    end
end

-- Draw card being dragged
function UI:drawDraggingCard()
    if not self.dragging.active or not self.dragging.card then
        return
    end
    
    -- Draw shadow under the dragged card
    love.graphics.setColor(0, 0, 0, 0.5)
    self:drawRoundedRectangle(
        self.dragging.currentX - CARD_WIDTH/2 + 5, 
        self.dragging.currentY - CARD_HEIGHT/2 + 5, 
        CARD_WIDTH, 
        CARD_HEIGHT, 
        CARD_CORNER_RADIUS
    )
    
    -- Draw the card with slight rotation for "picked up" feel
    love.graphics.push()
    love.graphics.translate(self.dragging.currentX, self.dragging.currentY)
    love.graphics.rotate(math.sin(love.timer.getTime() * 2) * 0.05)
    self:drawEnhancedCard(
        self.dragging.card, 
        -CARD_WIDTH/2, 
        -CARD_HEIGHT/2, 
        true
    )
    love.graphics.pop()
    
    -- Draw targeting line if dragging from field
    if self.dragging.sourceType == "field" then
        love.graphics.setColor(1, 0.5, 0.2, 0.7)
        love.graphics.setLineWidth(3)
        love.graphics.line(
            self.dragging.startX, 
            self.dragging.startY, 
            self.dragging.currentX, 
            self.dragging.currentY
        )
        
        -- Draw arrow at target end
        local angle = math.atan2(
            self.dragging.currentY - self.dragging.startY,
            self.dragging.currentX - self.dragging.startX
        )
        
        local arrowSize = 10
        love.graphics.polygon(
            "fill",
            self.dragging.currentX,
            self.dragging.currentY,
            self.dragging.currentX - arrowSize * math.cos(angle - math.pi/6),
            self.dragging.currentY - arrowSize * math.sin(angle - math.pi/6),
            self.dragging.currentX - arrowSize * math.cos(angle + math.pi/6),
            self.dragging.currentY - arrowSize * math.sin(angle + math.pi/6)
        )
    end
end

return UI 