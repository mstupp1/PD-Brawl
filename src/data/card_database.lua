-- Card Database for PD Brawl
local Card = require("src.card_types.card")

local CardDatabase = {}
CardDatabase.__index = CardDatabase

-- Create a new CardDatabase instance
function CardDatabase.new()
    local self = setmetatable({}, CardDatabase)
    return self
end

-- Card data for all available cards
local cardData = {
    -- Character Cards
    characters = {
        -- Popeye (entered public domain in 2024)
        {
            id = "popeye_standard",
            name = "Sailor Popeye",
            type = "character",
            essenceCost = 2,
            hp = 100,
            power = 30,
            rarity = "rare",
            flavorText = "I yam what I yam and that's all what I yam!",
            artVariant = "standard",
            abilities = {"spinach_power"},
            fourthWallQuotes = {
                {context = "play", text = "Ready to clobber the competition, I am!"},
                {context = "attack", text = "Hope ya don't mind me breakin' the fourth wall!"},
                {context = "defeat", text = "The animator drew me losin'? That ain't fair!"}
            },
            fusionRequirements = {"spinach_item"}
        },
        {
            id = "popeye_fusion",
            name = "Spinach-Powered Popeye",
            type = "character",
            essenceCost = 4,
            hp = 150,
            power = 50,
            rarity = "legendary",
            flavorText = "I'm strong to the finish, 'cause I eats me spinach!",
            artVariant = "fusion",
            abilities = {"spinach_power", "anchor_toss"},
            fourthWallQuotes = {
                {context = "play", text = "The animator gave me extra muscles this time!"},
                {context = "attack", text = "I'll knock ya right outta the card frame!"},
                {context = "win", text = "Blow me down! I won the whole game!"}
            }
        },
        
        -- Original Mickey Mouse (1928 Steamboat Willie entered public domain in 2024)
        {
            id = "steamboat_mickey",
            name = "Steamboat Mickey",
            type = "character",
            essenceCost = 1,
            hp = 60,
            power = 15,
            rarity = "common",
            flavorText = "Whistling away on the steamboat!",
            artVariant = "vintage",
            abilities = {"whistle_distraction"},
            fourthWallQuotes = {
                {context = "play", text = "Finally free from the clutches of copyright!"},
                {context = "damage", text = "Ouch! Careful with the vintage character!"},
                {context = "fusion", text = "This game's animator is getting creative with me!"}
            },
            fusionRequirements = {"steamboat_wheel"}
        },
        {
            id = "cigar_mickey",
            name = "Cigar-Chomping Mickey",
            type = "character",
            essenceCost = 3,
            hp = 80,
            power = 25,
            rarity = "rare",
            flavorText = "A little edgier than the corporate version...",
            artVariant = "parody",
            abilities = {"smoke_screen", "whistle_distraction"},
            fourthWallQuotes = {
                {context = "play", text = "The big company would NEVER let me smoke in their parks!"},
                {context = "attack", text = "Surprise! I'm not the family-friendly version!"},
                {context = "win", text = "Ha ha! Public domain for the win!"}
            }
        },
        
        -- Sherlock Holmes (long in public domain)
        {
            id = "sherlock_holmes",
            name = "Sherlock Holmes",
            type = "character",
            essenceCost = 3,
            hp = 80,
            power = 20,
            rarity = "rare",
            flavorText = "Elementary, my dear player.",
            artVariant = "classic",
            abilities = {"deduction", "pipe_smoke"},
            fourthWallQuotes = {
                {context = "play", text = "I've been in the public domain so long, I've lost count of my adaptations!"},
                {context = "examine", text = "I can see you're holding your cards at a slight angle. Interesting."},
                {context = "win", text = "The game is afoot, and now it's over!"}
            },
            fusionRequirements = {"watson_card"}
        },
        {
            id = "sexy_sherlock",
            name = "Sexy Sherlock",
            type = "character",
            essenceCost = 4,
            hp = 90,
            power = 25,
            rarity = "legendary",
            flavorText = "The game is afoot... and so am I.",
            artVariant = "parody",
            abilities = {"deduction", "charming_distraction"},
            fourthWallQuotes = {
                {context = "play", text = "Sir Arthur Conan Doyle never described me THIS way!"},
                {context = "attack", text = "My powers of observation note you're blushing!"},
                {context = "fusion", text = "I deduce this fusion will be... stimulating."}
            }
        },
        
        -- Dracula (public domain)
        {
            id = "count_dracula",
            name = "Count Dracula",
            type = "character",
            essenceCost = 3,
            hp = 100,
            power = 25,
            rarity = "rare",
            flavorText = "I vant to drink your... essence!",
            artVariant = "classic",
            abilities = {"life_drain", "bat_form"},
            fourthWallQuotes = {
                {context = "play", text = "Bram Stoker created me, but the public domain sustains me!"},
                {context = "attack", text = "I never drink... coffee. But I will drain your life points!"},
                {context = "night", text = "Ah! The game switches to night mode. My power grows!"}
            },
            fusionRequirements = {"full_moon_card"}
        },
        {
            id = "surfer_dracula",
            name = "Surfer Dude Dracula",
            type = "character",
            essenceCost = 3,
            hp = 90,
            power = 30,
            rarity = "rare",
            flavorText = "Hanging ten under the moonlight, dude!",
            artVariant = "parody",
            abilities = {"life_drain", "wave_rider"},
            fourthWallQuotes = {
                {context = "play", text = "Bram Stoker is totally rolling in his grave right now, dude!"},
                {context = "attack", text = "Gonna catch some waves and some blood, bro!"},
                {context = "sunlight", text = "Whoa, harsh vibes with that sunlight, man!"}
            }
        }
    },
    
    -- Action Cards
    actions = {
        {
            id = "spinach_power",
            name = "Spinach Power-Up",
            type = "action",
            essenceCost = 1,
            target = "character",
            rarity = "common",
            flavorText = "Instant muscles, just add leafy greens!",
            effect = function(card, target, game)
                target:applyBuff("power", 20, 2)
                return true, "Power increased by 20 for 2 turns"
            end,
            fourthWallQuotes = {
                {context = "play", text = "Even in card form, this stuff works wonders!"}
            }
        },
        {
            id = "detective_insight",
            name = "Detective's Insight",
            type = "action",
            essenceCost = 2,
            target = "player",
            rarity = "uncommon",
            flavorText = "A glance reveals all!",
            effect = function(card, target, game)
                -- Allows player to see opponent's hand for one turn
                -- This would be implemented in the UI
                return true, "You can see your opponent's hand until your next turn"
            end,
            fourthWallQuotes = {
                {context = "play", text = "I can see through the fourth wall... and your strategy!"}
            }
        },
        {
            id = "midnight_feast",
            name = "Midnight Feast",
            type = "action",
            essenceCost = 2,
            target = "character",
            rarity = "uncommon",
            flavorText = "Dining under the stars... on someone else's vitality.",
            effect = function(card, target, opponent, game)
                local damage = 15
                target:takeDamage(damage)
                card.owner:heal(damage)
                return true, "Drained " .. damage .. " HP from enemy"
            end,
            fourthWallQuotes = {
                {context = "play", text = "This card is in-VEIN-tive, wouldn't you say?"}
            }
        },
        {
            id = "public_domain_shuffle",
            name = "Public Domain Shuffle",
            type = "action",
            essenceCost = 3,
            target = "any",
            rarity = "rare",
            flavorText = "Copyright law can't touch this move!",
            effect = function(card, game)
                -- Shuffle all characters back into decks and redraw
                return true, "All characters returned to their decks"
            end,
            fourthWallQuotes = {
                {context = "play", text = "Lawyers HATE this one weird trick!"}
            }
        }
    },
    
    -- Item Cards
    items = {
        {
            id = "spinach_can",
            name = "Can of Spinach",
            type = "item",
            essenceCost = 1,
            target = "character",
            duration = "permanent",
            rarity = "common",
            flavorText = "Essential nutrition for sailors and card battlers alike.",
            effect = function(card, target, game)
                target:applyBuff("power", 15, "permanent")
                return true, "Power permanently increased by 15"
            end,
            fourthWallQuotes = {
                {context = "play", text = "The animators always give me one of these when I need it most!"}
            }
        },
        {
            id = "deerstalker_hat",
            name = "Deerstalker Hat",
            type = "item",
            essenceCost = 1,
            target = "character",
            duration = "permanent",
            rarity = "uncommon",
            flavorText = "Elementary fashion, my dear player.",
            effect = function(card, target, game)
                -- Once per turn, examine one card in opponent's hand
                return true, "Can examine one opponent card per turn"
            end,
            fourthWallQuotes = {
                {context = "play", text = "I never actually wore this in the books, you know!"}
            }
        },
        {
            id = "captains_wheel",
            name = "Captain's Wheel",
            type = "item",
            essenceCost = 2,
            target = "character",
            duration = "permanent",
            rarity = "uncommon",
            flavorText = "Take the wheel and steer this duel!",
            effect = function(card, target, game)
                target:applyBuff("hp", 20, "permanent")
                -- Add ability to redirect one attack per turn
                return true, "HP increased by 20, can redirect one attack per turn"
            end,
            fourthWallQuotes = {
                {context = "play", text = "Now I'm the captain of this game!"}
            }
        },
        {
            id = "vintage_microphone",
            name = "Vintage Microphone",
            type = "item",
            essenceCost = 1,
            target = "character",
            duration = "permanent",
            rarity = "common",
            flavorText = "Broadcasting across the fourth wall!",
            effect = function(card, target, game)
                -- Allows character to stun an opponent once per turn
                return true, "Can stun one opponent character per turn"
            end,
            fourthWallQuotes = {
                {context = "play", text = "Testing, testing! Can the player hear me?"}
            }
        }
    },
    
    -- Fusion Results (accessed through fusion mechanic, not directly in deck)
    fusionResults = {
        {
            id = "popeye_spinach_fusion",
            baseCard = "popeye_standard",
            materials = {"spinach_can"},
            result = "popeye_fusion"
        },
        {
            id = "detective_duo",
            baseCard = "sherlock_holmes",
            materials = {"watson_card"},
            result = {
                id = "detective_duo",
                name = "Holmes & Watson",
                type = "character",
                essenceCost = 5,
                hp = 140,
                power = 35,
                rarity = "legendary",
                flavorText = "The dynamic duo of deduction!",
                artVariant = "fusion",
                abilities = {"deduction", "faithful_assistant", "pipe_smoke"},
                fourthWallQuotes = {
                    {context = "play", text = "Together in the public domain, solving mysteries across card games!"},
                    {context = "attack", text = "Watson, observe how I break this fourth wall!"},
                    {context = "win", text = "The case of the card game victory is closed!"}
                }
            }
        }
    }
}

-- Create a card from data
function CardDatabase:createCard(data)
    return Card.new(data)
end

-- Get a standard starter deck
function CardDatabase:getStandardDeck(playerIndex)
    -- For demo purposes, create preset decks
    -- In a full game, this would let players build custom decks
    local decks = {
        -- Player 1: Vintage Heroes Deck
        {
            mainDeck = {
                cardData.characters[1], -- Popeye
                cardData.characters[3], -- Steamboat Mickey
                cardData.characters[5], -- Sherlock Holmes
                cardData.characters[7], -- Count Dracula
                cardData.actions[1],    -- Spinach Power-Up
                cardData.actions[1],    -- Spinach Power-Up (duplicate)
                cardData.actions[2],    -- Detective's Insight
                cardData.actions[3],    -- Midnight Feast
                cardData.items[1],      -- Can of Spinach
                cardData.items[2],      -- Deerstalker Hat
                cardData.items[3],      -- Captain's Wheel
                cardData.items[4],      -- Vintage Microphone
                -- Duplicate some cards to reach desired deck size
                cardData.characters[1], -- Popeye (duplicate)
                cardData.characters[3], -- Steamboat Mickey (duplicate)
                cardData.actions[4],    -- Public Domain Shuffle
                cardData.items[1],      -- Can of Spinach (duplicate)
                cardData.items[2],      -- Deerstalker Hat (duplicate)
                cardData.items[3],      -- Captain's Wheel (duplicate)
                cardData.items[4],      -- Vintage Microphone (duplicate)
                cardData.actions[2],    -- Detective's Insight (duplicate)
            },
            fusionDeck = {
                -- Fusion results would be accessed through fusion mechanic
            }
        },
        
        -- Player 2: Parody Versions Deck
        {
            mainDeck = {
                cardData.characters[2], -- Spinach-Powered Popeye
                cardData.characters[4], -- Cigar-Chomping Mickey
                cardData.characters[6], -- Sexy Sherlock
                cardData.characters[8], -- Surfer Dude Dracula
                cardData.actions[1],    -- Spinach Power-Up
                cardData.actions[2],    -- Detective's Insight
                cardData.actions[3],    -- Midnight Feast
                cardData.actions[4],    -- Public Domain Shuffle
                cardData.items[1],      -- Can of Spinach
                cardData.items[2],      -- Deerstalker Hat
                cardData.items[3],      -- Captain's Wheel
                cardData.items[4],      -- Vintage Microphone
                -- Duplicate some cards to reach desired deck size
                cardData.characters[2], -- Spinach-Powered Popeye (duplicate)
                cardData.characters[4], -- Cigar-Chomping Mickey (duplicate)
                cardData.actions[1],    -- Spinach Power-Up (duplicate)
                cardData.actions[3],    -- Midnight Feast (duplicate)
                cardData.items[1],      -- Can of Spinach (duplicate)
                cardData.items[3],      -- Captain's Wheel (duplicate)
                cardData.items[4],      -- Vintage Microphone (duplicate)
                cardData.actions[4],    -- Public Domain Shuffle (duplicate)
            },
            fusionDeck = {
                -- Fusion results would be accessed through fusion mechanic
            }
        }
    }
    
    return decks[playerIndex] or decks[1]
end

-- Get a card by ID
function CardDatabase:getCardById(id)
    -- Search through all card types
    for _, category in pairs(cardData) do
        for _, card in ipairs(category) do
            if card.id == id then
                return self:createCard(card)
            end
        end
    end
    
    return nil
end

-- Get fusion result for combination
function CardDatabase:getFusionResult(baseCardId, materialIds)
    for _, fusion in ipairs(cardData.fusionResults) do
        if fusion.baseCard == baseCardId then
            -- Check if materials match
            local materialMatches = true
            
            if #fusion.materials ~= #materialIds then
                materialMatches = false
            else
                for i, material in ipairs(fusion.materials) do
                    if material ~= materialIds[i] then
                        materialMatches = false
                        break
                    end
                end
            end
            
            if materialMatches then
                -- Return fusion result
                if type(fusion.result) == "string" then
                    return self:getCardById(fusion.result)
                else
                    return self:createCard(fusion.result)
                end
            end
        end
    end
    
    return nil
end

-- Get all cards
function CardDatabase:getAllCards()
    local allCards = {}
    
    for _, category in pairs(cardData) do
        for _, card in ipairs(category) do
            table.insert(allCards, card)
        end
    end
    
    return allCards
end

return CardDatabase 