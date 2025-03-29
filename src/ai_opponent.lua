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
    
    -- PRIORITY 1: Play a character on field if we don't have one
    if #player.field == 0 then
        -- Find best character card for field
        local bestFieldChar = self:findBestCharacterForField(player.hand)
        
        if bestFieldChar then
            table.insert(priorities, {
                priority = 20, -- Highest priority
                action = function()
                    local success, message = self.game:playCard(2, bestFieldChar.index, nil, "field")
                    if success then
                        self:adjustActionIndices(bestFieldChar.index)
                    end
                end,
                description = "Play " .. bestFieldChar.card.name .. " on field"
            })
        end
    end
    
    -- PRIORITY 2: Place characters on bench if we have room
    if #player.bench < 3 then
        -- Find character cards for bench
        local benchCharacters = self:findCharactersForBench(player.hand, 3 - #player.bench)
        
        for _, charData in ipairs(benchCharacters) do
            table.insert(priorities, {
                priority = 18 - #player.bench, -- Lower priority than field character
                action = function()
                    local success, message = self.game:playCard(2, charData.index, nil, "bench")
                    if success then
                        self:adjustActionIndices(charData.index)
                    end
                end,
                description = "Place " .. charData.card.name .. " on bench"
            })
        end
    end
    
    -- PRIORITY 3: Perform fusions if possible
    if #player.bench >= 2 then
        -- Check for fusion pairs
        local fusionPairs = self:findFusionPairs(player.bench)
        
        if #fusionPairs > 0 and player.essence >= 2 then
            for _, pair in ipairs(fusionPairs) do
                table.insert(priorities, {
                    priority = 16,
                    action = function()
                        local success, message = self.game:fusionSummon(2, pair[1], pair[2])
                    end,
                    description = "Fuse bench characters " .. player.bench[pair[1]].name .. " and " .. player.bench[pair[2]].name
                })
                -- Only plan one fusion per turn
                break
            end
        end
    end
    
    -- PRIORITY 4: Attach essence to field character
    if #player.field > 0 and player.essence > 0 then
        local fieldChar = player.field[1]
        -- Only attach essence if we plan to attack
        if fieldChar and not fieldChar.hasAttacked and #opponent.field > 0 then
            table.insert(priorities, {
                priority = 15,
                action = function()
                    local targetInfo = {
                        zone = "field",
                        cardIndex = 1
                    }
                    local success, message = self.game:attachEssence(2, targetInfo)
                end,
                description = "Attach essence to field character"
            })
        end
    end
    
    -- PRIORITY 5: Attack with field character
    if #player.field > 0 and #opponent.field > 0 and not self.game.firstTurn then
        local fieldChar = player.field[1]
        
        if fieldChar and not fieldChar.hasAttacked then
            -- Determine best attack strength based on available essence
            local attackStrength = self:determineBestAttackStrength(fieldChar, opponent.field[1])
            
            if attackStrength then
                table.insert(priorities, {
                    priority = 14,
                    action = function()
                        local success, message = self.game:attackOpponent(2, attackStrength)
                    end,
                    description = "Attack with " .. fieldChar.name .. " using " .. attackStrength .. " attack"
                })
            end
        end
    end
    
    -- PRIORITY 6: Play item cards on characters
    for i, card in ipairs(player.hand) do
        if card.type == "item" and player.essence >= card.essenceCost then
            -- Find best target for item
            local targetInfo = self:findBestItemTarget(card)
            
            if targetInfo then
                table.insert(priorities, {
                    priority = 12,
                    action = function()
                        local success, message = self.game:playCard(2, i, targetInfo)
                        if success then
                            self:adjustActionIndices(i)
                        end
                    end,
                    description = "Use " .. card.name .. " on " .. (targetInfo.description or "target")
                })
            end
        end
    end
    
    -- PRIORITY 7: Play action cards strategically
    for i, card in ipairs(player.hand) do
        if card.type == "action" and player.essence >= card.essenceCost then
            -- Find appropriate target
            local targetInfo = self:findBestActionTarget(card)
            
            if targetInfo then
                table.insert(priorities, {
                    priority = 10,
                    action = function()
                        local success, message = self.game:playCard(2, i, targetInfo.target)
                        if success then
                            self:adjustActionIndices(i)
                        end
                    end,
                    description = "Use " .. card.name .. " on " .. (targetInfo.description or "target")
                })
            end
        end
    end
    
    -- PRIORITY 8: Switch character from bench to field if needed
    if #player.field > 0 and #player.bench > 0 and player.essence >= 1 then
        local currentField = player.field[1]
        local bestBenchIndex = self:findBestBenchCharacterToField()
        
        if bestBenchIndex and currentField.hp < currentField.maxHp * 0.3 then
            table.insert(priorities, {
                priority = 8,
                action = function()
                    local success, message = self.game:switchCharacter(2, bestBenchIndex)
                end,
                description = "Switch to bench character " .. player.bench[bestBenchIndex].name
            })
        end
    end
    
    -- Sort priorities from highest to lowest
    table.sort(priorities, function(a, b) return a.priority > b.priority end)
    
    -- Add top actions to our action queue
    local actionsAdded = 0
    local maxActions = 3 -- Limit the number of actions per turn
    
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

-- Find the best character for the field
function AIOpponent:findBestCharacterForField(hand)
    local bestChar = nil
    local bestScore = -1
    
    for i, card in ipairs(hand) do
        if card.type == "character" then
            -- Calculate a score based on stats
            local score = (card.power or 0) * 1.5 + (card.hp or 0)
            
            -- Adjust score based on character type
            if card.characterType == "z" or card.characterType == "z-fusion" then
                score = score * 1.3 -- Z-types are generally stronger
            end
            
            -- Adjust score based on essence cost vs available essence
            local player = self.game.players[2]
            if card.essenceCost > player.essence then
                score = score * 0.5 -- Penalize if we can't afford it
            end
            
            if score > bestScore then
                bestScore = score
                bestChar = {index = i, card = card, score = score}
            end
        end
    end
    
    return bestChar
end

-- Find characters to place on bench
function AIOpponent:findCharactersForBench(hand, maxCount)
    local characters = {}
    
    for i, card in ipairs(hand) do
        if card.type == "character" then
            -- Calculate a score for bench placement
            local score = (card.power or 0) + (card.hp or 0)
            
            -- Regular characters get preference for bench (fusion potential)
            if card.characterType == "regular" then
                score = score * 1.2
            end
            
            table.insert(characters, {index = i, card = card, score = score})
        end
    end
    
    -- Sort by score
    table.sort(characters, function(a, b) return a.score > b.score end)
    
    -- Return top characters
    local result = {}
    for i = 1, math.min(maxCount, #characters) do
        table.insert(result, characters[i])
    end
    
    return result
end

-- Find valid fusion pairs on bench
function AIOpponent:findFusionPairs(bench)
    local pairs = {}
    local player = self.game.players[2]
    
    -- Check all possible bench card combinations
    for i = 1, #bench do
        for j = i + 1, #bench do
            local card1 = bench[i]
            local card2 = bench[j]
            
            -- Only regular characters that have been on bench for a turn can fuse
            if card1.type == "character" and card2.type == "character" and
               card1.characterType == "regular" and card2.characterType == "regular" and
               card1.fusable and card2.fusable then
                table.insert(pairs, {i, j})
            end
        end
    end
    
    return pairs
end

-- Determine best attack strength based on attached essence
function AIOpponent:determineBestAttackStrength(attackerCard, defenderCard)
    -- If no essence attached, can't attack
    if not attackerCard.attachedEssence or attackerCard.attachedEssence == 0 then
        return nil
    end
    
    local attackOptions = {"weak", "medium", "strong", "ultra"}
    local availableAttacks = {}
    
    -- Find attacks we can afford
    for _, strength in ipairs(attackOptions) do
        local cost = attackerCard.attackCosts[strength]
        if cost and attackerCard.attachedEssence >= cost then
            table.insert(availableAttacks, strength)
        end
    end
    
    -- If no affordable attacks, return nil
    if #availableAttacks == 0 then
        return nil
    end
    
    -- Calculate damage for each attack
    local attackValues = {}
    for _, strength in ipairs(availableAttacks) do
        local damage = 0
        if strength == "weak" then
            damage = math.floor(attackerCard.power * 0.5)
        elseif strength == "medium" then
            damage = math.floor(attackerCard.power * 0.75)
        elseif strength == "strong" then
            damage = attackerCard.power
        elseif strength == "ultra" then
            damage = math.floor(attackerCard.power * 1.5)
        end
        
        local cost = attackerCard.attackCosts[strength]
        local value = damage / cost -- Damage per essence point
        
        -- If this attack can defeat the opponent, give it a big bonus
        if damage >= defenderCard.hp then
            value = value * 3
        end
        
        table.insert(attackValues, {strength = strength, value = value})
    end
    
    -- Sort by value
    table.sort(attackValues, function(a, b) return a.value > b.value end)
    
    -- Return the best attack strength
    return attackValues[1].strength
end

-- Find best target for an item card
function AIOpponent:findBestItemTarget(itemCard)
    local player = self.game.players[2]
    
    -- Items typically target characters
    local targetCards = {}
    
    -- Check field character first
    if #player.field > 0 then
        table.insert(targetCards, {
            zone = "field",
            cardIndex = 1,
            card = player.field[1],
            description = player.field[1].name
        })
    end
    
    -- Then check bench characters
    for i, card in ipairs(player.bench) do
        table.insert(targetCards, {
            zone = "bench",
            cardIndex = i,
            card = card,
            description = card.name
        })
    end
    
    -- Find best card to receive this item
    local bestTarget = nil
    local bestScore = -1
    
    for _, target in ipairs(targetCards) do
        local score = 0
        
        -- Field characters get preference
        if target.zone == "field" then
            score = score + 10
        end
        
        -- Stronger characters get preference
        score = score + (target.card.power or 0) / 10
        
        -- Z and Z-fusion characters get preference
        if target.card.characterType == "z" or target.card.characterType == "z-fusion" then
            score = score + 5
        end
        
        if score > bestScore then
            bestScore = score
            bestTarget = target
        end
    end
    
    return bestTarget
end

-- Find best action card target
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
        
        -- Offensive actions - target opponent's character
        if cardName:find("power%-up") or cardName:find("attack") or cardName:find("damage") or 
           cardName:find("destruction") or cardName:find("feast") then
            if #opponentField > 0 then
                targetData.target = {
                    playerIndex = 1,
                    cardIndex = 1,
                    zone = "field"
                }
                targetData.priority = 6
                targetData.description = getCardDesc(1, 1)
            end
        -- Defensive/buff actions - target our character
        elseif cardName:find("shield") or cardName:find("heal") or cardName:find("boost") or
               cardName:find("protect") or cardName:find("insight") then
            if #playerField > 0 then
                targetData.target = {
                    playerIndex = 2,
                    cardIndex = 1,
                    zone = "field"
                }
                targetData.priority = 7
                targetData.description = getCardDesc(2, 1)
            end
        -- Generic actions - determine based on card specifics
        else
            -- Default to targeting opponent's character if available
            if #opponentField > 0 then
                targetData.target = {
                    playerIndex = 1,
                    cardIndex = 1,
                    zone = "field"
                }
                targetData.priority = 4
                targetData.description = getCardDesc(1, 1)
            end
        end
    end
    
    -- Return nil if no valid target found
    if not targetData.target then
        return nil
    end
    
    return targetData
end

-- Find best bench character to switch to field
function AIOpponent:findBestBenchCharacterToField()
    local player = self.game.players[2]
    
    if #player.bench == 0 then
        return nil
    end
    
    local bestIndex = 1
    local bestScore = -1
    
    for i, card in ipairs(player.bench) do
        local score = (card.power or 0) + (card.hp or 0) / 2
        
        -- Z-types and Z-fusions are generally better
        if card.characterType == "z" or card.characterType == "z-fusion" then
            score = score * 1.3
        end
        
        if score > bestScore then
            bestScore = score
            bestIndex = i
        end
    end
    
    return bestIndex
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