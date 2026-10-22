local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Zeilen im Gegenstands-Tooltip. Die Funktionen melden sich mit AMO:RegisterItemLines(key, fn) an; fn(module, data, tooltip)
-- gibt eine Liste { Links, Rechts, r, g, b [, r, g, b rechts], colored = "Rechts mit Farbcodes" } oder nil zurück.

AMO.itemLines = {}

-- Dünne Trennlinie. Eine Linie mit Höhe 1 auf einer Zwischenposition wird zwei Pixel dick, deshalb wird sie in echten
-- Pixeln bemessen und am Raster ausgerichtet (wie in Binds).
function AMO:CreateDivider(parent, layer, alpha)
    local line = parent:CreateTexture(nil, layer or "ARTWORK")
    line:SetColorTexture(0.88, 0.66, 0.23, alpha or 0.5) -- Gold #E1A93A
    if PixelUtil and PixelUtil.SetHeight then
        PixelUtil.SetHeight(line, 1)
    else
        line:SetHeight(1)
    end
    if line.SetSnapToPixelGrid then
        line:SetSnapToPixelGrid(true)
        line:SetTexelSnappingBias(0)
    end
    return line
end

--- Kopfzeile "(Logo) A·M·O" mit einer Linie bis zum rechten Rand des Tooltips (wie in Binds). Die Linie hängt am
-- rechten Rand des Textes statt an einer gemessenen Breite: im Client ist die Textbreite ein geheimer Wert, Rechnen damit
-- würde den Tooltip verseuchen. Eine Linie je Tooltip, sie verschwindet mit dem Tooltip.
function AMO:AddTooltipHeader(tooltip, size)
    tooltip:AddLine(format("|T%s:%d:%d:0:0|t %s", self.icon, size or 24, size or 24, self.wordmark))
    local name = tooltip.GetName and tooltip:GetName()
    local text = name and _G[name .. "TextLeft" .. tooltip:NumLines()]
    if not (text and tooltip.CreateTexture) then return end
    local line = tooltip.amoHeaderLine
    if not line then
        line = self:CreateDivider(tooltip)
        tooltip.amoHeaderLine = line
        local function hide() line:Hide() end
        tooltip:HookScript("OnHide", hide)
        if tooltip:HasScript("OnTooltipCleared") then tooltip:HookScript("OnTooltipCleared", hide) end
    end
    line:ClearAllPoints()
    line:SetPoint("LEFT", text, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", tooltip, "RIGHT", -10, 0)
    line:Show()
end

local function OnItem(tooltip, data)
    if not (tooltip and tooltip.AddDoubleLine) or (issecretvalue and issecretvalue(data)) then return end
    local titled
    for _, fn in pairs(AMO.itemLines) do
        local ok, rows = pcall(fn, AMO, data, tooltip)
        if ok and type(rows) == "table" and #rows > 0 then
            if not titled then
                titled = true
                tooltip:AddLine(" ")
                AMO:AddTooltipHeader(tooltip)
            end
            for _, row in ipairs(rows) do
                tooltip:AddDoubleLine(row[1], row.colored or row[2], row[3], row[4], row[5], row[6] or row[3], row[7] or row[4], row[8] or row[5])
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
