local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Debug-Meldungen gehen nur an die BugLab-Console (Quelle "AMO"). Ohne BugLab gibt es keine Debug-Ausgabe, auch keinen
-- Ersatz im Chat. Werte immer über das Format-Argument übergeben, BugLab färbt sie.
--   local debug = AMO:NewDebugger()
--   debug:Log("lege %d an", id)   Stufe Debug, nur wenn der Debug-Modus an ist
--   debug:Warn(...), debug:Error(...)   Warn nur im Debug-Modus, Error immer

--- BugLab, wenn installiert
function AMO:GetBugLab()
    local bugLab = _G.BugLab
    return bugLab and bugLab.GetLogger and bugLab or nil
end

function AMO:IsDebug()
    return self.db ~= nil and self.db.profile.debug == true
end

function AMO:NewDebugger()
    local function Send(method, onlyDebug)
        return function(_, text, ...)
            if onlyDebug and not AMO:IsDebug() then return end
            local bugLab = AMO:GetBugLab()
            if bugLab then
                local log = bugLab:GetLogger(AMO.name)
                log[method](log, text, ...)
            end
        end
    end
    return { Log = Send("Debug", true), Warn = Send("Warn", true), Error = Send("Error", false) }
end

--- Beim Anmelden einmal an BugLab melden: Version aus der TOC und ob der Debug-Modus an ist
function AMO:Announce()
    local bugLab = self:GetBugLab()
    if not bugLab then return end
    local log = bugLab:GetLogger(self.name)
    if log and log.Announce then log:Announce({ debug = self:IsDebug() }) end
end
