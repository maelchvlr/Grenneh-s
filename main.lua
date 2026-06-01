local MyMod = RegisterMod("Grenneh Mod", 1)

local grennehType = Isaac.GetPlayerTypeByName("Grenneh", false)
local grennetteType = Isaac.GetPlayerTypeByName("Grennette", true)



local grennehHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_hair.anm2") 
local grennehstolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_stoles.anm2") 
local grennetteHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_hair.anm2") 
local grennettestolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_stoles.anm2") 
local grennettewigCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_wig.anm2") 
local redbullWingCostume = Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_FATE)


local skillIssue = Isaac.GetSoundIdByName("SkillIssue")

local SkillIssue= {
    ID = Isaac.GetPillEffectByName("Skill Issue"),

}

SkillIssue.Color = Isaac.AddPillEffectToPool(SkillIssue.ID)

function MyMod:GiveCostumesOnInit(player)
    if player:GetPlayerType() == grennehType then
        player:AddNullCostume(grennehHairCostume)
        player:AddNullCostume(grennehstolesCostume)
        return -- Only give costumes to Grenneh
    elseif player:GetPlayerType() == grennetteType then
        player:AddNullCostume(grennetteHairCostume)
        player:AddNullCostume(grennettestolesCostume)
        return -- Only give costumes to Grennette
    end


end

MyMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyMod.GiveCostumesOnInit)


-- Function to check if an item is a key item
function MyMod:IsKeyItem(itemID)
    if not itemID or itemID <= 0 then
        return true
    end

    local itemConfig = Isaac.GetItemConfig():GetCollectible(itemID)
    if itemConfig and ItemConfig and ItemConfig.TAG_QUEST then
        local success, isQuestItem = pcall(function()
            return itemConfig.Tags and (itemConfig.Tags & ItemConfig.TAG_QUEST) == ItemConfig.TAG_QUEST
        end)

        if success and isQuestItem then
            return true
        end
    end

    local KeyItem = {}
    local function addKeyItem(collectibleId)
        if collectibleId then
            KeyItem[#KeyItem + 1] = collectibleId
        end
    end

    addKeyItem(CollectibleType.COLLECTIBLE_POLAROID)
    addKeyItem(CollectibleType.COLLECTIBLE_NEGATIVE)
    addKeyItem(CollectibleType.COLLECTIBLE_KEY_PIECE_1)
    addKeyItem(CollectibleType.COLLECTIBLE_KEY_PIECE_2)
    addKeyItem(CollectibleType.COLLECTIBLE_DADS_NOTE)
    addKeyItem(CollectibleType.COLLECTIBLE_KNIFE_PIECE_1)
    addKeyItem(CollectibleType.COLLECTIBLE_KNIFE_PIECE_2)
    addKeyItem(CollectibleType.COLLECTIBLE_BROKEN_SHOVEL_1)
    addKeyItem(CollectibleType.COLLECTIBLE_BROKEN_SHOVEL_2)
    addKeyItem(CollectibleType.COLLECTIBLE_MOMS_SHOVEL)
    addKeyItem(CollectibleType.COLLECTIBLE_DOGMA)
    
    -- Check if the itemID is in the KeyItem list
    for _, keyItem in ipairs(KeyItem) do
        if itemID == keyItem then
            return true
        end
    end
    return false
end

local function IsPlayerEntity(entity)
    return entity and entity.Type == EntityType.ENTITY_PLAYER
end

local function IsCollectiblePickup(entity)
    return entity
        and entity.Type == EntityType.ENTITY_PICKUP
        and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE
        and entity:ToPickup() ~= nil
end

local MarkCollectibleSeen

function MyMod:CanRerollCollectiblePickup(pickup)
    if not pickup or not pickup:Exists() then
        return false
    end

    if pickup.SubType <= 0 or MyMod:IsKeyItem(pickup.SubType) then
        return false
    end

    return true
end

function MyMod:CanModRerollCollectiblePickup(pickup)
    return MyMod:CanRerollCollectiblePickup(pickup)
        and (not MyMod.IsChoixRoom or not MyMod:IsChoixRoom())
end

local function MorphCollectible(pickup, itemId, keepPrice)
    if not pickup or not pickup:Exists() or not itemId or itemId <= 0 then
        return false
    end

    local originalPrice = pickup.Price
    pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemId, true, true, false)
    pcall(function()
        local itemPool = Game():GetItemPool()
        if itemPool.RemoveCollectible then
            itemPool:RemoveCollectible(itemId)
        end
    end)
    if MarkCollectibleSeen then
        MarkCollectibleSeen(itemId)
    end

    if keepPrice and originalPrice and originalPrice ~= 0 then
        pickup.Price = originalPrice
    end

    return true
end

--------------------------------------------------------------------------------------------------
-- Gestion Grenneh

local game = Game() -- Grabbing game
local sound = SFXManager()
local music = MusicManager()

local modState = {
    seenCollectibles = {},
    tatanoCount = {},
    bottleCount = {},
    monsterSixthTriggered = {},
    monsterInversionTimers = {},
    wigCostumeApplied = {},
    redbullWingsApplied = {},
    moonPillActive = false,
    moonPillProcessedRooms = {},
    moonPillClearProcessedRooms = {},
    grennetteTransformation = false,
    grennetteTransformationProgress = -1
}

local function SafeCall(context, func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in " .. context .. ": " .. tostring(err) .. "\n")
    end
end

local function GetPlayerKey(player)
    local data = player:GetData()
    if not data.GrennehModPlayerKey then
        data.GrennehModPlayerKey = tostring(player.InitSeed)
    end
    return data.GrennehModPlayerKey
end

local function ForEachPlayer(callback)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player and player:Exists() then
            callback(player)
        end
    end
end

local function AnyPlayerHasCollectible(collectibleId)
    local hasCollectible = false
    ForEachPlayer(function(player)
        if player:HasCollectible(collectibleId) then
            hasCollectible = true
        end
    end)
    return hasCollectible
end

local function AddCollectibleIfMissing(player, collectibleId)
    if collectibleId and collectibleId > 0 and not player:HasCollectible(collectibleId) then
        player:AddCollectible(collectibleId, 0, false)
    end
end

local function AddTears(player, tearsUp)
    local currentTears = 30 / (player.MaxFireDelay + 1)
    player.MaxFireDelay = math.max(0, (30 / math.max(0.1, currentTears + tearsUp)) - 1)
end

MarkCollectibleSeen = function(collectibleId)
    if collectibleId and collectibleId > 0 then
        modState.seenCollectibles[collectibleId] = true
    end
end

local function WasCollectibleSeen(collectibleId)
    return collectibleId and collectibleId > 0 and modState.seenCollectibles[collectibleId]
end

local function GetUnseenCollectibleFromPool(poolType, seed, maxAttempts, qualityPredicate)
    local itemPool = Game():GetItemPool()
    local chosenItem = 0
    maxAttempts = maxAttempts or 20
    seed = seed or Game():GetRoom():GetSpawnSeed()

    for attempt = 1, maxAttempts do
        local candidate = itemPool:GetCollectible(poolType, false, seed + attempt)
        local itemConfig = Isaac.GetItemConfig():GetCollectible(candidate)
        if candidate and candidate > 0
            and not MyMod:IsKeyItem(candidate)
            and not WasCollectibleSeen(candidate)
            and (not qualityPredicate or qualityPredicate(itemConfig))
        then
            chosenItem = candidate
            break
        end
    end

    if chosenItem <= 0 then
        for attempt = 1, maxAttempts do
            local candidate = itemPool:GetCollectible(poolType, false, seed + maxAttempts + attempt)
            if candidate and candidate > 0 and not MyMod:IsKeyItem(candidate) then
                chosenItem = candidate
                break
            end
        end
    end

    MarkCollectibleSeen(chosenItem)
    return chosenItem
end

function MyMod:TrackSeenCollectiblePickup(pickup)
    if pickup and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
        MarkCollectibleSeen(pickup.SubType)
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, MyMod.TrackSeenCollectiblePickup, PickupVariant.PICKUP_COLLECTIBLE)

function MyMod:ResetRunState(isContinued)
    if isContinued then
        ForEachPlayer(function(player)
            local playerKey = GetPlayerKey(player)
            modState.tatanoCount[playerKey] = player:GetCollectibleNum(Isaac.GetItemIdByName("Tatanosaurus"))
            modState.bottleCount[playerKey] = player:GetCollectibleNum(Isaac.GetItemIdByName("A Bo'oh'o'wa'er"))
        end)
        return
    end

    modState.seenCollectibles = {}
    modState.tatanoCount = {}
    modState.bottleCount = {}
    modState.monsterSixthTriggered = {}
    modState.monsterInversionTimers = {}
    modState.wigCostumeApplied = {}
    modState.redbullWingsApplied = {}
    modState.moonPillActive = false
    modState.moonPillProcessedRooms = {}
    modState.moonPillClearProcessedRooms = {}
    modState.grennetteTransformation = false
    modState.grennetteTransformationProgress = -1
end

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MyMod.ResetRunState)


function MyMod:HandleStartingStats(player, flag)
    if player:GetPlayerType() == grennehType then
        if flag == CacheFlag.CACHE_DAMAGE then
            -- Cap damage at 5
            player.Damage = player.Damage * 0.3
        end

        if flag == CacheFlag.CACHE_FIREDELAY then
            -- Uncap delay
            
            player.MaxFireDelay = player.MaxFireDelay * 0.15


        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.HandleStartingStats)

function MyMod:OnPlayerInit(player)
    if player:GetPlayerType() == grennehType then
        AddCollectibleIfMissing(player, Isaac.GetItemIdByName("Mimine"))
        AddCollectibleIfMissing(player, Isaac.GetItemIdByName("Grenneh's bean"))
    end

    if player:GetPlayerType() == grennetteType then
        AddCollectibleIfMissing(player, Isaac.GetItemIdByName("Head of Kramptus"))
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyMod.OnPlayerInit)

local hitSound = Isaac.GetSoundIdByName("GrennehHit")

function MyMod:damage()
    if Isaac.GetPlayer(0):GetPlayerType() == Isaac.GetPlayerTypeByName("Grenneh") then
        local pitch = math.random(80,120)/100
        sound:Play(hitSound,2.0,0, false, pitch)
    end
end

 
function MyMod:db()
    if Isaac.GetPlayer(0):GetPlayerType() == Isaac.GetPlayerTypeByName("Grenneh") then
        if (sound:IsPlaying(SoundEffect.SOUND_ISAAC_HURT_GRUNT)) then
            sound:Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT);
        end
    end
end

 

MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, MyMod.db)
MyMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, MyMod.damage, EntityType.ENTITY_PLAYER)


---------------------------------------------------------------------------------------------------
-- Mimine

local mimineItemId = Isaac.GetItemIdByName("Mimine")
local mimineLuckPerItem = 1

-- Safely execute a function and catch any errors
local function MimineSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Mimine: " .. tostring(err) .. "\n")
    end
end

-- Evaluate Mimine's luck bonus effect
function MyMod:EvaluateMimineCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
        local mimineItemCount = player:GetCollectibleNum(mimineItemId)
        local totalLuckToAdd = mimineLuckPerItem * mimineItemCount
        player.Luck = player.Luck + totalLuckToAdd
    end
end

-- Wrapper for EvaluateMimineCache with SafeCall
function MyMod:EvaluateMimineCacheSafe(player, cacheFlags)
    MimineSafeCall(MyMod.EvaluateMimineCache, MyMod, player, cacheFlags)
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateMimineCacheSafe)

-- List of all Guppy item IDs
local guppyItemIds = {
    Isaac.GetItemIdByName("Guppy's Tail"),
    Isaac.GetItemIdByName("Guppy's Collar"),
    Isaac.GetItemIdByName("Dead Cat"),
    Isaac.GetItemIdByName("Guppy's Hairball"),
    Isaac.GetItemIdByName("Guppy's Head"),
    Isaac.GetItemIdByName("Guppy's Paw"),
    Isaac.GetItemIdByName("Guppy's Eye")
}

-- Get a list of Guppy items that the player does not already have
function MyMod:GetMimineAvailableGuppyItems(player)
    local availableGuppyItems = {}
    for _, itemId in ipairs(guppyItemIds) do
        if itemId and itemId > 0 and not player:HasCollectible(itemId) and not WasCollectibleSeen(itemId) then
            table.insert(availableGuppyItems, itemId)
        end
    end
    return availableGuppyItems
end

-- Handle Mimine's effect when entering a new room
function MyMod:HandleMimineNewRoom()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    
    -- Check if the player has Mimine and if it's the first visit to the room
    if not player:HasCollectible(mimineItemId) or not room:IsFirstVisit() then
        return -- Do nothing if player doesn't have Mimine or room isn't visited for the first time
    end

    local availableGuppyItems = MyMod:GetMimineAvailableGuppyItems(player)
    if #availableGuppyItems == 0 then
        return -- Do nothing if all Guppy items are already collected
    end

    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        if IsCollectiblePickup(entity) then
            local pickup = entity:ToPickup()
            if MyMod:CanModRerollCollectiblePickup(pickup) and not pickup:IsShopItem() then
                -- 8% chance to reroll into an available Guppy item
                if math.random() < 0.08 then
                    local randomIndex = math.random(#availableGuppyItems)
                    local randomGuppyItem = availableGuppyItems[randomIndex]
                    MorphCollectible(pickup, randomGuppyItem, false)
                end
            end
        end
    end
end

-- Wrapper for HandleMimineNewRoom with SafeCall
function MyMod:HandleMimineNewRoomSafe()
    MimineSafeCall(MyMod.HandleMimineNewRoom, MyMod)
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.HandleMimineNewRoomSafe)


--------------------------------------------------------------------------------------------------------------
-- Haricot pet

local grennehBean = Isaac.GetItemIdByName("Grenneh's bean")
local grennehBeanSound = Isaac.GetSoundIdByName("Fartmod")

function MyMod:useGrennehBean(_, rng, player, flags, slot)
    sound:Play(grennehBeanSound, 2, 0, false, 1)
    return true
end

MyMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyMod.useGrennehBean, grennehBean)





--------------------------------------------------------------------------------------------------------------
-- Kramptus

local kramptus = Isaac.GetItemIdByName("Head of Kramptus")

function MyMod:useKramptus(_, rng, player, flags, slot)
    player = player or Isaac.GetPlayer(0)
    slot = slot or ActiveSlot.SLOT_PRIMARY

    local hud = game:GetHUD()
    -- setup message
    local message = "T'as les cramptés"

    -- display
    hud:ShowFortuneText(message)

    -- remove
    player:RemoveCollectible(kramptus, false, slot, true)
    return true
end

MyMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyMod.useKramptus, kramptus)

-------------------------------------------------------------------------------------------------------------
-- BMTH

local bmthItemId = Isaac.GetItemIdByName("BMTH !")
local bmthDamagePerItem = 2.5

-- Safely execute a function and catch any errors
local function BmthSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in BMTH!: " .. tostring(err) .. "\n")
    end
end

-- Evaluate BMTH! item effects on damage
function MyMod:EvaluateBmthCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local bmthItemCount = player:GetCollectibleNum(bmthItemId)
        local totalDamageToAdd = bmthDamagePerItem * bmthItemCount
        player.Damage = player.Damage + totalDamageToAdd
    end
end

-- Wrapper for EvaluateBmthCache with SafeCall
function MyMod:EvaluateBmthCacheSafe(player, cacheFlags)
    BmthSafeCall(MyMod.EvaluateBmthCache, MyMod, player, cacheFlags)
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateBmthCacheSafe)

-- Update BMTH! tear effects
function MyMod:UpdateBmthTear(tear)
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(bmthItemId) then
        -- Change tear color to red
        tear.Color = Color(1, 0, 0, 1, 0, 0, 0)  -- Red tears
    end
end

-- Wrapper for UpdateBmthTear with SafeCall
function MyMod:UpdateBmthTearSafe(tear)
    BmthSafeCall(MyMod.UpdateBmthTear, MyMod, tear)
end

MyMod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, MyMod.UpdateBmthTearSafe)

-- Handle BMTH! blood trail effect
function MyMod:HandleBmthBloodTrail(player)
    if not player:HasCollectible(bmthItemId) then
        return -- End the function early if the player doesn't have BMTH!
    end

    -- Every 4 frames, spawn a blood creep effect
    if player.Velocity:Length() > 0.1 and Game():GetFrameCount() % 4 == 0 then
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, player.Position, Vector.Zero, player):ToEffect()
        creep.SpriteScale = Vector(0.5, 0.5) -- Make the creep smaller
        creep:Update() -- Update the creep to get rid of the initial red animation
    end
end

-- Wrapper for HandleBmthBloodTrail with SafeCall
function MyMod:HandleBmthBloodTrailSafe(player)
    BmthSafeCall(MyMod.HandleBmthBloodTrail, MyMod, player)
end

MyMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyMod.HandleBmthBloodTrailSafe)

--------------------------------------------------------------------------------------------------------------
-- Chaise

local chaise = Isaac.GetItemIdByName("Gaming Chair")
local chaiseSpeed = 0.4

function MyMod:EvaluateChair(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
        local itemCount = player:GetCollectibleNum(chaise);
        local spdToAdd = chaiseSpeed * itemCount
        player.MoveSpeed = player.MoveSpeed + spdToAdd
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateChair)


--------------------------------------------------------------------------------------------------------------
-- Thatano

local tatano = Isaac.GetItemIdByName("Tatanosaurus")


function MyMod:updateTatano()
    ForEachPlayer(function(player)
        local playerKey = GetPlayerKey(player)
        local previousCount = modState.tatanoCount[playerKey] or 0
        local currentCount = player:GetCollectibleNum(tatano)

        if currentCount > previousCount then
            local gainedCopies = currentCount - previousCount
            player:AddMaxHearts(4 * gainedCopies, false)
            player:AddHearts(4 * gainedCopies)
        end

        modState.tatanoCount[playerKey] = currentCount
    end)
end

MyMod:AddCallback( ModCallbacks.MC_POST_UPDATE, MyMod.updateTatano);


--------------------------------------------------------------------------------------------------------------
-- bouteille

local bouteille = Isaac.GetItemIdByName("A Bo'oh'o'wa'er")
local bouteilleTearsUp = 0.7

function MyMod:updateBouteille()
    ForEachPlayer(function(player)
        local playerKey = GetPlayerKey(player)
        modState.bottleCount[playerKey] = player:GetCollectibleNum(bouteille)
    end)
end

MyMod:AddCallback( ModCallbacks.MC_POST_UPDATE, MyMod.updateBouteille);

function MyMod:EvaluateBouteille(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
        AddTears(player, bouteilleTearsUp * player:GetCollectibleNum(bouteille))
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateBouteille)

--------------------------------------------------------------------------------------------------------------
-- redbull

local redbull = Isaac.GetItemIdByName("Redbull")

function MyMod:EvaluateRedbull(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
        local itemCount = player:GetCollectibleNum(redbull)
        if itemCount > 0 then
            player.MoveSpeed = math.max(player.MoveSpeed, 2) + (0.2 * (itemCount - 1))
        end
    end

    if cacheFlags & CacheFlag.CACHE_FLYING == CacheFlag.CACHE_FLYING then
        if player:HasCollectible(redbull) then
            player.CanFly = true  -- Grant the player the ability to fly    
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateRedbull)

function MyMod:UpdateRedbullWings(player)
    if not player or not player:Exists() then
        return
    end

    local playerKey = GetPlayerKey(player)
    if player:HasCollectible(redbull) then
        if not modState.redbullWingsApplied[playerKey] then
            player:AddCostume(redbullWingCostume, false)
            modState.redbullWingsApplied[playerKey] = true
        end
    elseif modState.redbullWingsApplied[playerKey] then
        pcall(function()
            player:TryRemoveCollectibleCostume(CollectibleType.COLLECTIBLE_FATE, false)
        end)
        pcall(function()
            player:RemoveCostume(redbullWingCostume)
        end)
        modState.redbullWingsApplied[playerKey] = false
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    SafeCall("Redbull wings", MyMod.UpdateRedbullWings, MyMod, player)
end)

---------------------------------------------------------------------------------------------------------------------
-- Pillule

function SkillIssue.Proc(_PillEffect)
    local level = game:GetLevel()
    level:SetRedHeartDamage()
    sound:Play(skillIssue, 2, 0, false, 1)
end

MyMod:AddCallback(ModCallbacks.MC_USE_PILL, SkillIssue.Proc, SkillIssue.ID)




-- V.0.2


--------------------------------------------------------------------------------------------------------------
-- Monster
local monsterItemId = Isaac.GetItemIdByName("Monster")
local monsterDamageMultiplier = 1.2
local monsterSpeedMultiplier = 0.1
local monsterTearRateMultiplier = -0.2
local visitedRooms = {}  -- To track if a room has been visited

function MyMod:IsMonsterCleansed(player)
    return modState.monsterSixthTriggered[GetPlayerKey(player)] == true
end

function MyMod:IsMonsterInversionActive(player)
    if not player or not player:Exists() or MyMod:IsMonsterCleansed(player) then
        return false
    end

    return (modState.monsterInversionTimers[GetPlayerKey(player)] or 0) > 0
end

function MyMod:StartMonsterInversion(player, duration)
    if player and player:Exists() and not MyMod:IsMonsterCleansed(player) then
        modState.monsterInversionTimers[GetPlayerKey(player)] = duration or 75
    end
end

function MyMod:HandleMonsterDoubleDamage(entity, amount, flags, source, countdown)
    local player = entity and entity:ToPlayer()
    if not player or not player:Exists() then
        return
    end

    local data = player:GetData()
    if data.GrennehMonsterApplyingDoubleDamage then
        return
    end

    if player:GetCollectibleNum(monsterItemId) >= 3 and not MyMod:IsMonsterCleansed(player) then
        data.GrennehMonsterApplyingDoubleDamage = true
        player:TakeDamage(amount * 2, flags, source, countdown)
        data.GrennehMonsterApplyingDoubleDamage = false
        return false
    end
end

function MyMod:HandleMonsterDoubleDamageSafe(entity, amount, flags, source, countdown)
    local result
    local success, err = pcall(function()
        result = MyMod.HandleMonsterDoubleDamage(MyMod, entity, amount, flags, source, countdown)
    end)

    if not success then
        Isaac.ConsoleOutput("Error in Monster double damage: " .. tostring(err) .. "\n")
    end

    return result
end

MyMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, MyMod.HandleMonsterDoubleDamageSafe, EntityType.ENTITY_PLAYER)

-- Safely execute a function and catch any errors
local function MonsterSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Monster: " .. tostring(err) .. "\n")
    end
end

-- Evaluate Monster item effects on player stats
function MyMod:EvaluateMonsterCache(player, cacheFlags)
    if not player or not player:Exists() then return end  -- Ensure player exists

    local itemCount = player:GetCollectibleNum(monsterItemId)

    if itemCount >= 1 and cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * monsterDamageMultiplier ^ itemCount
    end
    if itemCount >= 2 and cacheFlags & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed * (1 + monsterSpeedMultiplier) ^ (itemCount - 1)
    end
    if itemCount >= 3 and cacheFlags & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay * (1 + monsterTearRateMultiplier) ^ (itemCount - 2)
    end
    if itemCount >= 4 then
        local radioactiveGreen = Color(0.4, 0.5, 0.4, 0.8, 0, 0.5, 0)  -- RGB with a strong green glow
        player.TearColor = radioactiveGreen
        player:SetColor(radioactiveGreen, 0, 1, false, false)  -- Set player color to radioactive green
    end
end

-- Wrapper for EvaluateMonsterCache with SafeCall
function MyMod:EvaluateMonsterCacheSafe(player, cacheFlags)
    MonsterSafeCall(MyMod.EvaluateMonsterCache, MyMod, player, cacheFlags)
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateMonsterCacheSafe)

-- Update Monster tear effects
function MyMod:UpdateMonsterTear(tear)
    -- Ensure the tear exists before proceeding
    if not tear or not tear:Exists() or tear:GetData().grennehMonsterRedirected then
        return -- Exit the function early if the tear is invalid
    end

    local player = tear.Parent and tear.Parent:ToPlayer() or Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists
    if MyMod:IsMonsterCleansed(player) then return end

    local itemCount = player:GetCollectibleNum(monsterItemId)

    if itemCount >= 4 then
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_POISON

        if math.random() < 0.3 then
            tear:Remove()
            local newTear = player:FireTear(player.Position, Vector.FromAngle(math.random() * 360) * 10, false, false, false)
            if newTear then
                newTear:GetData().grennehMonsterRedirected = true
            end
        end
    end
end

-- Wrapper for UpdateMonsterTear with SafeCall
function MyMod:UpdateMonsterTearSafe(tear)
    MonsterSafeCall(MyMod.UpdateMonsterTear, MyMod, tear)
end

MyMod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, MyMod.UpdateMonsterTearSafe)

-- Handle the one-time effect when picking up the sixth Monster item
function MyMod:HandleMonsterItemPickup(player)
    if not player or not player:Exists() then return end  -- Ensure player exists

    local itemCount = player:GetCollectibleNum(monsterItemId)
    local playerKey = GetPlayerKey(player)
    if itemCount >= 6 and not modState.monsterSixthTriggered[playerKey] then
        player:Die()  -- Kill the player to apply the one-time effect
        modState.monsterSixthTriggered[playerKey] = true
    end
end

-- Wrapper for HandleMonsterItemPickup with SafeCall
function MyMod:HandleMonsterItemPickupSafe(player)
    MonsterSafeCall(MyMod.HandleMonsterItemPickup, MyMod, player)
end

MyMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyMod.HandleMonsterItemPickupSafe)

-- Update inverted controls if applicable
function MyMod:UpdateMonsterInvertedControls()
    ForEachPlayer(function(player)
        local playerKey = GetPlayerKey(player)
        local timer = modState.monsterInversionTimers[playerKey] or 0

        if timer > 0 then
            if MyMod:IsMonsterCleansed(player) or player:GetCollectibleNum(monsterItemId) < 5 then
                modState.monsterInversionTimers[playerKey] = 0
            else
                modState.monsterInversionTimers[playerKey] = timer - 1
            end
        end
    end)
end

-- Wrapper for UpdateMonsterInvertedControls with SafeCall
function MyMod:UpdateMonsterInvertedControlsSafe()
    MonsterSafeCall(MyMod.UpdateMonsterInvertedControls, MyMod)
end

MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, MyMod.UpdateMonsterInvertedControlsSafe)

function MyMod:InvertMonsterInput(entity, inputHook, buttonAction)
    local player = entity and entity:ToPlayer()
    if not player or not MyMod:IsMonsterInversionActive(player) then
        return
    end

    local oppositeAction = nil
    if buttonAction == ButtonAction.ACTION_LEFT then
        oppositeAction = ButtonAction.ACTION_RIGHT
    elseif buttonAction == ButtonAction.ACTION_RIGHT then
        oppositeAction = ButtonAction.ACTION_LEFT
    elseif buttonAction == ButtonAction.ACTION_UP then
        oppositeAction = ButtonAction.ACTION_DOWN
    elseif buttonAction == ButtonAction.ACTION_DOWN then
        oppositeAction = ButtonAction.ACTION_UP
    else
        return
    end

    if inputHook == InputHook.GET_ACTION_VALUE then
        return Input.GetActionValue(oppositeAction, player.ControllerIndex)
    elseif inputHook == InputHook.IS_ACTION_PRESSED then
        return Input.IsActionPressed(oppositeAction, player.ControllerIndex)
    elseif inputHook == InputHook.IS_ACTION_TRIGGERED then
        return Input.IsActionTriggered(oppositeAction, player.ControllerIndex)
    end
end

function MyMod:InvertMonsterInputSafe(entity, inputHook, buttonAction)
    local result
    local success, err = pcall(function()
        result = MyMod.InvertMonsterInput(MyMod, entity, inputHook, buttonAction)
    end)

    if not success then
        Isaac.ConsoleOutput("Error in Monster input inversion: " .. tostring(err) .. "\n")
    end

    return result
end

MyMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, MyMod.InvertMonsterInputSafe)

-- Handle effects when entering a new room
function MyMod:HandleMonsterNewRoom()
    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists

    local level = Game():GetLevel()
    local currentRoomIndex = tostring(level:GetStage()) .. ":" .. tostring(level:GetCurrentRoomIndex())
    local itemCount = player:GetCollectibleNum(monsterItemId)

    if not visitedRooms[currentRoomIndex] then
        visitedRooms[currentRoomIndex] = true  -- Mark the room as visited

        -- Reroll a random item on the floor to 'Monster' based on item count, if not the sixth pickup
        if math.random() < (0.1 * itemCount) and not MyMod:IsMonsterCleansed(player) then
            for _, entity in pairs(Isaac.GetRoomEntities()) do
                if IsCollectiblePickup(entity) then
                    local pickup = entity:ToPickup()
                    if MyMod:CanModRerollCollectiblePickup(pickup) and pickup.SubType ~= monsterItemId then
                        MorphCollectible(pickup, monsterItemId, pickup:IsShopItem())
                        break  -- Only reroll one item per room entry
                    end
                end
            end
        end

        -- Invert controls if the player has at least 5 Monster items, but not the sixth pickup
        if itemCount >= 5 and math.random() < 0.1 and not MyMod:IsMonsterCleansed(player) then
            MyMod:StartMonsterInversion(player, 75)  -- Invert controls for 2.5 seconds (30 frames per second)
        end

        -- 25% chance to activate Unicorn Stump effect if player has 5 or more Monster items
        if itemCount >= 5 and math.random() < 0.2 then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN, false, true, false, false)
        end
    end
end

-- Wrapper for HandleMonsterNewRoom with SafeCall
function MyMod:HandleMonsterNewRoomSafe()
    MonsterSafeCall(MyMod.HandleMonsterNewRoom, MyMod)
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.HandleMonsterNewRoomSafe)

-- Handle potential reroll of any pickup into 'Monster'
function MyMod:HandleMonsterPickupInit(pickup)
    if not pickup or not pickup:Exists() then return end  -- Ensure pickup exists

    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists

    local itemCount = player:GetCollectibleNum(monsterItemId)

    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE
        and pickup.SubType ~= monsterItemId
        and math.random() < (0.1 * itemCount)
        and not MyMod:IsMonsterCleansed(player)
        and MyMod:CanModRerollCollectiblePickup(pickup)
    then
        MorphCollectible(pickup, monsterItemId, pickup:IsShopItem())
    end
end

-- Wrapper for HandleMonsterPickupInit with SafeCall
function MyMod:HandleMonsterPickupInitSafe(pickup)
    MonsterSafeCall(MyMod.HandleMonsterPickupInit, MyMod, pickup)
end

MyMod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, MyMod.HandleMonsterPickupInitSafe)

-- Reset Monster room state when starting a new run
function MyMod:MonsterReset()
    visitedRooms = {}
    modState.monsterInversionTimers = {}
end 

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MyMod.MonsterReset)


-------- Choix du Chat

local choixDuChat = Isaac.GetItemIdByName("Choix du Chat")
local choixRoomActive = false
local choixCleanupFrames = 0

function MyMod:IsChoixRoom()
    local roomDesc = Game():GetLevel():GetCurrentRoomDesc()
    return roomDesc and roomDesc.Data and roomDesc.Data.Variant == 7777
end

function MyMod:RemoveOtherChoixPedestals(chosenPickup)
    if not choixRoomActive or not MyMod:IsChoixRoom() or not chosenPickup then
        return
    end

    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if IsCollectiblePickup(entity) and entity.InitSeed ~= chosenPickup.InitSeed then
            entity:Remove()
        end
    end
end

function MyMod:RemoveRemainingChoixPedestals()
    if not choixRoomActive or not MyMod:IsChoixRoom() then
        return
    end

    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if IsCollectiblePickup(entity) then
            entity:Remove()
        end
    end
end

-- When the item is used
function MyMod:UseChoixDuChat(_, rng, player, flags, slot)
    player = player or Isaac.GetPlayer(0)
    slot = slot or ActiveSlot.SLOT_PRIMARY
    player:AnimateTeleport(true)
    choixRoomActive = true
    Isaac.ExecuteCommand("goto s.default.7777")  -- Teleport to the custom room
    player:RemoveCollectible(choixDuChat, false, slot, true)  -- Remove the item from the inventory
    return true
end

MyMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyMod.UseChoixDuChat, choixDuChat)

-- Function to handle room entry
function MyMod:ChoixNewRoom()
    if choixRoomActive and MyMod:IsChoixRoom() then
        game:GetHUD():ShowItemText("Chat, on prends quoi?", "")
    elseif choixRoomActive then
        choixRoomActive = false
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.ChoixNewRoom)

function MyMod:OnChoixPickupCollision(pickup, collider)
    if IsPlayerEntity(collider) and MyMod:CanRerollCollectiblePickup(pickup) then
        MyMod:RemoveOtherChoixPedestals(pickup)
        choixCleanupFrames = 3
    end
end

MyMod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, MyMod.OnChoixPickupCollision, PickupVariant.PICKUP_COLLECTIBLE)

function MyMod:UpdateChoixCleanup()
    if choixCleanupFrames <= 0 then
        return
    end

    choixCleanupFrames = choixCleanupFrames - 1
    if choixCleanupFrames == 0 then
        MyMod:RemoveRemainingChoixPedestals()
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, MyMod.UpdateChoixCleanup)

function MyMod:ResetChoixRoom()
    choixRoomActive = false
    choixCleanupFrames = 0
end

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MyMod.ResetChoixRoom)

----- happenings

local happeningSounds = Isaac.GetSoundIdByName("Happening")

function MyMod:PlayRandomSoundOnRoomEntry()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    
    if room:IsFirstVisit() then
        -- low% chance to play a sound
        if math.random(1, 1500) == 1 then
            sound:Play(happeningSounds, 1.0, 0, false, 1.0)
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.PlayRandomSoundOnRoomEntry)

------- Grennette's Mascara


local grennettesMascara = Isaac.GetItemIdByName("Grennette's Mascara")

-- Define colors for Grennette's Mascara rainbow tears with pastel transition
local grennettesMascaraRainbowColors = {
    Color(1, 0, 0, 1, 0, 0, 0),     -- Red
    Color(1, 0.5, 0, 1, 0, 0, 0),   -- Orange
    Color(1, 1, 0, 1, 0, 0, 0),     -- Yellow
    Color(0, 1, 0, 1, 0, 0, 0),     -- Green
    Color(0, 0, 1, 1, 0, 0, 0),     -- Blue
    Color(0.29, 0, 0.51, 1, 0, 0, 0), -- Indigo
    Color(0.56, 0, 1, 1, 0, 0, 0)   -- Violet
}

local grennettesMascaraColorIndex = 1
local grennettesMascaraColorTransitionSpeed = 0.25 -- Faster color transition speed
local grennettesMascaraCurrentColor = grennettesMascaraRainbowColors[grennettesMascaraColorIndex]
local grennettesMascaraMaxTearSize = 3.0 -- Maximum allowed tear size for Grennette's Mascara

-- Helper function to handle errors gracefully
local function grennettesMascaraSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Grennette's Mascara: " .. tostring(err) .. "\n")
    end
end

-- Evaluate Grennette's Mascara item effects
function MyMod:EvaluateGrennettesMascaraCache(player, cacheFlag)
    if not player or not player:Exists() then return end  -- Ensure player exists

    if player:HasCollectible(grennettesMascara) then
        if cacheFlag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * 2.0 -- Double damage
        end
        if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = player.MaxFireDelay + 2 -- Reduce fire rate (increase delay)
        end
        if cacheFlag & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + 2 -- Increase luck
        end
        if cacheFlag & CacheFlag.CACHE_TEARFLAG == CacheFlag.CACHE_TEARFLAG then
            player.TearFlags = player.TearFlags | TearFlags.TEAR_PIERCING | TearFlags.TEAR_SPECTRAL -- Allow tears to pierce and pass through walls
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheFlag)
    grennettesMascaraSafeCall(MyMod.EvaluateGrennettesMascaraCache, MyMod, player, cacheFlag)
end)

-- Update color transition for Grennette's Mascara tears
function MyMod:UpdateGrennettesMascaraColorTransition()
    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists

    if player:HasCollectible(grennettesMascara) then
        local nextColorIndex = grennettesMascaraColorIndex % #grennettesMascaraRainbowColors + 1
        local nextColor = grennettesMascaraRainbowColors[nextColorIndex]

        grennettesMascaraCurrentColor = Color(
            grennettesMascaraCurrentColor.R + (nextColor.R - grennettesMascaraCurrentColor.R) * grennettesMascaraColorTransitionSpeed,
            grennettesMascaraCurrentColor.G + (nextColor.G - grennettesMascaraCurrentColor.G) * grennettesMascaraColorTransitionSpeed,
            grennettesMascaraCurrentColor.B + (nextColor.B - grennettesMascaraCurrentColor.B) * grennettesMascaraColorTransitionSpeed,
            1,
            0,
            0,
            0
        )

        -- Update index when fully transitioned to the next color
        if (math.abs(grennettesMascaraCurrentColor.R - nextColor.R) < 0.01 and
            math.abs(grennettesMascaraCurrentColor.G - nextColor.G) < 0.01 and
            math.abs(grennettesMascaraCurrentColor.B - nextColor.B) < 0.01) then
            grennettesMascaraColorIndex = nextColorIndex
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    grennettesMascaraSafeCall(MyMod.UpdateGrennettesMascaraColorTransition, MyMod)
end)

-- Update Grennette's Mascara tear effects
function MyMod:OnGrennettesMascaraTearUpdate(tear)
    -- Ensure the tear and player exist before proceeding
    if not tear or not tear:Exists() then return end
    local player = tear.Parent and tear.Parent:ToPlayer()
    if not player or not player:Exists() then return end

    if player:HasCollectible(grennettesMascara) then
        -- Assign smooth transition color to tears
        tear.Color = grennettesMascaraCurrentColor

        -- Apply tear effects: Charm, piercing, and spectral
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_CHARM | TearFlags.TEAR_PIERCING | TearFlags.TEAR_SPECTRAL

        -- Initialize the tear size
        local tearData = tear:GetData()
        if not tearData.grennettesMascaraInitialized then
            tear.Scale = 1.5 -- Start with larger tears
            tearData.grennettesMascaraInitialized = true
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    grennettesMascaraSafeCall(MyMod.OnGrennettesMascaraTearUpdate, MyMod, tear)
end)

-- Handle Grennette's Mascara tear collision effects
function MyMod:OnGrennettesMascaraTearCollision(tear, entity)
    -- Ensure the tear, player, and entity exist before proceeding
    if not tear or not tear:Exists() then return end
    local player = tear.Parent and tear.Parent:ToPlayer()
    if not player or not player:Exists() then return end
    if not entity or not entity:Exists() or not entity:IsVulnerableEnemy() then return end

    if player:HasCollectible(grennettesMascara) then
        tear.Scale = math.min(tear.Scale + 0.2, grennettesMascaraMaxTearSize) -- Increase the size of the tear, capped at maxTearSize
    end
end

MyMod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, tear, entity)
    grennettesMascaraSafeCall(MyMod.OnGrennettesMascaraTearCollision, MyMod, tear, entity)
end)


------ Contemplation de la lune pillule

local moonPillEffect = Isaac.GetPillEffectByName("Cérémonie de Contemplation de la Lune")
local moonPillColor = Isaac.AddPillEffectToPool(moonPillEffect)

-- Add custom sound
local moonPillSound = Isaac.GetSoundIdByName("MoonPillSound") -- Ensure this sound is registered in sounds.xml

-- Callback to handle using the Moon Pill
function MyMod:UseMoonPill(pillEffect, player)
    if pillEffect ~= moonPillEffect then
        return
    end

    modState.moonPillActive = true
    modState.moonPillProcessedRooms = {}
    modState.moonPillClearProcessedRooms = {}

    -- Apply Curse of Darkness for the rest of the floor.
    game:GetLevel():AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
    sound:Play(moonPillSound, 1.0, 0, false, 1.0)

    ForEachPlayer(function(currentPlayer)
        currentPlayer:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        currentPlayer:EvaluateItems()
    end)

    MyMod:OnLuneNewRoom()
end

-- Function to find a nearby position to place duplicates
function MyMod:FindNearbyPosition(originalPosition)
    local offsets = {
        Vector(40, 0),  -- Right
        Vector(-40, 0), -- Left
        Vector(0, 40),  -- Down
        Vector(0, -40)  -- Up
    }

    local room = Game():GetRoom()

    -- Try each offset to find a valid position
    for _, offset in ipairs(offsets) do
        local duplicatePosition = originalPosition + offset
        if room:IsPositionInRoom(duplicatePosition, 0) then
            return duplicatePosition
        end
    end

    -- Default to the original position if no valid nearby position found
    return originalPosition
end

function MyMod:IsMoonPillBlockedRoom()
    local room = Game():GetRoom()
    return room and room:GetType() == RoomType.ROOM_SHOP
end

-- Callback to handle doubling enemies and bosses in each room
function MyMod:DoubleEnemiesInRooms()
    local room = Game():GetRoom()
    if modState.moonPillActive and not MyMod:IsMoonPillBlockedRoom() and room:GetFrameCount() <= 1 then
        local entities = Isaac.GetRoomEntities()
        for _, entity in ipairs(entities) do
            if entity:IsVulnerableEnemy() and entity:IsActiveEnemy(false) and not entity:GetData().GrennehMoonDuplicate then
                -- Find a nearby position for the duplicate
                local duplicatePosition = self:FindNearbyPosition(entity.Position)

                -- Duplicate the enemy
                local clone = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, duplicatePosition, Vector(0, 0), nil)
                clone:ClearEntityFlags(EntityFlag.FLAG_APPEAR) -- Ensure it doesn't reappear
                clone:GetData().GrennehMoonDuplicate = true
            end
        end
    end
end

-- Callback to handle doubling item drops in each room
function MyMod:DoubleItemsInRooms()
    local room = Game():GetRoom()
    if modState.moonPillActive and not MyMod:IsMoonPillBlockedRoom() then
        local entities = Isaac.GetRoomEntities()
        for _, entity in ipairs(entities) do
            if entity.Type == EntityType.ENTITY_PICKUP and not entity:GetData().GrennehMoonDuplicate then
                local pickup = entity:ToPickup()
                -- Check if the pickup is a valid type to duplicate
                if pickup and (pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE or pickup.Variant == PickupVariant.PICKUP_HEART or
                   pickup.Variant == PickupVariant.PICKUP_COIN or pickup.Variant == PickupVariant.PICKUP_BOMB or
                   pickup.Variant == PickupVariant.PICKUP_KEY or pickup.Variant == PickupVariant.PICKUP_TAROTCARD) then

                    -- Find a nearby position for the duplicate
                    local duplicatePosition = self:FindNearbyPosition(pickup.Position)

                    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                        if not pickup:IsShopItem() and MyMod:CanRerollCollectiblePickup(pickup) then
                            local roomPool = MyMod.GetPoolForRoom and MyMod:GetPoolForRoom(room:GetType()) or ItemPoolType.POOL_TREASURE
                            local newItem = GetUnseenCollectibleFromPool(roomPool or ItemPoolType.POOL_TREASURE, room:GetSpawnSeed(), 25, function(itemConfig)
                                return itemConfig ~= nil
                            end)

                            -- Spawn the new item
                            if newItem ~= pickup.SubType and newItem > 0 then
                                local duplicate = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, duplicatePosition, Vector.Zero, nil)
                                duplicate:GetData().GrennehMoonDuplicate = true
                            end
                        end
                    else
                        -- Duplicate non-collectible items
                        local duplicate = Isaac.Spawn(EntityType.ENTITY_PICKUP, pickup.Variant, pickup.SubType, duplicatePosition, pickup.Velocity, nil)
                        duplicate:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        duplicate:GetData().GrennehMoonDuplicate = true
                    end
                end
            end
        end
    end
end

-- Callback to reset duplicated entities at the start of each room
function MyMod:OnLuneNewRoom()
    if not modState.moonPillActive or MyMod:IsMoonPillBlockedRoom() then
        return
    end

    local room = Game():GetRoom()
    local level = Game():GetLevel()
    local roomIndex = tostring(level:GetStage()) .. ":" .. tostring(level:GetCurrentRoomIndex())

    -- Check if the room has already been processed for duplication
    if not modState.moonPillProcessedRooms[roomIndex] then
        self:DoubleEnemiesInRooms() -- Call the function to double enemies at the start of the room
        self:DoubleItemsInRooms()   -- Call the function to double items at the start of the room
        modState.moonPillProcessedRooms[roomIndex] = true -- Mark the room as processed
    end
end

function MyMod:OnLuneUpdate()
    if not modState.moonPillActive or MyMod:IsMoonPillBlockedRoom() then
        return
    end

    local room = Game():GetRoom()
    if not room or not room:IsClear() then
        return
    end

    local level = Game():GetLevel()
    local roomIndex = tostring(level:GetStage()) .. ":" .. tostring(level:GetCurrentRoomIndex())
    if modState.moonPillClearProcessedRooms[roomIndex] then
        return
    end

    -- Wait a few frames so vanilla and modded room-clear rewards have time to spawn.
    if room:GetFrameCount() < 5 then
        return
    end

    self:DoubleItemsInRooms()
    modState.moonPillClearProcessedRooms[roomIndex] = true
end

-- Callback to reset moonPillActive at the start of each level
function MyMod:OnLuneNewLevel()
    modState.moonPillActive = false
    modState.moonPillProcessedRooms = {}
    modState.moonPillClearProcessedRooms = {}

    ForEachPlayer(function(player)
        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        player:EvaluateItems()
    end)
end

-- Callback to adjust player's cache for tear rate
function MyMod:EvaluateCache(player, cacheFlag)
    if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY and modState.moonPillActive then
        AddTears(player, 1.5)
    end
end

-- Register callbacks
MyMod:AddCallback(ModCallbacks.MC_USE_PILL, MyMod.UseMoonPill, moonPillEffect)
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.OnLuneNewRoom)
MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, MyMod.OnLuneUpdate)
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, MyMod.OnLuneNewLevel)
MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateCache)


---- La Contemplation

-- Register the new item "La Contemplation"
local LaContemplation = Isaac.GetItemIdByName("La Contemplation")

-- Callback for using the item "La Contemplation"
function MyMod:UseLaContemplation(_, rng, player, flags, slot)
    player = player or Isaac.GetPlayer(0)

    -- Create a table to hold all the player's collectible items
    local collectibles = {}

    -- Iterate over the player's inventory
    for i = 1, Isaac.GetItemConfig():GetCollectibles().Size - 1 do
        local item = Isaac.GetItemConfig():GetCollectible(i)
        if item and player:HasCollectible(i) and not MyMod:IsKeyItem(i) then
            table.insert(collectibles, i)
        end
    end


    -- If the player has any collectibles, proceed
    if #collectibles > 0 then
        -- Select a random item from the player's inventory
        local randomIndex = rng and (rng:RandomInt(#collectibles) + 1) or math.random(1, #collectibles)
        local randomCollectible = collectibles[randomIndex]

        -- Remove the random item from the player
        player:RemoveCollectible(randomCollectible)
    end

    -- Teleport the player to the Planetarium using a console command
    Isaac.ExecuteCommand("goto s.planetarium") -- The command to teleport to the special room type Planetarium

    return true
end

-- Register the callback for using the item
MyMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyMod.UseLaContemplation, LaContemplation)



---- Grennette's wig

local grennettesWig = Isaac.GetItemIdByName("Grennette's Wig")
local uwuSound = Isaac.GetSoundIdByName("uwu")

-- Helper function to handle errors gracefully
local function grennettesWigSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Grennette's Wig: " .. tostring(err) .. "\n")
    end
end

-- Callback when player takes damage
function MyMod:OnPlayerDamage(entity, amount, flag, source, countdown)
    local player = entity:ToPlayer()
    if not player or not player:Exists() then return end  -- Ensure player exists
    
    if player:HasCollectible(grennettesWig) then
        -- Play the custom "uwu sound" with a slight pitch variation
        local pitch = math.random(100, 150) / 100
        SFXManager():Play(uwuSound, 2.0, 0, false, pitch)
        
        -- Generate a random number between 1 and 3
        local numFans = math.random(1, 3)
        
        for i = 1, numFans do
            local fanType
            if math.random() <= 0.8 then
                fanType = EntityType.ENTITY_GAPER  -- 80% chance to spawn a Gaper
            else
                fanType = EntityType.ENTITY_FATTY  -- 20% chance to spawn a Fatty
            end
            
            local fan = Isaac.Spawn(fanType, 0, 0, player.Position, Vector.Zero, player)
            if fan and fan:Exists() then
                fan:AddCharmed(EntityRef(player), -1) -- Charm the fan
                fan:GetData().isGrennetteFan = true -- Mark the fan for despawning later
            end
        end
    end
end

-- Callback to stop the default grunt sound when taking damage
function MyMod:StopDefaultGrunt()
    if AnyPlayerHasCollectible(grennettesWig) then
        if SFXManager():IsPlaying(SoundEffect.SOUND_ISAAC_HURT_GRUNT) then
            SFXManager():Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT)
        end
        if SFXManager():IsPlaying(hitSound) then
            SFXManager():Stop(hitSound)
        end
    end
end

-- Callback for handling new room events
function MyMod:OnWigNewRoom()
    local entities = Isaac.GetRoomEntities()
    
    for _, entity in ipairs(entities) do
        if entity:GetData().isGrennetteFan then
            entity:Remove() -- Despawn the fan when entering a new room
        end
    end
end

-- Callback to put the wig costume on the player
function MyMod:PutWigOn(player)
    if not player or not player:Exists() then return end  -- Ensure player exists
    
    local playerKey = GetPlayerKey(player)
    if player:HasCollectible(grennettesWig) and not modState.wigCostumeApplied[playerKey] then
        player:AddNullCostume(grennettewigCostume)
        modState.wigCostumeApplied[playerKey] = true
    end
end

-- Wrapper for PutWigOn with SafeCall
function MyMod:PutWigOnSafe(player)
    grennettesWigSafeCall(MyMod.PutWigOn, MyMod, player)
end

MyMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyMod.PutWigOnSafe)

-- Register the callbacks
MyMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flag, source, countdown)
    grennettesWigSafeCall(MyMod.OnPlayerDamage, MyMod, entity, amount, flag, source, countdown)
end, EntityType.ENTITY_PLAYER)

MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    grennettesWigSafeCall(MyMod.StopDefaultGrunt, MyMod)
end)

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    grennettesWigSafeCall(MyMod.OnWigNewRoom, MyMod)
end)

----- whippin

local whippinItem = Isaac.GetItemIdByName("Whippin")

-- Define the item pools to shuffle
local itemPools = {
    ItemPoolType.POOL_TREASURE,
    ItemPoolType.POOL_BOSS,
    ItemPoolType.POOL_DEVIL,
    ItemPoolType.POOL_SHOP,
    ItemPoolType.POOL_ANGEL,
    ItemPoolType.POOL_SECRET,
    ItemPoolType.POOL_LIBRARY,
    ItemPoolType.POOL_PLANETARIUM,
}

local shuffledPools = {}  -- Table to store the shuffled pools
local IndexOf

-- Helper function to handle errors gracefully
local function whippinSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Whippin': " .. tostring(err) .. "\n")
    end
end

-- Shuffle function
local function shuffleTable(t)
    local shuffled = {}
    for i, v in ipairs(t) do
        shuffled[i] = v
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

-- Function to reset the shuffled pools when the run is rerolled
function MyMod:ResetShuffle()
    shuffledPools = {}
end

-- Callback to shuffle the item pools when the player picks up the item
function MyMod:OnWhippinPlayerUpdate(player)
    if not player or not player:Exists() then return end  -- Ensure player exists
    
    if not next(shuffledPools) and player:HasCollectible(whippinItem) then
        -- Shuffle the item pools
        shuffledPools = shuffleTable(itemPools)
        print("shuffled")
    end
end

-- Callback to modify the spawned item based on the shuffled pools
function MyMod:OnWhippinNewRoom()
    if MyMod.ApplyPoolSwitchesInRoom then
        MyMod:ApplyPoolSwitchesInRoom()
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    whippinSafeCall(MyMod.OnWhippinNewRoom, MyMod)
end)

-- Utility function to get the pool based on room type
function MyMod:GetPoolForRoom(roomType)
    if roomType == RoomType.ROOM_TREASURE then
        return ItemPoolType.POOL_TREASURE
    elseif roomType == RoomType.ROOM_DEVIL then
        return ItemPoolType.POOL_DEVIL
    elseif roomType == RoomType.ROOM_ANGEL then
        return ItemPoolType.POOL_ANGEL
    elseif roomType == RoomType.ROOM_SHOP then
        return ItemPoolType.POOL_SHOP
    elseif roomType == RoomType.ROOM_BOSS then
        return ItemPoolType.POOL_BOSS
    elseif roomType == RoomType.ROOM_LIBRARY then
        return ItemPoolType.POOL_LIBRARY
    elseif roomType == RoomType.ROOM_SECRET then
        return ItemPoolType.POOL_SECRET
    elseif roomType == RoomType.ROOM_PLANETARIUM then
        return ItemPoolType.POOL_PLANETARIUM
    elseif roomType == RoomType.ROOM_CURSE then
        return ItemPoolType.POOL_DEVIL
    elseif roomType == RoomType.ROOM_ULTRA_SECRET then
        return ItemPoolType.POOL_SECRET
    else
        return nil
    end
end

-- Utility function to find index in table
IndexOf = function(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            return i
        end
    end
    return nil
end

-- Register the callbacks
MyMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    whippinSafeCall(MyMod.OnWhippinPlayerUpdate, MyMod, player)
end)



MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    whippinSafeCall(MyMod.ResetShuffle, MyMod)
end)

-- cursed orb

local grennehCursedOrb = Isaac.GetItemIdByName("Grenneh's Cursed Orb")

-- Helper function to handle errors gracefully
local function CursedOrbSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Grenneh's Cursed Orb: " .. tostring(err) .. "\n")
    end
end

-- Function to reroll items based on quality and the specified pool
local function rerollItemToTargetQuality(pickup, targetPool)
    local newItem = GetUnseenCollectibleFromPool(targetPool, pickup.InitSeed, 30, function(itemConfig)
        return itemConfig and itemConfig.Quality >= 2
    end)
    local itemConfig = Isaac.GetItemConfig():GetCollectible(newItem)
    local currentQuality = itemConfig and itemConfig.Quality or 0
    
    -- 15% chance to reroll from Quality 2 to 3
    if currentQuality == 2 and math.random() <= 0.15 then
        newItem = GetUnseenCollectibleFromPool(targetPool, pickup.InitSeed, 30, function(config)
            return config and config.Quality == 3
        end)
        itemConfig = Isaac.GetItemConfig():GetCollectible(newItem)
        currentQuality = itemConfig and itemConfig.Quality or currentQuality
    end
    
    -- 6% chance to reroll from Quality 3 to 4
    if currentQuality == 3 and math.random() <= 0.06 then
        newItem = GetUnseenCollectibleFromPool(targetPool, pickup.InitSeed, 30, function(config)
            return config and config.Quality == 4
        end)
    end
    
    return newItem
end

function MyMod:OnCursedOrbNewRoom()
    if MyMod.ApplyPoolSwitchesInRoom then
        MyMod:ApplyPoolSwitchesInRoom()
    end
end

function MyMod:ResetCursedOrb()
end

function MyMod:GetPoolSwitchTargetPool()
    local room = Game():GetRoom()
    if not room then
        return nil, nil
    end

    local roomType = room:GetType()
    if AnyPlayerHasCollectible(grennehCursedOrb) then
        if roomType == RoomType.ROOM_DEVIL then
            return ItemPoolType.POOL_ANGEL, "cursed_orb"
        elseif roomType == RoomType.ROOM_ANGEL then
            return ItemPoolType.POOL_DEVIL, "cursed_orb"
        end
    end

    if next(shuffledPools) and AnyPlayerHasCollectible(whippinItem) then
        local originalPool = MyMod:GetPoolForRoom(roomType)
        local originalPoolIndex = originalPool and IndexOf(itemPools, originalPool)
        if originalPoolIndex then
            return shuffledPools[originalPoolIndex], "whippin"
        end
    end

    return nil, nil
end

function MyMod:ApplyPoolSwitchToPickup(pickup)
    if not MyMod:CanModRerollCollectiblePickup(pickup) then
        return false
    end

    local targetPool, source = MyMod:GetPoolSwitchTargetPool()
    if not targetPool then
        return false
    end

    local data = pickup:GetData()
    if data.GrennehPoolSwitchOutput == pickup.SubType and data.GrennehPoolSwitchSource == source then
        return false
    end

    local newItem
    if source == "cursed_orb" then
        newItem = rerollItemToTargetQuality(pickup, targetPool)
    else
        newItem = GetUnseenCollectibleFromPool(targetPool, pickup.InitSeed, 25)
    end

    if newItem and newItem > 0 and newItem ~= pickup.SubType then
        MorphCollectible(pickup, newItem, pickup:IsShopItem())
        local newData = pickup:GetData()
        newData.GrennehPoolSwitchSource = source
        newData.GrennehPoolSwitchOutput = newItem
        return true
    end

    return false
end

function MyMod:ApplyPoolSwitchesInRoom()
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if IsCollectiblePickup(entity) then
            MyMod:ApplyPoolSwitchToPickup(entity:ToPickup())
        end
    end
end

function MyMod:OnPoolSwitchPickupUpdate(pickup)
    if not pickup or not pickup:Exists() or pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE then
        return
    end

    MyMod:ApplyPoolSwitchToPickup(pickup)
end

function MyMod:OnPoolSwitchPickupUpdateSafe(pickup)
    local success, err = pcall(function()
        MyMod.OnPoolSwitchPickupUpdate(MyMod, pickup)
    end)

    if not success then
        Isaac.ConsoleOutput("Error in pool switch pickup update: " .. tostring(err) .. "\n")
    end
end

-- Register the callbacks
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    CursedOrbSafeCall(MyMod.OnCursedOrbNewRoom, MyMod)
end)

MyMod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, MyMod.OnPoolSwitchPickupUpdateSafe, PickupVariant.PICKUP_COLLECTIBLE)

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    CursedOrbSafeCall(MyMod.ResetCursedOrb, MyMod)
end)

-- Grennette's tucker

local grennettesTucker = Isaac.GetItemIdByName("Grennette's Tucker")

-- Chance for the effect to trigger when taking damage
local burstChance = 0.15

-- Number of tears in the burst
local numTears = 8

-- Spread angle of the cone (in degrees)
local coneAngle = 60

-- Duration of the pee puddle in frames
local puddleDuration = 100

-- Callback function for when the player takes damage
function MyMod:OnTuckerPlayerDamage(entity, amount, flags, source, countdown)
    local player = entity and entity:ToPlayer()
    if not player or not player:Exists() then return end

    if player:HasCollectible(grennettesTucker) then
        -- Chance to release a burst of tears and create a pee puddle
        if math.random() <= burstChance then
            MyMod:CreatePeePuddle(player)
            MyMod:ReleaseBurstOfTears(player)
        end
    end
end

-- Function to create a pee puddle
function MyMod:CreatePeePuddle(player)
    local playerPos = player.Position
    local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_LEMON_MISHAP, 0, playerPos, Vector(0, 0), player):ToEffect()
    creep.Scale = 0.5  -- Size of the puddle
    creep:SetTimeout(puddleDuration)  -- Duration the puddle lasts
    creep:Update()
end

-- Function to release a burst of yellow tears behind the player
function MyMod:ReleaseBurstOfTears(player)
    local playerPos = player.Position
    local moveDir = player:GetMovementDirection()
    local baseAngle = 0
    
    -- Determine the base angle depending on movement direction
    if moveDir == Direction.NO_DIRECTION then
        baseAngle = 90  -- Default to shooting upwards
    elseif moveDir == Direction.LEFT then
        baseAngle = 0
    elseif moveDir == Direction.UP then
        baseAngle = 90
    elseif moveDir == Direction.RIGHT then
        baseAngle = 180
    elseif moveDir == Direction.DOWN then
        baseAngle = 270
    end
    
    for i = 1, numTears do
        -- Add randomness to the angle within the cone
        local angleOffset = math.random(-coneAngle / 2, coneAngle / 2)
        local finalAngle = baseAngle + angleOffset
        
        -- Randomize the speed slightly for each tear
        local randomSpeed = math.random(5, 10)
        local tearDirection = Vector.FromAngle(finalAngle):Resized(randomSpeed)
        
        local tear = player:FireTear(playerPos, tearDirection, false, true, false)
        tear.Color = Color(1, 1, 0, 1, 0, 0, 0)  -- Yellow color
        tear.FallingSpeed = -randomSpeed
        tear.FallingAcceleration = 1
        tear.Scale = 0.75  -- Adjust the size of the tears
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_SPECTRAL
        tear.Height = -20  -- Adjust to control the range
        tear.FallingSpeed = 0
        
        -- Set the tear damage to 3 times the player's damage
        tear.CollisionDamage = player.Damage * 3
    end
end

-- Register the callbacks
MyMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, countdown)
    if entity.Type == EntityType.ENTITY_PLAYER then
        MyMod:OnTuckerPlayerDamage(entity, amount, flags, source, countdown)
    end
end)














-- Define the Grennette items required for the transformation
local grenetteTransformationItems = {
    [Isaac.GetItemIdByName("Grennette's Wig")] = true,
    [Isaac.GetItemIdByName("Grennette's Mascara")] = true,
    [Isaac.GetItemIdByName("Grennette's Tucker")] = true
}

function MyMod:RegisterEIDDescriptions(transformationProgress)
    if not EID then
        return
    end

    transformationProgress = transformationProgress or 0
    local progressColor = transformationProgress >= 3 and "{{ColorGreen}}" or "{{ColorRed}}"
    local progressText = "#Grennette's True Form: " .. progressColor .. transformationProgress .. "/3"
        .. "#{{ColorPink}}At 3/3: 20% chance to turn a nearby non-boss enemy into a heart when hit."

    EID:addCollectible(mimineItemId, "{{Luck}} +1 Luck#8% chance on first room entry to replace a valid pedestal with an unseen Guppy item.")
    EID:addCollectible(grennehBean, "Plays a fart sound.")
    EID:addCollectible(kramptus, "Fires a powerful brimstone laser#Or does it?..")
    EID:addCollectible(bmthItemId, "{{Damage}} Big damage up#Red tears#Leaves red creep while moving.")
    EID:addCollectible(chaise, "{{Speed}} Speed up.")
    EID:addCollectible(tatano, "{{Heart}} +2 heart containers and heals 2 hearts for each copy picked up.")
    EID:addCollectible(bouteille, "{{Tears}} Fire rate up.")
    EID:addCollectible(redbull, "{{Speed}} Speed is raised to 2#Grants flight#Adds wings.")
    EID:addCollectible(monsterItemId, "Evolves with each copy:#1: damage up#2: speed up#3: tears up and incoming damage is doubled#4: poison green tears with occasional wild shots#5: occasional inverted controls and invincibility burst#6: one-time lethal overdose, then disables the bad effects.")
    EID:addCollectible(choixDuChat, "Teleports to a choice room#Taking one item removes the other pedestals#Destroys itself on use.")
    EID:addCollectible(grennettesMascara, "{{Damage}} x2 Damage#{{Luck}} +2 Luck#Rainbow charm, piercing, spectral tears#Tears start larger and grow on hit." .. progressText)
    EID:addCollectible(LaContemplation, "{{Warning}} Removes one random non-key item#Teleports to a Planetarium.")
    EID:addCollectible(grennettesWig, "When hit, plays an uwu sound and spawns 1-3 charmed fans#Fans leave on room exit." .. progressText)
    EID:addCollectible(whippinItem, "Shuffles room item-pool assignments for this run#Pools stay populated#New and rerolled pedestals use the reassigned pool.")
    EID:addCollectible(grennehCursedOrb, "Devil rooms use Angel pool items#Angel rooms use Devil pool items#New and rerolled pedestals are affected#Items are at least Quality 2, with small upgrade chances.")
    EID:addCollectible(grennettesTucker, "15% chance when hit to splash lemon creep and fire a burst of yellow spectral tears." .. progressText)

    if EID.addPill then
        pcall(function()
            EID:addPill(SkillIssue.ID, "Counts as red heart damage for the floor#Plays the Skill Issue sound.")
            EID:addPill(moonPillEffect, "For the rest of the floor:#{{Tears}} Fire rate up#Curse of Darkness#First visit rooms duplicate enemies, bosses, pickups, and room-clear rewards#Does nothing in shops.")
        end)
    end
end

-- Register item details in the initialization function
function MyMod:OnGameStart()
    MyMod:RegisterEIDDescriptions(0)
end

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MyMod.OnGameStart)

-- transformation

-- register the audio for the transformation
local transformationSound = Isaac.GetSoundIdByName("transfoSound")


-- Check if the player has collected all Grennette items
local function checkForGrennetteTransformation(player)
    local itemCount = 0
    for item, _ in pairs(grenetteTransformationItems) do
        if player:HasCollectible(item) then
            itemCount = itemCount + 1
        end
    end

    if itemCount ~= modState.grennetteTransformationProgress then
        modState.grennetteTransformationProgress = itemCount
        MyMod:RegisterEIDDescriptions(itemCount)
    end

    if itemCount >= 3 and not modState.grennetteTransformation then
        modState.grennetteTransformation = true
        Game():GetHUD():ShowItemText("Grennette's True Form!")
        -- play the transformation sound
        SFXManager():Play(transformationSound, 1.0, 0, false, 1.0)
    end
end

-- 20% chance to transform an enemy into a heart pickup when the player takes damage
local function onTransfoPlayerDamage(_, player, damageAmount, damageFlag, source, countdownFrames)
    if modState.grennetteTransformation then
        if math.random() < 0.20 then  -- 20% chance
            local enemies = Isaac.FindInRadius(player.Position, 100, EntityPartition.ENEMY)
            for _, enemy in ipairs(enemies) do
                if enemy:IsVulnerableEnemy() and not enemy:IsBoss() then
                    enemy:Remove()
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 0, enemy.Position, Vector(0, 0), nil)
                    break
                end
            end
        end
    end
end

-- Update transformation status and apply effects on game update
local function onTransfoGameUpdate()
    local player = Isaac.GetPlayer(0)
    checkForGrennetteTransformation(player)
end

-- reset the transformation status when starting a new game
local function onTransfoNewGame()
    modState.grennetteTransformation = false
    modState.grennetteTransformationProgress = -1
end



-- Register callbacks for transformation and damage event
MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, onTransfoGameUpdate)
MyMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, onTransfoPlayerDamage, EntityType.ENTITY_PLAYER)
MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onTransfoNewGame)
