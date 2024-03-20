local MyMod = RegisterMod("Grenneh Mod", 1)

local grennehType = Isaac.GetPlayerTypeByName("Grenneh", false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.
local grennetteType = Isaac.GetPlayerTypeByName("Grenneh", true)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_hair.anm2") -- Exact path, with the "resources" folder as the root
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_stoles.anm2") -- Exact path, with the "resources" folder as the root

local skillIssue = Isaac.GetSoundIdByName("SkillIssue")

local SkillIssue= {
    ID = Isaac.GetPillEffectByName("Skill Issue"),

}

SkillIssue.Color = Isaac.AddPillEffectToPool(SkillIssue.ID)

function MyMod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= grennehType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
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

function MyMod:OnPlayerInit(player)
    tatanoHealed = false
    print("yo", grennehType, grennetteType)
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
        local itemCount = player:GetCollectibleNum(redbull);
        local spdToAdd = redbullSpeed * itemCount
        player.MoveSpeed = player.MoveSpeed + spdToAdd
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



