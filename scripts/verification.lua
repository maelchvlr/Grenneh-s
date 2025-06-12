-- #region IsKeyItem verification

-- Function to check if an item is a key item (key item are importants item to not destroy)
function Grenneh:IsKeyItem(itemID)
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
--#endregion

--#region Debug function

local SkillIssuePill= {
    PillEffectID = Isaac.GetPillEffectByName("Skill Issue"),
}

---@param player EntityPlayer
function Grenneh:RenderDebugMessageTopOfPlayer(player)
    local position = Isaac.WorldToScreen(player.Position) + Vector(-15, -45)
    local str = tostring(player:GetPlayerType())
    local str2 = tostring(Isaac.GetPlayerTypeByName("Grennette", true))
    Isaac.RenderText(tostring(SkillIssuePill.PillEffectID), position.X, position.Y, 1, 1, 1, 1)
end
Grenneh:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Grenneh.RenderDebugMessageTopOfPlayer)
--#endregion
