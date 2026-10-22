-- luacheck: ignore 111 113 122 143 432
-- Minimale Nachbildung der WoW-Umgebung, damit sich die reine Logik der Addons offline testen lässt.
-- Aufruf aus dem Ordner mit den Addon-Ordnern:  lua tests/run.lua
local stub = {}

local ROOT = ((arg and arg[0] or ""):match("^(.*)/[^/]*$") or ".") .. "/.."
stub.root = ROOT

function stub.reset()
    -- Lua-5.1-Ausdrücke, die der Client mitbringt
    _G.tinsert = table.insert
    _G.tremove = table.remove
    _G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    _G.format = string.format
    _G.strmatch = string.match
    _G.strlower = string.lower
    _G.gsub = string.gsub
    _G.strsplit = function(sep, text)
        local parts, pos = {}, 1
        while true do
            local from, to = text:find(sep, pos, true)
            if not from then parts[#parts + 1] = text:sub(pos) break end
            parts[#parts + 1] = text:sub(pos, from - 1)
            pos = to + 1
        end
        return (table.unpack or unpack)(parts)
    end
    _G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

    -- Spielzeit und Zeitgeber, vom Test gesteuert
    stub.now = 0
    stub.timers = {}
    _G.GetTime = function() return stub.now end
    _G.C_Timer = { After = function(_, func) stub.timers[#stub.timers + 1] = func end }
    function stub.flush()
        local list = stub.timers
        stub.timers = {}
        for _, func in ipairs(list) do func() end
    end

    stub.keys = { shift = false, ctrl = false, alt = false }
    _G.IsShiftKeyDown = function() return stub.keys.shift end
    _G.IsControlKeyDown = function() return stub.keys.ctrl end
    _G.IsAltKeyDown = function() return stub.keys.alt end

    _G.Enum = {
        LootSlotType = { Item = 1 },
        ItemClass = { Tradegoods = 7, Gem = 3, Weapon = 2 },
        ItemTradeGoodsSubclass = { Herb = 9, MetalStone = 7 },
    }

    stub.units = {}
    _G.UnitGUID = function(unit) return stub.units[unit] and stub.units[unit].guid end
    _G.UnitName = function(unit) return stub.units[unit] and stub.units[unit].name end
    _G.UnitLevel = function(unit) return stub.units[unit] and stub.units[unit].level end

    -- Frame, das nur Skripte und Events merkt
    stub.frames = {}
    _G.CreateFrame = function()
        local frame = { events = {} }
        function frame:SetScript(_, func) self.onEvent = func end
        function frame:RegisterUnitEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        stub.frames[#stub.frames + 1] = frame
        return frame
    end
end

-- Ace-Bibliotheken so weit nachgebaut, wie AMO sie nutzt
function stub.newAMO()
    local addon = { handlers = {}, registered = {} }
    function addon:RegisterEvent(event, handler) self.handlers[event] = handler end
    function addon:UnregisterEvent(event) self.handlers[event] = nil end

    local function Copy(value)
        if type(value) ~= "table" then return value end
        local copy = {}
        for key, item in pairs(value) do copy[key] = Copy(item) end
        return copy
    end

    local libs = {
        ["AceAddon-3.0"] = {
            NewAddon = function(_, name) addon.name = name return addon end,
            GetAddon = function() return addon end,
        },
        ["AceLocale-3.0"] = {
            GetLocale = function() return setmetatable({}, { __index = function(_, key) return key end }) end,
        },
        ["AceDB-3.0"] = {
            New = function(_, _, defaults) return { profile = Copy(defaults.profile) } end,
        },
    }
    _G.LibStub = function(name) return libs[name] end
    return addon
end

-- Lädt eine Addon-Datei aus dem Ordner AMO/, ADDON_NAME wird wie vom Client als erstes Argument übergeben
function stub.load(path, addonName)
    local chunk, err = loadfile(ROOT .. "/AMO/" .. path)
    assert(chunk, err)
    return chunk(addonName or "AMO")
end

return stub
