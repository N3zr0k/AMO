local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Zeilen im Gegenstands-Tooltip. Die Funktionen melden sich mit AMO:RegisterItemLines(key, fn) an; fn(module, data, tooltip)
-- gibt eine Liste { Links, Rechts, r, g, b } oder nil zurück.

AMO.itemLines = {}

local function OnItem(tooltip, data)
    if not (tooltip and tooltip.AddDoubleLine) or (issecretvalue and issecretvalue(data)) then return end
    for _, fn in pairs(AMO.itemLines) do
        local ok, rows = pcall(fn, AMO, data, tooltip)
        if ok and type(rows) == "table" then
            for _, row in ipairs(rows) do
                tooltip:AddDoubleLine(row[1], row[2], row[3], row[4], row[5], row[3], row[4], row[5])
            end
        elseif not ok then
            geterrorhandler()(rows)
        end
    end
end

function AMO:RegisterItemLines(key, fn)
    self.itemLines[key] = fn
    if self.itemHooked or not (TooltipDataProcessor and Enum and Enum.TooltipDataType) then return end
    self.itemHooked = true
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItem)
end
