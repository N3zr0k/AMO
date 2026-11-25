-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- AMO: Levelup-Anzeige des Tiers
local function setup()
    stub.newAMO()
    _G.GetLocale = function() return "enUS" end
    _G.UNKNOWNOBJECT = "Unknown"
    _G.LEVEL_GAINED = "Level %d"
    for _, file in ipairs({ "Core/AMO.lua", "Core/AMOLevelUp.lua" }) do stub.load(file, "AMO") end
    local AMO = _G.AMO
    local shown = {}
    AMO.ShowLevelUp = function(_, reached, level) shown[#shown + 1] = { reached, level } end
    AMO.api.UnitGUID = function(unit) return stub.units[unit] and stub.units[unit].guid end
    AMO.api.UnitName = function(unit) return stub.units[unit] and stub.units[unit].name end
    AMO.api.UnitLevel = function(unit) return stub.units[unit] and stub.units[unit].level end
    AMO.api.NativePetDisplay = function() return false end
    return AMO, shown
end

test("AMO: Tier-Levelup zeigt den Tiernamen und die neue Stufe", function()
    local AMO, shown = setup()
    stub.units.pet = { guid = "Pet-1", name = "Rex", level = 10 }
    AMO:EnablePetLevel()
    eq(AMO:CheckPetLevel(), false, "gleiche Stufe: nichts")
    stub.units.pet.level = 11
    eq(AMO:CheckPetLevel(), true, "höhere Stufe")
    eq(shown[1][1], "Rex", "Tiername oben")
    eq(shown[1][2], "Level 11", "Stufe groß")
    eq(AMO:CheckPetLevel(), false, "nicht doppelt")
end)

test("AMO: neues Tier und Hinweise", function()
    local AMO, shown = setup()
    AMO:EnablePetLevel()
    stub.units.pet = { guid = "Pet-2", name = "Bär", level = 40 }
    eq(AMO:CheckPetLevel(), false, "frisch gerufenes Tier ist kein Levelup")
    stub.units.pet.level = 41
    AMO.api.NativePetDisplay = function() return true end
    eq(AMO:CheckPetLevel(), false, "Blizzards Anzeige zeigt es schon")
    eq(#shown, 0, "keine eigene Anzeige")
end)
