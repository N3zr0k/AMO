local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Regler mit eigenen Beschriftungen unter dem linken und rechten Ende, z. B. "Aus" bei 0 und "Max" am Anschlag.
-- Verwendung in einer Option: dialogControl = AMO:SliderType(links, rechts); nil lässt die Zahl stehen.

local registered = {}

--- Name eines Reglertyps für AceConfig (dialogControl); der Typ wird beim ersten Aufruf angemeldet
function AMO.SliderType(_, low, high)
    local AceGUI = LibStub("AceGUI-3.0")
    local name = format("AMOSlider:%s:%s", low or "", high or "")
    if registered[name] then return name end
    registered[name] = true

    AceGUI:RegisterWidgetType(name, function()
        local widget = AceGUI.WidgetRegistry["Slider"]()
        widget.type = name

        -- Die Beschriftung setzt der Regler bei jeder Änderung der Grenzen neu, deshalb danach überschreiben
        local function Labels(slider)
            if low then slider.lowtext:SetText(low) end
            if high then slider.hightext:SetText(high) end
        end
        local setValues, setPercent = widget.SetSliderValues, widget.SetIsPercent
        widget.SetSliderValues = function(slider, ...)
            setValues(slider, ...)
            Labels(slider)
        end
        widget.SetIsPercent = function(slider, ...)
            setPercent(slider, ...)
            Labels(slider)
        end
        return widget
    end, 1)
    return name
end
