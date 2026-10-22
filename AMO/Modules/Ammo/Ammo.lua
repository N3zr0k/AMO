local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Munition: Warnungen zur Munition. Drei Stufen: Köcher bald leer (aus der Verbrauchsgeschwindigkeit hochgerechnet), wenige
-- Schuss übrig, zu wenig vor einem Dungeon. Geprüft wird bei Änderungen am Inventar und beim Betreten einer Instanz.
-- Die erste Stufe gilt je Köcherplatz (ein Platz = ein Stapel Munition): Sind höchstens "soonAt" Plätze gefüllt, kommt die
-- Warnung, und noch einmal bei jedem weiteren Platz, der leer wird.

local AMMO_SLOT = 0   -- Munitionsplatz
local RANGED_SLOT = 18
local PROJECTILE = 6               -- Gegenstandsklasse Geschosse
local ARROW, BULLET = 2, 3         -- Unterklassen der Geschosse
local BOW, GUN, CROSSBOW = 2, 3, 18 -- Unterklassen der Fernkampfwaffen
local STACK = 200     -- Stapelgröße, falls die Munition nicht in einem Köcher liegt
local MIN_SAMPLE = 10 -- Mindestdauer und -menge der Messung für eine Hochrechnung
local MIN_USED = 3
local LOAD_DELAY = 20 -- Sekunden nach dem Laden, bis geprüft wird

local Ammo = {}
AMO.ammo = Ammo
Ammo.STACK = STACK
Ammo.ARROW, Ammo.BULLET = ARROW, BULLET
Ammo.ready = true -- false zwischen Betreten der Welt und Ablauf von LOAD_DELAY

Ammo.api = {
    GetInventoryItemCount = GetInventoryItemCount,
    GetInventoryItemID = GetInventoryItemID,
    IsInInstance = IsInInstance,
    GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant,
    GetItemName = C_Item and C_Item.GetItemNameByID or GetItemInfo and function(id) return (GetItemInfo(id)) end,
    InCombat = function() return UnitAffectingCombat("player") end,
    GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots,
    GetNumFreeSlots = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots,
    GetTime = GetTime,
    -- Gegenstand und Anzahl eines Taschenplatzes (neue und alte Client-Schnittstelle)
    ItemAt = function(bag, slot)
        if C_Container and C_Container.GetContainerItemInfo then
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then return info.itemID, info.stackCount end
        elseif GetContainerItemID then
            local id = GetContainerItemID(bag, slot)
            if id then return id, select(2, GetContainerItemInfo(bag, slot)) end
        end
    end,
}

Ammo.defaults = {
    soon = 2,           -- Warnung ab so vielen gefüllten Köcherplätzen, 0 = aus
    low = true,         -- dringende Warnung
    lowAt = 50,
    dungeon = true,     -- Warnung vor dem Betreten eines Dungeons
    dungeonAt = 200,
    restock = 0,        -- beim Händler auffüllen, wenn weniger Schuss da sind, 0 = aus
    autoEquip = true,   -- beste Munition automatisch anlegen
    tooltip = true,     -- Vorrat und Verbrauch im Tooltip von Munition und Köcher
}

--- Alle Schuss der passenden Munitionsart in allen Taschen und Köchern, nil wenn der Jäger keine Fernkampfwaffe trägt
-- (dann ist leer nichts Besonderes). Mit quiverOnly zählen nur die Köcher (fürs Nachkaufen). Ohne bekannte Munitionsart
-- zählt der angelegte Stapel.
function Ammo:Ammo(quiverOnly)
    local api = self.api
    if not api.GetInventoryItemID("player", RANGED_SLOT) then return nil end

    local kind = self:AmmoKind()
    if kind and api.GetNumSlots and api.ItemAt then
        local total = 0
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            if not quiverOnly or self:IsQuiver(bag, kind) then
                for slot = 1, api.GetNumSlots(bag) or 0 do
                    local id, count = api.ItemAt(bag, slot)
                    if id then
                        local _, _, _, _, _, class, subclass = api.GetItemInfoInstant(id)
                        if class == PROJECTILE and subclass == kind then total = total + (count or 1) end
                    end
                end
            end
        end
        return total
    end

    -- Ein leerer Munitionsplatz liefert in manchen Clients 1 statt 0, deshalb zuerst nach dem Gegenstand fragen
    if not api.GetInventoryItemID("player", AMMO_SLOT) then return 0 end
    return api.GetInventoryItemCount("player", AMMO_SLOT) or 0
end

--- Ist die Tasche ein Köcher oder Munitionsbeutel für diese Munitionsart?
-- Beutelart: Bit 1 Köcher für Pfeile, Bit 2 Munitionsbeutel für Kugeln
function Ammo:IsQuiver(bag, kind)
    local api = self.api
    if not (api.GetNumSlots and api.GetNumFreeSlots) or (api.GetNumSlots(bag) or 0) == 0 then return false end
    local _, family = api.GetNumFreeSlots(bag)
    if not family or family % 4 == 0 then return false end
    local wanted = kind == ARROW and 1 or kind == BULLET and 2 or 3
    return wanted == 3 or family % (wanted * 2) >= wanted
end

--- Munitionsart der getragenen Fernkampfwaffe (ARROW, BULLET) oder nil
function Ammo:AmmoKind()
    local id = self.api.GetInventoryItemID("player", RANGED_SLOT)
    if not (id and self.api.GetItemInfoInstant) then return nil end
    local _, _, _, _, _, class, subclass = self.api.GetItemInfoInstant(id)
    if class ~= 2 then return nil end
    if subclass == BOW or subclass == CROSSBOW then return ARROW end
    if subclass == GUN then return BULLET end
end

--- Gefüllte und vorhandene Plätze. Gefüllt ist jeder Platz in irgendeiner Tasche mit Munition der Art der Waffe, vorhanden
-- sind die Plätze der passenden Köcher. Ohne Köcher werden die Stapel aus der Menge geschätzt.
function Ammo:Slots(count)
    local kind = self:AmmoKind()
    local api = self.api
    local filled, total, stacks = 0, 0, 0
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        local slots = api.GetNumSlots and api.GetNumSlots(bag) or 0
        if self:IsQuiver(bag, kind) then
            total = total + slots
            filled = filled + slots - (api.GetNumFreeSlots(bag) or 0)
        end
        if kind and api.ItemAt then
            for slot = 1, slots do
                local id = api.ItemAt(bag, slot)
                if id then
                    local _, _, _, _, _, class, subclass = api.GetItemInfoInstant(id)
                    if class == PROJECTILE and subclass == kind then stacks = stacks + 1 end
                end
            end
        end
    end
    if kind and api.ItemAt then filled = stacks end
    if total == 0 then return math.ceil((count or 0) / STACK), 10 end
    return filled, total
end

--- Verbrauch: Schuss pro Sekunde seit dem ersten verbrauchten Schuss des Kampfes (jeder Kampf misst neu), oder nil wenn zu wenig gemessen wurde
function Ammo:Rate(count, now)
    local track = self.track
    if track and count > (self.count or 0) then track = nil end -- nachgefüllt: neu messen
    -- Gemessen wird nur im Kampf; Käufe, Verkäufe und Tauschen außerhalb zählen nicht als Verbrauch
    if count < (self.count or count) and self.api.InCombat() then
        track = track or { start = self.time or now, from = self.count }
    end
    self.track = track
    if not track then return nil end

    local used, elapsed = track.from - count, now - track.start
    if used < MIN_USED or elapsed < MIN_SAMPLE then return nil end
    return used / elapsed
end

--- Prüft den Köcher nach einer Änderung; meldet beim Unterschreiten einer Schwelle
function Ammo:Check()
    if not (self.ready and self:IsOn()) then return end
    local settings = Ammo:Settings()
    local count = self:Ammo()
    if not (settings and count) then
        self.count, self.track, self.warnedSlots, self.lowDone = nil, nil, nil, nil
        return
    end

    local now = self.api.GetTime()
    if self.Track then self:Track(count, now) end
    local rate = self:Rate(count, now)
    local filled = self:Slots(count)

    if settings.soon > 0 and filled <= settings.soon then
        if count == 0 then
            if (self.count or 1) > 0 then AMO:Notify("big", AMO:Say("ammoEmpty", 0), "ammoEmpty") end
        elseif not self.warnedSlots or filled < self.warnedSlots then
            if rate and rate > 0 then
                local minutes = math.max(1, math.ceil(count / rate / 60))
                AMO:Notify("warn", AMO:Say("ammoSoon", minutes), "ammoSoon" .. filled)
            else
                AMO:Notify("warn", AMO:Say("ammoSoonNoRate", count), "ammoSoon" .. filled)
            end
        end
        self.warnedSlots = math.min(self.warnedSlots or filled, filled)
    elseif filled > settings.soon then
        self.warnedSlots = nil
    end

    -- dringend: nur beim Unterschreiten, Nachkaufen setzt zurück
    if settings.low and count > 0 and count <= settings.lowAt then
        if not self.lowDone then AMO:Notify("urgent", AMO:Say("ammoLow", count), "ammoLow") end
        self.lowDone = true
    elseif count > settings.lowAt then
        self.lowDone = nil
    end

    self.count, self.time = count, now
end

--- Beim Betreten einer Instanz: zu wenig Munition für den Dungeon
function Ammo:CheckDungeon()
    if not (self.ready and self:IsOn()) then return end
    local settings = Ammo:Settings()
    local count = self:Ammo()
    if not (settings and settings.dungeon and count) then return end

    local inInstance, kind = self.api.IsInInstance()
    if inInstance and (kind == "party" or kind == "raid") and count < settings.dungeonAt then
        AMO:Notify("big", AMO:Say("ammoDungeon", count), "ammoDungeon")
    end
end

function Ammo:Settings()
    return AMO.db.profile.ammo
end

--- Läuft die Funktion? Ausgeschaltet wird nichts geprüft und nichts gemeldet.
function Ammo:IsOn()
    return AMO.db.profile.enabled
end

-- Taschen und Gegenstandsdaten sind nach dem Laden erst nach einer Weile da; vorher gibt es keine Meldung
function Ammo:StartDelay()
    self.ready = false
    self:RefreshOptions()
    self.delayId = (self.delayId or 0) + 1
    local id = self.delayId
    C_Timer.After(LOAD_DELAY, function()
        if Ammo.delayId ~= id then return end
        Ammo.ready = true
        Ammo.count, Ammo.track = nil, nil
        Ammo:EquipBest()
        Ammo:Check()
        Ammo:CheckDungeon()
    end)
end

function Ammo:Enable()
    Ammo:StartDelay() -- schon beim Anmelden, denn die Taschen-Ereignisse kommen vor dem Betreten der Welt
    AMO:Listen("PLAYER_ENTERING_WORLD", function() Ammo:StartDelay() end)
    if Ammo.EnableRestock then Ammo:EnableRestock() end
    if Ammo.EnableEquip then Ammo:EnableEquip() end
    if Ammo.EnableStats then Ammo:EnableStats() end
    if Ammo.EnableTooltip then Ammo:EnableTooltip() end
    AMO:Listen("PLAYER_REGEN_DISABLED", function() Ammo.track = nil end)
    AMO:Listen("UNIT_INVENTORY_CHANGED", function(_, unit)
        if unit == "player" then Ammo:Check() end
    end)
    AMO:Listen("BAG_UPDATE_DELAYED", function()
        Ammo:RefreshOptions()
        Ammo:Check()
    end)
end

