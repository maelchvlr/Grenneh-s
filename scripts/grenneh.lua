-- #region evaluate damage and firedelay

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
Grenneh:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, Grenneh.HandleStartingStats)
