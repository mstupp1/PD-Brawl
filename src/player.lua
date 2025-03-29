-- Player module - handles player data and actions
local Player = {}
Player.__index = Player

-- Create a new player
function Player.new(playerIndex)
    local self = setmetatable({}, Player)
    
    self.playerIndex = playerIndex
    self.essence = 0
    self.maxEssence = 1 -- Limited to 1 essence maximum
    self.hearts = 3     -- Each player starts with 3 hearts
    self.hand = {}
    self.field = {}     -- Single active character
    self.bench = {}     -- Bench for up to 3 reserve characters
    self.deck = {}
    self.fusionDeck = {}
    self.graveyard = {}
    self.defeatedEnemyCount = 0
    
    return self
end

-- Shuffle the player's deck
function Player:shuffleDeck()
    for i = #self.deck, 2, -1 do
        local j = math.random(i)
        self.deck[i], self.deck[j] = self.deck[j], self.deck[i]
    end
end

-- Draw a card from deck to hand
function Player:drawCard()
    if #self.deck == 0 then
        return false, "Deck is empty"
    end
    
    local card = table.remove(self.deck, 1)
    table.insert(self.hand, card)
    return true, "Card drawn"
end

-- Draw initial hand (5 cards)
function Player:drawInitialHand()
    for i = 1, 5 do
        self:drawCard()
    end
end

-- Draw multiple cards
function Player:drawCards(count)
    local result = true
    local message = "Drew " .. count .. " cards"
    
    for i = 1, count do
        local success, cardMsg = self:drawCard()
        if not success then
            result = false
            message = cardMsg
            break
        end
    end
    
    return result, message
end

-- Add essence to player
function Player:addEssence(amount)
    self.essence = math.min(self.essence + amount, self.maxEssence)
    return self.essence
end

-- Use essence for actions
function Player:useEssence(amount)
    if self.essence < amount then
        return false, "Not enough essence"
    end
    
    self.essence = self.essence - amount
    return true, "Essence used"
end

-- Decrease player hearts
function Player:loseHeart(amount)
    self.hearts = self.hearts - amount
    return self.hearts <= 0, "Player lost " .. amount .. " heart(s)"
end

-- Remove a card from hand
function Player:removeCardFromHand(index)
    if not self.hand[index] then
        return false, "Invalid card index"
    end
    
    table.remove(self.hand, index)
    return true
end

-- Add a card to field (single character slot)
function Player:addToField(card)
    -- Replace any existing card on field
    if #self.field > 0 then
        table.insert(self.graveyard, self.field[1])
        self.field[1] = card
    else
        table.insert(self.field, card)
    end
    return true
end

-- Add a card to bench (up to 3 characters)
function Player:addToBench(card)
    if #self.bench >= 3 then
        return false, "Bench is full"
    end
    
    table.insert(self.bench, card)
    return true
end

-- Remove a card from field
function Player:removeFromField(index)
    if not self.field[index] then
        return false, "Invalid field index"
    end
    
    local card = table.remove(self.field, index)
    table.insert(self.graveyard, card)
    return card
end

-- Remove a card from bench
function Player:removeFromBench(index)
    if not self.bench[index] then
        return false, "Invalid bench index"
    end
    
    local card = table.remove(self.bench, index)
    table.insert(self.graveyard, card)
    return card
end

-- Move card from bench to field
function Player:benchToField(benchIndex)
    if not self.bench[benchIndex] then
        return false, "Invalid bench index"
    end
    
    -- If there's already a character on field, swap them
    if #self.field > 0 then
        local fieldCard = self.field[1]
        self.field[1] = self.bench[benchIndex]
        self.bench[benchIndex] = fieldCard
    else
        -- Otherwise just move bench card to field
        self.field[1] = self.bench[benchIndex]
        table.remove(self.bench, benchIndex)
    end
    
    return true
end

-- Attack opponent's card
function Player:attackCard(attackingIndex, targetPlayer, targetIndex)
    if not self.field[attackingIndex] then
        return false, "Invalid attacker"
    end
    
    if not targetPlayer.field[targetIndex] then
        return false, "Invalid target"
    end
    
    local attacker = self.field[attackingIndex]
    local target = targetPlayer.field[targetIndex]
    
    -- Calculate battle result
    local attackerPower = attacker.power or 0
    local targetHP = target.hp
    
    -- Reduce target HP by attack power
    target.hp = target.hp - attackerPower
    
    -- Check if target is defeated
    if target.hp <= 0 then
        targetPlayer:removeFromField(targetIndex)
        self.defeatedEnemyCount = self.defeatedEnemyCount + 1
        return true, string.format("%s defeated %s!", attacker.name, target.name)
    end
    
    return true, string.format("%s damaged %s! %d HP remaining", attacker.name, target.name, target.hp)
end

-- Get all valid fusion targets on bench
function Player:getValidFusionTargets(benchCardIndex)
    local baseCard = self.bench[benchCardIndex]
    if not baseCard or baseCard.type ~= "character" or baseCard.characterType ~= "regular" then 
        return {} 
    end
    
    -- Only regular characters that have been on the bench for a turn can fuse
    if not baseCard.fusable then
        return {}
    end
    
    local validTargets = {}
    
    -- Check each card on bench for fusion compatibility
    for i, card in ipairs(self.bench) do
        if i ~= benchCardIndex and 
           card.type == "character" and 
           card.characterType == "regular" and
           card.fusable then
            table.insert(validTargets, i)
        end
    end
    
    return validTargets
end

-- Get player state info
function Player:getStateInfo()
    return {
        essence = self.essence,
        maxEssence = self.maxEssence,
        hearts = self.hearts,
        handCount = #self.hand,
        fieldCount = #self.field,
        benchCount = #self.bench,
        deckCount = #self.deck,
        graveyardCount = #self.graveyard,
        defeatedEnemyCount = self.defeatedEnemyCount
    }
end

return Player 