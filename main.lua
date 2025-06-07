local MyMod = RegisterMod("Grenneh Mod", 1)

local grennehType = Isaac.GetPlayerTypeByName("Grenneh", false)
local grennetteType = Isaac.GetPlayerTypeByName("Grennette", true)



local grennehHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_hair.anm2") 
local grennehstolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_stoles.anm2") 
local grennetteHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_hair.anm2") 
local grennettestolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_stoles.anm2") 
local grennettewigCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_wig.anm2") 
local redbullWingCostume = Isaac.GetCostumeIdByPath("gfx/characters/redbull_wings.anm2")


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
        player:AddNullCostume(grennehHairCostume)
        player:AddNullCostume(grennehstolesCostume)
        return -- Only give costumes to Grennette
    end


end

MyMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyMod.GiveCostumesOnInit)


-- Function to check if an item is a key item
function MyMod:IsKeyItem(itemID)
    local KeyItem = {
        CollectibleType.COLLECTIBLE_POLAROID,
        CollectibleType.COLLECTIBLE_NEGATIVE,
        CollectibleType.COLLECTIBLE_KEY_PIECE_1,
        CollectibleType.COLLECTIBLE_KEY_PIECE_2,
        CollectibleType.COLLECTIBLE_DADS_NOTE,
        CollectibleType.COLLECTIBLE_KNIFE_PIECE_1,
        CollectibleType.COLLECTIBLE_KNIFE_PIECE_2
    }
    
    -- Check if the itemID is in the KeyItem list
    for _, keyItem in ipairs(KeyItem) do
        if itemID == keyItem then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------------------------
-- Gestion Grenneh

local game = Game() -- Grabbing game
local sound = SFXManager()
local music = MusicManager()


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

local tatanoHealed = false
local hasSixthPickup = false  -- Track if the player has survived the sixth pickup
local wigOn = false
local wingsOn = false

function MyMod:OnPlayerInit(player)
    tatanoHealed = false
    hasSixthPickup = false
    wigOn = false
    wingsOn = false

    if player:GetPlayerType() == Isaac.GetPlayerTypeByName("Grenneh") then

        if not player:HasCollectible(Isaac.GetItemIdByName("Mimine")) then
            player:AddCollectible(Isaac.GetItemIdByName("Mimine"))
            -- Add any additional initialization here
        end
        if not player:HasCollectible(Isaac.GetItemIdByName("Grenneh's bean")) then
            player:AddCollectible(Isaac.GetItemIdByName("Grenneh's bean"))
            -- Add any additional initialization here
        end
    end
    if player:GetPlayerType() == grennetteType then
        if not player:HasCollectible(Isaac.GetItemIdByName("Head of Kramptus")) then
            player:AddCollectible(Isaac.GetItemIdByName("Head of Kramptus"))
            -- Add any additional initialization here
        end
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
    Isaac.GetItemIdByName("Guppy's Hairball")
}

-- Get a list of Guppy items that the player does not already have
function MyMod:GetMimineAvailableGuppyItems(player)
    local availableGuppyItems = {}
    for _, itemId in ipairs(guppyItemIds) do
        if not player:HasCollectible(itemId) then
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
function MyMod:HandleMimineNewRoomSafe()
    MimineSafeCall(MyMod.HandleMimineNewRoom, MyMod)
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.HandleMimineNewRoomSafe)


--------------------------------------------------------------------------------------------------------------
-- Haricot pet

local grennehBean = Isaac.GetItemIdByName("Grenneh's bean")
local grennehBeanSound = Isaac.GetSoundIdByName("Fartmod")

function MyMod:useGrennehBean(grennehBean, rng)
    sound:Play(grennehBeanSound, 2, 0, false, 1)
end

MyMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyMod.useGrennehBean, grennehBean)





--------------------------------------------------------------------------------------------------------------
-- Kramptus

local kramptus = Isaac.GetItemIdByName("Head of Kramptus")

function MyMod:useKramptus()
    local player = Isaac.GetPlayer(0)

    local hud = game:GetHUD()
    -- setup message
    local message = "Eh, t'as les Kramptus ?"

    -- display
    hud:ShowFortuneText(message)

    -- remove
    player:RemoveCollectible(kramptus,false, ActiveSlot.SLOT_PRIMARY, true)
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
    if Game():GetFrameCount() % 4 == 0 then
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
	local player = Isaac.GetPlayer(0);

	if (player:HasCollectible(tatano)) then
	
		if not tatanoHealed then
            player:AddMaxHearts(4,false)
            player:AddHearts(4)
            tatanoHealed = true
        end
	end
end

MyMod:AddCallback( ModCallbacks.MC_POST_UPDATE, MyMod.updateTatano);


--------------------------------------------------------------------------------------------------------------
-- bouteille

local bouteille = Isaac.GetItemIdByName("A Bo'oh'o'wa'er")
local bouteilleHeal = false

function MyMod:updateBouteille()
	local player = Isaac.GetPlayer(0);

	if (player:HasCollectible(bouteille)) then
	
		if not bouteilleHeal then
            player:AddSoulHearts(2,false)
            player.MaxFireDelay = player.MaxFireDelay - 0.1
            bouteilleHeal = true
        end
	end
end

MyMod:AddCallback( ModCallbacks.MC_POST_UPDATE, MyMod.updateBouteille);

--------------------------------------------------------------------------------------------------------------
-- redbull

local redbull = Isaac.GetItemIdByName("Redbull")
local redbullSpeed = 2

function MyMod:EvaluateRedbull(player, cacheFlags)
    local player = Isaac.GetPlayer(0)
    if cacheFlags & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
        local itemCount = player:GetCollectibleNum(redbull)
        local spdToAdd = redbullSpeed * itemCount
        player.MoveSpeed = player.MoveSpeed + spdToAdd
    end

    if cacheFlags & CacheFlag.CACHE_FLYING == CacheFlag.CACHE_FLYING then
        if player:HasCollectible(redbull) then
            player.CanFly = true  -- Grant the player the ability to fly    
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateRedbull)

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
local isInverted = false
local inversionTimer = 0
local visitedRooms = {}  -- To track if a room has been visited
local hasSixthPickup = false  -- Tracks if the sixth pickup has been obtained

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
    if not tear or not tear:Exists() or hasSixthPickup then
        return -- Exit the function early if the tear is invalid
    end

    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists

    local itemCount = player:GetCollectibleNum(monsterItemId)

    if itemCount >= 4 then
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_POISON

        if math.random() < 0.3 then
            tear:Remove()
            player:FireTear(player.Position, Vector.FromAngle(math.random() * 360) * 10, false, false, false)
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
    if itemCount == 6 and not hasSixthPickup then
        player:Die()  -- Kill the player to apply the one-time effect
        hasSixthPickup = true
    end
end

-- Wrapper for HandleMonsterItemPickup with SafeCall
function MyMod:HandleMonsterItemPickupSafe(player)
    MonsterSafeCall(MyMod.HandleMonsterItemPickup, MyMod, player)
end

MyMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyMod.HandleMonsterItemPickupSafe)

-- Update inverted controls if applicable
function MyMod:UpdateMonsterInvertedControls()
    if hasSixthPickup then
        return -- Exit the function early if the sixth pickup has been obtained
    end

    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists

    if isInverted and inversionTimer > 0 then
        MyMod:InvertMonsterControls(player)
        inversionTimer = inversionTimer - 1
    elseif inversionTimer <= 0 then
        isInverted = false
    end
end

-- Invert player controls
function MyMod:InvertMonsterControls(player)
    if not player or not player:Exists() then return end  -- Ensure player exists

    local moveInput = player:GetMovementInput()
    local invertedVector = Vector(-moveInput.X, -moveInput.Y)

    if invertedVector:Length() > 0 then
        invertedVector = invertedVector:Normalized()
        player.Velocity = player.Velocity + invertedVector * 2.5  -- Apply normalized, inverted movement
    end
end

-- Wrapper for UpdateMonsterInvertedControls with SafeCall
function MyMod:UpdateMonsterInvertedControlsSafe()
    MonsterSafeCall(MyMod.UpdateMonsterInvertedControls, MyMod)
end

MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, MyMod.UpdateMonsterInvertedControlsSafe)

-- Handle effects when entering a new room
function MyMod:HandleMonsterNewRoom()
    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists

    local currentRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
    local itemCount = player:GetCollectibleNum(monsterItemId)

    if not visitedRooms[currentRoomIndex] then
        visitedRooms[currentRoomIndex] = true  -- Mark the room as visited

        -- Reroll a random item on the floor to 'Monster' based on item count, if not the sixth pickup
        if math.random() < (0.1 * itemCount) and not hasSixthPickup then
            for _, entity in pairs(Isaac.GetRoomEntities()) do
                if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    entity:ToPickup():Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, monsterItemId, true, true, false)
                    break  -- Only reroll one item per room entry
                end
            end
        end

        -- Invert controls if the player has at least 5 Monster items, but not the sixth pickup
        if itemCount >= 5 and math.random() < 0.1 and not hasSixthPickup then
            isInverted = true
            inversionTimer = 75  -- Invert controls for 2.5 seconds (30 frames per second)
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

    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= monsterItemId and math.random() < (0.1 * itemCount) and not hasSixthPickup and not MyMod:IsKeyItem(pickup.SubType) then
        pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, monsterItemId, true, true, false)
    end
end

-- Wrapper for HandleMonsterPickupInit with SafeCall
function MyMod:HandleMonsterPickupInitSafe(pickup)
    MonsterSafeCall(MyMod.HandleMonsterPickupInit, MyMod, pickup)
end

MyMod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, MyMod.HandleMonsterPickupInitSafe)

-- reset hasSixthPickup when starting a new run
function MyMod:MonsterReset()
    hasSixthPickup = false
end 

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MyMod.MonsterReset)


-------- Choix du Chat

local choixDuChat = Isaac.GetItemIdByName("Choix du Chat")
local isInSpecialRoom = false

-- When the item is used
function MyMod:UseChoixDuChat()
    local player = Isaac.GetPlayer(0)
    player:AnimateTeleport(true)
    Isaac.ExecuteCommand("goto s.default.7777")  -- Teleport to the custom room
    player:RemoveCollectible(choixDuChat)  -- Remove the item from the inventory
    isInSpecialRoom = true
end

MyMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyMod.UseChoixDuChat, choixDuChat)

-- Function to handle room entry
function MyMod:ChoixNewRoom()
    if isInSpecialRoom then
        local game = Game()
        local level = game:GetLevel()
        local roomDesc = level:GetCurrentRoomDesc()
        game:GetHUD():ShowItemText("Chat, on prends quoi?", "")
        isInSpecialRoom = false  -- Reset flag
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.ChoixNewRoom)

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
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * 2.0 -- Double damage
        end
        if cacheFlag == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = player.MaxFireDelay + 2 -- Reduce fire rate (increase delay)
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + 2 -- Increase luck
        end
        if cacheFlag == CacheFlag.CACHE_TEARFLAG then
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
    local player = Isaac.GetPlayer(0)
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

-- Add custom sound
local moonPillSound = Isaac.GetSoundIdByName("MoonPillSound") -- Ensure this sound is registered in sounds.xml

-- Define variables to track the pill's active state
local moonPillActive = false
local floorEffectsActive = false
local processedRooms = {}  -- Track rooms that have already been processed
local tearRateIncreased = false  -- Track whether the tear rate increase has been applied

-- Callback to handle using the Moon Pill
function MyMod:UseMoonPill(pillEffect)
    if pillEffect == moonPillEffect then
        moonPillActive = true
        floorEffectsActive = true
        local player = Isaac.GetPlayer(0)
        local level = game:GetLevel()

        -- Apply Curse of the Blind
        level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)

        -- Play custom sound
        sound:Play(moonPillSound, 1.0, 0, false, 1.0)

        -- Apply tear rate increase
        if not tearRateIncreased then
            player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
            player:EvaluateItems()
            tearRateIncreased = true
        end
    end
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

-- Callback to handle doubling enemies and bosses in each room
function MyMod:DoubleEnemiesInRooms()
    local room = Game():GetRoom()
    if floorEffectsActive and room:GetFrameCount() <= 1 then
        local entities = Isaac.GetRoomEntities()
        for _, entity in ipairs(entities) do
            if entity:IsVulnerableEnemy() and entity:IsActiveEnemy(false) then
                -- Find a nearby position for the duplicate
                local duplicatePosition = self:FindNearbyPosition(entity.Position)

                -- Duplicate the enemy
                local clone = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, duplicatePosition, Vector(0, 0), nil)
                clone:ClearEntityFlags(EntityFlag.FLAG_APPEAR) -- Ensure it doesn't reappear
            end
        end
    end
end

-- Callback to handle doubling item drops in each room
function MyMod:DoubleItemsInRooms()
    local room = Game():GetRoom()
    local itemPool = Game():GetItemPool()
    if floorEffectsActive and room:GetFrameCount() <= 1 then
        local entities = Isaac.GetRoomEntities()
        for _, entity in ipairs(entities) do
            if entity.Type == EntityType.ENTITY_PICKUP then
                local pickup = entity:ToPickup()
                -- Check if the pickup is a valid type to duplicate
                if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE or pickup.Variant == PickupVariant.PICKUP_HEART or
                   pickup.Variant == PickupVariant.PICKUP_COIN or pickup.Variant == PickupVariant.PICKUP_BOMB or
                   pickup.Variant == PickupVariant.PICKUP_KEY or pickup.Variant == PickupVariant.PICKUP_TAROTCARD then

                    -- Find a nearby position for the duplicate
                    local duplicatePosition = self:FindNearbyPosition(pickup.Position)

                    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                        -- Ensure the duplicated item is different from the original
                        local newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, true, room:GetSpawnSeed())

                        -- Keep trying until we find a different item
                        while newItem == pickup.SubType do
                            newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, true, room:GetSpawnSeed())
                        end

                        -- Spawn the new item
                        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, duplicatePosition, Vector.Zero, nil)
                    else
                        -- Duplicate non-collectible items
                        local duplicate = Isaac.Spawn(EntityType.ENTITY_PICKUP, pickup.Variant, pickup.SubType, duplicatePosition, pickup.Velocity, nil)
                        duplicate:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    end
                end
            end
        end
    end
end

-- Callback to reset duplicated entities at the start of each room
function MyMod:OnLuneNewRoom()
    local room = Game():GetRoom()
    local roomIndex = room:GetDecorationSeed()

    -- Check if the room has already been processed for duplication
    if not processedRooms[roomIndex] then
        self:DoubleEnemiesInRooms() -- Call the function to double enemies at the start of the room
        self:DoubleItemsInRooms()   -- Call the function to double items at the start of the room
        processedRooms[roomIndex] = true -- Mark the room as processed
    end
end

-- Callback to reset moonPillActive at the start of each level
function MyMod:OnLuneNewLevel()
    local player = Isaac.GetPlayer(0)

    -- Decrease tear rate back to normal for the new level
    if tearRateIncreased then
        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        player:EvaluateItems()
        tearRateIncreased = false
    end

    moonPillActive = false
    floorEffectsActive = false
    processedRooms = {} -- Reset processed rooms for the new level

    player.MaxFireDelay = player.MaxFireDelay / 0.6667 -- Revert tear rate increase on new level
end

-- Callback to adjust player's cache for tear rate
function MyMod:EvaluateCache(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
        if floorEffectsActive then
            player.MaxFireDelay = player.MaxFireDelay * 0.6667 -- Apply 1.5x tear rate increase (2/3 of original delay)
        end
    end
end

-- Register callbacks
MyMod:AddCallback(ModCallbacks.MC_USE_PILL, MyMod.UseMoonPill, moonPillEffect)
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.OnLuneNewRoom)
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, MyMod.OnLuneNewLevel)
MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateCache)


---- La Contemplation

-- Register the new item "La Contemplation"
local LaContemplation = Isaac.GetItemIdByName("La Contemplation")

-- Callback for using the item "La Contemplation"
function MyMod:UseLaContemplation()
    local player = Isaac.GetPlayer(0)

    -- Create a table to hold all the player's collectible items
    local collectibles = {}

    -- Iterate over the player's inventory
    for i = 1, Isaac.GetItemConfig():GetCollectibles().Size - 1 do
        local item = Isaac.GetItemConfig():GetCollectible(i)
        if item and player:HasCollectible(i) then
            table.insert(collectibles, i)
        end
    end


    -- If the player has any collectibles, proceed
    if #collectibles > 0 then
        -- Select a random item from the player's inventory
        local randomIndex = math.random(1, #collectibles)
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
    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists
    
    if player:HasCollectible(grennettesWig) then
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
    
    if player:HasCollectible(grennettesWig) and not wigOn then
        player:AddNullCostume(grennettewigCostume)
        wigOn = true
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
    ItemPoolType.POOL_DEVIL,
    ItemPoolType.POOL_SHOP,
    ItemPoolType.POOL_ANGEL,
    ItemPoolType.POOL_SECRET,
    ItemPoolType.POOL_LIBRARY,
    ItemPoolType.POOL_PLANETARIUM,
}

local shuffledPools = {}  -- Table to store the shuffled pools
local rerolledRooms = {}  -- Table to keep track of rooms that have already had their items rerolled

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
    rerolledRooms = {}
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
    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists

    if next(shuffledPools) and player:HasCollectible(whippinItem) then
        local room = Game():GetRoom()
        if not room then return end  -- Ensure room exists
        
        local roomSeed = room:GetSpawnSeed()
        
        -- Check if the room has already been rerolled
        if not rerolledRooms[roomSeed] then
            local entities = Isaac.GetRoomEntities()
            for _, entity in ipairs(entities) do
                if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    local pickup = entity:ToPickup()
                    if pickup then
                        local itemPool = Game():GetItemPool()
                        if not itemPool then return end  -- Ensure item pool exists
                        
                        -- Get the current item ID on the pedestal
                        local currentItem = pickup.SubType
                        
                        -- Check if the current item is a key item
                        if MyMod:IsKeyItem(currentItem) then
                            -- Skip rerolling this item since it's a key item
                            print("Skipping reroll for key item: " .. currentItem)
                        else
                            -- Determine the original pool based on room type
                            local originalPool = MyMod:GetPoolForRoom(room:GetType())
                            
                            -- Reroll the item according to the shuffled pools
                            if originalPool then
                                local shuffledPool = shuffledPools[table.indexof(itemPools, originalPool)]
                                if shuffledPool then
                                    local newItem = itemPool:GetCollectible(shuffledPool, true, entity.InitSeed)
                                    pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, true)
                                end
                            end
                        end
                    end
                end
            end
            
            -- Mark this room as having been rerolled
            rerolledRooms[roomSeed] = true
        end
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
function table.indexof(tbl, val)
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

local rerolledRooms = {}  -- Table to keep track of rooms that have already had their items rerolled

-- Helper function to handle errors gracefully
local function CursedOrbSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Grenneh's Cursed Orb: " .. tostring(err) .. "\n")
    end
end

-- Function to reroll items based on quality and the specified pool
local function rerollItemToTargetQuality(pickup, targetPool)
    local itemPool = Game():GetItemPool()
    local newItem = itemPool:GetCollectible(targetPool, true, pickup.InitSeed)
    local itemConfig = Isaac.GetItemConfig():GetCollectible(newItem)
    local currentQuality = itemConfig.Quality
    
    -- Reroll until item is at least Quality 2
    while currentQuality < 2 do
        newItem = itemPool:GetCollectible(targetPool, true, pickup.InitSeed)
        itemConfig = Isaac.GetItemConfig():GetCollectible(newItem)
        currentQuality = itemConfig.Quality
    end
    
    -- 15% chance to reroll from Quality 2 to 3
    if currentQuality == 2 and math.random() <= 0.15 then
        while currentQuality ~= 3 do
            newItem = itemPool:GetCollectible(targetPool, true, pickup.InitSeed)
            itemConfig = Isaac.GetItemConfig():GetCollectible(newItem)
            currentQuality = itemConfig.Quality
        end
    end
    
    -- 6% chance to reroll from Quality 3 to 4
    if currentQuality == 3 and math.random() <= 0.06 then
        while currentQuality ~= 4 do
            newItem = itemPool:GetCollectible(targetPool, true, pickup.InitSeed)
            itemConfig = Isaac.GetItemConfig():GetCollectible(newItem)
            currentQuality = itemConfig.Quality
        end
    end
    
    return newItem
end

function MyMod:OnCursedOrbNewRoom()
    local player = Isaac.GetPlayer(0)
    if not player or not player:Exists() then return end  -- Ensure player exists
    
    if player:HasCollectible(grennehCursedOrb) then
        local room = Game():GetRoom()
        if not room then return end  -- Ensure room exists
        
        local roomSeed = room:GetSpawnSeed()
        
        -- Check if the room has already been rerolled
        if not rerolledRooms[roomSeed] then
            local roomType = room:GetType()
            
            if roomType == RoomType.ROOM_DEVIL then
                local entities = Isaac.GetRoomEntities()
                for _, entity in ipairs(entities) do
                    if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                        local pickup = entity:ToPickup()
                        if pickup then
                            local newItem = rerollItemToTargetQuality(pickup, ItemPoolType.POOL_ANGEL)
                            pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, true)
                        end
                    end
                end
            elseif roomType == RoomType.ROOM_ANGEL then
                local entities = Isaac.GetRoomEntities()
                for _, entity in ipairs(entities) do
                    if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                        local pickup = entity:ToPickup()
                        if pickup then
                            local newItem = rerollItemToTargetQuality(pickup, ItemPoolType.POOL_DEVIL)
                            pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, true)
                        end
                    end
                end
            end
            
            -- Mark this room as having been rerolled
            rerolledRooms[roomSeed] = true
        end
    end
end

function MyMod:ResetCursedOrb()
    rerolledRooms = {}
end

-- Register the callbacks
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    CursedOrbSafeCall(MyMod.OnCursedOrbNewRoom, MyMod)
end)

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
    local player = Isaac.GetPlayer(0)
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

-- Register item details in the initialization function
function MyMod:OnGameStart()
    if EID then

        local progress = 0

        EID:addCollectible(Isaac.GetItemIdByName("Mimine"), "Gives a #{{Luck}} +1 Luck bonus and 8% chance to reroll items into Guppy items! #{{ColorRainbow}}Meow!")
        EID:addCollectible(Isaac.GetItemIdByName("Grenneh's bean"), "Farts!")
        EID:addCollectible(Isaac.GetItemIdByName("Head of Kramptus"), "Might or might not be what you think....")
        EID:addCollectible(Isaac.GetItemIdByName("BMTH !"), "Increases your damage by 2.5 for each one you have! #{{ColorRed}}Rock on! #Also turns your tears red and leaves a red creep trail.")
        EID:addCollectible(Isaac.GetItemIdByName("Gaming Chair"), "Boosts your speed by 0.4 for each one you have! #{{ColorTeal}}Get in the fast lane!")
        EID:addCollectible(Isaac.GetItemIdByName("Tatanosaurus"), "Adds 2 max hearts and heals you for 2 hearts when picked up! #{{ColorRed}}Feel the power of the Tatanosaurus!")
        EID:addCollectible(Isaac.GetItemIdByName("A Bo'oh'o'wa'er"), "Adds 1 soul hearts and reduces fire delay by 0.1 when picked up! #Stay hydrated!")
        EID:addCollectible(Isaac.GetItemIdByName("Redbull"), "Gives you wings! #Increases speed by 2 and grants flight! #{{ColorYellow}}Fly and move faster!")
        EID:addCollectible(Isaac.GetItemIdByName("Monster"), "Various buffs based on how many you have! #1: Damage x1.2 #2: Speed x1.1 + everything before #3: Fire rate x0.8 + everything before #4: Tears become radioactive green and poison enemies + stats from before but you have a chance to not fire in the right direction #5: Randomly invert controls and but random triggers little unicorn, also + stats from before #6: Die, revive if you have a life item, removes every bad effect.")
        EID:addCollectible(Isaac.GetItemIdByName("Choix du Chat"), "Teleport to a special room! #{{ColorPurple}}Let the chat decide! #Teleports to a custom room when used.")

        -- Grennette items with progress
        EID:addCollectible(Isaac.GetItemIdByName("Grennette's Mascara"), 
            "Beautiful rainbow tears! #{{ColorRainbow}}Double damage #Increases tear size #Reduces fire rate #+2 Luck #Smooth transition colors #Charm, piercing, and spectral tears #Tears increase in size on hit." ..
            "#Progress towards Grennette's True Form: {{ColorRed}}" .. progress .. "/3" ..
            "#{{ColorPink}}Grennette's True Form: 20% chance to transform enemies into heart pickups when taking contact damage."
        )
        EID:addCollectible(Isaac.GetItemIdByName("Grennette's Wig"), 
            "Grennette's wig! #{{ColorPink}}UwU #Spawn 1 to 3 fans when hit, 80% chance to be a Gaper, 20% chance to be a Fatty #{{Warning}} {{ColorYellow}}Fans are charmed and despawn when entering a new room." ..
            "#Progress towards Grennette's True Form: {{ColorRed}}" .. progress .. "/3" .. 
            "#{{ColorPink}}Grennette's True Form: 20% chance to transform enemies into heart pickups when taking contact damage."
        )
        EID:addCollectible(Isaac.GetItemIdByName("Grennette's Tucker"), 
            "Grennette's Tucker! #{{ColorYellow}} 15% Chance to release a burst of tears and create a pee puddle when taking damage." ..
            "#Progress towards Grennette's True Form: {{ColorRed}}" .. progress .. "/3" .. 
            "#{{ColorPink}}Grennette's True Form: 20% chance to transform enemies into heart pickups when taking contact damage."
        )

        EID:addCollectible(Isaac.GetItemIdByName("La Contemplation"), "{{Warning}}Deletes a random item from your inventory and teleports you to the Planetarium! #{{ColorBlue}}Look to the stars!")
        EID:addCollectible(Isaac.GetItemIdByName("Whippin"), "#{{ColorRainbow}} Whippin'! #{{Warning}} Shuffles all the item pools except boss pool. Doesn't work with rerolls.")
        EID:addCollectible(Isaac.GetItemIdByName("Grenneh's Cursed Orb"), "Grenneh's Cursed Orb! #{{Warning}} Switches angel items with devil items and vice versa. Doesn't work with rerolls #All items will be at least Q2 #↑ 15% chance to reroll from Quality 2 to 3 #{{ColorPink}}↑ 6% chance to reroll from Quality 3 to 4")
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MyMod.OnGameStart)

-- transformation

local transformed = false

-- register the audio for the transformation
local transformationSound = Isaac.GetSoundIdByName("transfoSound")


-- Check if the player has collected all Grennette items
local function checkForGrennetteTransformation(player)
    local itemCount = 0
    for item, _ in pairs(grenetteTransformationItems) do
        if player:HasCollectible(item) then
            itemCount = itemCount + 1

            local color = "{{ColorRed}}"

            if itemCount == 3 then
                color = "{{ColorGreen}}"
            end

            -- Update the progress for the item in the EID description
            if EID then
                EID:addCollectible(Isaac.GetItemIdByName("Grennette's Mascara"), 
                "Beautiful rainbow tears! #{{ColorRainbow}}Double damage #Increases tear size #Reduces fire rate #+2 Luck #Smooth transition colors #Charm, piercing, and spectral tears #Tears increase in size on hit." ..
                "#Progress towards Grennette's True Form: " .. color .. itemCount .. "/3" .. 
                "#{{ColorPink}}Grennette's True Form: 20% chance to transform enemies into heart pickups when taking contact damage."
             )
            EID:addCollectible(Isaac.GetItemIdByName("Grennette's Wig"), 
                "Grennette's wig! #{{ColorPink}}UwU #Spawn 1 to 3 fans when hit, 80% chance to be a Gaper, 20% chance to be a Fatty #{{Warning}} {{ColorYellow}}Fans are charmed and despawn when entering a new room." ..
                "#Progress towards Grennette's True Form: " .. color .. itemCount .. "/3" .. 
                "#{{ColorPink}}Grennette's True Form: 20% chance to transform enemies into heart pickups when taking contact damage."
            )
            EID:addCollectible(Isaac.GetItemIdByName("Grennette's Tucker"), 
                "Grennette's Tucker! #{{ColorYellow}} 15% Chance to release a burst of tears and create a pee puddle when taking damage." ..
                "#Progress towards Grennette's True Form: " .. color .. itemCount .. "/3" .. 
                "#{{ColorPink}}Grennette's True Form: 20% chance to transform enemies into heart pickups when taking contact damage."
            )
            end


        end
    end

    if itemCount >= 3 and not transformed then
        transformed = true
        Game():GetHUD():ShowItemText("Grennette's True Form!")
        -- play the transformation sound
        SFXManager():Play(transformationSound, 1.0, 0, false, 1.0)
    end
end

-- 20% chance to transform an enemy into a heart pickup when the player takes damage
local function onTransfoPlayerDamage(_, player, damageAmount, damageFlag, source, countdownFrames)
    if transformed then
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
    transformed = false
end



-- Register callbacks for transformation and damage event
MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, onTransfoGameUpdate)
MyMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, onTransfoPlayerDamage, EntityType.ENTITY_PLAYER)
MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onTransfoNewGame)
