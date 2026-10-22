local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L

-- Optionsseite im Einstellungsfenster, mit normalen Blizzard-Bausteinen wie in Binds.
-- Aufbau: "AMO" ist eine Übersichtsseite (Logo, Version, Autor), alle Einstellungen stehen in der Unterseite "Allgemein",
-- gegliedert in Abschnitte mit Überschrift links und Trennlinie. Was auf die Seite kommt, steht als Daten in
-- AMO:OptionSections() (Core) und Ammo.OptionSections() (Modules/Ammo/AmmoOptions.lua).

local PADDING = 16
local SECTION_GAP = 22
local WIDTH = 560 -- Breite des Inhalts der Unterseite
local CHECK_WIDTH = 30 -- Platz des Kästchens, daneben beginnt der Beschreibungstext

----------------------------------------------------------------------
-- Daten
----------------------------------------------------------------------

--- Abschnitte der Unterseite: Liste { title, items }; ein Eintrag ist { type = "toggle" | "slider", key, name, desc, get, set,
-- indent, enabledIf, ... }. Für andere Klassen als Jäger gibt es nur einen Hinweis.
function AMO:OptionSections()
    if not self:IsHunter() then
        return { { title = L["Addon"], note = L["AMO is for hunters. The options appear on a hunter character."] } }
    end
    local sections = {
        { title = L["Addon"], items = { {
            type = "toggle", key = "enabled", name = L["Active"],
            desc = L["Turns the addon off completely: no warnings, no questions, nothing is checked."],
            get = function() return self.db.profile.enabled end,
            set = function(value) self.db.profile.enabled = value and true or false end,
        } } },
    }
    for _, section in ipairs(self.ammo.OptionSections()) do sections[#sections + 1] = section end
    return sections
end

--- Ist ein Eintrag ausgegraut? Ist das Addon aus, ist alles außer "Aktiv" aus; sonst hängt es von enabledIf ab
function AMO:IsOptionDisabled(item)
    if item.key == "enabled" then return false end
    if not self.db.profile.enabled then return true end
    return item.enabledIf ~= nil and not item.enabledIf()
end

----------------------------------------------------------------------
-- Bausteine
----------------------------------------------------------------------

local panels = {}
local sliderCount = 0

local function CreatePanel(name)
    local panel = CreateFrame("Frame")
    panel.name = name
    panel.refreshers = {}
    panel:Hide()
    panel:SetScript("OnShow", function(self) AMO:RefreshPanel(self) end)
    panels[#panels + 1] = panel
    return panel
end

--- Alle Einträge einer Seite neu aus den Einstellungen lesen
function AMO:RefreshPanel(panel)
    for _, refresh in ipairs(panel.refreshers) do refresh() end
end

--- Offene Optionsseiten nachführen, z. B. wenn sich der Köcher ändert und damit die Obergrenzen der Regler
function AMO:RefreshOptionsPanel()
    for _, panel in ipairs(panels) do
        if panel:IsShown() then self:RefreshPanel(panel) end
    end
end

-- Überschrift der Seite mit Untertitel; gibt die Höhe zurück, die bis zum nächsten Baustein vergeht
local function Header(parent, title, subtitle)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetPoint("TOPLEFT", PADDING, -PADDING)
    text:SetText(AMO:Colorize(title, "primary"))
    local sub = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(WIDTH)
    sub:SetJustifyH("LEFT")
    sub:SetText(subtitle or "")
    return PADDING + text:GetStringHeight() + 6 + sub:GetStringHeight()
end

-- Abschnitt: Überschrift links in Gold, danach eine dünne Linie bis zum rechten Rand
local function Section(parent, y, title)
    y = y + SECTION_GAP
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("TOPLEFT", PADDING, -y)
    text:SetText(AMO:Colorize(title, "accent"))
    local line = AMO:CreateDivider(parent, nil, 0.35)
    line:SetPoint("LEFT", text, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -PADDING, 0)
    return y + text:GetStringHeight()
end

local function Description(parent, anchor, x, width, text)
    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    desc:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -anchor)
    desc:SetWidth(width)
    desc:SetJustifyH("LEFT")
    desc:SetText(text)
    return desc
end

local function SetEnabledLook(widget, label, on)
    if widget.SetEnabled then widget:SetEnabled(on) end
    if label then label:SetFontObject(on and "GameFontHighlight" or "GameFontDisable") end
end

local function Toggle(panel, parent, y, item)
    local x = PADDING + (item.indent or 0)
    y = y + 6
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    -- eigene Beschriftung, denn das Textfeld der Vorlage heißt je nach Client anders
    local label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 4, 1)
    label:SetText(item.name)
    check:SetScript("OnClick", function(self)
        item.set(self:GetChecked() and true or false)
        AMO:RefreshPanel(panel)
    end)
    panel.refreshers[#panel.refreshers + 1] = function()
        check:SetChecked(item.get() and true or false)
        SetEnabledLook(check, label, not AMO:IsOptionDisabled(item))
    end
    y = y + 26
    if item.desc then
        local desc = Description(parent, y + 2, x + CHECK_WIDTH, WIDTH - (item.indent or 0) - CHECK_WIDTH, item.desc)
        y = y + 2 + desc:GetStringHeight()
    end
    return y
end

local function Slider(panel, parent, y, item)
    local x = PADDING + (item.indent or 0)
    y = y + 10
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    label:SetText(item.name)
    local value = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    value:SetPoint("LEFT", label, "RIGHT", 8, 0)

    sliderCount = sliderCount + 1
    local name = "AMOOptionsSlider" .. sliderCount
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -(y + 22))
    slider:SetWidth(280)
    slider:SetValueStep(item.step or 1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local text = _G[name .. "Text"]
    if text then text:SetText("") end -- der Name steht über dem Regler
    local low, high = _G[name .. "Low"], _G[name .. "High"]

    local function Max()
        return type(item.max) == "function" and item.max() or item.max
    end

    local function ShowValue(current)
        if current == item.min and item.low then
            value:SetText(item.low)
        elseif current == Max() and item.high then
            value:SetText(item.high)
        else
            value:SetText(tostring(current))
        end
    end

    local refreshing = false
    slider:SetScript("OnValueChanged", function(_, current)
        if refreshing then return end
        local step = item.step or 1
        current = math.floor(current / step + 0.5) * step
        item.set(current)
        ShowValue(current)
    end)
    panel.refreshers[#panel.refreshers + 1] = function()
        refreshing = true
        local max = Max()
        slider:SetMinMaxValues(item.min, max)
        slider:SetValue(math.min(item.get(), max))
        if low then low:SetText(item.low or tostring(item.min)) end
        if high then high:SetText(item.high or tostring(max)) end
        ShowValue(item.get())
        refreshing = false
        local on = not AMO:IsOptionDisabled(item)
        SetEnabledLook(slider, label, on)
        slider:SetAlpha(on and 1 or 0.5)
    end
    y = y + 22 + 17 + 14
    if item.desc then
        local desc = Description(parent, y, x, WIDTH - (item.indent or 0), item.desc)
        y = y + desc:GetStringHeight()
    end
    return y
end

----------------------------------------------------------------------
-- Seiten
----------------------------------------------------------------------

local function BuildMainPanel()
    local panel = CreatePanel(format("|T%s:0|t %s", AMO.icon, AMO.wordmark))

    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(256, 256)
    logo:SetPoint("TOPLEFT", PADDING, -PADDING)
    logo:SetTexture(AMO.logoLarge)

    local info = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    info:SetPoint("LEFT", logo, "RIGHT", PADDING, 0)
    info:SetJustifyH("LEFT")
    local get = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local muted = AMO.colors.muted
    info:SetText(format("|cff%s%s:|r %s\n|cff%s%s:|r %s", muted, L["Version"],
        get(AMO.name, "Version") or "?", muted, L["Author"], get(AMO.name, "Author") or "?"))

    local intro = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    intro:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -PADDING)
    intro:SetPoint("RIGHT", -PADDING, 0)
    intro:SetJustifyH("LEFT")
    intro:SetSpacing(3)
    intro:SetText(L["Warns when your ammo runs low and offers to refill the quiver at a vendor."])

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -12)
    hint:SetText(L["The settings are under General."])
    return panel
end

local function BuildGeneralPanel()
    local panel = CreatePanel(L["General"])

    -- Die Seite kann länger sein als das Einstellungsfenster, deshalb scrollt der Inhalt
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", -28, 4)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH + 2 * PADDING, 1)
    scroll:SetScrollChild(content)

    local y = Header(content, L["General"], L["Warns when your ammo runs low and offers to refill the quiver at a vendor."])
    for _, section in ipairs(AMO:OptionSections()) do
        y = Section(content, y, section.title)
        if section.note then
            y = y + 8
            local note = Description(content, y, PADDING, WIDTH, section.note)
            y = y + note:GetStringHeight()
        end
        for _, item in ipairs(section.items or {}) do
            y = (item.type == "slider" and Slider or Toggle)(panel, content, y, item)
        end
    end
    content:SetHeight(y + PADDING)
    return panel
end

----------------------------------------------------------------------
-- Anmeldung
----------------------------------------------------------------------

function AMO:SetupOptions()
    if not (CreateFrame and (Settings or InterfaceOptions_AddCategory)) then return end
    local main, general = BuildMainPanel(), BuildGeneralPanel()
    -- Die alte Oberfläche hängt eine Seite über den Namen unter ihre Hauptseite
    general.parent = main.name
    self.generalPanel = general
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(main, main.name)
        self.settingsCategory = category
        if Settings.RegisterCanvasLayoutSubcategory then
            self.settingsSubcategory = Settings.RegisterCanvasLayoutSubcategory(category, general, general.name)
        end
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(main)
        InterfaceOptions_AddCategory(general)
    end
end

function AMO:OpenOptions()
    if InCombatLockdown and InCombatLockdown() then
        -- Das Einstellungsfenster im Kampf zu öffnen kann geschützte Seiten verseuchen
        self:Print(L["The options cannot be opened in combat."])
        return
    end
    if self.settingsCategory and Settings and Settings.OpenToCategory then
        local target = self.settingsSubcategory or self.settingsCategory
        Settings.OpenToCategory(target:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory and self.generalPanel then
        -- Zweimal, denn die alte Oberfläche überhört den ersten Aufruf, solange sie nie offen war
        InterfaceOptionsFrame_OpenToCategory(self.generalPanel)
        InterfaceOptionsFrame_OpenToCategory(self.generalPanel)
    end
end
