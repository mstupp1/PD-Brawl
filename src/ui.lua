-- UI module for PD Brawl
local UI = {}
UI.__index = UI

-- UI constants
local CARD_WIDTH = 120
local CARD_HEIGHT = 160
local CARD_SPACING = 20
local HAND_Y_OFFSET = 520
local FIELD_Y_OFFSET = 300
local ESSENCE_DISPLAY_X = 20
local ESSENCE_DISPLAY_Y = 560
local DECK_DISPLAY_X = 700
local DECK_DISPLAY_Y = 560
local MESSAGE_X = 400
local MESSAGE_Y = 250
local TURN_DISPLAY_X = 400
local TURN_DISPLAY_Y = 20
local ESSENCE_ICON = "💧" -- Using emoji for now, would be replaced with graphic

-- Color constants
local COLORS = {
    background = {0.1, 0.1, 0.1, 1},
    card = {0.8, 0.8, 0.8, 1},
    cardBack = {0.2, 0.2, 0.5, 1},
    character = {0.2, 0.6, 0.8, 1},
    action = {0.8, 0.4, 0.4, 1},
    item = {0.4, 0.8, 0.4, 1},
    text = {1, 1, 1, 1},
    highlight = {1, 0.9, 0.2, 1},
    button = {0.4, 0.4, 0.8, 1},
    buttonHover = {0.5, 0.5, 0.9, 1},
    essence = {0.3, 0.7, 0.9, 1}
}

-- Rarity color coding
local RARITY_COLORS = {
    common = {0.8, 0.8, 0.8, 1},
    uncommon = {0.2, 0.8, 0.2, 1},
    rare = {0.2, 0.2, 0.8, 1},
    legendary = {0.8, 0.2, 0.8, 1}
}

-- Initialize UI
function UI.new(game)
    local self = setmetatable({}, UI)
    
    self.game = game
    self.fonts = {
        small = love.graphics.newFont(12),
        medium = love.graphics.newFont(16),
        large = love.graphics.newFont(24)
    }
    
    -- UI state
    self.selectedCardIndex = nil
    self.selectedFieldIndex = nil
    self.targetingMode = false
    self.message = nil
    self.messageTimer = 0
    self.fourthWallMessage = nil
    self.fourthWallTimer = 0
    
    -- Buttons
    self.buttons = {
        endTurn = {
            x = 700,
            y = 500,
            width = 120,
            height = 40,
            text = "End Turn",
            action = function() 
                self.game:endTurn()
                self:showMessage("Turn ended")
            end
        },
        fusion = {
            x = 570,
            y = 500,
            width = 120,
            height = 40,
            text = "Fusion",
            action = function()
                if self.selectedFieldIndex then
                    self:enterFusionMode()
                else
                    self:showMessage("Select a base card first")
                end
            end
        }
    }
    
    -- Initialize card positions
    self:updateCardPositions()
    
    return self
end

-- Update card positions based on game state
function UI:updateCardPositions()
    -- Position cards in player 1's hand
    self.player1HandPositions = {}
    local handWidth = #self.game.players[1].hand * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING
    local startX = (love.graphics.getWidth() - handWidth) / 2
    
    for i = 1, #self.game.players[1].hand do
        table.insert(self.player1HandPositions, {
            x = startX + (i-1) * (CARD_WIDTH + CARD_SPACING),
            y = HAND_Y_OFFSET
        })
    end
    
    -- Position cards in player 1's field
    self.player1FieldPositions = {}
    local fieldWidth = #self.game.players[1].field * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING
    startX = (love.graphics.getWidth() - fieldWidth) / 2
    
    for i = 1, #self.game.players[1].field do
        table.insert(self.player1FieldPositions, {
            x = startX + (i-1) * (CARD_WIDTH + CARD_SPACING),
            y = FIELD_Y_OFFSET + 100
        })
    end
    
    -- Position cards in player 2's field
    self.player2FieldPositions = {}
    fieldWidth = #self.game.players[2].field * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING
    startX = (love.graphics.getWidth() - fieldWidth) / 2
    
    for i = 1, #self.game.players[2].field do
        table.insert(self.player2FieldPositions, {
            x = startX + (i-1) * (CARD_WIDTH + CARD_SPACING),
            y = FIELD_Y_OFFSET - 100
        })
    end
    
    -- Position cards in player 2's hand (face down)
    self.player2HandPositions = {}
    handWidth = #self.game.players[2].hand * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING
    startX = (love.graphics.getWidth() - handWidth) / 2
    
    for i = 1, #self.game.players[2].hand do
        table.insert(self.player2HandPositions, {
            x = startX + (i-1) * (CARD_WIDTH + CARD_SPACING),
            y = 80
        })
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
    
    -- Update card positions if game state has changed
    self:updateCardPositions()
end

-- Draw the UI
function UI:draw()
    -- Draw background
    love.graphics.setBackgroundColor(COLORS.background)
    
    -- Draw turn indicator
    love.graphics.setFont(self.fonts.large)
    love.graphics.setColor(COLORS.text)
    local turnText = "Turn " .. self.game.currentTurn .. " - Player " .. self.game.currentPlayer
    love.graphics.printf(turnText, TURN_DISPLAY_X - 200, TURN_DISPLAY_Y, 400, "center")
    
    -- Draw player 1 hand
    self:drawPlayerHand(1)
    
    -- Draw player 1 field
    self:drawPlayerField(1)
    
    -- Draw player 2 field
    self:drawPlayerField(2)
    
    -- Draw player 2 hand (face down)
    self:drawOpponentHand()
    
    -- Draw player 1 essence and deck counts
    self:drawPlayerResources(1)
    
    -- Draw player 2 essence and deck counts
    self:drawPlayerResources(2)
    
    -- Draw buttons
    self:drawButtons()
    
    -- Draw messages
    if self.message then
        love.graphics.setFont(self.fonts.large)
        love.graphics.setColor(COLORS.text)
        love.graphics.printf(self.message, MESSAGE_X - 200, MESSAGE_Y, 400, "center")
    end
    
    -- Draw fourth wall messages
    if self.fourthWallMessage then
        love.graphics.setFont(self.fonts.medium)
        love.graphics.setColor(1, 0.8, 0.2, 1)
        love.graphics.printf(self.fourthWallMessage, MESSAGE_X - 200, MESSAGE_Y + 40, 400, "center")
    end
    
    -- Draw game state message
    if self.game.state == "gameOver" then
        love.graphics.setFont(self.fonts.large)
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.printf("Game Over! Player " .. self.game.winner .. " wins!", 
            MESSAGE_X - 200, MESSAGE_Y - 50, 400, "center")
    end
end

-- Draw player hand
function UI:drawPlayerHand(playerIndex)
    local player = self.game.players[playerIndex]
    local positions = self["player" .. playerIndex .. "HandPositions"]
    
    for i, card in ipairs(player.hand) do
        local pos = positions[i]
        if pos then
            -- Highlight selected card
            if self.selectedCardIndex == i and playerIndex == 1 then
                love.graphics.setColor(COLORS.highlight)
                love.graphics.rectangle("fill", pos.x - 5, pos.y - 5, 
                    CARD_WIDTH + 10, CARD_HEIGHT + 10)
            end
            
            -- Draw card
            self:drawCard(card, pos.x, pos.y)
        end
    end
end

-- Draw opponent's hand (face down)
function UI:drawOpponentHand()
    for i, pos in ipairs(self.player2HandPositions) do
        self:drawCardBack(pos.x, pos.y)
    end
end

-- Draw player field
function UI:drawPlayerField(playerIndex)
    local player = self.game.players[playerIndex]
    local positions = self["player" .. playerIndex .. "FieldPositions"]
    
    for i, card in ipairs(player.field) do
        local pos = positions[i]
        if pos then
            -- Highlight selected field card
            if self.selectedFieldIndex == i and playerIndex == 1 and 
               not self.targetingMode then
                love.graphics.setColor(COLORS.highlight)
                love.graphics.rectangle("fill", pos.x - 5, pos.y - 5, 
                    CARD_WIDTH + 10, CARD_HEIGHT + 10)
            end
            
            -- Highlight target card in targeting mode
            if self.targetingMode and playerIndex == 2 then
                love.graphics.setColor(1, 0, 0, 0.5)
                love.graphics.rectangle("fill", pos.x - 5, pos.y - 5, 
                    CARD_WIDTH + 10, CARD_HEIGHT + 10)
            end
            
            -- Draw card
            self:drawCard(card, pos.x, pos.y)
        end
    end
end

-- Draw a card
function UI:drawCard(card, x, y)
    -- Card background based on type
    if card.type == "character" then
        love.graphics.setColor(COLORS.character)
    elseif card.type == "action" then
        love.graphics.setColor(COLORS.action)
    elseif card.type == "item" then
        love.graphics.setColor(COLORS.item)
    else
        love.graphics.setColor(COLORS.card)
    end
    
    -- Draw card back
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card border based on rarity
    love.graphics.setColor(RARITY_COLORS[card.rarity] or COLORS.text)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)
    
    -- Draw card name
    love.graphics.setColor(COLORS.text)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.printf(card.name, x + 5, y + 5, CARD_WIDTH - 10, "center")
    
    -- Draw card cost
    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(COLORS.essence)
    love.graphics.print(ESSENCE_ICON .. card.essenceCost, x + 5, y + 25)
    
    -- Draw card type
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(COLORS.text)
    love.graphics.printf(card.type:upper(), x + 5, y + 40, CARD_WIDTH - 10, "center")
    
    -- Draw character-specific stats
    if card.type == "character" then
        -- HP
        love.graphics.setFont(self.fonts.medium)
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.print("HP: " .. card.hp, x + 5, y + 60)
        
        -- Power
        love.graphics.setColor(0.2, 0.2, 1, 1)
        love.graphics.print("PWR: " .. card.power, x + 5, y + 80)
    end
    
    -- Draw flavor text
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf(card.flavorText, x + 5, y + 110, CARD_WIDTH - 10, "center")
end

-- Draw a card back
function UI:drawCardBack(x, y)
    love.graphics.setColor(COLORS.cardBack)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)
    love.graphics.setColor(COLORS.text)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)
    love.graphics.setFont(self.fonts.large)
    love.graphics.printf("PD", x, y + CARD_HEIGHT/2 - 20, CARD_WIDTH, "center")
    love.graphics.printf("Brawl", x, y + CARD_HEIGHT/2 + 10, CARD_WIDTH, "center")
end

-- Draw player resources
function UI:drawPlayerResources(playerIndex)
    local player = self.game.players[playerIndex]
    local y = playerIndex == 1 and ESSENCE_DISPLAY_Y or 40
    
    -- Draw essence
    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(COLORS.essence)
    love.graphics.print(ESSENCE_ICON .. " Essence: " .. player.essence, ESSENCE_DISPLAY_X, y)
    
    -- Draw deck count
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Deck: " .. #player.deck, DECK_DISPLAY_X, y)
    
    -- Draw fusion deck count
    love.graphics.print("Fusion Deck: " .. #player.fusionDeck, DECK_DISPLAY_X - 200, y)
end

-- Draw UI buttons
function UI:drawButtons()
    for _, button in pairs(self.buttons) do
        -- Check if mouse is hovering
        local mx, my = love.mouse.getPosition()
        local hover = mx >= button.x and mx <= button.x + button.width and
                      my >= button.y and my <= button.y + button.height
        
        -- Draw button background
        love.graphics.setColor(hover and COLORS.buttonHover or COLORS.button)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        -- Draw button border
        love.graphics.setColor(COLORS.text)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
        
        -- Draw button text
        love.graphics.setFont(self.fonts.medium)
        love.graphics.printf(button.text, button.x, button.y + 10, button.width, "center")
    end
end

-- Handle mouse press
function UI:mousepressed(x, y, button)
    if button ~= 1 then return end
    
    -- Check button clicks
    for _, btn in pairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height then
            btn.action()
            return
        end
    end
    
    -- Handle targeting mode
    if self.targetingMode then
        self:handleTargeting(x, y)
        return
    end
    
    -- Check if clicking on a card in hand
    local clickedIndex = self:getClickedHandCardIndex(x, y)
    if clickedIndex then
        if self.selectedCardIndex == clickedIndex then
            -- Deselect if clicked again
            self.selectedCardIndex = nil
        else
            -- Select new card
            self.selectedCardIndex = clickedIndex
            self.selectedFieldIndex = nil
            
            -- Show fourth wall message if applicable
            local card = self.game.players[1].hand[clickedIndex]
            local quote = card:getFourthWallQuote("select")
            if quote then
                self:showFourthWallMessage(quote)
            end
        end
        return
    end
    
    -- Check if clicking on a card in field
    clickedIndex = self:getClickedFieldCardIndex(x, y, 1)
    if clickedIndex then
        if self.selectedFieldIndex == clickedIndex then
            -- Deselect if clicked again
            self.selectedFieldIndex = nil
        else
            -- Select new field card
            self.selectedFieldIndex = clickedIndex
            self.selectedCardIndex = nil
            
            -- Show fourth wall message if applicable
            local card = self.game.players[1].field[clickedIndex]
            local quote = card:getFourthWallQuote("select")
            if quote then
                self:showFourthWallMessage(quote)
            end
        end
        return
    end
    
    -- If a card in hand is selected and clicked on an empty space, try to play it
    if self.selectedCardIndex and 
       self.game.currentPlayer == 1 then
        self:playSelectedCard()
    end
    
    -- If a field card is selected and clicked an opponent card, try to attack
    if self.selectedFieldIndex and
       self.game.currentPlayer == 1 then
        clickedIndex = self:getClickedFieldCardIndex(x, y, 2)
        if clickedIndex then
            self:attackWithSelectedCard(clickedIndex)
        end
    end
end

-- Handle mouse release
function UI:mousereleased(x, y, button)
    -- Handle any release events if needed
end

-- Handle key press
function UI:keypressed(key)
    if key == "space" and self.game.currentPlayer == 1 then
        self.game:endTurn()
        self:showMessage("Turn ended")
    elseif key == "f" and self.selectedFieldIndex then
        self:enterFusionMode()
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
function UI:playSelectedCard()
    local player = self.game.players[1]
    local card = player.hand[self.selectedCardIndex]
    
    if not card then return end
    
    -- If card needs a target, enter targeting mode
    if card.type == "action" or card.type == "item" then
        self.targetingMode = true
        self:showMessage("Select a target for " .. card.name)
        return
    end
    
    -- Otherwise play the card directly
    local success, message = self.game:playCard(1, self.selectedCardIndex)
    
    if success then
        self:showMessage(message or "Card played successfully")
        
        -- Show fourth wall message if applicable
        local quote = card:getFourthWallQuote("play")
        if quote then
            self:showFourthWallMessage(quote)
        end
        
        self.selectedCardIndex = nil
    else
        self:showMessage(message or "Unable to play card")
    end
end

-- Attack with the selected card
function UI:attackWithSelectedCard(targetIndex)
    local player = self.game.players[1]
    local card = player.field[self.selectedFieldIndex]
    
    if not card then return end
    
    -- Check if card has already attacked
    if card.hasAttacked then
        self:showMessage("This card has already attacked this turn")
        return
    end
    
    -- Perform attack
    local success, message = player:attackCard(
        self.selectedFieldIndex, 
        self.game.players[2], 
        targetIndex
    )
    
    if success then
        card.hasAttacked = true
        self:showMessage(message or "Attack successful")
        
        -- Show fourth wall message if applicable
        local quote = card:getFourthWallQuote("attack")
        if quote then
            self:showFourthWallMessage(quote)
        end
        
        -- Check win condition
        if self.game:checkWinCondition() then
            self:showMessage("Player 1 wins!")
        end
        
        self.selectedFieldIndex = nil
    else
        self:showMessage(message or "Unable to attack")
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
    
    -- Apply the card effect
    local card = self.game.players[1].hand[self.selectedCardIndex]
    local target = self.game.players[targetInfo.playerIndex].field[targetInfo.cardIndex]
    
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

-- Show a message to the player
function UI:showMessage(text)
    self.message = text
    self.messageTimer = 3 -- Show for 3 seconds
end

-- Show a fourth-wall-breaking message
function UI:showFourthWallMessage(text)
    self.fourthWallMessage = text
    self.fourthWallTimer = 4 -- Show for 4 seconds
end

return UI 