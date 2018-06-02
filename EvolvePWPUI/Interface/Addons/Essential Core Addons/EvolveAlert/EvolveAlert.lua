local warnFrame = CreateFrame("frame")
warnFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
warnFrame:SetScript("OnEvent", function(self, event, _, action, sourceGUID, _, _, _, _, _, spellID)
    if spellID == 8143 and action == "SPELL_CAST_SUCCESS" and (UnitGUID("target") == sourceGUID or UnitGUID("focus") == sourceGUID) then
        PlaySound("AlarmClockWarning3")
    end
end)