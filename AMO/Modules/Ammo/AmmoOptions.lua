local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L
local Ammo = AMO.ammo

-- Munition: Optionen. Ammo.OptionSections liefert die Abschnitte für die Optionsseite (Core/AMOOptions.lua).

local STACK = Ammo.STACK
local INDENT = 30

local function Toggle(key, name, desc, extra)
    local item = {
        type = "toggle", key = key, name = name, desc = desc,
        get = function() return Ammo:Settings()[key] end,
        set = function(value) Ammo:Settings()[key] = value and true or false end,
    }
    for field, value in pairs(extra or {}) do item[field] = value end
    return item
end

local function Slider(key, name, desc, min, max, step, extra)
    local item = {
        type = "slider", key = key, name = name, desc = desc, min = min, max = max, step = step,
        get = function() return Ammo:Settings()[key] end,
        set = function(value) Ammo:Settings()[key] = value end,
    }
    for field, value in pairs(extra or {}) do item[field] = value end
    return item
end

--- Anzahl der Köcherplätze, mindestens 1. Die Obergrenzen der Regler hängen vom Köcher ab und werden bei Änderungen am
-- Inventar nachgeführt (Ammo:RefreshOptions).
local function QuiverSlots()
    local _, slots = Ammo:Slots(Ammo:Ammo())
    return math.max(slots or 0, 1)
end

function Ammo:RefreshOptions()
    if AMO.RefreshOptionsPanel then AMO:RefreshOptionsPanel() end
end

function Ammo.OptionSections()
    local function LowOn() return Ammo:Settings().low end
    local function DungeonOn() return Ammo:Settings().dungeon end
    return {
        { title = L["Warnings"], items = {
            Slider("soon", L["Quiver almost empty (filled slots)"],
                L["Warns when only this many quiver slots are still filled and says when the quiver will be empty if you keep shooting like this. It comes again with every slot that empties. 0 turns the warning off; the maximum is the number of quiver slots."],
                0, QuiverSlots, 1, { low = L["Off"], high = L["Max"] }),
            Toggle("low", L["Ammo running low"], L["An urgent warning when only a few rounds are left."]),
            Slider("lowAt", L["Warn at or below"], L["The urgent warning comes at this many rounds or less."],
                10, 300, 5, { indent = INDENT, enabledIf = LowOn }),
            Toggle("dungeon", L["Before a dungeon"], L["A big warning when you enter a dungeon or raid with too little ammo."]),
            Slider("dungeonAt", L["Minimum ammo"], L["Below this many rounds the dungeon warning comes."],
                50, 1000, 10, { indent = INDENT, enabledIf = DungeonOn }),
        } },
        { title = L["Ammo"], items = {
            Toggle("autoEquip", L["Equip the best ammo automatically"],
                L["Puts the strongest ammo you can use into the ammo slot. When a stack runs out, the next weaker one follows. Nothing is swapped in combat."]),
            Slider("restock", L["Ask to refill below (rounds)"],
                L["The number of rounds (arrows or bullets), not slots. When you open a vendor who sells ammo and have fewer rounds than this, you are asked whether to fill the quiver with the best ammo you can use. 0 turns the question off; the maximum is every quiver slot full."],
                0, function() return QuiverSlots() * STACK end, 10, { low = L["Off"], high = L["Max"] }),
        } },
        { title = L["Tooltip"], items = {
            Toggle("tooltip", L["Ammo tooltip"],
                L["Shows the supply per ammo type, the use per minute (average and last combat) and the time until empty on the tooltip of ammo and quivers."]),
        } },
    }
end
