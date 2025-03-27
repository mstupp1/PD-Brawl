-- AI Opponent module for PD Brawl
local AIOpponent = {}
AIOpponent.__index = AIOpponent

-- Create a new AI opponent instance
function AIOpponent.new(game)
    local self = setmetatable({}, AIOpponent)
    
    self.game = game
    self.thinkingTime = 1.0 -- Simulate thinking for this many seconds
    self.currentThinkingTime = 0
    self.planningPhase = true
    self.actions = {} -- Queue of actions to perform
    
    return self
end

-- Update AI during its turn
function AIOpponent:update(dt)
    -- Only run AI logic during player 2's turn
    if self.game.currentPlayer ~= 2 or self.game.state ~= "player2Turn" then
        return
    end
    
    -- If we're planning actions, take time to "think"
    if self.planningPhase then
        self.currentThinkingTime = self.currentThinkingTime + dt
        
        if self.currentThinkingTime >= self.thinkingTime then
            self:planActions()
            self.planningPhase = false
            self.currentThinkingTime = 0
        end
        return
    end
    
    -- Execute the next planned action if any
    if #self.actions > 0 then
        self.currentThinkingTime = self.currentThinkingTime + dt
        
        -- Small delay between actions to simulate thinking
        if self.currentThinkingTime >= 0.5 then
            local nextAction = table.remove(self.actions, 1)
            nextAction()
            self.currentThinkingTime = 0
        end
    else
        -- No more actions, end turn
        self.game:endTurn()
        self.planningPhase = true
    end
end

-- Plan a sequence of actions for this turn
function AIOpponent:planActions()
    self.actions = {}
    local player = self.game.players[2]
    
    -- First, check if we can play any character cards
    for i, card in ipairs(player.hand) do
        if card.type == "character" then
            local essenceCost = card.essenceCost or card.cost or 0
            if player.essence >= essenceCost then
                table.insert(self.actions, function()
                    local success, message = self.game:playCard(2, i)
                    if success then
                        -- Adjust indices for the removed card
                        self:adjustActionIndices(i)
                    end
                end)
            end
        end
    end
    
    -- Then, check if we can attack with any characters on the field
    for i, card in ipairs(player.field) do
        if not card.hasAttacked and #self.game.players[1].field > 0 then
            -- Find the best target to attack
            -- Simple strategy: attack the character with lowest HP
            local bestTarget = self:findBestAttackTarget()
            
            if bestTarget then
                table.insert(self.actions, function()
                    -- Use game's attack method instead of player's
                    local success, message = self.game:attackCard(2, i, 1, bestTarget)
                    -- Check win condition handled by attackCard
                end)
            end
        end
    end
    
    -- Finally, check if we can play any action/item cards
    for i, card in ipairs(player.hand) do
        if (card.type == "action" or card.type == "item") then
            local essenceCost = card.essenceCost or card.cost or 0
            if player.essence >= essenceCost then
                -- Find appropriate target
                local target = self:findBestActionTarget(card)
                
                if target then

                    table.insert(self.actions, function()
                        -- Simplified action/item handling
                        local success, message = self.game:playCard(2, i, target)
                        
                        if success then
                            -- Adjust indices already handled by playCard
                            self:adjustActionIndices(i)
                        end
                    end)
                end
            end
        end
    end
    
    -- Check if we can perform fusion
    for i, baseCard in ipairs(player.field) do
        local validTargets = player:getValidFusionTargets(i)
        
        if #validTargets > 0 and player.essence >= 2 then
            table.insert(self.actions, function()
                local materialIndices = {validTargets[1]} -- Just use first valid material
                self.game:fusionSummon(2, i, materialIndices)
            end)
        end
    end
end

-- Find the best character to attack
function AIOpponent:findBestAttackTarget()
    local opponents = self.game.players[1].field
    local bestIndex = nil
    local lowestHP = math.huge
    
    for i, card in ipairs(opponents) do
        local hp = card.hp or card.currentHP or 0
        if hp < lowestHP then
            lowestHP = hp
            bestIndex = i
        end
    end
    
    return bestIndex
end

-- Find best target for action/item card
function AIOpponent:findBestActionTarget(card)
    -- Simplified targeting - just pick a card on either field
    if card.type == "action" then
        -- For actions, target opponent's field
        if #self.game.players[1].field > 0 then
            return {
                playerIndex = 1,
                cardIndex = 1,
                zone = "field"
            }
        end
    elseif card.type == "item" then
        -- For items, target our own field
        if #self.game.players[2].field > 0 then
            return {
                playerIndex = 2,
                cardIndex = 1,
                zone = "field"
            }
        end
    end
    
    return nil
end

-- Adjust action indices after a card is removed from hand
function AIOpponent:adjustActionIndices(removedIndex)
    for i, action in ipairs(self.actions) do
        -- Here we would update any indices in planned actions
        -- This is complex and would depend on how actions are stored
        -- For a simple implementation, we'll just rely on the fact that
        -- the game will check validity when actions are executed
    end
end

-- Get AI fourth wall breaking message
function AIOpponent:getFourthWallMessage()
    local messages = {
        "I'm just some code, but I'll still beat you!",
        "The developer didn't give me very good AI...",
        "Is that a bug, or am I just playing poorly?",
        "01001000 01100101 01101100 01101100 01101111 00100001",
        "Loading optimal strategy... ERROR: File not found.",
        "I can see all the cards in your hand. Just kidding, I can't.",
        "Drag and drop those cards! I'm watching you...",
        "The screen shake is for dramatic effect. I didn't really hit that hard.",
        "Are you enjoying the new visual effects?",
        "Try dragging your cards. It's much more satisfying!",
        "Fusion looks so cool! Drag a character onto another for awesome effects!",
        "Did you know you can fuse characters? Just drag one onto another!",
        "No buttons needed! Just drag and drop to do everything.",
        "I wish I could drag and drop my cards as smoothly as you can...",
        "That fusion explosion effect is my favorite part!",
        "Hmm, I wonder which characters would make the best fusion..."
    }
    return messages[math.random(#messages)]
end

return AIOpponent 