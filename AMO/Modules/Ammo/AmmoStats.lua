local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local Ammo = AMO.ammo

-- Munition: Verbrauch in Schuss pro Minute. Gemessen wird nur im Kampf, vom Kampfbeginn (oder der letzten Prüfung) bis zum
-- letzten verbrauchten Schuss. Der Tooltip zeigt die laufende Sitzung: Durchschnitt über ihre Kämpfe und Rate des letzten
-- Kampfs. Es wird nichts gespeichert, die Sitzung beginnt bei jedem Laden neu.

local MIN_USED = 3 -- Kämpfe mit weniger Schuss oder kürzer als MIN_SPAN Sekunden zählen nicht
local MIN_SPAN = 5

--- Summen der laufenden Sitzung: { used, seconds, lastRate }
function Ammo:Stats()
    self.session = self.session or {}
    return self.session
end

--- Schuss pro Minute der Sitzung: Durchschnitt über alle Kämpfe und letzter Kampf (nil, solange nichts gemessen wurde)
function Ammo:Rates()
    local stats = self:Stats()
    local average = (stats.seconds or 0) > 0 and (stats.used or 0) / stats.seconds * 60 or nil
    return average, stats.lastRate
end

--- Verbrauch im Kampf festhalten (von Check gerufen, bevor der alte Stand ersetzt wird)
function Ammo:Track(count, now)
    local before = self.count
    if not (before and self.api.InCombat()) or count >= before then return end
    local run = self.run
    if not run then
        run = { start = math.max(self.time or now, self.combatStart or now), used = 0 }
        self.run = run
    end
    run.used = run.used + (before - count)
    run.last = now
end

--- Kampfende: den Kampf in die Summen übernehmen
function Ammo:EndCombat()
    local run = self.run
    self.run, self.combatStart = nil, nil
    if not run then return end
    local span = (run.last or 0) - run.start
    if run.used < MIN_USED or span < MIN_SPAN then return end
    local stats = self:Stats()
    stats.used, stats.seconds = (stats.used or 0) + run.used, (stats.seconds or 0) + span
    stats.lastRate = run.used / span * 60
end

function Ammo:EnableStats()
    AMO:Listen("PLAYER_REGEN_DISABLED", function() Ammo.combatStart = Ammo.api.GetTime() end)
    AMO:Listen("PLAYER_REGEN_ENABLED", function() Ammo:EndCombat() end)
end
