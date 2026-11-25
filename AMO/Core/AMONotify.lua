local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Meldungen: auf dem Bildschirm und im Chat. level: "warn" (Warnung, Gold), "urgent" (Dringend, Orange, mit Ton), "big"
-- (große Schrift in der Bildschirmmitte in Kritisch-Rot, mit Ton). Farben aus AMO.colors.

AMO.lastNotice = {}

local MIN_REPEAT = 30 -- Mindestabstand zwischen zwei gleichen Meldungen, Sekunden
local DEFAULT_SOUND = 8959 -- Raid-Warnung
local BIG_SECONDS = 6
local LINE_SECONDS = 5
local bigFrame, lineFrame

--- Große Schrift in Kritisch-Rot mitten auf dem Bildschirm, verschwindet nach einigen Sekunden von selbst
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
        bigFrame.text:SetTextColor(self:RGB("critical"))
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

--- Einzeilige Meldung oben im Bild in eigenem Frame. Bewusst nicht RaidNotice_AddMessage(RaidWarningFrame): der Aufruf aus
-- Addon-Code schreibt verseuchte Werte in Blizzards Meldungstabellen, und der nächste Blizzard-Code, der sie liest (z. B.
-- RaidWarningUtil.ClearBossEmotes in CinematicFrame), läuft danach verseucht und scheitert an geheimen Zahlen (LowHealthFrame).
function AMO:ShowLine(text)
    local api = self.api
    if not (api.CreateFrame and api.UIParent) then return end
    if not lineFrame then
        lineFrame = api.CreateFrame("Frame", nil, api.UIParent)
        lineFrame:SetSize(1000, 40)
        lineFrame:SetPoint("TOP", api.UIParent, "TOP", 0, -180)
        lineFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        lineFrame.text = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        lineFrame.text:SetAllPoints()
        lineFrame.text:SetShadowOffset(1, -1)
    end
    lineFrame.id = (lineFrame.id or 0) + 1
    local id = lineFrame.id
    lineFrame.text:SetText(text)
    lineFrame:Show()
    if api.After then
        api.After(LINE_SECONDS, function() if lineFrame.id == id then lineFrame:Hide() end end)
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

    local colorKey = level == "warn" and "warning" or level == "urgent" and "urgent" or "critical"
    local colored = self:Colorize(text, colorKey)
    local api = self.api
    -- "big" zeigt den Text schon groß in der Bildschirmmitte, die Raidwarnung oben wäre dieselbe Meldung ein zweites Mal
    local bigShown = level == "big" and api.CreateFrame and api.UIParent
    if bigShown then
        pcall(self.ShowBig, self, text)
    else
        pcall(api.ShowLine, self, colored)
    end
    self:Print(colored)
    if level ~= "warn" and api.PlaySound then pcall(api.PlaySound, DEFAULT_SOUND) end
    return true
end
