local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L

-- /amo                  Einstellungen öffnen
-- /amo <Probe>          Prüfung ausgeben, z. B. /amo equip
-- Prüfungen (Probes) melden sich mit AMO:RegisterProbe (AMO.lua) an.

local function RunProbe(self, name, args)
    local probe = self.probes[name]
    local ok, result = pcall(probe.func, args)
    if not ok then result = { AMO:Colorize(tostring(result), "critical") } end
    if type(result) ~= "table" then result = { tostring(result or "") } end
    for _, line in ipairs(result) do self:Print(line) end
end

local function Handle(input)
    local command, rest = strmatch(strtrim(input or ""), "^(%S*)%s*(.-)$")
    command = strlower(command)
    if command == "" then
        AMO:OpenOptions()
    elseif AMO.probes[command] then
        RunProbe(AMO, command, rest)
    else
        AMO:Print(L["Commands: /amo"])
        for name, probe in pairs(AMO.probes) do AMO:Print(format("/amo %s - %s", name, probe.help or "")) end
    end
end

SLASH_AMO1 = "/amo" -- luacheck: ignore 112 113
SlashCmdList["AMO"] = Handle -- luacheck: ignore 112
