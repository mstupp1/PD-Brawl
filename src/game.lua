-- Game module - core game logic for PD Brawl
local Card = require("src.card_types.card")
local Player = require("src.player")

local Game = {}
Game.__index = Game

-- Create a new game instance
function Game.new()
    local self = setmetatable({}, Game)
    
    -- Game states
    self.state = "setup" -- setup, player1Turn, player2Turn, gameOver
    self.currentTurn = 1
    self.currentPlayer = 1
    
    -- Players
    self.players = {
        Player.new(1),
        Player.new(2)
    }
    
    -- Action history
    self.history = {}
    
    -- Initialize game
    self:initialize()
    
    return self
end

-- Initialize game state
function Game:initialize()
    -- Deal initial hands
    for _, player in ipairs(self.players) do
        player:drawInitialHand()
    end
    
    -- Set initial state
    self.state = "player1Turn"
    
    -- Add starting essence
    self.players[1]:addEssence(1)
end

-- Update game state
function Game:update(dt)
    -- Process any ongoing animations or effects
end

-- Start a player's turn
function Game:startTurn(playerIndex)
    local player = self.players[playerIndex]
    
    -- Give player essence
    player:addEssence(1)
    
    -- Allow player to draw a card
    player:drawCard()
    
    -- Set current player
    self.currentPlayer = playerIndex
    
    -- Increment turn counter if player 1
    if playerIndex == 1 then
        self.currentTurn = self.currentTurn + 1
    end
    
    -- Update game state
    self.state = "player" .. playerIndex .. "Turn"
    
    -- Trigger any start-of-turn effects
    self:processTurnStartEffects(player)
end

-- End current player's turn
function Game:endTurn()
    local nextPlayer = self.currentPlayer == 1 and 2 or 1
    self:startTurn(nextPlayer)
end

-- Process a card play
function Game:playCard(playerIndex, cardIndex, targetInfo)
    local player = self.players[playerIndex]
    local card = player.hand[cardIndex]
    
    if not card then return false, "Invalid card" end
    
    -- Check if player has enough essence
    if player.essence < card.essenceCost then
        return false, "Not enough essence"
    end
    
    -- Process card effect based on type
    local success, message = card:play(player, self, targetInfo)
    
    if success then
        -- Deduct essence cost
        player:useEssence(card.essenceCost)
        
        -- Move card from hand to appropriate zone
        player:removeCardFromHand(cardIndex)
        
        -- If it's a character card, add to field
        if card.type == "character" then
            player:addToField(card)
        end
        
        -- Log the action
        table.insert(self.history, {
            turn = self.currentTurn,
            player = playerIndex,
            action = "playCard",
            card = card.name
        })
    end
    
    return success, message
end

-- Process fusion between cards
function Game:fusionSummon(playerIndex, baseCardIndex, materialIndices)
    local player = self.players[playerIndex]
    local baseCard = player.field[baseCardIndex]
    local materials = {}
    
    -- Collect fusion materials
    for _, idx in ipairs(materialIndices) do
        table.insert(materials, player.hand[idx])
    end
    
    -- Check if fusion is valid
    local fusionResult = self:checkFusionValidity(baseCard, materials)
    
    if not fusionResult.valid then
        return false, fusionResult.message
    end
    
    -- Pay fusion cost
    player:useEssence(fusionResult.essenceCost)
    
    -- Remove materials from hand
    for i = #materialIndices, 1, -1 do
        player:removeCardFromHand(materialIndices[i])
    end
    
    -- Replace base card with fusion result
    player:replaceOnField(baseCardIndex, fusionResult.resultCard)
    
    -- Log the action
    table.insert(self.history, {
        turn = self.currentTurn,
        player = playerIndex,
        action = "fusion",
        baseCard = baseCard.name,
        result = fusionResult.resultCard.name
    })
    
    return true, "Fusion successful!"
end

-- Check if fusion is valid and return result
function Game:checkFusionValidity(baseCard, materials)
    -- This would check against the fusion database
    -- For now, returning a mock result
    
    if #materials == 0 then
        return {valid = false, message = "No fusion materials provided"}
    end
    
    -- Mock fusion logic - to be expanded with actual fusion rules
    local totalPower = baseCard.power or 0
    local fusionName = baseCard.name
    
    for _, card in ipairs(materials) do
        totalPower = totalPower + (card.power or 0)
        fusionName = fusionName .. " + " .. card.name
    end
    
    local mockFusionCard = Card.new({
        id = "fusion_1",
        name = "Fused " .. baseCard.name,
        type = "character",
        hp = baseCard.hp * 1.5,
        essenceCost = baseCard.essenceCost + 1,
        power = totalPower,
        abilities = baseCard.abilities,
        flavorText = "A fusion of " .. fusionName
    })
    
    return {
        valid = true,
        essenceCost = 2,
        resultCard = mockFusionCard
    }
end

-- Process start-of-turn effects
function Game:processTurnStartEffects(player)
    -- Apply effects from field cards that trigger at turn start
    for _, card in ipairs(player.field) do
        if card.onTurnStart then
            card:onTurnStart(player, self)
        end
    end
    
    -- Apply any global turn start effects
end

-- Process end-of-turn effects
function Game:processTurnEndEffects(player)
    -- Apply effects from field cards that trigger at turn end
    for _, card in ipairs(player.field) do
        if card.onTurnEnd then
            card:onTurnEnd(player, self)
        end
    end
end

-- Check win conditions
function Game:checkWinCondition()
    -- Win condition: defeat 3 of opponent's heroes
    for i, player in ipairs(self.players) do
        local opponent = i == 1 and 2 or 1
        if player.defeatedEnemyCount >= 3 then
            self.state = "gameOver"
            self.winner = i
            return true
        end
    end
    
    return false
end

-- Get current game state information
function Game:getStateInfo()
    return {
        state = self.state,
        turn = self.currentTurn,
        currentPlayer = self.currentPlayer,
        players = {
            {
                essence = self.players[1].essence,
                handSize = #self.players[1].hand,
                fieldSize = #self.players[1].field,
                deckSize = #self.players[1].deck
            },
            {
                essence = self.players[2].essence,
                handSize = #self.players[2].hand,
                fieldSize = #self.players[2].field,
                deckSize = #self.players[2].deck
            }
        }
    }
end

return Game 