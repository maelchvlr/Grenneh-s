-- File dedicated to all the initialization that isn't specific to a single entity
-- #region Grenneh Init

Grenneh.game = Game()
Grenneh.sound = SFXManager()

-- #endregion
-- #region initSafeCall

-- Safely execute a function and catch any errors
local function InitSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Grenneh : " .. tostring(err) .. "\n")
    end
end

-- #endregion
-- #region Init Characters

-- Storage of tainted & untainted version of the character in Grenneh mod
Grenneh.grennehType  = Isaac.GetPlayerTypeByName("Grenneh", false)
Grenneh.grenetteType = Isaac.GetPlayerTypeByName("Grennette", true)

-- The following line is used in Epiphany to provide a unlimited number of new characters and is followed by lot  of new function to use it
-- witch is not supported in this program
--Grenneh.technical_character = Isaac.GetPlayerTypeByName("[TECHNICAL] C-Side Detect")

--#endregion
-- #region  Init Cosmetics

-- Each character as his own costume / hair (more or less)
local grennehHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_hair.anm2")
local grennehstolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grenneh_stoles.anm2")
local grennetteHairCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_hair.anm2")
local grennettestolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_stoles.anm2")
local grennettewigCostume = Isaac.GetCostumeIdByPath("gfx/characters/grennette_wig.anm2")

-- don't work ? idk
local redbullWingCostume = Isaac.GetCostumeIdByPath("gfx/characters/redbull_wings.anm2")

--#endregion
-- #region GiveCostumesOnInit

-- Add the costumes for grenneh and grenette
---@param player EntityPlayer
function Grenneh:GiveCostumesOnInit(player)
    if player:GetPlayerType() == Grenneh.grennehType then
        player:AddNullCostume(grennehHairCostume)
        player:AddNullCostume(grennehstolesCostume)
        return -- Only give costumes to Grenneh
    elseif player:GetPlayerType() == Grenneh.grenetteType then
        player:AddNullCostume(grennetteHairCostume)
        player:AddNullCostume(grennettestolesCostume)
        return -- Only give costumes to Grennette
    end
end

function Grenneh:GiveCostumesOnInitSafe(player)
    InitSafeCall(Grenneh.GiveCostumesOnInit, Grenneh, player)
end

Grenneh:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Grenneh.GiveCostumesOnInitSafe)
--#endregion