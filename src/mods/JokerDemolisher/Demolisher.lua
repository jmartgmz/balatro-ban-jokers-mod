-- Return cached instance if it exists (singleton pattern)
if JokerDemolisher_Demolisher then
    return JokerDemolisher_Demolisher
end

local mod_path = SMODS.current_mod and SMODS.current_mod.path or JokerDemolisher_ModPath
-- Cache mod_path globally for other modules
JokerDemolisher_ModPath = mod_path

local Utils = assert(loadfile(mod_path .. "Utils.lua"))()
local Persistence = assert(loadfile(mod_path .. "Persistence.lua"))()

local Demolisher = {}

function Demolisher.checkGloballyDisabled(center)
    if not center or not center.key or not center.set then
        return false
    end
    return Persistence.isGloballyDisabled(center.key, center.set)
end

function Demolisher.runGloballyDisabledFlips(card)
    if card and card.config and card.config.center then
        local isGloballyDisabled = Demolisher.checkGloballyDisabled(card.config.center)
        if isGloballyDisabled and card.facing == 'front' then
            card:flip()
        elseif not isGloballyDisabled and card.facing == 'back' then
            card:flip()
        end
    end
end

function Demolisher.Enable()
    -- Load saved globally disabled items
    Persistence.loadGloballyDisabled()
    
    -- Hook Game:start_run to apply global bans
    local GameStartRun = Game.start_run
    function Game:start_run(args)
        GameStartRun(self, args)
        
        -- Apply globally disabled jokers to banned_keys
        G.GAME.banned_keys = G.GAME.banned_keys or {}
        for _, key in ipairs(Utils.globallyDisabledJokers) do
            G.GAME.banned_keys[key] = true
        end
    end
    
    -- Hook Card:click to toggle global disable in collection view
    local CardClick = Card.click
    function Card:click()
        -- Handle globally disabling items in vanilla collection view (only when card is in collection area)
        if G.your_collection then
            -- Check if this card is actually in the collection areas
            local isInCollection = false
            for j = 1, #G.your_collection do
                if G.your_collection[j] and G.your_collection[j].cards then
                    for i = 1, #G.your_collection[j].cards do
                        if G.your_collection[j].cards[i] == self then
                            isInCollection = true
                            break
                        end
                    end
                end
                if isInCollection then break end
            end
            
            if isInCollection and self.config and self.config.center then
                local center = self.config.center
                local itemType = center.set
                if itemType == 'Joker' then
                    local isNowDisabled = Persistence.toggleGloballyDisabled(center.key, itemType)
                    -- Flip the card to show it's disabled/enabled
                    self:flip()
                    self:juice_up(0.3, 0.3)
                    if isNowDisabled then
                        play_sound('card1', 0.8, 0.5)
                    else
                        play_sound('card1', 1.2, 0.5)
                    end
                    return
                end
            end
        end
        
        CardClick(self)
    end
    
    -- Track collection cards for global disable flips
    local globalDisableCollectionProcessed = {}
    local lastCollectionCardKeys = ""
    
    local OriginalUpdate = love.update
    function love.update(dt)
        if OriginalUpdate then
            OriginalUpdate(dt)
        end
        
        -- Check if we're in collection view and need to flip globally disabled items
        if G.your_collection then
            -- Build a string of all current card keys to detect page changes
            local currentCardKeys = ""
            for j = 1, #G.your_collection do
                if G.your_collection[j] and G.your_collection[j].cards then
                    for i = 1, #G.your_collection[j].cards do
                        local card = G.your_collection[j].cards[i]
                        if card and card.config and card.config.center then
                            currentCardKeys = currentCardKeys .. (card.config.center.key or "") .. ","
                        end
                    end
                end
            end
            
            -- Reset processed list if the cards changed (page change or new collection)
            if currentCardKeys ~= lastCollectionCardKeys then
                globalDisableCollectionProcessed = {}
                lastCollectionCardKeys = currentCardKeys
            end
            
            for j = 1, #G.your_collection do
                if G.your_collection[j] and G.your_collection[j].cards then
                    for i = 1, #G.your_collection[j].cards do
                        local card = G.your_collection[j].cards[i]
                        if card and card.config and card.config.center then
                            local cardId = j .. "_" .. i .. "_" .. (card.config.center.key or "")
                            if not globalDisableCollectionProcessed[cardId] then
                                globalDisableCollectionProcessed[cardId] = true
                                Demolisher.runGloballyDisabledFlips(card)
                            end
                        end
                    end
                end
            end
        else
            -- Clear the processed list when not in collection view
            if lastCollectionCardKeys ~= "" then
                globalDisableCollectionProcessed = {}
                lastCollectionCardKeys = ""
            end
        end
    end
    
    Utils.log("JokerDemolisher mod enabled")
end

-- Cache the instance globally
JokerDemolisher_Demolisher = Demolisher

return Demolisher
