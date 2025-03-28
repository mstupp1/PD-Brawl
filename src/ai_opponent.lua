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
    local opponent = self.game.players[1]
    
    -- Create a priorities list
    local priorities = {}
    
    -- PRIORITY 1: Play powerful characters if we have few or none on the field
    if #player.field < 2 then
        -- Find character cards sorted by power
        local characters = {}
        for i, card in ipairs(player.hand) do
            if card.type == "character" then
                local essenceCost = card.essenceCost or card.essence or card.cost or 0
                if player.essence >= essenceCost then
                    table.insert(characters, {index = i, card = card, power = card.power or 0})
                end
            end
        end
        
        -- Sort by power (highest first)
        table.sort(characters, function(a, b) return a.power > b.power end)
        
        -- Add strongest characters to actions
        for i, char in ipairs(characters) do
            if i <= 2 then -- Play at most 2 characters
                table.insert(priorities, {
                    priority = 10 + char.power / 10, -- Higher priority for stronger characters
                    action = function()
                        local success, message = self.game:playCard(2, char.index)
                        if success then
                            self:adjustActionIndices(char.index)
                        end
                    end,
                    description = "Play character " .. char.card.name
                })
            end
        end
    end
    
    -- PRIORITY 2: Perform fusions if possible
    for i, baseCard in ipairs(player.field) do
        local validTargets = player:getValidFusionTargets(i)
        
        if #validTargets > 0 and player.essence >= 2 then
            -- Find the best fusion material
            local bestMaterial = nil
            local bestScore = -1
            
            for _, targetIdx in ipairs(validTargets) do
                local material = player.hand[targetIdx]
                local score = 0
                
                -- Score based on card type and stats
                if material.type == "character" then
                    score = (material.power or 0) * 0.7 + (material.hp or 0) * 0.3
                elseif material.type == "item" then
                    score = 50 -- Items often have good fusion results
                end
                
                -- Prefer to use lower cost cards for fusion
                local cost = material.essenceCost or material.essence or 0
                score = score - (cost * 5)
                
                -- Special cases for known good fusions
                if baseCard.name == "Sailor Popeye" and material.name == "Can of Spinach" then
                    score = 200 -- Very high priority for known good fusion
                elseif baseCard.name == "Sherlock Holmes" and material.name:find("Watson") then
                    score = 180
                end
                
                if score > bestScore then
                    bestScore = score
                    bestMaterial = targetIdx
                end
            end
            
            if bestMaterial then
                table.insert(priorities, {
                    priority = 8 + bestScore / 100, -- High priority for good fusions
                    action = function()
                        local materialIndices = {bestMaterial}
                        self.game:fusionSummon(2, i, materialIndices)
                        -- Adjust indices for removed material
                        self:adjustActionIndices(bestMaterial)
                    end,
                    description = "Fuse " .. baseCard.name .. " with card from hand"
                })
            end
        end
    end
    
    -- PRIORITY 3: Attack opponent's characters with good trade-offs
    for i, card in ipairs(player.field) do
        if not card.hasAttacked and #opponent.field > 0 and card.type == "character" then
            -- Find best attack target with smart targeting
            local attackData = self:findBestAttackTarget(card)
            
            if attackData then
                table.insert(priorities, {
                    priority = attackData.priority,
                    action = function()
                        local success, message = self.game:attackCard(2, i, 1, attackData.index)
                    end,
                    description = "Attack " .. opponent.field[attackData.index].name .. " with " .. card.name
                })
            end
        end
    end
    
    -- PRIORITY 4: Play action/item cards strategically
    for i, card in ipairs(player.hand) do
        if (card.type == "action" or card.type == "item") then
            local essenceCost = card.essenceCost or card.essence or card.cost or 0
            if player.essence >= essenceCost then
                -- Find appropriate target
                local targetData = self:findBestActionTarget(card)
                
                if targetData then
                    table.insert(priorities, {
                        priority = targetData.priority,
                        action = function()
                            local success, message = self.game:playCard(2, i, targetData.target)
                            if success then
                                self:adjustActionIndices(i)
                            end
                        end,
                        description = "Use " .. card.name .. " on " .. (targetData.description or "target")
                    })
                end
            end
        end
    end
    
    -- PRIORITY 5: Play any remaining characters if we have essence
    for i, card in ipairs(player.hand) do
        if card.type == "character" then
            local essenceCost = card.essenceCost or card.essence or card.cost or 0
            if player.essence >= essenceCost and #player.field < 5 then
                -- Check if we've already planned to play this card
                local alreadyPlanned = false
                for _, p in ipairs(priorities) do
                    if p.description == "Play character " .. card.name then
                        alreadyPlanned = true
                        break
                    end
                end
                
                if not alreadyPlanned then
                    table.insert(priorities, {
                        priority = 3 + (card.power or 0) / 20, -- Lower priority
                        action = function()
                            local success, message = self.game:playCard(2, i)
                            if success then
                                self:adjustActionIndices(i)
                            end
                        end,
                        description = "Play character " .. card.name .. " (backup plan)"
                    })
                end
            end
        end
    end
    
    -- Sort priorities from highest to lowest
    table.sort(priorities, function(a, b) return a.priority > b.priority end)
    
    -- Add top actions to our action queue
    local actionsAdded = 0
    local maxActions = 4 -- Limit the number of actions per turn
    
    for _, p in ipairs(priorities) do
        if actionsAdded < maxActions then
            -- Add slight delay between actions for dramatic effect
            if actionsAdded > 0 then
                table.insert(self.actions, function()
                    -- Just a delay function
                    return
                end)
            end
            
            table.insert(self.actions, p.action)
            actionsAdded = actionsAdded + 1
        else
            break
        end
    end
    
    -- If no actions planned, add a message
    if #self.actions == 0 then
        table.insert(self.actions, function()
            -- No actions possible this turn
        end)
    end
end

-- Find the best character to attack
function AIOpponent:findBestAttackTarget(attackerCard)
    local opponents = self.game.players[1].field
    local attackerPower = attackerCard.power or 10
    local myField = self.game.players[2].field
    
    -- Keep track of best target
    local bestTarget = {
        index = nil,
        priority = 0
    }
    
    -- Analyze each potential target
    for i, card in ipairs(opponents) do
        local hp = card.hp or card.currentHP or 0
        local power = card.power or 10
        local priority = 0
        
        -- Base priority calculation
        if attackerPower >= hp then
            -- We can defeat this card in one hit - high priority!
            priority = 9 + (power / 10) -- Higher priority for defeating stronger cards
        else
            -- Can't defeat in one hit
            if power >= attackerCard.hp then
                -- Target can defeat us - lower priority
                priority = 2
            else
                -- Neither can defeat the other - medium priority based on damage potential
                priority = 5 - (hp / attackerPower)
            end
        end
        
        -- Adjust priority based on strategic value
        
        -- Low HP cards are tempting targets
        if hp < attackerPower * 0.7 then
            priority = priority + 2
        end
        
        -- Target high-power opponent cards
        if power > 20 then
            priority = priority + power / 20
        end
        
        -- Target cards with special abilities if we can identify them
        if card.abilities and #card.abilities > 0 then
            -- Simplistic approach - just count abilities as threat
            priority = priority + #card.abilities * 0.5
        end
        
        -- If opponent has few cards, prioritize attacking them
        if #opponents <= 2 then
            priority = priority + 2
        end
        
        -- Avoid attacking if we'd lose an important card (unless we can one-shot)
        if power >= attackerCard.hp and attackerPower < hp and #myField <= 2 then
            priority = priority - 4
        end
        
        -- Update best target if this one has higher priority
        if priority > bestTarget.priority then
            bestTarget.index = i
            bestTarget.priority = priority
        end
    end
    
    -- Return nil if no good targets
    if bestTarget.priority <= 0 then
        return nil
    end
    
    return bestTarget
end

-- Find best target for action/item card
function AIOpponent:findBestActionTarget(card)
    local playerField = self.game.players[2].field
    local opponentField = self.game.players[1].field
    local targetData = {
        priority = 0,
        target = nil,
        description = ""
    }
    
    -- Helper function to get description for a card
    local function getCardDesc(playerIdx, cardIdx)
        local player = self.game.players[playerIdx]
        if player and player.field[cardIdx] then
            return player.field[cardIdx].name
        else
            return "unknown card"
        end
    end
    
    -- Different logic based on the card type
    if card.type == "action" then
        -- Check action card name/abilities to determine targeting strategy
        local cardName = card.name:lower()
        
        -- Offensive actions - target opponent's strongest card
        if cardName:find("power%-up") or cardName:find("attack") or cardName:find("damage") or 
           cardName:find("destruction") or cardName:find("feast") then
            if #opponentField > 0 then
                -- Find opponent's strongest character
                local bestIdx = 1
                local highestPower = 0
                
                for i, oppCard in ipairs(opponentField) do
                    if (oppCard.power or 0) > highestPower then
                        highestPower = oppCard.power or 0
                        bestIdx = i
                    end
                end
                
                targetData.target = {
                    playerIndex = 1,
                    cardIndex = bestIdx,
                    zone = "field"
                }
                targetData.priority = 6
                targetData.description = getCardDesc(1, bestIdx)
            end
        -- Defensive/buff actions - target our strongest character
        elseif cardName:find("shield") or cardName:find("heal") or cardName:find("boost") or
               cardName:find("protect") or cardName:find("insight") then
            if #playerField > 0 then
                -- Find our strongest character
                local bestIdx = 1
                local highestValue = 0
                
                for i, myCard in ipairs(playerField) do
                    local value = (myCard.power or 0) + (myCard.hp or 0) / 2
                    if value > highestValue then
                        highestValue = value
                        bestIdx = i
                    end
                end
                
                targetData.target = {
                    playerIndex = 2,
                    cardIndex = bestIdx,
                    zone = "field"
                }
                targetData.priority = 7
                targetData.description = getCardDesc(2, bestIdx)
            end
        -- Generic actions - determine based on card specifics
        else
            -- Default to targeting opponent's field if available
            if #opponentField > 0 then
                -- Find opponent's weakest character (default target)
                local bestIdx = 1
                local lowestHP = math.huge
                
                for i, oppCard in ipairs(opponentField) do
                    if (oppCard.hp or math.huge) < lowestHP then
                        lowestHP = oppCard.hp or math.huge
                        bestIdx = i
                    end
                end
                
                targetData.target = {
                    playerIndex = 1,
                    cardIndex = bestIdx,
                    zone = "field"
                }
                targetData.priority = 4
                targetData.description = getCardDesc(1, bestIdx)
            end
        end
    elseif card.type == "item" then
        -- Items usually target our own field
        if #playerField > 0 then
            -- Find our best character to improve
            local bestIdx = 1
            local bestScore = 0
            
            for i, myCard in ipairs(playerField) do
                -- Score based on character stats, prioritizing more powerful cards
                local score = (myCard.power or 0) * 1.5 + (myCard.hp or 0) * 0.5
                
                -- Special cases for good item combinations
                if myCard.name == "Sailor Popeye" and card.name == "Can of Spinach" then
                    score = score * 3 -- Triple score for thematic combination
                elseif myCard.name:find("Sherlock") and card.name:find("Deerstalker") then
                    score = score * 2.5
                end
                
                -- Prioritize characters already in combat
                if myCard.hasAttacked then
                    score = score * 0.7 -- Lower priority for already used characters
                end
                
                if score > bestScore then
                    bestScore = score
                    bestIdx = i
                end
            end
            
            targetData.target = {
                playerIndex = 2,
                cardIndex = bestIdx,
                zone = "field"
            }
            targetData.priority = 5 + bestScore / 100
            targetData.description = getCardDesc(2, bestIdx)
        end
    end
    
    -- Return nil if no valid target found
    if not targetData.target then
        return nil
    end
    
    return targetData
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