-- #region SkillIssue

-- Cannot make Skill Issue spawn so don't know if it work

-- get sound
local SkillIssuePill = {
    PillEffectID = Isaac.GetPillEffectByName("Skill Issue"),
}
SkillIssuePill.Color = Isaac.AddPillEffectToPool(SkillIssuePill.PillEffectID)

function SkillIssuePill.Proc(PillEffectID, playerWhoUsedItem, useFlag)
    local SkillIssueSound = Isaac.GetSoundIdByName("SkillIssue")    --Add or remove smace for lisibility between SkillIssue (pill) and Skill Issue (sound)
    Isaac.DebugString("Use the SkillIssuePill")
    local level = Grenneh.game:GetLevel()
    level:SetRedHeartDamage()
    Grenneh.sound:Play(SkillIssueSound, 2, 0, false, 1)
end
Grenneh:AddCallback(ModCallbacks.MC_USE_PILL, SkillIssuePill.Proc, SkillIssuePill.PillEffectID)

--#endregion