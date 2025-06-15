-- #region Mimine

local mimineItemId = Isaac.GetItemIdByName("Mimine")
local mimineLuckPerItem = 1

-- #region Mimine Luck processing
local function MimineSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Mimine: " .. tostring(err) .. "\n")
    end
end

-- Evaluate Mimine's luck bonus effect
function Grenneh:EvaluateMimineCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
        local mimineItemCount = player:GetCollectibleNum(mimineItemId)
        local totalLuckToAdd = mimineLuckPerItem * mimineItemCount
        player.Luck = player.Luck + totalLuckToAdd
    end
end

-- Wrapper for EvaluateMimineCache with SafeCall
function Grenneh:EvaluateMimineCacheSafe(player, cacheFlags)
    MimineSafeCall(Grenneh.EvaluateMimineCache, Grenneh, player, cacheFlags)
end

Grenneh:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Grenneh.EvaluateMimineCacheSafe)

-- #endregion
-- #region Mimine Item spawning processing
-- List of all Guppy item IDs
local guppyItemIds = {
    Isaac.GetItemIdByName("Guppy's Tail"),
    Isaac.GetItemIdByName("Guppy's Collar"),
    Isaac.GetItemIdByName("Dead Cat"),
    Isaac.GetItemIdByName("Guppy's Hairball")
}

-- Get a list of Guppy items that the player does not already have
function Grenneh:GetMimineAvailableGuppyItems(player)
    local availableGuppyItems = {}
    for _, itemId in ipairs(guppyItemIds) do
        if not player:HasCollectible(itemId) then
            table.insert(availableGuppyItems, itemId)
        end
    end
    return availableGuppyItems
end

-- Handle Mimine's effect when entering a new room
function Grenneh:HandleMimineNewRoom()
    local player = Isaac.GetPlayer(0)
    local room = Grenneh.game:GetRoom()

    -- Check if the player has Mimine and if it's the first visit to the room
    if not player:HasCollectible(mimineItemId) or not room:IsFirstVisit() then
        return -- Do nothing if player doesn't have Mimine or room isn't visited for the first time
    end

    local availableGuppyItems = Grenneh:GetMimineAvailableGuppyItems(player)
    if #availableGuppyItems == 0 then
        return -- Do nothing if all Guppy items are already collected
    end

    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            local pickup = entity:ToPickup()
            if pickup and not pickup:IsShopItem() then
                -- 8% chance to reroll into an available Guppy item
                if math.random() < 0.08 then
                    local randomIndex = math.random(#availableGuppyItems)
                    local randomGuppyItem = availableGuppyItems[randomIndex]
                    pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, randomGuppyItem, true)
                end
            end
        end
    end
end

-- Wrapper for HandleMimineNewRoom with SafeCall
function Grenneh:HandleMimineNewRoomSafe()
    MimineSafeCall(Grenneh.HandleMimineNewRoom, Grenneh)
end

Grenneh:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Grenneh.HandleMimineNewRoomSafe)

-- #endregion
-- #endregion
-- #region Haricot pet (play song when grennehBean used) (fart)

local grennehBeanSound = Isaac.GetSoundIdByName("Fartmod")

---@param grennehBean   CollectibleType
---@param rng           RNG
---@param player        EntityPlayer
---@param useFlag       UseFlag
---@param activeSlot    ActiveSlot
---@param varData       CustomVarData
---@return boolean
function Grenneh:useGrennehBean(grennehBean, rng, player, useFlag, activeSlot, varData)
    Grenneh.sound:Play(grennehBeanSound, 2, 0, false, 1)
end

Grenneh:AddCallback(ModCallbacks.MC_USE_ITEM, Grenneh.useGrennehBean, grennehBean)

-- #endregion
-- #region Kramptus (Can't test if it works, TODO review later)

local kramptus = Isaac.GetItemIdByName("Head of Kramptus")

function Grenneh:useKramptus()
    local player = Isaac.GetPlayer(0)

    local hud = Grenneh.game:GetHUD()
    -- setup message
    local message = "Eh, t'as les Kramptus ?"

    -- display
    hud:ShowFortuneText(message)

    -- remove
    player:RemoveCollectible(kramptus,false, ActiveSlot.SLOT_PRIMARY, true)
end

Grenneh:AddCallback(ModCallbacks.MC_USE_ITEM, Grenneh.useKramptus, kramptus)

-- #endregion