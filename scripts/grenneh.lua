-- File dedicated to all the function that are initializing custom behavior for grenneh character
-- #region GrennehSafeCall

-- Safely execute a function and catch any errors
local function GrennehSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Grenneh : " .. tostring(err) .. "\n")
    end
end

-- #endregion
-- #region init Grenneh & Grennette
-- TODO Move the function to init.lua if grennette hasn't it own class

---@param player EntityPlayer
function Grenneh:OnPlayerInit(player)
    TATANOHEALED = false
    WIGON = false
    --HAS_SIXTH_PICKUP = false
    --WINGS_ON = false

    if player:GetPlayerType() == Grenneh.grennehType then
        if not player:HasCollectible(Isaac.GetItemIdByName("Mimine")) then
            player:AddCollectible(Isaac.GetItemIdByName("Mimine"))
            -- Add any additional initialization here
        end
        if not player:HasCollectible(Isaac.GetItemIdByName("Grenneh's bean")) then
            player:AddCollectible(Isaac.GetItemIdByName("Grenneh's bean"))
            -- Add any additional initialization here
        end
    end
    if player:GetPlayerType() == Grenneh.grennetteType then -- TODO : move it to it's own class
        if not player:HasCollectible(Isaac.GetItemIdByName("Head of Kramptus")) then
            player:AddCollectible(Isaac.GetItemIdByName("Head of Kramptus"))
            -- Add any additional initialization here
        end
    end
end

-- Wrapper for Grenneh:OnPlayerInit with SafeCall
function Grenneh:OnPlayerInitSafe(player)
    GrennehSafeCall(Grenneh.OnPlayerInit, Grenneh, player)
end

Grenneh:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Grenneh.OnPlayerInitSafe)

--#endregion
-- #region evaluate Grenneh damage and firedelay

--- @param player EntityPlayer
--- @param flag CacheFlag 
function Grenneh:HandleStartingStats(player, flag)
    if player:GetPlayerType() == Grenneh.grennehType then
        if flag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then --Bitwise operation to obtain the value wanted
            player.Damage = player.Damage * 0.3  -- Cap damage at 5 also divide them by three
        end
        if flag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = player.MaxFireDelay * 0.15 -- Uncap delay also boost speedrate
        end
    end
end

function Grenneh:HandleStartingStatsSafe(player, flag)
    GrennehSafeCall(Grenneh.HandleStartingStats, Grenneh, player, flag)
end

Grenneh:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Grenneh.HandleStartingStatsSafe)

-- #endregion
-- #region Grenneh custom hitsound

---@param Entity Entity             --Entity pinpoint in the callback
---@param Amout number              --float
---@param DamageFlags number        --int   if Entity = EntityPlayer then Damage Amounts in half-hearts, otherwise number of hit points
---@param Source EntityRef          
---@param CountDownFrames number    --int
---@return boolean                  --return true if damage calculation or false to ignore
function Grenneh:Damage(Entity, Amout, DamageFlags, Source, CountDownFrames)
    local hitSound = Isaac.GetSoundIdByName("GrennehHit")
    if Isaac.GetPlayer(0):GetPlayerType() == Grenneh.grennehType then
        local pitch = math.random(80,120)/100   -- Make different sound when taking damages i guess
        Grenneh.sound:Play(hitSound,2.0,0, false, pitch)
    end
    return true
end

function Grenneh:DamageSafe(Entity, Amout, DamageFlags, Source, CountDownFrames)
    GrennehSafeCall(Grenneh.Damage, Grenneh, Entity, Amout, DamageFlags, Source, CountDownFrames)
end

Grenneh:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Grenneh.DamageSafe, EntityType.ENTITY_PLAYER)

-- #endregion
-- #region I don't know if it the perfect way to do that

-- Deactivated till more specification
function Grenneh:db()
    if Isaac.GetPlayer(0):GetPlayerType() == Grenneh.grennehType then   -- Search the player because no params for POST_UPDATE
        if (Grenneh.sound:IsPlaying(SoundEffect.SOUND_ISAAC_HURT_GRUNT)) then
            Grenneh.sound:Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT);
        end
    end
end

function Grenneh:dbSafe()
    GrennehSafeCall(Grenneh.db, Grenneh)
end

--Grenneh:AddCallback(ModCallbacks.MC_POST_UPDATE, Grenneh.dbSafe)

-- #endregion