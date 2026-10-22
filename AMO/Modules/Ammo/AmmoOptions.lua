local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L
local Ammo = AMO.ammo

-- Munition: Optionen (Ammo.Options liefert die Einträge für die Optionsseite)

local STACK = Ammo.STACK

local function Control(low, high)
    return AMO:SliderType(low, high)
end

local function Slider(order, key, name, desc, min, max, step)
    return {
        dialogControl = Control(nil, L["Rounds"]),
        type = "range", order = order, name = name, desc = desc, min = min, max = max, step = step, width = "double",
        get = function() return Ammo:Settings()[key] end,
        set = function(_, value) Ammo:Settings()[key] = value end,
    }
end

local function Toggle(order, key, name, desc)
    return {
        type = "toggle", order = order, name = name, desc = desc, width = "full",
        get = function() return Ammo:Settings()[key] end,
        set = function(_, value) Ammo:Settings()[key] = value and true or false end,
    }
end

-- AceConfig erlaubt für min und max nur Zahlen. Die Obergrenzen hängen vom Köcher ab und werden deshalb bei Änderungen
-- am Inventar nachgeführt (Ammo:RefreshOptions).
local soonOption, restockOption

function Ammo:RefreshOptions()
    if not soonOption then return end
    local _, slots = self:Slots(self:Ammo())
    slots = math.max(slots, 1)
    if soonOption.max == slots then return end
    soonOption.max = slots
    restockOption.max = slots * STACK
    LibStub("AceConfigRegistry-3.0"):NotifyChange(AMO.name)
end

local function Options()
    soonOption = {
            type = "range", order = 1, name = L["Quiver almost empty (filled slots)"], dialogControl = Control(L["Off"], L["Max"]), width = "double", min = 0, step = 1,
            max = 10,
            desc = L["Warns when only this many quiver slots are still filled and says when the quiver will be empty if you keep shooting like this. It comes again with every slot that empties. 0 turns the warning off; the maximum is the number of quiver slots."],
            get = function() return Ammo:Settings().soon end,
            set = function(_, value) Ammo:Settings().soon = value end,
    }
    restockOption = {
            type = "range", order = 7, name = L["Ask to refill below (rounds)"], dialogControl = Control(L["Off"], L["Max"]), width = "double", min = 0, step = 10,
            max = 10 * STACK,
            desc = L["The number of rounds (arrows or bullets), not slots. When you open a vendor who sells ammo and have fewer rounds than this, you are asked whether to fill the quiver with the best ammo you can use. 0 turns the question off; the maximum is every quiver slot full."],
            get = function() return Ammo:Settings().restock end,
            set = function(_, value) Ammo:Settings().restock = value end,
    }
    Ammo:RefreshOptions()
    return {
        soon = soonOption,
        restock = restockOption,
        autoEquip = Toggle(0.5, "autoEquip", L["Equip the best ammo automatically"],
            L["Puts the strongest ammo you can use into the ammo slot. When a stack runs out, the next weaker one follows. Nothing is swapped in combat."]),
        tooltip = Toggle(0.6, "tooltip", L["Ammo tooltip"],
            L["Shows the supply per ammo type, the use per minute (average and last combat) and the time until empty on the tooltip of ammo and quivers."]),
        low = Toggle(3, "low", L["Ammo running low"], L["An urgent warning when only a few rounds are left."]),
        lowAt = Slider(4, "lowAt", L["Warn at or below"], L["The urgent warning comes at this many rounds or less."], 10, 300, 5),
        dungeon = Toggle(5, "dungeon", L["Before a dungeon"], L["A big warning when you enter a dungeon or raid with too little ammo."]),
        dungeonAt = Slider(6, "dungeonAt", L["Minimum ammo"], L["Below this many rounds the dungeon warning comes."], 50, 1000, 10),
    }
end

Ammo.Options = Options
