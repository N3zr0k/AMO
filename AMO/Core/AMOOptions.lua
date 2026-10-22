local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L

-- Optionsseite im Einstellungsfenster: Schalter "Aktiv", die Optionen der Munition (Modules/Ammo/AmmoOptions.lua) und der
-- Debug-Modus. Für andere Klassen als Jäger steht nur ein Hinweis da.

local function Gray(text) return "|cff9d9d9d" .. text .. "|r" end

function AMO:BuildOptions()
    local args = {
        description = {
            type = "description", order = 0, fontSize = "medium", width = "full",
            name = Gray(L["Warns when your ammo runs low and offers to refill the quiver at a vendor."]),
        },
    }
    if self:IsHunter() then
        local function Off() return not self.db.profile.enabled end
        for key, option in pairs(self.ammo.Options()) do
            if option.disabled == nil then option.disabled = Off end
            args[key] = option
        end
        args.enabled = {
            type = "toggle", order = 0.4, width = "full", name = L["Active"],
            desc = L["Turns the addon off completely: no warnings, no questions, nothing is checked."],
            get = function() return self.db.profile.enabled end,
            set = function(_, value) self.db.profile.enabled = value and true or false end,
        }
    else
        args.note = {
            type = "description", order = 1, fontSize = "medium", width = "full",
            name = L["AMO is for hunters. The options appear on a hunter character."],
        }
    end
    args.debug = {
        type = "toggle", order = 100, width = "full", name = L["Debug mode"],
        desc = L["Sends diagnostic messages to the BugLab console. Without BugLab nothing is shown."],
        get = function() return self.db.profile.debug end,
        set = function(_, value) self.db.profile.debug = value and true or false end,
    }
    return args
end

function AMO:SetupOptions()
    local title = "AMO - Ammunition Management Organizer"
    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, { type = "group", name = title, args = self:BuildOptions() })
    local _, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, title)
    self.categoryID = categoryID
end

function AMO:OpenOptions()
    if Settings and Settings.OpenToCategory and self.categoryID then
        Settings.OpenToCategory(self.categoryID)
    else
        LibStub("AceConfigDialog-3.0"):Open(self.name)
    end
end
