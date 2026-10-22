local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L

-- Eintrag im Addon-Kompartment (Knopf oben rechts an der Minikarte): Klick öffnet die Optionen, beim Darüberfahren zeigt
-- ein Tooltip das Logo. Gibt es das Kompartment im Client nicht, passiert nichts.

-- Je nach Client-Version kommt der Knopf als erstes oder als zweites Argument (das andere ist der Eintrag als Tabelle)
local function Owner(first, second)
    for _, candidate in ipairs({ first, second }) do
        if type(candidate) == "table" and candidate.GetObjectType then return candidate end
    end
    return UIParent
end

-- Das Logo hängt wie bei ATT groß links neben dem Tooltip, vertikal in der Mitte. Der Tooltip ist der gemeinsame
-- GameTooltip, deshalb wird das Logo mit ihm wieder ausgeblendet.
local LOGO_SIZE = 80
local logo

local function Logo()
    if logo then return logo end
    logo = GameTooltip:CreateTexture(nil, "OVERLAY")
    logo:SetSize(LOGO_SIZE, LOGO_SIZE)
    logo:SetTexture(AMO.logo)
    logo:SetPoint("RIGHT", GameTooltip, "LEFT", -4, 0)
    logo:Hide()
    local function Hide() logo:Hide() end
    GameTooltip:HookScript("OnHide", Hide)
    if GameTooltip:HasScript("OnTooltipCleared") then GameTooltip:HookScript("OnTooltipCleared", Hide) end
    return logo
end

local function OnEnter(first, second)
    if not (GameTooltip and GameTooltip.SetOwner) then return end
    GameTooltip:SetOwner(Owner(first, second), "ANCHOR_LEFT")
    GameTooltip:AddLine(AMO.title, 1, 1, 1)
    GameTooltip:AddLine(L["Click to open the options."], 0.8, 0.8, 0.8)
    GameTooltip:Show()
    Logo():Show()
end

local function OnLeave()
    if not GameTooltip then return end
    if logo then logo:Hide() end
    if GameTooltip.Hide then GameTooltip:Hide() end
end

function AMO:SetupCompartment()
    if not (AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon) then return end
    AddonCompartmentFrame:RegisterAddon({
        text = self.title,
        icon = self.icon,
        notCheckable = true,
        registerForAnyClick = true,
        func = function() self:OpenOptions() end,
        funcOnEnter = OnEnter,
        funcOnLeave = OnLeave,
    })
end
