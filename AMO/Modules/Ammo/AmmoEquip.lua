local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local Ammo = AMO.ammo
local debug = AMO:NewDebugger()

-- Jäger: Die beste Munition im Munitionsplatz. Ist der Platz leer oder liegt stärkere Munition in den Taschen, wird sie
-- angelegt; ist ein Stapel leer, kommt automatisch die nächst schwächere dran. Stärke ist die Gegenstandsstufe, genutzt wird
-- nur, was die Stufe des Jägers erlaubt. Ein leerer Platz wird sofort gefüllt, auch im Kampf und beim Kampfbeginn und
-- beim Wirken von Mal des Jägers; stärkere Munition gegen angelegte zu tauschen wartet bis nach dem Kampf.

local AMMO_SLOT = 0
local PROJECTILE = 6
local RETRY = 2 -- Sekunden Pause zwischen zwei Versuchen
local HUNTERS_MARK = { [1130] = true, [14323] = true, [14324] = true, [14325] = true } -- alle Ränge

Ammo.api.GetItemInfo = Ammo.api.GetItemInfo or (C_Item and C_Item.GetItemInfo or GetItemInfo)
Ammo.api.UnitLevel = Ammo.api.UnitLevel or UnitLevel
Ammo.api.UseContainerItem = C_Container and C_Container.UseContainerItem or UseContainerItem
Ammo.api.PickupContainerItem = C_Container and C_Container.PickupContainerItem or PickupContainerItem
Ammo.api.PickupInventoryItem = PickupInventoryItem
Ammo.api.CursorHasItem = CursorHasItem
Ammo.api.ClearCursor = ClearCursor

--- Gegenstandsstufe und Mindeststufe der Munition, nil solange der Client sie nicht kennt
local function ItemLevels(id)
    local api = Ammo.api
    if not api.GetItemInfo then return nil end
    local _, _, _, itemLevel, minLevel = api.GetItemInfo(id)
    if type(itemLevel) ~= "number" then return nil end
    return itemLevel, minLevel or 0
end

--- Beste nutzbare Munition der Waffenart in den Taschen: { id, bag, slot, itemLevel } oder nil
function Ammo:BestInBags(kind)
    local api = self.api
    if not (kind and api.GetNumSlots and api.ItemAt and api.GetItemInfoInstant) then return nil end
    local level = api.UnitLevel and api.UnitLevel("player") or 1
    local best
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, api.GetNumSlots(bag) or 0 do
            local id = api.ItemAt(bag, slot)
            if id then
                local _, _, _, _, _, class, subclass = api.GetItemInfoInstant(id)
                if class == PROJECTILE and subclass == kind then
                    local itemLevel, minLevel = ItemLevels(id)
                    if itemLevel and minLevel <= level and (not best or itemLevel > best.itemLevel) then
                        best = { id = id, bag = bag, slot = slot, itemLevel = itemLevel }
                    end
                end
            end
        end
    end
    return best
end

--- Anlegen, wenn der Platz leer ist (oder falsche Munition liegt) oder in den Taschen stärkere Munition liegt. Mit
-- emptyOnly nur bei leerem Platz (im Kampf und zum Kampfbeginn). Liefert die angelegte Munition oder nil.
function Ammo:EquipBest(emptyOnly)
    local settings = self:Settings()
    local api = self.api
    if not (self.ready and self:IsOn() and settings and settings.autoEquip) then return nil end
    local now = api.GetTime()
    if self.lastEquip and now - self.lastEquip < RETRY then return nil end

    local kind = self:AmmoKind()
    local best = self:BestInBags(kind)
    if not best then
        self:EquipNote("keine passende Munition in den Taschen (Art %s)", tostring(kind))
        return nil
    end
    local current = api.GetInventoryItemID("player", AMMO_SLOT)
    if current == best.id then return nil end
    -- Ein aufgebrauchter Stapel bleibt mit Anzahl 0 im Platz liegen und zählt als leer
    if current and (api.GetInventoryItemCount("player", AMMO_SLOT) or 0) <= 0 then current = nil end
    if current then
        -- Falsche Munitionsart (Pfeile zum Gewehr) wird ersetzt, sonst nur durch stärkere
        local _, _, _, _, _, class, subclass = api.GetItemInfoInstant(current)
        local fits = class == PROJECTILE and subclass == kind
        if fits then
            local currentLevel = ItemLevels(current)
            if emptyOnly or not currentLevel or currentLevel >= best.itemLevel then return nil end
        end
    end
    if not emptyOnly and api.InCombat() then
        self.equipPending = true
        return nil
    end
    self.lastEquip = now
    self:EquipNote("lege %d an (Tasche %d, Platz %d, Stufe %d), vorher %s", best.id, best.bag, best.slot, best.itemLevel, tostring(current))
    self:Equip(best)
    -- Im Kampf lässt der Client den Munitionsplatz meist nicht zu: nach dem Kampf noch einmal versuchen
    if api.InCombat() then self.equipPending = true end
    return best
end

--- Munition aus der Tasche in den Munitionsplatz legen: aufnehmen und in den Platz fallen lassen (nicht geschützt),
-- sonst Rechtsklick-Aufruf
function Ammo:Equip(best)
    local api = self.api
    if api.PickupContainerItem and api.PickupInventoryItem then
        api.PickupContainerItem(best.bag, best.slot)
        api.PickupInventoryItem(AMMO_SLOT)
        if api.CursorHasItem and api.CursorHasItem() and api.ClearCursor then api.ClearCursor() end
    elseif api.UseContainerItem then
        api.UseContainerItem(best.bag, best.slot)
    end
end

--- Entscheidung als Debug-Zeile (nur bei Änderung, damit der Chat nicht läuft)
function Ammo:EquipNote(text, ...)
    local line = format(text, ...)
    if line == self.lastNote then return end
    self.lastNote = line
    debug:Log(text, ...)
end

function Ammo:EnableEquip()
    -- Kampfbeginn und Mal des Jägers: ein leerer Platz wird noch davor gefüllt
    AMO:Listen("PLAYER_REGEN_DISABLED", function() Ammo:EquipBest(true) end)
    local function OnCast(_, unit, _, _, spellID)
        if unit == "player" and HUNTERS_MARK[spellID] then Ammo:EquipBest(true) end
    end
    AMO:Listen("UNIT_SPELLCAST_SENT", OnCast)
    AMO:Listen("UNIT_SPELLCAST_SUCCEEDED", OnCast)
    AMO:Listen("PLAYER_REGEN_ENABLED", function()
        if Ammo.equipPending then
            Ammo.equipPending = nil
            Ammo.lastEquip = nil
            Ammo:EquipBest()
            if C_Timer and C_Timer.After then C_Timer.After(1, function() Ammo:EquipBest() end) end
        end
    end)
    -- ein leerer Platz wird auch im Kampf gefüllt (der Client sagt dazu nein, wenn es dort nicht geht)
    AMO:Listen("BAG_UPDATE_DELAYED", function() Ammo:EquipBest(Ammo.api.InCombat()) end)
    AMO:Listen("UNIT_INVENTORY_CHANGED", function(_, unit)
        if unit == "player" then Ammo:EquipBest(Ammo.api.InCombat()) end
    end)
    AMO:Listen("GET_ITEM_INFO_RECEIVED", function() Ammo:EquipBest() end)
end

--- Probe "ammo equip": Zustand des Anlegens (Waffenart, angelegte Munition, Kandidaten in den Taschen mit Stufen)
function Ammo:EquipLines()
    local api = self.api
    local lines = {}
    local function Add(text, ...) lines[#lines + 1] = format(text, ...) end
    local settings = self:Settings()
    Add("Funktion aktiv: %s, automatisch anlegen: %s, bereit: %s, Kampf: %s", tostring(self:IsOn()), tostring(settings and settings.autoEquip),
        tostring(self.ready), tostring(api.InCombat()))
    local kind = self:AmmoKind()
    Add("Waffe: %s, Munitionsart: %s", tostring(api.GetInventoryItemID("player", 18)), tostring(kind))
    local current = api.GetInventoryItemID("player", AMMO_SLOT)
    Add("Angelegte Munition: %s (Stufe %s), Anzahl %s", tostring(current), tostring(current and (ItemLevels(current))),
        tostring(api.GetInventoryItemCount("player", AMMO_SLOT)))
    local level = api.UnitLevel and api.UnitLevel("player") or 1
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, (api.GetNumSlots(bag) or 0) do
            local id = api.ItemAt(bag, slot)
            if id then
                local _, _, _, _, _, class, subclass = api.GetItemInfoInstant(id)
                if class == PROJECTILE then
                    local itemLevel, minLevel = ItemLevels(id)
                    Add("Tasche %d Platz %d: Gegenstand %d, Unterklasse %s, Stufe %s, ab Stufe %s (du %d)", bag, slot, id, tostring(subclass),
                        tostring(itemLevel), tostring(minLevel), level)
                end
            end
        end
    end
    local best = self:BestInBags(kind)
    Add("Beste Munition in den Taschen: %s", best and format("%d (Tasche %d Platz %d)", best.id, best.bag, best.slot) or "keine")
    Add("Letzte Entscheidung: %s", tostring(self.lastNote))
    return lines
end

AMO:RegisterProbe("equip", function() return Ammo:EquipLines() end,
    "Zeigt, welche Munition angelegt ist, welche in den Taschen liegt und was das automatische Anlegen entscheidet")
