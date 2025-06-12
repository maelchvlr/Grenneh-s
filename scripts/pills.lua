-- #region PillsSafeCall

-- Safely execute a function and catch any errors
local function PillsSafeCall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Isaac.ConsoleOutput("Error in Pills : " .. tostring(err) .. "\n")
    end
end

-- #endregion
-- #region SkillIssue

-- Cannot make Skill Issue spawn so don't know if it work

local SkillIssuePill = {
    PillEffectID = Isaac.GetPillEffectByName("Skill Issue"),
}
SkillIssuePill.Color = Isaac.AddPillEffectToPool(SkillIssuePill.PillEffectID)

---@param PillEffectID any
---@param playerWhoUsedItem any
---@param useFlag any
function SkillIssuePill.ProcPill(PillEffectID, playerWhoUsedItem, useFlag)
    local SkillIssueSound = Isaac.GetSoundIdByName("SkillIssue")    --Add or remove smace for lisibility between SkillIssue (pill) and Skill Issue (sound)
    Isaac.DebugString("Use the SkillIssuePill")
    local level = Grenneh.game:GetLevel()
    level:SetRedHeartDamage()
    Grenneh.sound:Play(SkillIssueSound, 2, 0, false, 1)
end

function SkillIssuePill.ProcSafe(PillEffectID, playerWhoUsedItem, useFlag)
    PillsSafeCall(Grenneh.ProcPill, Grenneh, PillEffectID, playerWhoUsedItem, useFlag)
end

Grenneh:AddCallback(ModCallbacks.MC_USE_PILL, SkillIssuePill.ProcSafe, SkillIssuePill.PillEffectID)

-- #endregion