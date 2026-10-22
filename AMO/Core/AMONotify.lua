local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Meldungen: auf dem Bildschirm und im Chat. level: "warn" (gelb), "urgent" (rot, mit Ton), "big" (große rote Schrift
-- in der Bildschirmmitte, mit Ton).

AMO.lastNotice = {}

local MIN_REPEAT = 30 -- Mindestabstand zwischen zwei gleichen Meldungen, Sekunden
local DEFAULT_SOUND = 8959 -- Raid-Warnung
local BIG_SECONDS = 6
local bigFrame

--- Große rote Schrift mitten auf dem Bildschirm, verschwindet nach einigen Sekunden von selbst
function AMO:ShowBig(text)
    local api = self.api
    if not (api.CreateFrame and api.UIParent) then return end
    if not bigFrame then
        bigFrame = api.CreateFrame("Frame", nil, api.UIParent)
        bigFrame:SetSize(1000, 120)
        bigFrame:SetPoint("CENTER", api.UIParent, "CENTER", 0, 160)
        bigFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        bigFrame.text = bigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        bigFrame.text:SetAllPoints()
        bigFrame.text:SetTextColor(1, 0.1, 0.1)
        bigFrame.text:SetShadowOffset(2, -2)
    end
    bigFrame.id = (bigFrame.id or 0) + 1
    local id = bigFrame.id
    bigFrame.text:SetText(text)
    bigFrame:Show()
    if api.After then
        api.After(BIG_SECONDS, function() if bigFrame.id == id then bigFrame:Hide() end end)
    end
end

--- Meldung zeigen. key sperrt die Meldung für kurze Zeit gegen Wiederholen; ohne key wird sie immer gezeigt.
function AMO:Notify(level, text, key)
    local now = self.api.GetTime()
    if key then
        local last = self.lastNotice[key]
        if last and now - last < MIN_REPEAT then return false end
        self.lastNotice[key] = now
    end

    local color = level == "warn" and "ffd100" or "ff4040"
    local colored = "|cff" .. color .. text .. "|r"
    local api = self.api
    -- "big" zeigt den Text schon groß in der Bildschirmmitte, die Raidwarnung oben wäre dieselbe Meldung ein zweites Mal
    local bigShown = level == "big" and api.CreateFrame and api.UIParent
    if bigShown then
        pcall(self.ShowBig, self, text)
    elseif api.RaidNotice_AddMessage and api.RaidWarningFrame and api.ChatTypeInfo then
        api.RaidNotice_AddMessage(api.RaidWarningFrame, colored, api.ChatTypeInfo["RAID_WARNING"])
    elseif api.UIErrorsFrame then
        api.UIErrorsFrame:AddMessage(text, 1, level == "warn" and 0.82 or 0.25, level == "warn" and 0 or 0.25)
    end
    self:Print(colored)
    if level ~= "warn" and api.PlaySound then pcall(api.PlaySound, DEFAULT_SOUND) end
    return true
end
