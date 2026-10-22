local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L
local Ammo = AMO.ammo

-- Munition: Tooltip auf Munition, Köcher und Munitionsbeutel. Zeigt den Vorrat je Munitionsart (Schuss/Platz im Köcher),
-- den Verbrauch pro Minute (Durchschnitt und letzter Kampf) und die Zeit bis leer.

local PROJECTILE = 6 -- Gegenstandsklasse Geschosse
local QUIVER_CLASS = 11 -- Gegenstandsklasse Köcher; Unterklasse 2 Köcher, 3 Munitionsbeutel
local QUIVER, AMMO_POUCH = 2, 3

--- Vorrat je Munitionssorte: Liste { id, kind, count } (Pfeile zuerst, dann nach Gegenstand) und Platz im Köcher je Art
function Ammo:Inventory()
    local api = self.api
    local items, capacity, order = {}, {}, {}
    if not (api.GetNumSlots and api.ItemAt and api.GetItemInfoInstant) then return order, capacity end
    for _, kind in ipairs({ self.ARROW, self.BULLET }) do
        local slotsTotal = 0
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            local slots = api.GetNumSlots(bag) or 0
            if self:IsQuiver(bag, kind) then slotsTotal = slotsTotal + slots end
            for slot = 1, slots do
                local id, stack = api.ItemAt(bag, slot)
                if id then
                    local _, _, _, _, icon, class, subclass = api.GetItemInfoInstant(id)
                    if class == PROJECTILE and subclass == kind then
                        local entry = items[id]
                        if not entry then
                            entry = { id = id, kind = kind, count = 0, icon = icon }
                            items[id] = entry
                            order[#order + 1] = entry
                        end
                        entry.count = entry.count + (stack or 1)
                    end
                end
            end
        end
        if slotsTotal > 0 then capacity[kind] = slotsTotal * self.STACK end
    end
    return order, capacity
end

local function ItemName(entry, ammo)
    local name = ammo.api.GetItemName and ammo.api.GetItemName(entry.id)
    name = name or (entry.kind == ammo.ARROW and L["Arrows"] or L["Bullets"])
    -- Symbol des Gegenstands vor dem Namen
    if entry.icon then return format("|T%s:14:14:0:0|t %s", entry.icon, name) end
    return name
end

local function Duration(minutes)
    if minutes >= 60 then return format("%d h %d min", math.floor(minutes / 60), math.floor(minutes % 60)) end
    return format("%d min", math.max(1, math.floor(minutes + 0.5)))
end

--- Status eines Vorrats nach den Reglern: leer = Kritisch, höchstens "lowAt" Schuss = Dringend, höchstens "soon" gefüllte
-- Köcherplätze = Warnung, sonst in Ordnung. Ohne filled gilt nur die Schusszahl.
function Ammo:StatusKey(count, filled)
    local settings = self:Settings()
    if count <= 0 then return "critical" end
    if settings.low and count <= settings.lowAt then return "urgent" end
    if filled and settings.soon > 0 and filled <= settings.soon then return "warning" end
    return "ok"
end

--- Zeilen { Links, Rechts, r, g, b } für den Tooltip. Mit onlyId nur diese Sorte (Tooltip der Munition), sonst alle Sorten
-- mit Gesamtzeile (Tooltip des Köchers). Verbrauch und Zeit bis leer gelten immer insgesamt.
function Ammo:TooltipRows(onlyId)
    local rows = {}
    local items, capacity = self:Inventory()
    local shown = {}
    for _, entry in ipairs(items) do
        if not onlyId or entry.id == onlyId then shown[#shown + 1] = entry end
    end
    if #shown == 0 then return rows end
    local current = self:AmmoKind()
    local ir, ig, ib = AMO:RGB("primary") -- Beschriftungen in Elfenbein
    local total, currentCount, cap = 0, 0, 0
    for _, entry in ipairs(items) do
        if entry.kind == current or not current then currentCount = currentCount + entry.count end
    end
    for _, entry in ipairs(shown) do
        rows[#rows + 1] = { ItemName(entry, self), tostring(entry.count), ir, ig, ib,
            colored = AMO:Colorize(tostring(entry.count), self:StatusKey(entry.count)) }
        total = total + entry.count
    end
    if not onlyId then
        for _, value in pairs(capacity) do cap = cap + value end
        if #shown > 1 or cap > 0 then
            local text = cap > 0 and format("%d / %d", total, cap) or tostring(total)
            -- Der aktuelle Wert zeigt den Status, der Höchstwert ist Elfenbein
            local colored = AMO:Colorize(tostring(total), self:StatusKey(currentCount, (self:Slots(currentCount))))
            if cap > 0 then colored = colored .. AMO:Colorize(" / " .. cap, "primary") end
            rows[#rows + 1] = { L["Total"], text, ir, ig, ib, colored = colored }
        end
    end
    -- Verbrauch und Restzeit sind Information: Werte in der Informationsfarbe
    local function Info(label, text) return { label, text, ir, ig, ib, colored = AMO:Colorize(text, "info") } end
    local average, last = self:Rates()
    if average then rows[#rows + 1] = Info(L["Average"], format(L["%.1f rounds/min"], average)) end
    if last then rows[#rows + 1] = Info(L["Last combat"], format(L["%.1f rounds/min"], last)) end
    if average and average > 0 and currentCount > 0 then
        rows[#rows + 1] = Info(L["Empty in (average)"], Duration(currentCount / average))
    end
    return rows
end

--- Gehört der Gegenstand dazu (Munition, Köcher, Munitionsbeutel)? Zweiter Wert: Munitionsart, wenn es Munition ist
function Ammo:IsAmmoItem(id)
    if not (id and self.api.GetItemInfoInstant) then return false end
    local _, _, _, _, _, class, subclass = self.api.GetItemInfoInstant(id)
    if class == PROJECTILE then return true, subclass end
    return class == QUIVER_CLASS and (subclass == QUIVER or subclass == AMMO_POUCH), nil
end

local function OnItem(_, data)
    local settings = Ammo:Settings()
    if not (settings and settings.tooltip and Ammo:IsOn()) then return nil end
    if not (data and type(data.id) == "number") then return nil end
    local isAmmo, kind = Ammo:IsAmmoItem(data.id)
    if not isAmmo then return nil end
    local rows = Ammo:TooltipRows(kind and data.id or nil)
    return #rows > 0 and rows or nil
end
Ammo.OnItem = OnItem

function Ammo:EnableTooltip()
    AMO:RegisterItemLines("ammo", OnItem)
end
