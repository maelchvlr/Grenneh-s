local MyMod = RegisterMod("Grenneh Mod", 1)

local grennehType = Isaac.GetPlayerTypeByName("Grenneh", false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.
local grennetteType = Isaac.GetPlayerTypeByName("Grennette", true)
local grennehHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_hair.anm2") -- Exact path, with the "resources" folder as the root
local grennehstolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_stoles.anm2") -- Exact path, with the "resources" folder as the root
local grennetteHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_hair.anm2") -- Exact path, with the "resources" folder as the root
local grennettestolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_stoles.anm2") -- Exact path, with the "resources" folder as the root

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
local hasTeleported = false

function MyMod:OnPlayerInit(player)
    tatanoHealed = false
    hasSixthPickup = false
    hasTeleported = false
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

local mimine = Isaac.GetItemIdByName("Mimine")
local mimineLuck = 1

function MyMod:EvaluateMimine(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK then
        local itemCount = player:GetCollectibleNum(mimine);
        local luckToAdd = mimineLuck * itemCount
        player.Luck = player.Luck + luckToAdd
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateMimine)

-- List of all Guppy item IDs
local guppyItems = {
    Isaac.GetItemIdByName("Guppy's Tail"),
    Isaac.GetItemIdByName("Guppy's Collar"),
    Isaac.GetItemIdByName("Dead Cat"),
    Isaac.GetItemIdByName("Guppy's Hairball")
}

-- Function to get a list of Guppy items that the player does not already have
local function GetAvailableGuppyItems(player)
    local availableItems = {}
    for _, itemId in ipairs(guppyItems) do
        if not player:HasCollectible(itemId) then
            table.insert(availableItems, itemId)
        end
    end
    return availableItems
end

function MyMod:OnNewRoom()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    -- Check if the player has Mimine
    if not player:HasCollectible(mimine) or not room:IsFirstVisit() then
        return -- Do not reroll if player doesn't have Mimine
    end

    local availableGuppyItems = GetAvailableGuppyItems(player)
    if #availableGuppyItems == 0 then
        return -- All Guppy items already collected
    end

    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
        local entity = entities[i]
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

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.OnNewRoom)


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

local bmth = Isaac.GetItemIdByName("BMTH !")
local bmthDamage = 2.5

function MyMod:EvaluateBmth(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(bmth);
        local dmgToAdd = bmthDamage * itemCount
        player.Damage = player.Damage + dmgToAdd
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateBmth)

function MyMod:OnTearUpdate(tear)
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(bmth) then
        -- Change tear color. Modify the RGBA values as needed.
        tear.Color = Color(1, 0, 0, 1, 0, 0, 0)  -- Red tears, for example
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, MyMod.OnTearUpdate)

function MyMod:HandleBloodTrail(player)
    if not player:HasCollectible(bmth) then
        return -- End the function early
    end

    -- Every 4 frames. The percentage sign is the modulo operator, which returns the remainder of a division operation!
    if game:GetFrameCount() % 4 == 0 then
        -- Vector.Zero is the same as Vector(0, 0). It is a constant!
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, player.Position, Vector.Zero, player):ToEffect()
        creep.SpriteScale = Vector(0.5, 0.5) -- Make it smaller!
        creep:Update() -- Update it to get rid of the initial red animation that lasts a single frame.
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyMod.HandleBloodTrail)

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
local mod = RegisterMod("MyMod", 1)
local monster = Isaac.GetItemIdByName("Monster")
local monsterDamage = 1.2
local monsterSpeed = 0.1
local monsterTearRate = -0.2
local isApplyingExtraDamage = false  -- Flag to prevent recursion
local isInverted = false
local inversionTimer = 0
local visitedRooms = {}  -- To track if a room has been visited

function mod:EvaluateMonster(player, cacheFlags)
    local itemCount = player:GetCollectibleNum(monster)

    if itemCount >= 1 and cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * monsterDamage ^ itemCount
    end
    if itemCount >= 2 and cacheFlags & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed * (1 + monsterSpeed) ^ (itemCount - 1)
    end
    if itemCount >= 3 and cacheFlags & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay * (1 + monsterTearRate) ^ (itemCount - 2)
    end
    if itemCount >= 4 then
        local radioactiveGreen = Color(0.4, 0.5, 0.4, 0.8, 0, 0.5, 0)  -- RGB with a strong green glow
        player.TearColor = radioactiveGreen
        player:SetColor(radioactiveGreen, 0, 1, false, false)  -- Set player color to radioactive green
    end
end

function mod:OnTearFire(tear)
    local player = Isaac.GetPlayer(0)
    local itemCount = player:GetCollectibleNum(monster)

    -- Apply the poison effect directly when the tear is fired if the player has at least 4 Monster pickups
    if itemCount >= 4 then
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_POISON
    end

    -- Random tear direction modification
    if not hasSixthPickup and itemCount >= 4 and math.random() < 0.3 then
        tear:Remove()
        player:FireTear(player.Position, Vector.FromAngle(math.random() * 360) * 10, false, false, false)
    end
end

function mod:OnDamageTaken(entity, amount, flag, source, countdownFrames)
    local player = Isaac.GetPlayer(0)
    if entity.Type == EntityType.ENTITY_PLAYER and player:GetCollectibleNum(monster) >= 3 and not hasSixthPickup and not isApplyingExtraDamage then
        isApplyingExtraDamage = true
        player:TakeDamage(1, DamageFlag.DAMAGE_RED_HEARTS, EntityRef(nil), 0)
        isApplyingExtraDamage = false
    end
end

function mod:OnItemPickup(player)
    local player = Isaac.GetPlayer(0)
    local itemCount = player:GetCollectibleNum(monster)
    if itemCount == 6 and not hasSixthPickup then
        player:Die()  -- Kill the player to apply the one-time effect
        hasSixthPickup = true
    end
end

function mod:updateInvertedControls()
    local player = Isaac.GetPlayer(0)
    if isInverted and inversionTimer > 0 then
        mod:InvertControls(player)
        inversionTimer = inversionTimer - 1
    elseif inversionTimer <= 0 then
        isInverted = false
    end
end

function mod:InvertControls(player)
    local moveInput = player:GetMovementInput()
    local invertedVector = Vector(-moveInput.X, -moveInput.Y)

    if invertedVector:Length() > 0 then
        invertedVector = invertedVector:Normalized()
        player.Velocity = player.Velocity + invertedVector * 2.5  -- Apply normalized, inverted movement
    end
end

function mod:OnNewRoom()
    local player = Isaac.GetPlayer(0)
    local currentRoomIndex = Game():GetLevel():GetCurrentRoomIndex()
    local itemCount = player:GetCollectibleNum(monster)

    -- Check if the room is newly entered
    if not visitedRooms[currentRoomIndex] then
        visitedRooms[currentRoomIndex] = true  -- Mark the room as visited

        -- Reroll a random item on the floor to 'Monster' based on item count, if not the sixth pickup
        if math.random() < (0.1 * itemCount) and not hasSixthPickup then
            for _, entity in pairs(Isaac.GetRoomEntities()) do
                if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    entity:ToPickup():Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, monster, true, true, false)
                    break  -- Only reroll one item per room entry
                end
            end
        end

        -- Invert controls if the player has at least 5 monsters, not the sixth pickup
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

-- Function to potentially reroll any pickup into 'Monster'
function mod:OnPickupInit(pickup)
    local player = Isaac.GetPlayer(0)
    local itemCount = player:GetCollectibleNum(monster)

    -- Check if the pickup is a collectible and not already a 'Monster'
    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= monster and math.random() < (0.1 * itemCount) and not hasSixthPickup then
        pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, monster, true, true, false)
    end
end


-- Register callbacks
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.OnPickupInit)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateMonster)
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnTearFire)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnDamageTaken, EntityType.ENTITY_PLAYER)
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OnItemPickup)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.updateInvertedControls)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)


-------- Choix du Chat

local choixDuChat = Isaac.GetItemIdByName("Choix du Chat")
local isInSpecialRoom = false

-- When the item is used
function mod:UseChoixDuChat()
    local player = Isaac.GetPlayer(0)
    player:AnimateTeleport(true)
    Isaac.ExecuteCommand("goto s.default.7777")  -- Teleport to the custom room
    player:RemoveCollectible(choixDuChat)  -- Remove the item from the inventory
    isInSpecialRoom = true
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseChoixDuChat, choixDuChat)

-- Function to handle room entry
function mod:OnNewRoom()
    if isInSpecialRoom then
        local game = Game()
        local level = game:GetLevel()
        local roomDesc = level:GetCurrentRoomDesc()
        game:GetHUD():ShowItemText("Chat, on prends quoi?", "")
        isInSpecialRoom = false  -- Reset flag
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

----- happenings

local happeningSounds = Isaac.GetSoundIdByName("Happening")

function MyMod:PlayRandomSoundOnRoomEntry()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()
    
    if room:IsFirstVisit() then
        -- 1% chance to play a sound
        if math.random(1, 500) == 1 then
            sound:Play(happeningSounds, 1.0, 0, false, 1.0)
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.PlayRandomSoundOnRoomEntry)

------- Grennette's Mascara


local grennettesMascara = Isaac.GetItemIdByName("Grennette's Mascara")

-- Define colors for rainbow tears with pastel transition
local rainbowColors = {
    Color(1, 0, 0, 1, 0, 0, 0),     -- Red
    Color(1, 0.5, 0, 1, 0, 0, 0),   -- Orange
    Color(1, 1, 0, 1, 0, 0, 0),     -- Yellow
    Color(0, 1, 0, 1, 0, 0, 0),     -- Green
    Color(0, 0, 1, 1, 0, 0, 0),     -- Blue
    Color(0.29, 0, 0.51, 1, 0, 0, 0), -- Indigo
    Color(0.56, 0, 1, 1, 0, 0, 0)   -- Violet
}

local colorIndex = 1
local colorTransitionSpeed = 0.25 -- Faster color transition speed
local currentColor = rainbowColors[colorIndex]

-- Cache flags for item effects
function MyMod:EvaluateGrennetteMascara(player, cacheFlag)
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
            player.TearFlags = player.TearFlags | TearFlags.TEAR_PIERCING | TearFlags.TEAR_SPECTRAL -- Allow tears to pierce, and pass through walls
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateGrennetteMascara)

-- Smooth transition for multicolor tears
function MyMod:UpdateColorTransition()
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(grennettesMascara) then
        local nextColorIndex = colorIndex % #rainbowColors + 1
        local nextColor = rainbowColors[nextColorIndex]

        currentColor = Color(
            currentColor.R + (nextColor.R - currentColor.R) * colorTransitionSpeed,
            currentColor.G + (nextColor.G - currentColor.G) * colorTransitionSpeed,
            currentColor.B + (nextColor.B - currentColor.B) * colorTransitionSpeed,
            1,
            0,
            0,
            0
        )

        -- Update index when fully transitioned to the next color
        if (math.abs(currentColor.R - nextColor.R) < 0.01 and
            math.abs(currentColor.G - nextColor.G) < 0.01 and
            math.abs(currentColor.B - nextColor.B) < 0.01) then
            colorIndex = nextColorIndex
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_UPDATE, MyMod.UpdateColorTransition)

-- Add tear effects
function MyMod:OnTearUpdate(tear)
    local player = tear.Parent:ToPlayer()
    if player and player:HasCollectible(grennettesMascara) then
        -- Assign smooth transition color to tears
        tear.Color = currentColor

        -- Apply tear effects: Charm, piercing, and spectral
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_CHARM | TearFlags.TEAR_PIERCING | TearFlags.TEAR_SPECTRAL

        -- Initialize the tear size
        if not tear:GetData().initialized then
            tear.Scale = 1.5 -- Start with larger tears
            tear:GetData().initialized = true
        end
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, MyMod.OnTearUpdate)

-- Increase tear size on hit
function MyMod:OnTearCollision(tear, entity)
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(grennettesMascara) and entity:IsVulnerableEnemy() then
        tear.Scale = tear.Scale + 0.2 -- Increase the size of the tear each time it hits an enemy
    end
end

MyMod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, MyMod.OnTearCollision)


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
function MyMod:OnNewRoom()
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
function MyMod:OnNewLevel()
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
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MyMod.OnNewRoom)
MyMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, MyMod.OnNewLevel)
MyMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyMod.EvaluateCache)


---- La Contemplation

-- Register the new item "La Contemplation"
local LaContemplation = Isaac.GetItemIdByName("La Contemplation")

-- Callback for using the item "La Contemplation"
function MyMod:UseLaContemplation()
    local player = Isaac.GetPlayer(0)

    -- Get the player's collectible items
    local collectibles = {}
    for i = 1, CollectibleType.NUM_COLLECTIBLES do
        if player:HasCollectible(i) then
            table.insert(collectibles, i)
        end
    end

    -- Check if the player has any collectibles to remove
    if #collectibles > 0 then
        -- Select a random collectible to remove
        local randomIndex = math.random(1, #collectibles)
        local randomCollectible = collectibles[randomIndex]

        -- Remove the random collectible
        player:RemoveCollectible(randomCollectible)
    end

    -- Teleport the player to the Planetarium using a console command
    Isaac.ExecuteCommand("goto s.planetarium") -- The command to teleport to the special room type Planetarium

    return true
end

-- Register the callback for using the item
MyMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyMod.UseLaContemplation, LaContemplation)

-- Register item details in the initialization function
function MyMod:OnGameStart()
    if EID then
        EID:addCollectible(Isaac.GetItemIdByName("Mimine"), "Gives a #{{Luck}} +1 Luck bonus and 8% chance to reroll items into Guppy items! #{{ColorRed}}Meow!")
        EID:addCollectible(Isaac.GetItemIdByName("Grenneh's bean"), "Farts!")
        EID:addCollectible(Isaac.GetItemIdByName("Head of Kramptus"), "Might or might not be what you think....")
        EID:addCollectible(Isaac.GetItemIdByName("BMTH !"), "Increases your damage by 2.5 for each one you have! #{{ColorRed}}Rock on! #Also turns your tears red and leaves a red creep trail.")
        EID:addCollectible(Isaac.GetItemIdByName("Gaming Chair"), "Boosts your speed by 0.4 for each one you have! #{{ColorTeal}}Get in the fast lane!")
        EID:addCollectible(Isaac.GetItemIdByName("Tatanosaurus"), "Adds 4 max hearts and heals you for 4 hearts when picked up! #{{ColorRed}}Feel the power of the Tatanosaurus!")
        EID:addCollectible(Isaac.GetItemIdByName("A Bo'oh'o'wa'er"), "Adds 2 soul hearts and reduces fire delay by 0.1 when picked up! #Stay hydrated!")
        EID:addCollectible(Isaac.GetItemIdByName("Redbull"), "Gives you wings! #Increases speed by 2 and grants flight! #{{ColorYellow}}Fly and move faster!")
        EID:addCollectible(Isaac.GetItemIdByName("Monster"), "Various buffs based on how many you have! #1: Damage x1.2 #2: Speed x1.1 #3: Fire rate x0.8 but take full heart damage forever #4: Tears become radioactive green and poison enemies but you have a chance to not fire in the right direction #5: Randomly invert controls and gain temporary invincibility #6: Die, revive if you have a life item, removes every bad effect.")
        EID:addCollectible(Isaac.GetItemIdByName("Choix du Chat"), "Teleport to a special room! #{{ColorPurple}}Let the chat decide! #Teleports to a custom room when used.")
        EID:addCollectible(Isaac.GetItemIdByName("Grennette's Mascara"), "Beautiful rainbow tears! #{{ColorRainbow}}Double damage #Increases tear size #Reduces fire rate #+2 Luck #Tears split, pierce, and are spectral #Smooth transition colors #Charm, piercing, and spectral tears #Tears increase in size on hit.")
        EID:addCollectible(Isaac.GetItemIdByName("La Contemplation"), "{{Warning}}Deletes a random item from your inventory and teleports you to the Planetarium! #{{ColorBlue}}Look to the stars!")
    end
end

MyMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MyMod.OnGameStart)