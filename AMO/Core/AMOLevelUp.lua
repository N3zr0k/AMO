local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Levelup-Anzeige für das Tier des Jägers. Optik und Ablauf folgen Blizzards LevelUpDisplay (Blizzard_LevelUpDisplay, Typ
-- "character"): schwarzer Hintergrund und zwei Goldlinien aus Interface\LevelUp\LevelUpTex (liegt im Client, wird nicht
-- mitgeliefert), oben die kleine Zeile, darunter groß "Level X". Statt "Du hast Level ... erreicht" steht oben der Tiername.
-- Bewusst ein eigener Frame und nicht Blizzards LevelUpDisplay: Dessen Felder aus Addon-Code zu setzen würde Blizzards
-- Ablauf verseuchen (siehe BUGFIX.md), und je nach Client-Version kennt er das Tier gar nicht.

local TEXTURE = "Interface\\LevelUp\\LevelUpTex"
-- Ausschnitte der Textur wie bei Blizzard (Typ "character")
local COORDS = {
    bg = { 0.00195313, 0.63867188, 0.03710938, 0.23828125 },
    line = { 0.00195313, 0.81835938, 0.01953125, 0.03320313 },
}
local WIDTH, HEIGHT = 418, 72
local DELAY = 1.5        -- bis Linien und Text erscheinen
local LINE_GROW = 0.5    -- Linien wachsen von der Mitte aus
local BG_DELAY, BG_GROW = 0.25, 0.15
local FADE_IN, HOLD, FADE_OUT = 0.7, 4, 0.5
local TOTAL = DELAY + FADE_IN + HOLD + FADE_OUT
local frame

local function Clamp01(x) return x < 0 and 0 or x > 1 and 1 or x end

local function OnUpdate(self, elapsed)
    local t = self.t + elapsed
    self.t = t
    if t >= TOTAL then
        self:SetScript("OnUpdate", nil)
        self:Hide()
        return
    end
    local lines = Clamp01((t - DELAY) / LINE_GROW)
    self.lineTop:SetWidth(math.max(WIDTH * lines, 1))
    self.lineBottom:SetWidth(math.max(WIDTH * lines, 1))
    self.lineTop:SetShown(t >= DELAY)
    self.lineBottom:SetShown(t >= DELAY)
    local bg = Clamp01((t - DELAY - BG_DELAY) / BG_GROW)
    self.bg:SetHeight(math.max(103 * bg, 1))
    self.bg:SetShown(t >= DELAY + BG_DELAY)
    local alpha
    if t < DELAY then alpha = 0
    elseif t < DELAY + FADE_IN then alpha = (t - DELAY) / FADE_IN
    elseif t < DELAY + FADE_IN + HOLD then alpha = 1
    else alpha = 1 - (t - DELAY - FADE_IN - HOLD) / FADE_OUT end
    self.text:SetAlpha(Clamp01(alpha))
end

local function Build(api)
    local f = api.CreateFrame("Frame", nil, api.UIParent)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("TOP", api.UIParent, "TOP", 0, -190)
    f:SetFrameStrata("HIGH")
    f:Hide()

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetTexture(TEXTURE)
    f.bg:SetTexCoord(unpack(COORDS.bg))
    f.bg:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    f.bg:SetSize(326, 103)
    f.bg:SetVertexColor(1, 1, 1, 0.6)

    f.lineTop = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    f.lineTop:SetTexture(TEXTURE)
    f.lineTop:SetTexCoord(unpack(COORDS.line))
    f.lineTop:SetPoint("TOP", f, "TOP", 0, 0)
    f.lineTop:SetSize(WIDTH, 7)
    f.lineBottom = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    f.lineBottom:SetTexture(TEXTURE)
    f.lineBottom:SetTexCoord(unpack(COORDS.line))
    f.lineBottom:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    f.lineBottom:SetSize(WIDTH, 7)

    -- Text in eigenem Rahmen, damit er sich getrennt einblenden lässt
    f.text = api.CreateFrame("Frame", nil, f)
    f.text:SetAllPoints()
    f.level = f.text:CreateFontString(nil, "ARTWORK", "GameFont_Gigantic")
    f.level:SetPoint("BOTTOM", 0, 5)
    f.level:SetTextColor(AMO:RGB("accent"))
    f.reached = f.text:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Large")
    f.reached:SetPoint("BOTTOM", f.level, "TOP", 0, 5)
    f.reached:SetTextColor(AMO:RGB("primary"))
    return f
end

--- Anzeige zeigen: reached = kleine Zeile oben (der Tiername), level = große Zeile darunter
function AMO:ShowLevelUp(reached, level)
    local api = self.api
    if not (api.CreateFrame and api.UIParent) then return end
    frame = frame or Build(api)
    frame.reached:SetText(reached or "")
    frame.level:SetText(level or "")
    frame.t = 0
    frame.bg:Hide()
    frame.lineTop:Hide()
    frame.lineBottom:Hide()
    frame.text:SetAlpha(0)
    frame:Show()
    frame:SetScript("OnUpdate", OnUpdate)
end

-- Tier: UNIT_LEVEL für "pet" kommt auch beim Rufen und Anmelden. Gemeldet wird nur, wenn dasselbe Tier (GUID) eine höhere
-- Stufe hat als zuletzt gesehen.
local seen = {}

--- Neue Stufe des Tiers prüfen; gibt true zurück, wenn die Anzeige kam
function AMO:CheckPetLevel()
    local api = self.api
    local guid, level = api.UnitGUID("pet"), api.UnitLevel("pet")
    if not guid or not level or level < 1 then return false end
    local old = seen[guid]
    seen[guid] = level
    if not old or level <= old then return false end
    -- Hat der Client selbst eine Levelup-Anzeige, die das Tier kennt (sie hört auf UNIT_LEVEL), zeigt sie es schon
    local native = api.NativePetDisplay and api.NativePetDisplay()
    if native then return false end
    local name = api.UnitName("pet")
    if not name or name == UNKNOWNOBJECT then return false end
    self:ShowLevelUp(name, format(LEVEL_GAINED or "Level %d", level))
    return true
end

function AMO:EnablePetLevel()
    local api = self.api
    seen[api.UnitGUID("pet") or ""] = api.UnitLevel("pet")
    self:Listen("UNIT_LEVEL", function(_, unit) if unit == "pet" then AMO:CheckPetLevel() end end)
    self:Listen("UNIT_PET", function(_, unit)
        local guid = unit == "player" and api.UnitGUID("pet")
        if guid and not seen[guid] then seen[guid] = api.UnitLevel("pet") end
    end)
end

AMO:RegisterProbe("levelup", function()
    AMO:ShowLevelUp(AMO.api.UnitName("pet") or AMO.api.UnitName("player"), format(LEVEL_GAINED or "Level %d", 99))
    return { AMO:Colorize("Levelup-Anzeige (Vorschau)", "info") }
end, "Levelup display preview")
