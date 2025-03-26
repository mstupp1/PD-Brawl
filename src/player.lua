-- Player module - handles player data and actions
local CardDatabase = require("src.data.card_database")

local Player = {}
Player.__index = Player

-- Create a new player
function Player.new(playerIndex)
    local self = setmetatable({}, Player)
    
    self.playerIndex = playerIndex
    self.essence = 0
    self.hand = {}
    self.field = {}
    self.deck = {}
    self.fusionDeck = {}
    self.graveyard = {}
    self.defeatedEnemyCount = 0
    
    -- Initialize player deck
    self:initializeDeck()
    
    return self
end

-- Initialize player deck with cards from database
function Player:initializeDeck()
    -- Load standard deck for player
    local standardDeck = CardDatabase.getStandardDeck(self.playerIndex)
    
    for _, cardData in ipairs(standardDeck.mainDeck) do
        table.insert(self.deck, CardDatabase.createCard(cardData))
    end
    
    for _, cardData in ipairs(standardDeck.fusionDeck) do
        table.insert(self.fusionDeck, CardDatabase.createCard(cardData))
    end
    
    -- Shuffle deck
    self:shuffleDeck()
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

-- Add essence to player
function Player:addEssence(amount)
    self.essence = self.essence + amount
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

-- Remove a card from hand
function Player:removeCardFromHand(index)
    if not self.hand[index] then
        return false, "Invalid card index"
    end
    
    table.remove(self.hand, index)
    return true
end

-- Add a card to field
function Player:addToField(card)
    table.insert(self.field, card)
    return #self.field
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

-- Replace a card on field with a new one (for fusion)
function Player:replaceOnField(index, newCard)
    if not self.field[index] then
        return false, "Invalid field index"
    end
    
    local oldCard = self.field[index]
    self.field[index] = newCard
    
    -- Add old card to graveyard
    table.insert(self.graveyard, oldCard)
    
    return newCard
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

-- Get all valid fusion targets in hand
function Player:getValidFusionTargets(baseCardIndex)
    local baseCard = self.field[baseCardIndex]
    if not baseCard then return {} end
    
    local validTargets = {}
    
    -- Check each card in hand for fusion compatibility
    for i, card in ipairs(self.hand) do
        if baseCard:canFuseWith(card) then
            table.insert(validTargets, i)
        end
    end
    
    return validTargets
end

-- Get player state info
function Player:getStateInfo()
    return {
        essence = self.essence,
        handCount = #self.hand,
        fieldCount = #self.field,
        deckCount = #self.deck,
        graveyardCount = #self.graveyard,
        defeatedEnemyCount = self.defeatedEnemyCount
    }
end

return Player 