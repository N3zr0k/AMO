local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Debug-Meldungen gehen nur an die BugLab-Console (Quelle "AMO"). Es gibt keinen Schalter: Ist BugLab erkannt, ist Debug an,
-- ohne BugLab gibt es keine Debug-Ausgabe, auch keinen Ersatz im Chat. Werte immer über das Format-Argument übergeben,
-- BugLab färbt sie.
--   local debug = AMO:NewDebugger()
--   debug:Log("lege %d an", id)   Stufe Debug
--   debug:Warn(...), debug:Error(...)

--- BugLab, wenn installiert
function AMO:GetBugLab()
    local bugLab = _G.BugLab
    return bugLab and bugLab.GetLogger and bugLab or nil
end

--- Debug ist an, sobald BugLab erkannt wurde
function AMO:IsDebug()
    return self:GetBugLab() ~= nil
end

function AMO:NewDebugger()
    local function Send(method)
        return function(_, text, ...)
            local bugLab = AMO:GetBugLab()
            if bugLab then
                local log = bugLab:GetLogger(AMO.name)
                log[method](log, text, ...)
            end
        end
    end
    return { Log = Send("Debug"), Warn = Send("Warn"), Error = Send("Error") }
end

--- Beim Anmelden einmal an BugLab melden: Version aus der TOC; Debug ist dann an
function AMO:Announce()
    local bugLab = self:GetBugLab()
    if not bugLab then return end
    local log = bugLab:GetLogger(self.name)
    if log and log.Announce then log:Announce({ debug = self:IsDebug() }) end
end
