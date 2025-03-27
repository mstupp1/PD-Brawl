-- Game module - core game logic for PD Brawl
local Card = require("src.card_types.card")
local Player = require("src.player")
local CardDatabase = require("src.data.card_database")

local Game = {}
Game.__index = Game

-- Create a new game instance
function Game.new()
    local self = setmetatable({}, Game)
    
    -- Initialize game state
    self.players = {
        Player.new(1),  -- Player 1 (human)
        Player.new(2)   -- Player 2 (AI)
    }
    
    self.currentPlayer = 1
    self.currentTurn = 1
    self.state = "init"
    self.winner = nil
    self.history = {} -- Add history array
    
    -- Load card database
    self.cardDatabase = CardDatabase.new()
    
    -- Initialize players' decks with cards from database
    self:initializeDecks()
    
    -- Initial draw
    for _, player in ipairs(self.players) do
        player:drawCards(5)
    end
    
    -- Ensure player 1 has at least one character card
    self:ensurePlayerHasCharacter(1)
    
    -- Start the game
    self.state = "player1Turn"
    
    return self
end

-- Ensure a player has at least one character card in their starting hand
function Game:ensurePlayerHasCharacter(playerIndex)
    local player = self.players[playerIndex]
    
    -- Check if player already has a character card
    local hasCharacter = false
    for _, card in ipairs(player.hand) do
        if card.type == "character" then
            hasCharacter = true
            break
        end
    end
    
    -- If no character card, find one in the deck and add it to hand
    if not hasCharacter then
        -- Get all character cards from the player's deck
        local characterCards = {}
        for i, card in ipairs(player.deck) do
            if card.type == "character" then
                table.insert(characterCards, {index = i, card = card})
            end
        end
        
        if #characterCards > 0 then
            -- Get a random character card
            local randomCharacter = characterCards[love.math.random(#characterCards)]
            
            -- Remove from deck and add to hand
            table.insert(player.hand, randomCharacter.card)
            table.remove(player.deck, randomCharacter.index)
            
            print("Added " .. randomCharacter.card.name .. " to player " .. playerIndex .. "'s starting hand")
        else
            -- If no character cards in deck, create a basic one
            local basicCharacter = Card.createCharacter(
                "Protagonist", 
                "A mysterious character that appears when you need them most.",
                10,
                100,
                3,
                "common"
            )
            table.insert(player.hand, basicCharacter)
            print("Added a basic character to player " .. playerIndex .. "'s starting hand")
        end
    end
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
    
    -- Reset "hasAttacked" flag on all cards for this player
    for _, card in ipairs(player.field) do
        if card.type == "character" then
            card.hasAttacked = false
        end
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
    
    -- Collect fusion materials (from hand)
    for _, idx in ipairs(materialIndices) do
        table.insert(materials, player.hand[idx])
    end
    
    -- Check if player has enough essence for fusion
    if player.essence < 2 then
        return false, "Not enough essence for fusion (requires 2)"
    end
    
    -- Check if fusion is valid
    local fusionResult = self:checkFusionValidity(baseCard, materials)
    
    if not fusionResult.valid then
        return false, fusionResult.message
    end
    
    -- Pay fusion cost
    player:useEssence(2) -- Standard cost is 2 essence
    
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
    
    return true, "Fusion successful! Created " .. fusionResult.resultCard.name
end

-- Check if fusion is valid and return result
function Game:checkFusionValidity(baseCard, materials)
    -- This would check against the fusion database
    if #materials == 0 then
        return {valid = false, message = "No fusion materials provided"}
    end
    
    -- Only character cards can be fused (for now)
    if baseCard.type ~= "character" then
        return {valid = false, message = "Base card must be a character"}
    end
    
    -- First, check if there's a specific fusion rule for these cards
    if self.cardDatabase and baseCard.id then
        -- Get material IDs
        local materialIds = {}
        for _, card in ipairs(materials) do
            table.insert(materialIds, card.id)
        end
        
        -- Check for predefined fusion result
        local fusionCard = self.cardDatabase:getFusionResult(baseCard.id, materialIds)
        if fusionCard then
            return {
                valid = true,
                essenceCost = 2,
                resultCard = fusionCard
            }
        end
    end
    
    -- Generic fusion logic if no specific fusion is found
    -- Check if all materials are compatible with the base card
    for _, card in ipairs(materials) do
        if not (card.type == "character" or card.type == "item") then
            return {valid = false, message = "Invalid fusion material type"}
        end
    end
    
    -- Generate a fusion card based on the materials
    local material = materials[1] -- For now, just use the first material
    
    -- Calculate fusion stats
    local totalPower = baseCard.power or 0
    local totalHP = baseCard.hp or 0
    local fusionName = ""
    local fusionDescription = ""
    local abilities = {}
    
    -- Combine base card and material stats/properties
    if material.type == "character" then
        -- Character + Character fusion
        totalPower = totalPower + (material.power * 0.8)
        totalHP = totalHP + (material.hp * 0.6)
        fusionName = baseCard.name .. " + " .. material.name
        fusionDescription = "A powerful fusion of " .. baseCard.name .. " and " .. material.name
        
        -- Copy abilities from both cards
        for _, ability in ipairs(baseCard.abilities or {}) do
            table.insert(abilities, ability)
        end
        for _, ability in ipairs(material.abilities or {}) do
            if not table.contains(abilities, ability) then
                table.insert(abilities, ability)
            end
        end
    elseif material.type == "item" then
        -- Character + Item fusion
        totalPower = totalPower * 1.3
        totalHP = totalHP * 1.2
        fusionName = material.name .. " " .. baseCard.name
        fusionDescription = baseCard.name .. " empowered by the " .. material.name
    end
    
    -- Some random flavor to make fusions more interesting
    local fusionTitles = {
        "Super", "Mega", "Ultimate", "Powered-Up", "Enhanced", "Evolved",
        "Perfect", "Advanced", "Supreme", "Hyper", "Deluxe", "Elite",
        "Legendary", "Mythical", "Ethereal", "Divine", "Cosmic"
    }
    
    -- Create a unique variant for the fusion
    local fusionVariants = {
        "fusion", "powered", "evolved", "legendary", "mythical",
        "cosmic", "divine", "ultimate"
    }
    
    if math.random() > 0.5 then
        -- 50% chance to add a cool title
        fusionName = fusionTitles[math.random(#fusionTitles)] .. " " .. fusionName
    end
    
    -- Round stats to look cleaner
    totalPower = math.floor(totalPower)
    totalHP = math.floor(totalHP)
    
    -- Create the fusion card
    local fusionCard = Card.new({
        id = "fusion_" .. os.time() .. "_" .. math.random(1000),
        name = fusionName,
        type = "character",
        hp = totalHP,
        maxHp = totalHP,
        essenceCost = baseCard.essenceCost + 1,
        power = totalPower,
        abilities = abilities,
        flavorText = fusionDescription,
        artVariant = fusionVariants[math.random(#fusionVariants)],
        fourthWallQuotes = {
            {context = "play", text = "I've transcended my previous form!"},
            {context = "attack", text = "Feel the power of fusion!"},
            {context = "win", text = "The combined might of two cards is unstoppable!"}
        }
    })
    
    return {
        valid = true,
        essenceCost = 2,
        resultCard = fusionCard
    }
end

-- Helper function to check if a table contains a value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
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

-- Process attack between cards
function Game:attackCard(attackerPlayerIndex, attackerCardIndex, defenderPlayerIndex, defenderCardIndex)
    local attackerPlayer = self.players[attackerPlayerIndex]
    local defenderPlayer = self.players[defenderPlayerIndex]
    
    local attackerCard = attackerPlayer.field[attackerCardIndex]
    local defenderCard = defenderPlayer.field[defenderCardIndex]
    
    if not attackerCard then
        return false, "Attacker card not found"
    end
    
    if not defenderCard then
        return false, "Defender card not found"
    end
    
    -- Check if card has already attacked this turn
    if attackerCard.hasAttacked then
        return false, "This card has already attacked this turn"
    end
    
    -- Calculate damage
    local damage = attackerCard.power or 1
    
    -- Apply damage to defending card
    defenderCard.hp = (defenderCard.hp or 0) - damage
    
    -- Mark attacker as having attacked this turn
    attackerCard.hasAttacked = true
    
    -- Log the action
    table.insert(self.history, {
        turn = self.currentTurn,
        player = attackerPlayerIndex,
        action = "attack",
        attacker = attackerCard.name,
        defender = defenderCard.name,
        damage = damage
    })
    
    -- Check if defender is defeated
    if defenderCard.hp <= 0 then
        -- Remove the defeated card
        defenderPlayer:removeFromField(defenderCardIndex)
        
        -- Increment defeated enemy count
        attackerPlayer.defeatedEnemyCount = (attackerPlayer.defeatedEnemyCount or 0) + 1
        
        -- Check win condition
        self:checkWinCondition()
        
        return true, attackerCard.name .. " defeated " .. defenderCard.name .. "!"
    end
    
    return true, attackerCard.name .. " dealt " .. damage .. " damage to " .. defenderCard.name
end

-- Initialize players' decks with cards from database
function Game:initializeDecks()
    for i, player in ipairs(self.players) do
        -- Load standard deck for player
        local standardDeck = self.cardDatabase:getStandardDeck(i)
        
        if standardDeck and standardDeck.mainDeck then
            for _, cardData in ipairs(standardDeck.mainDeck) do
                table.insert(player.deck, self.cardDatabase:createCard(cardData))
            end
            
            if standardDeck.fusionDeck then
                for _, cardData in ipairs(standardDeck.fusionDeck) do
                    table.insert(player.fusionDeck, self.cardDatabase:createCard(cardData))
                end
            end
            
            -- Shuffle deck
            player:shuffleDeck()
        else
            -- If no standard deck, add some basic cards
            local basicCards = self:createBasicCards()
            for _, card in ipairs(basicCards) do
                table.insert(player.deck, card)
            end
            player:shuffleDeck()
        end
    end
end

-- Create basic cards if no standard deck is available
function Game:createBasicCards()
    local cards = {}
    
    -- Add some character cards
    for i = 1, 4 do
        table.insert(cards, Card.createCharacter(
            "Character " .. i,
            "A basic character card.",
            i + 1, -- essence cost
            80 + i * 10, -- hp
            10 + i * 5, -- power
            "common"
        ))
    end
    
    -- Add some action cards
    for i = 1, 3 do
        table.insert(cards, Card.createAction(
            "Action " .. i,
            "A basic action card.",
            i, -- essence cost
            function(card, target, game)
                if target and target.hp then
                    target.hp = target.hp - 10
                    return true, "Dealt 10 damage"
                end
                return false, "Invalid target"
            end,
            "any",
            "common"
        ))
    end
    
    -- Add some item cards
    for i = 1, 3 do
        table.insert(cards, Card.createItem(
            "Item " .. i,
            "A basic item card.",
            i, -- essence cost
            function(card, target, game)
                if target and target.power then
                    target.power = target.power + 5
                    return true, "Power increased by 5"
                end
                return false, "Invalid target"
            end,
            "character",
            "permanent",
            "common"
        ))
    end
    
    return cards
end

return Game 