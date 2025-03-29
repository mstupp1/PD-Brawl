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
    
    -- Coin flip to determine first player
    self.coinFlipResult = math.random(2) -- 1 or 2
    self.currentPlayer = self.coinFlipResult
    self.currentTurn = 1
    self.state = "coinFlip" -- Start with coin flip animation
    self.winner = nil
    self.history = {} -- Add history array
    self.firstTurn = true -- Track if it's the first turn
    
    -- Load card database
    self.cardDatabase = CardDatabase.new()
    
    -- Initialize players' decks with cards from database
    self:initializeDecks()
    
    -- Initial draw
    for _, player in ipairs(self.players) do
        player:drawCards(5)
    end
    
    -- Ensure both players have at least one character card
    self:ensurePlayerHasCharacter(1)
    self:ensurePlayerHasCharacter(2)
    
    return self
end

-- Ensure a player has at least one character card in their starting hand
function Game:ensurePlayerHasCharacter(playerIndex)
    local player = self.players[playerIndex]
    
    -- Check if player already has a character card
    local hasCharacter = false
    for _, card in ipairs(player.hand) do
        if card.type == "character" and card.characterType == "regular" then
            hasCharacter = true
            break
        end
    end
    
    -- If no character card, find one in the deck and add it to hand
    if not hasCharacter then
        -- Get all regular character cards from the player's deck
        local characterCards = {}
        for i, card in ipairs(player.deck) do
            if card.type == "character" and card.characterType == "regular" then
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
                1,
                100,
                10,
                "common",
                "regular" -- Character type
            )
            table.insert(player.hand, basicCharacter)
            print("Added a basic character to player " .. playerIndex .. "'s starting hand")
        end
    end
end

-- Start the game after coin flip
function Game:startGame()
    self.state = "player" .. self.currentPlayer .. "Turn"
    
    -- No essence on first turn
    -- Players start with a character on the field (handled in UI)
end

-- Update game state
function Game:update(dt)
    -- Process any ongoing animations or effects
end

-- Start a player's turn
function Game:startTurn(playerIndex)
    local player = self.players[playerIndex]
    
    -- Draw a card to start turn
    player:drawCard()
    
    -- Give player essence (except first turn)
    if not self.firstTurn then
        player:addEssence(1)
    else
        if playerIndex == 2 then -- Reset firstTurn after player 2's first turn
            self.firstTurn = false
        end
    end
    
    -- Set current player
    self.currentPlayer = playerIndex
    
    -- Increment turn counter if player 1
    if playerIndex == 1 then
        self.currentTurn = self.currentTurn + 1
    end
    
    -- Reset "hasAttacked" flag and "fusable" on all cards for this player
    for _, card in ipairs(player.field) do
        if card.type == "character" then
            card.hasAttacked = false
        end
    end
    
    for _, card in ipairs(player.bench) do
        -- Mark characters on bench as fusable if they've been there for a turn
        if card.type == "character" and not card.fusable and not card.justPlayed then
            card.fusable = true
        end
        -- Reset the justPlayed flag
        if card.justPlayed then
            card.justPlayed = false
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
function Game:playCard(playerIndex, cardIndex, targetInfo, zone)
    local player = self.players[playerIndex]
    local card = player.hand[cardIndex]
    
    if not card then return false, "Invalid card" end
    
    -- Check if it's a character card
    if card.type == "character" then
        -- Check if player has room on field or bench based on zone
        if zone == "field" and player.field[1] then
            return false, "Field already has a character"
        elseif zone == "bench" and #player.bench >= 3 then
            return false, "Bench is full"
        end
        
        -- Move card from hand to appropriate zone (no essence cost check)
        player:removeCardFromHand(cardIndex)
        
        if zone == "field" then
            player:addToField(card)
            -- No essence cost for playing cards
        elseif zone == "bench" then
            player:addToBench(card)
            -- Mark as just played so it can't fuse immediately
            card.justPlayed = true
        end
        
    -- Item cards must target a character
    elseif card.type == "item" then
        if not targetInfo or not targetInfo.zone or not targetInfo.cardIndex then
            return false, "Item requires a target character"
        end
        
        local targetZone = targetInfo.zone
        local targetCard
        
        if targetZone == "field" then
            targetCard = player.field[targetInfo.cardIndex]
        elseif targetZone == "bench" then
            targetCard = player.bench[targetInfo.cardIndex]
        else
            return false, "Invalid target zone"
        end
        
        if not targetCard or targetCard.type ~= "character" then
            return false, "Items can only be attached to characters"
        end
        
        -- Attach item to character (no essence cost check)
        if not targetCard.attachedItems then
            targetCard.attachedItems = {}
        end
        table.insert(targetCard.attachedItems, card)
        
        -- Apply item effects
        local success, message = card:play(player, self, targetCard)
        
        -- Remove card from hand
        player:removeCardFromHand(cardIndex)
        
        -- No essence cost for playing cards
        
    -- Action cards
    elseif card.type == "action" then
        -- Process action card effect (no essence cost check)
        local success, message = card:play(player, self, targetInfo)
        
        if success then
            -- No essence cost for playing cards
            
            -- Remove card from hand
            player:removeCardFromHand(cardIndex)
        end
        
        return success, message
    end
    
    -- Log the action
    table.insert(self.history, {
        turn = self.currentTurn,
        player = playerIndex,
        action = "playCard",
        card = card.name,
        zone = zone
    })
    
    return true, "Card played successfully"
end

-- Switch a character from bench to field
function Game:switchCharacter(playerIndex, benchIndex)
    local player = self.players[playerIndex]
    
    -- Check if there's a character on the field
    if not player.field[1] then
        return false, "No character on field to switch"
    end
    
    -- Check if the bench position is valid
    if not player.bench[benchIndex] then
        return false, "Invalid bench position"
    end
    
    -- Check if player has enough essence for retreating
    if player.essence < 1 then
        return false, "Not enough essence to retreat"
    end
    
    -- Switch characters
    local fieldChar = player.field[1]
    local benchChar = player.bench[benchIndex]
    
    player.field[1] = benchChar
    player.bench[benchIndex] = fieldChar
    
    -- Use essence for retreating
    player:useEssence(1)
    
    -- Log the action
    table.insert(self.history, {
        turn = self.currentTurn,
        player = playerIndex,
        action = "switch",
        benchIndex = benchIndex
    })
    
    return true, "Characters switched"
end

-- Process fusion between cards
function Game:fusionSummon(playerIndex, cardIndex1, cardIndex2)
    local player = self.players[playerIndex]
    
    -- Check if both indices are valid
    if not player.bench[cardIndex1] or not player.bench[cardIndex2] then
        return false, "Invalid bench positions"
    end
    
    local card1 = player.bench[cardIndex1]
    local card2 = player.bench[cardIndex2]
    
    -- Check if both cards are regular characters
    if card1.type ~= "character" or card2.type ~= "character" then
        return false, "Only characters can fuse"
    end
    
    if card1.characterType ~= "regular" or card2.characterType ~= "regular" then
        return false, "Only regular characters can fuse"
    end
    
    -- Check if both cards have been on bench for a turn (are fusable)
    if not card1.fusable or not card2.fusable then
        return false, "Characters must be on bench for a turn before fusion"
    end
    
    -- Check if player has enough essence
    if player.essence < 2 then
        return false, "Fusion requires 2 essence"
    end
    
    -- Check fusion and get result
    local fusionResult = self:checkFusionValidity(card1, card2)
    
    if not fusionResult.valid then
        return false, fusionResult.message
    end
    
    -- Pay fusion cost
    player:useEssence(2)
    
    -- Remove the two cards from bench
    player:removeFromBench(cardIndex1)
    player:removeFromBench(cardIndex2 < cardIndex1 and cardIndex2 or cardIndex2 - 1) -- Adjust index if needed
    
    -- Add fusion result to bench
    player:addToBench(fusionResult.resultCard)
    
    -- Mark fusion result as just played
    fusionResult.resultCard.justPlayed = true
    
    -- Log the action
    table.insert(self.history, {
        turn = self.currentTurn,
        player = playerIndex,
        action = "fusion",
        cards = {card1.name, card2.name},
        result = fusionResult.resultCard.name
    })
    
    return true, "Fusion successful! Created " .. fusionResult.resultCard.name
end

-- Check if fusion is valid and return result
function Game:checkFusionValidity(card1, card2)
    -- Ensure both are regular characters
    if card1.characterType ~= "regular" or card2.characterType ~= "regular" then
        return {valid = false, message = "Only regular characters can fuse"}
    end
    
    -- First, check if there's a specific fusion rule for these cards
    if self.cardDatabase and card1.id and card2.id then
        -- Check for predefined fusion result
        local fusionCard = self.cardDatabase:getFusionResult(card1.id, {card2.id})
        if fusionCard then
            return {
                valid = true,
                essenceCost = 2,
                resultCard = fusionCard
            }
        end
    end
    
    -- Generic fusion logic if no specific fusion is found
    -- Determine if this should be a Z-Fusion (25% chance) or regular Fusion
    local isZFusion = math.random() < 0.25
    
    -- Calculate fusion stats
    local totalPower = (card1.power or 0) + (card2.power or 0) * 0.5
    local totalHP = (card1.hp or 0) + (card2.hp or 0) * 0.5
    local fusionName = card1.name .. "-" .. card2.name .. " Fusion"
    local fusionDescription = "A fusion of " .. card1.name .. " and " .. card2.name
    local abilities = {}
    
    -- Copy abilities from both cards
    for _, ability in ipairs(card1.abilities or {}) do
        table.insert(abilities, ability)
    end
    for _, ability in ipairs(card2.abilities or {}) do
        if not table.contains(abilities, ability) then
            table.insert(abilities, ability)
        end
    end
    
    -- Z-Fusion gets better stats
    if isZFusion then
        totalPower = totalPower * 1.5
        totalHP = totalHP * 1.5
        fusionName = "Z-" .. fusionName
        fusionDescription = "A powerful Z-Fusion of " .. card1.name .. " and " .. card2.name
    end
    
    -- Some random flavor to make fusions more interesting
    local fusionTitles = {
        "Super", "Mega", "Ultimate", "Powered-Up", "Enhanced", "Evolved",
        "Perfect", "Advanced", "Supreme", "Hyper", "Deluxe", "Elite"
    }
    
    if math.random() > 0.7 then
        -- 30% chance to add a cool title
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
        characterType = isZFusion and "z-fusion" or "fusion",
        hp = totalHP,
        maxHp = totalHP,
        essenceCost = math.min(card1.essenceCost + card2.essenceCost - 1, 4), -- Cap at 4
        power = totalPower,
        abilities = abilities,
        flavorText = fusionDescription,
        attackCosts = {
            weak = 1,
            medium = 2,
            strong = 3,
            ultra = 4
        },
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

-- Process attack from field character
function Game:attackOpponent(playerIndex, attackStrength)
    local player = self.players[playerIndex]
    local opponent = self.players[playerIndex == 1 and 2 or 1]
    
    -- Check if player has a character on field
    if not player.field[1] then
        return false, "No character on field to attack with"
    end
    
    -- Check if opponent has a character on field
    if not opponent.field[1] then
        return false, "No target to attack"
    end
    
    local attackerCard = player.field[1]
    local defenderCard = opponent.field[1]
    
    -- Check if card has already attacked this turn
    if attackerCard.hasAttacked then
        return false, "This character has already attacked this turn"
    end
    
    -- Check if this is the first turn (no attacks allowed)
    if self.firstTurn then
        return false, "Cannot attack on the first turn"
    end
    
    -- Get attack cost based on strength
    local attackCost = attackerCard.attackCosts[attackStrength]
    if not attackCost then
        return false, "Invalid attack strength"
    end
    
    -- Check if player has enough essence attached to the character
    if attackerCard.attachedEssence < attackCost then
        return false, "Not enough essence attached to character for this attack"
    end
    
    -- Calculate damage based on attack strength
    local damage = 0
    if attackStrength == "weak" then
        damage = math.floor(attackerCard.power * 0.5)
    elseif attackStrength == "medium" then
        damage = math.floor(attackerCard.power * 0.75)
    elseif attackStrength == "strong" then
        damage = attackerCard.power
    elseif attackStrength == "ultra" then
        damage = math.floor(attackerCard.power * 1.5)
    end
    
    -- Use essence from the character
    attackerCard.attachedEssence = attackerCard.attachedEssence - attackCost
    
    -- Apply damage to defending card
    defenderCard.hp = defenderCard.hp - damage
    
    -- Mark attacker as having attacked this turn
    attackerCard.hasAttacked = true
    
    -- Log the action
    table.insert(self.history, {
        turn = self.currentTurn,
        player = playerIndex,
        action = "attack",
        attacker = attackerCard.name,
        defender = defenderCard.name,
        damage = damage,
        strength = attackStrength
    })
    
    -- Check if defender is defeated
    if defenderCard.hp <= 0 then
        -- Remove the defeated card
        opponent:removeFromField(1)
        
        -- Reduce opponent's hearts
        local heartsLost = 1
        if defenderCard.characterType == "z" or defenderCard.characterType == "z-fusion" then
            heartsLost = 2
        end
        
        opponent.hearts = opponent.hearts - heartsLost
        
        -- Check win condition
        if opponent.hearts <= 0 then
            self.state = "gameOver"
            self.winner = playerIndex
        end
        
        return true, attackerCard.name .. " defeated " .. defenderCard.name .. "! Opponent lost " .. heartsLost .. " heart(s)!"
    end
    
    return true, attackerCard.name .. " dealt " .. damage .. " damage to " .. defenderCard.name
end

-- Attach essence to a character
function Game:attachEssence(playerIndex, targetInfo)
    local player = self.players[playerIndex]
    
    if not targetInfo or not targetInfo.zone or not targetInfo.cardIndex then
        return false, "Invalid target"
    end
    
    -- Check if player has essence
    if player.essence <= 0 then
        return false, "No essence available"
    end
    
    local targetCard
    if targetInfo.zone == "field" then
        targetCard = player.field[targetInfo.cardIndex]
    elseif targetInfo.zone == "bench" then
        return false, "Cannot attach essence to bench characters"
    else
        return false, "Invalid target zone"
    end
    
    if not targetCard or targetCard.type ~= "character" then
        return false, "Can only attach essence to characters"
    end
    
    -- Attach essence
    if not targetCard.attachedEssence then
        targetCard.attachedEssence = 0
    end
    
    targetCard.attachedEssence = targetCard.attachedEssence + 1
    player.essence = player.essence - 1
    
    return true, "Essence attached to " .. targetCard.name
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
    for i = 1, 8 do
        table.insert(cards, Card.createCharacter(
            "Character " .. i,
            "A basic character card.",
            math.min(i, 4), -- essence cost (max 4)
            80 + i * 10, -- hp
            10 + i * 5, -- power
            "common",
            "regular" -- Regular type character
        ))
    end
    
    -- Add some Z-type characters
    for i = 1, 3 do
        table.insert(cards, Card.createCharacter(
            "Z-Character " .. i,
            "A powerful Z-type character.",
            math.min(i + 1, 4), -- essence cost (max 4)
            100 + i * 15, -- hp
            20 + i * 8, -- power
            "rare",
            "z" -- Z-type character
        ))
    end
    
    -- Add some action cards
    for i = 1, 6 do
        table.insert(cards, Card.createAction(
            "Action " .. i,
            "A basic action card.",
            math.min(i, 4), -- essence cost (max 4)
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
    for i = 1, 6 do
        table.insert(cards, Card.createItem(
            "Item " .. i,
            "A basic item card.",
            math.min(i, 4), -- essence cost (max 4)
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

-- Get current game state information
function Game:getStateInfo()
    return {
        state = self.state,
        turn = self.currentTurn,
        currentPlayer = self.currentPlayer,
        coinFlipResult = self.coinFlipResult,
        firstTurn = self.firstTurn,
        players = {
            {
                hearts = self.players[1].hearts,
                essence = self.players[1].essence,
                handSize = #self.players[1].hand,
                fieldSize = #self.players[1].field,
                benchSize = #self.players[1].bench,
                deckSize = #self.players[1].deck
            },
            {
                hearts = self.players[2].hearts,
                essence = self.players[2].essence,
                handSize = #self.players[2].hand,
                fieldSize = #self.players[2].field,
                benchSize = #self.players[2].bench,
                deckSize = #self.players[2].deck
            }
        }
    }
end

return Game 