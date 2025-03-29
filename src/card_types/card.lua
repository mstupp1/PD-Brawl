-- Base Card class for PD Brawl
local Card = {}
Card.__index = Card

-- Create a new card instance
function Card.new(data)
    local self = setmetatable({}, Card)
    
    -- Base card attributes
    self.id = data.id or "unknown"
    self.name = data.name or "Unknown Card"
    self.type = data.type or "character" -- character, action, item
    self.essenceCost = data.essenceCost or 1
    self.rarity = data.rarity or "common" -- common, rare, legendary
    self.flavorText = data.flavorText or ""
    self.artVariant = data.artVariant or "standard" -- standard, vintage, fusion, etc.
    self.abilities = data.abilities or {}
    
    -- Type-specific attributes
    if self.type == "character" then
        self.hp = data.hp or 50
        self.maxHp = data.hp or 50
        self.power = data.power or 10
        self.hasAttacked = false
        self.characterType = data.characterType or "regular" -- regular, z, fusion, z-fusion
        self.fusable = false -- Characters must be on field for a turn before they can fuse
        self.justPlayed = true -- Track if the character was just played
        self.attachedEssence = 0 -- Essence attached to the character for attacks
        self.attachedItems = {} -- Items attached to the character
        
        -- Attack costs
        self.attackCosts = data.attackCosts or {
            weak = 1,   -- 50% power
            medium = 2, -- 75% power
            strong = 3, -- 100% power
            ultra = 4   -- 150% power
        }
    elseif self.type == "item" then
        self.target = data.target or "character" -- What the item can target
        self.effect = data.effect or function() end
        self.duration = data.duration or "permanent" -- permanent, temporary, once
    elseif self.type == "action" then
        self.effect = data.effect or function() end
        self.target = data.target or "any" -- any, character, player
    end
    
    -- Fourth-wall breaking properties
    self.fourthWallQuotes = data.fourthWallQuotes or {}
    self.metaAbilities = data.metaAbilities or {}
    
    return self
end

-- Play the card
function Card:play(player, game, targetInfo)
    -- Default implementation, overridden by specific card types
    return true, "Card played"
end

-- Check if this card can fuse with another card
function Card:canFuseWith(card)
    -- Only regular characters can fuse
    if self.type ~= "character" or card.type ~= "character" then
        return false
    end
    
    if self.characterType ~= "regular" or card.characterType ~= "regular" then
        return false
    end
    
    -- Both characters must have been on bench for a turn
    if not self.fusable or not card.fusable then
        return false
    end
    
    return true
end

-- Get a fourth-wall breaking quote
function Card:getFourthWallQuote(context)
    if #self.fourthWallQuotes == 0 then
        return nil
    end
    
    -- Return a quote appropriate for the context, or a random one
    for _, quote in ipairs(self.fourthWallQuotes) do
        if quote.context == context then
            return quote.text
        end
    end
    
    -- Return a random quote if no context match
    return self.fourthWallQuotes[math.random(#self.fourthWallQuotes)].text
end

-- Apply damage to this card
function Card:takeDamage(amount)
    if self.type ~= "character" then
        return false, "Only characters can take damage"
    end
    
    self.hp = math.max(0, self.hp - amount)
    
    if self.hp <= 0 then
        return true, "defeated"
    else
        return true, "damaged"
    end
end

-- Heal this card
function Card:heal(amount)
    if self.type ~= "character" then
        return false, "Only characters can be healed"
    end
    
    self.hp = math.min(self.maxHp, self.hp + amount)
    return true, "healed"
end

-- Reset this card for a new turn
function Card:resetForTurn()
    if self.type == "character" then
        self.hasAttacked = false
    end
end

-- Apply a buff to this card
function Card:applyBuff(buffType, value, duration)
    if not self.buffs then
        self.buffs = {}
    end
    
    table.insert(self.buffs, {
        type = buffType,
        value = value,
        duration = duration,
        remaining = duration
    })
    
    -- Apply immediate effect
    if buffType == "power" then
        self.power = self.power + value
    elseif buffType == "hp" then
        self.maxHp = self.maxHp + value
        self.hp = self.hp + value
    end
    
    return true, "Buff applied"
end

-- Process end of turn for this card
function Card:processTurnEnd()
    if not self.buffs then return end
    
    local buffsToRemove = {}
    
    -- Process each buff
    for i, buff in ipairs(self.buffs) do
        if buff.duration ~= "permanent" then
            buff.remaining = buff.remaining - 1
            
            if buff.remaining <= 0 then
                -- Record for removal
                table.insert(buffsToRemove, i)
                
                -- Revert buff effect
                if buff.type == "power" then
                    self.power = self.power - buff.value
                elseif buff.type == "hp" then
                    self.maxHp = self.maxHp - buff.value
                    self.hp = math.min(self.hp, self.maxHp)
                end
            end
        end
    end
    
    -- Remove expired buffs (in reverse order to avoid index shifts)
    for i = #buffsToRemove, 1, -1 do
        table.remove(self.buffs, buffsToRemove[i])
    end
end

-- Get visual representation data
function Card:getVisualData()
    local visualData = {
        name = self.name,
        type = self.type,
        rarity = self.rarity,
        flavorText = self.flavorText,
        art = self.artVariant,
        buffs = self.buffs or {}
    }
    
    if self.type == "character" then
        visualData.stats = {
            hp = self.hp,
            maxHp = self.maxHp,
            power = self.power,
            characterType = self.characterType,
            attackCosts = self.attackCosts,
            attachedEssence = self.attachedEssence or 0,
            attachedItems = #self.attachedItems or 0
        }
    end
    
    return visualData
end

-- Create a character card
function Card.createCharacter(name, flavorText, essenceCost, hp, power, rarity, characterType)
    return Card.new({
        id = "custom_" .. name:gsub("%s+", "_"):lower(),
        name = name,
        type = "character",
        characterType = characterType or "regular", -- regular, z, fusion, z-fusion
        essenceCost = essenceCost or 1,
        hp = hp or 100,
        power = power or 10,
        rarity = rarity or "common",
        flavorText = flavorText or "",
        artVariant = "standard",
        abilities = {},
        attackCosts = {
            weak = 1,   -- 50% power
            medium = 2, -- 75% power
            strong = 3, -- 100% power
            ultra = 4   -- 150% power
        },
        fourthWallQuotes = {
            {context = "play", text = "I'm ready to join the battle!"},
            {context = "attack", text = "Take that!"},
            {context = "fusion", text = "My power is growing!"}
        }
    })
end

-- Create an action card
function Card.createAction(name, flavorText, essenceCost, effect, target, rarity)
    return Card.new({
        id = "custom_" .. name:gsub("%s+", "_"):lower(),
        name = name,
        type = "action",
        essenceCost = essenceCost or 1,
        rarity = rarity or "common",
        flavorText = flavorText or "",
        artVariant = "standard",
        effect = effect or function() return true, "Action effect" end,
        target = target or "any",
        fourthWallQuotes = {
            {context = "play", text = "Action activated!"}
        }
    })
end

-- Create an item card
function Card.createItem(name, flavorText, essenceCost, effect, target, duration, rarity)
    return Card.new({
        id = "custom_" .. name:gsub("%s+", "_"):lower(),
        name = name,
        type = "item",
        essenceCost = essenceCost or 1,
        rarity = rarity or "common",
        flavorText = flavorText or "",
        artVariant = "standard",
        effect = effect or function() return true, "Item effect" end,
        target = target or "character",
        duration = duration or "permanent",
        fourthWallQuotes = {
            {context = "play", text = "Item equipped!"}
        }
    })
end

return Card 