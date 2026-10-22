-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- AMO: Munitionswarnungen, Händler, Anlegen und Tooltip
local FILES = { "Core/AMO.lua", "Core/AMODebug.lua", "Core/AMONotify.lua", "Core/AMOTooltip.lua",
    "Modules/Ammo/AmmoTexts.lua", "Modules/Ammo/Ammo.lua", "Modules/Ammo/AmmoRestock.lua", "Modules/Ammo/AmmoEquip.lua",
    "Modules/Ammo/AmmoStats.lua", "Modules/Ammo/AmmoTooltip.lua", "Modules/Ammo/AmmoOptions.lua", "Core/AMOOptions.lua" }

local function setup(class)
    stub.newAMO()
    _G.GetLocale = function() return "enUS" end
    _G.SlashCmdList = {}
    for _, file in ipairs(FILES) do stub.load(file, "AMO") end
    local AMO = _G.AMO
    function AMO.SliderType() return "slider" end
    function AMO:Print() end
    local state = { combat = true, quirk = true, ammo = 300, ranged = true, instance = false, kind = "none" }
    local notices = {}
    AMO.api.UnitClass = function() return "Jäger", class or "HUNTER" end
    AMO.api.UnitRace = function() return "Orc", state.race or "Orc" end
    AMO.api.GetTime = function() return stub.now end
    AMO.api.PlaySound = function() end
    AMO.api.RaidNotice_AddMessage = function(_, text) notices[#notices + 1] = text end
    AMO.api.RaidWarningFrame = {}
    AMO.api.ChatTypeInfo = { RAID_WARNING = {} }
    AMO.ammo.api.GetInventoryItemCount = function() return math.max(state.ammo, state.quirk and 1 or 0) end
    AMO.ammo.api.GetInventoryItemID = function(_, slot)
        if slot == 0 then return state.ammo > 0 and 2 or nil end
        return state.ranged and 1 or nil
    end
    AMO.ammo.api.InCombat = function() return state.combat end
    AMO.ammo.api.IsInInstance = function() return state.instance, state.kind end
    AMO:OnInitialize()
    return AMO, state, notices
end

test("AMO: nur Jäger bekommen die Optionen der Munition", function()
    local AMO = setup("HUNTER")
    local args = AMO:BuildOptions()
    eq(args.soon ~= nil, true, "Optionen des Jägers")
    -- AceConfig prüft: min, max und step eines Reglers müssen Zahlen sein
    for key, option in pairs(args) do
        if option.type == "range" then
            for _, field in ipairs({ "min", "max", "step" }) do
                eq(type(option[field]), "number", key .. "." .. field .. " ist eine Zahl")
            end
        end
    end
    AMO.api.UnitClass = function() return "Krieger", "WARRIOR" end
    local other = AMO:BuildOptions()
    eq(other.soon, nil, "andere Klasse: keine Optionen")
    eq(other.note ~= nil, true, "Hinweis")
end)

test("AMO: Funktion komplett abschaltbar", function()
    local AMO, state, notices = setup()
    local args = AMO:BuildOptions()
    eq(args.enabled.get(), true, "Standard an")
    eq(args.soon.disabled(), false, "Optionen aktiv")
    state.ammo = 40
    AMO.ammo:Check()
    local before = #notices
    eq(before > 0, true, "an: Warnung")
    args.enabled.set(nil, false)
    eq(args.soon.disabled(), true, "Optionen ausgegraut")
    state.ammo = 0
    AMO.ammo.count = nil
    AMO.ammo:Check()
    state.instance, state.kind = true, "party"
    AMO.ammo:CheckDungeon()
    AMO.ammo:OnMerchant()
    eq(#notices, before, "aus: keine Meldung")
end)

test("AMO: Debug nur mit BugLab und im Debug-Modus", function()
    local AMO = setup()
    local lines = {}
    local debug = AMO:NewDebugger()
    debug:Log("ohne BugLab")
    _G.BugLab = { GetLogger = function() return setmetatable({}, { __index = function(_, method)
        return function(_, text, ...) lines[#lines + 1] = { method, text, ... } end
    end }) end }
    debug:Log("aus %d", 1)
    eq(#lines, 0, "Debug-Modus aus")
    debug:Error("immer %d", 2)
    eq(lines[1][1], "Error", "Fehler unabhängig vom Modus")
    AMO.db.profile.debug = true
    debug:Log("an %d", 3)
    eq(lines[2][1], "Debug", "Stufe Debug")
    eq(lines[2][3], 3, "Wert als Argument")
    _G.BugLab = nil
    debug:Log("weg")
    eq(#lines, 2, "ohne BugLab nichts")
end)

test("AMO: Köcher bald leer mit Hochrechnung je Platz", function()
    local AMO, state, notices = setup()
    -- 3 Plätze im Köcher, einer je 200 Schuss
    AMO.ammo.api.GetNumSlots = function(bag) return bag == 1 and 3 or 0 end
    AMO.ammo.api.GetNumFreeSlots = function() return 3 - math.ceil(state.ammo / 200), 1 end
    AMO.ammo.api.GetTime = function() return stub.now end
    AMO.ammo:Settings().soon = 2
    AMO.ammo:Settings().low = false
    eq(select(2, AMO.ammo:Slots(1)), 3, "Plätze dynamisch")
    state.ammo = 600
    AMO.ammo:Check()
    eq(#notices, 0, "drei Plätze gefüllt, über der Schwelle")
    stub.now = 60
    state.ammo = 400
    AMO.ammo:Check()
    eq(#notices, 1, "zwei Plätze: Warnung")
    eq(notices[1]:find("2 min", 1, true) ~= nil or notices[1]:find("2 Min", 1, true) ~= nil
        or notices[1]:find("%d") ~= nil, true, "mit Minuten")
    stub.now = 120
    state.ammo = 399
    AMO.ammo:Check()
    eq(#notices, 1, "gleicher Platz: nicht noch einmal")
    stub.now = 180
    state.ammo = 190
    AMO.ammo:Check()
    eq(#notices, 2, "nächster Platz leer: erneut")
    state.ammo = 600
    AMO.ammo:Check()
    state.ammo = 300
    stub.now = 400
    AMO.ammo:Check()
    eq(#notices, 3, "nach dem Nachkaufen wieder")
    AMO.ammo:Settings().soon = 0
    state.ammo = 0
    AMO.ammo:Check()
    eq(#notices, 3, "0 = aus")
    -- außerhalb des Kampfes keine Messung
    AMO.ammo:Settings().soon = 2
    state.combat = false
    AMO.ammo.track = nil
    state.ammo = 100
    AMO.ammo:Check()
    state.ammo = 40
    stub.now = stub.now + 60
    AMO.ammo:Check()
    eq(AMO.ammo.track, nil, "kein Verbrauch außerhalb des Kampfes")
end)

test("AMO: leerer Köcher und dringende Warnung", function()
    local AMO, state, notices = setup()
    AMO.ammo.api.GetNumSlots = function() return 0 end
    AMO.ammo.api.GetTime = function() return stub.now end
    AMO.ammo:Settings().soon = 0
    state.ammo = 50
    AMO.ammo:Check()
    eq(#notices, 1, "dringend bei 50")
    AMO.ammo:Check()
    eq(#notices, 1, "nicht doppelt")
    AMO.ammo:Settings().soon = 1
    state.ammo = 0
    AMO.ammo:Check()
    eq(#notices, 2, "leer")
    eq(notices[2]:find("ff4040", 1, true) ~= nil, true, "rot")
    state.instance, state.kind, state.ammo = true, "party", 100
    AMO.ammo:CheckDungeon()
    eq(#notices, 3, "Dungeon-Warnung")
    stub.now = stub.now + 5
    AMO.ammo:CheckDungeon()
    eq(#notices, 3, "Wiederholsperre")
end)

test("AMO: ohne Fernkampfwaffe und mit abgeschalteter Stufe still", function()
    local AMO, state, notices = setup()
    AMO.ammo.api.GetNumSlots = function() return 0 end
    AMO.ammo.api.GetTime = function() return stub.now end
    state.ranged, state.ammo = false, 0
    AMO.ammo:Check()
    eq(#notices, 0, "keine Fernkampfwaffe")
    state.ranged = true
    AMO.ammo:Settings().soon = 0
    AMO.ammo:Settings().low = false
    AMO.ammo:Check()
    eq(#notices, 0, "abgeschaltet")
end)

test("AMO: Händler bietet die stärkste nutzbare Munition an", function()
    local AMO, state = setup()
    local H = AMO.ammo
    local items = {
        { name = "Schwache Pfeile", price = 10, batch = 200, class = 6, sub = 2, ilvl = 5, min = 1 },
        { name = "Gute Pfeile", price = 100, batch = 200, class = 6, sub = 2, ilvl = 30, min = 25 },
        { name = "Zu starke Pfeile", price = 500, batch = 200, class = 6, sub = 2, ilvl = 50, min = 40 },
        { name = "Kugeln", price = 20, batch = 200, class = 6, sub = 3, ilvl = 40, min = 1 },
        { name = "Brot", price = 1, batch = 5, class = 0, sub = 5, ilvl = 1, min = 1 },
    }
    local api = H.api
    api.GetMerchantNumItems = function() return #items end
    api.GetMerchantItemInfo = function(i) local it = items[i] return it.name, 0, it.price, it.batch, -1, true, true end
    api.GetMerchantItemLink = function(i) return i end
    api.GetMerchantItemID = nil
    api.GetItemInfoInstant = function(what)
        if what == "bow" or what == 99 then return 99, "", "", "", 0, 2, 2 end
        local it = items[what]
        return what, "", "", "", 0, it.class, it.sub
    end
    api.GetItemInfo = function(i) local it = items[i] return it.name, i, 1, it.ilvl, it.min, "", "", 200 end
    api.GetInventoryItemID = function(_, slot)
        if slot == 0 then return state.ammo > 0 and 2 or nil end
        return 99
    end
    api.UnitLevel = function() return 30 end
    api.GetMoney = function() return 1000 end
    api.MoneyText = function(c) return tostring(c) end
    local bought, shown = 0, {}
    api.BuyMerchantItem = function(index, n) bought = bought + n eq(index, 2, "gekauft wird Index 2") end
    api.StaticPopup_Show = function(name, text) shown = { name = name, text = text } end
    api.GetNumSlots = function(bag) return bag == 1 and 2 or 0 end
    api.GetNumFreeSlots = function() return 1, 1 end
    api.ItemAt = function(bag, slot) if bag == 1 and slot == 1 and state.ammo > 0 then return 2, state.ammo end end

    state.ammo = 150
    AMO.ammo:Settings().restock = 0
    H:OnMerchant()
    eq(shown.name, nil, "0 = aus")
    AMO.ammo:Settings().restock = 300
    H:OnMerchant()
    eq(shown.text:find("Gute Pfeile", 1, true) ~= nil, true, "stärkste nutzbare")
    -- Köcher mit 2 Plätzen zu 200 fasst 400, es liegen 150 darin: 250 Stück fehlen, Preis 100 je 200 Stück
    eq(shown.text:find("250 x", 1, true) ~= nil, true, "genau so viel wie in den Köcher passt")
    eq(shown.text:find("125", 1, true) ~= nil, true, "Preis nach Stück")
    H:BuyPlan()
    eq(bought, 250, "Stück gekauft, nicht Packungen")
    api.GetMoney = function() return 50 end
    H:OnMerchant()
    eq(shown.text:find("100 x", 1, true) ~= nil, true, "Geld reicht nur für 100 Stück")
    api.GetMoney = function() return 0 end
    shown = {}
    H:OnMerchant()
    eq(shown.name, nil, "kein Geld: keine Frage")
    api.GetMoney = function() return 1000 end
    state.ammo = 350
    shown = {}
    H:OnMerchant()
    eq(shown.name, nil, "genug Munition: keine Frage")
end)

test("AMO: Texte je Volk, Köcher nur der passenden Munitionsart", function()
    local AMO, state = setup()
    state.race = "Troll"
    local seen = {}
    for _ = 1, 40 do seen[AMO:Say("ammoLow", 7)] = true end
    for text in pairs(seen) do eq(text:find("mon") ~= nil or text:find("Mon") ~= nil or text:find("Da next", 1, true) ~= nil, true, "Troll-Text") end
    state.race = "Human"
    eq(AMO:Say("ammoLow", 7) ~= "", true, "ohne Volkstexte die allgemeinen")

    local H = AMO.ammo
    H.api.GetItemInfoInstant = function(id) if id == 100 then return 100, "", "", "", 0, 6, 2 end return 1, "", "", "", 0, 2, 2 end -- Pfeil / Bogen
    H.api.GetNumSlots = function(bag) return bag <= 1 and 4 or 0 end
    H.api.GetNumFreeSlots = function(bag) if bag == 0 then return 1, 2 end return 2, 1 end -- Beutel 0 Kugeln, Beutel 1 Pfeile
    H.api.ItemAt = function(bag, slot) -- zwei Stapel Pfeile in einer normalen Tasche, im Köcher nichts
        if bag == 0 and slot <= 2 then return 100, 200 end
    end
    local filled, total = H:Slots(400)
    eq(total, 4, "nur der Pfeilköcher")
    eq(filled, 2, "gefüllt: Pfeile in der Tasche zählen mit")
end)

test("AMO: Munition zählt aus allen Taschen, nicht nur dem Köcher", function()
    local AMO, state = setup()
    local H = AMO.ammo
    H.api.GetItemInfoInstant = function(id)
        if id == 99 then return 99, "", "", "", 0, 2, 2 end   -- Bogen
        if id == 1 or id == 2 then return id, "", "", "", 0, 6, 2 end -- Pfeile
        return id, "", "", "", 0, 0, 0                        -- Brot
    end
    H.api.GetInventoryItemID = function(_, slot) return slot == 18 and 99 or 1 end
    local bags = { [0] = { { 3, 5 }, { 1, 40 } }, [1] = { { 2, 100 }, { 1, 200 } } }
    H.api.GetNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end
    H.api.ItemAt = function(bag, slot) local item = bags[bag][slot] return item[1], item[2] end
    eq(H:Ammo(), 340, "Pfeile aus Rucksack und Köcher, ohne Brot")
    state.ranged = false
    H.api.GetInventoryItemID = function() return nil end
    eq(H:Ammo(), nil, "ohne Fernkampfwaffe nichts")
end)

test("AMO: kurz nach dem Laden keine Meldung", function()
    local AMO, state, notices = setup()
    state.ammo = 0
    AMO.ammo.ready = false
    AMO.ammo:Check()
    AMO.ammo:CheckDungeon()
    eq(#notices, 0, "vor Ablauf der Wartezeit still")
    AMO.ammo.ready = true
    AMO.ammo:Check()
    eq(#notices > 0, true, "danach wird geprüft")
end)

test("AMO: leerer Köcher, aber Munition in den Taschen, gibt keine Warnung", function()
    local AMO = setup()
    local H = AMO.ammo
    H.api.GetItemInfoInstant = function(id) if id == 100 then return 100, "", "", "", 0, 6, 2 end return 1, "", "", "", 0, 2, 2 end
    H.api.GetNumSlots = function(bag) return bag <= 1 and 6 or 0 end
    H.api.GetNumFreeSlots = function(bag) if bag == 1 then return 6, 1 end return 0, 0 end -- Beutel 1: leerer Pfeilköcher
    H.api.ItemAt = function(bag) if bag == 0 then return 100, 200 end end           -- 6 Stapel in der Tasche
    local filled, total = H:Slots(1200)
    eq(filled, 6, "Taschenplätze zählen")
    eq(total, 6, "Köcherplätze")
end)

test("AMO: große Meldung in der Bildschirmmitte", function()
    local AMO = setup()
    local shown, timers = nil, {}
    local frame = { text = { SetText = function(_, t) shown = t end } }
    for _, name in ipairs({ "SetSize", "SetPoint", "SetFrameStrata", "Show", "Hide" }) do frame[name] = function() end end
    function frame:Hide() shown = nil end
    function frame:CreateFontString()
        local text = { SetText = function(_, t) shown = t end }
        for _, name in ipairs({ "SetAllPoints", "SetTextColor", "SetShadowOffset" }) do text[name] = function() end end
        self.text = text
        return text
    end
    AMO.api.CreateFrame = function() return frame end
    AMO.api.UIParent = {}
    AMO.api.After = function(_, fn) timers[#timers + 1] = fn end
    AMO:Notify("big", "KÖCHER LEER")
    eq(shown, "KÖCHER LEER", "Text groß angezeigt")
    timers[1]()
    eq(shown, nil, "verschwindet wieder")
end)

test("AMO: beste Munition automatisch anlegen, nicht im Kampf", function()
    local AMO, state = setup("HUNTER")
    local ammo = AMO.ammo
    local api = ammo.api
    local items = { [10] = { level = 5, min = 1 }, [11] = { level = 15, min = 10 }, [12] = { level = 25, min = 40 } }
    local equipped, used = nil, {}
    local bags = { { 10 }, { 12, 11 } }
    api.UnitLevel = function() return 20 end
    api.GetNumSlots = function(bag) return bags[bag + 1] and #bags[bag + 1] or 0 end
    api.ItemAt = function(bag, slot) return bags[bag + 1] and bags[bag + 1][slot] end
    api.GetItemInfoInstant = function(id)
        if id == 1 then return nil, nil, nil, nil, nil, 2, 2 end -- Bogen
        return nil, nil, nil, nil, nil, 6, 2
    end
    api.GetItemInfo = function(id) local item = items[id]; return nil, nil, nil, item and item.level, item and item.min end
    api.GetInventoryItemID = function(_, slot)
        if slot == 0 then return equipped end
        return 1
    end
    api.GetTime = function() return stub.now end
    local picked
    api.PickupContainerItem = function(bag, slot) picked = bags[bag + 1][slot] end
    api.PickupInventoryItem = function() used[#used + 1] = picked end
    api.CursorHasItem = function() return false end
    ammo.ready = true
    ammo:Settings().autoEquip = true

    state.combat = true
    eq(ammo:EquipBest(), nil, "im Kampf wird nichts getauscht")
    eq(ammo.equipPending, true, "wird nach dem Kampf nachgeholt")
    eq(ammo:EquipBest(true).id, 11, "leerer Platz wird auch im Kampf gefüllt")
    eq(used[1], 11, "benutzt")
    used = {}
    stub.now = stub.now + 5
    state.combat = false
    local best = ammo:EquipBest()
    eq(best.id, 11, "stärkste nutzbare Munition (12 braucht Stufe 40)")
    eq(used[1], 11, "wird benutzt")

    stub.now = stub.now + 5
    equipped = 11
    eq(ammo:EquipBest(), nil, "schon angelegt")
    equipped = 12
    eq(ammo:EquipBest(), nil, "stärker angelegt: nicht zurücktauschen")
    equipped = 99 -- falsche Munitionsart (Kugeln zum Bogen)
    api.GetItemInfoInstant = function(id)
        if id == 1 then return nil, nil, nil, nil, nil, 2, 2 end
        if id == 99 then return nil, nil, nil, nil, nil, 6, 3 end
        return nil, nil, nil, nil, nil, 6, 2
    end
    eq(ammo:EquipBest().id, 11, "falsche Munitionsart wird ersetzt")
    stub.now = stub.now + 5
    equipped = nil
    bags = { { 10 }, {} } -- 11 ist aufgebraucht
    eq(ammo:EquipBest().id, 10, "nächst schwächere folgt")
    stub.now = stub.now + 5
    equipped = 10
    ammo:Settings().autoEquip = false
    bags = { { 10 }, { 11 } }
    eq(ammo:EquipBest(), nil, "ausgeschaltet")
    eq(#ammo:EquipLines() >= 5, true, "Probe ammo equip liefert Zeilen")
end)

test("AMO: Munitions-Tooltip mit Vorrat, Verbrauch und Zeit bis leer", function()
    local AMO, state = setup("HUNTER")
    local ammo = AMO.ammo
    local api = ammo.api
    local bags = { [1] = { 20, 20 }, [2] = { 30 } }
    local counts = { [20] = 150, [30] = 40 }
    local families = { [1] = 1, [2] = 2 } -- Tasche 1 Köcher (Pfeile), Tasche 2 Munitionsbeutel (Kugeln)
    api.GetNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end
    api.GetNumFreeSlots = function(bag) return 0, families[bag] end
    api.ItemAt = function(bag, slot) local id = bags[bag] and bags[bag][slot]; return id, id and counts[id] end
    api.GetItemInfoInstant = function(id)
        if id == 20 then return nil, nil, nil, nil, nil, 6, 2 end
        if id == 30 then return nil, nil, nil, nil, nil, 6, 3 end
        if id == 40 then return nil, nil, nil, nil, nil, 11, 2 end
        if id == 50 then return nil, nil, nil, nil, nil, 4, 1 end
        return nil, nil, nil, nil, nil, 2, 2 -- Bogen
    end
    api.GetInventoryItemID = function(_, slot) return slot == 0 and nil or 1 end
    api.GetTime = function() return stub.now end
    ammo:Settings().tooltip = true

    local rows = ammo:TooltipRows()
    eq(rows[1][1], "Arrows", "Pfeile zuerst")
    eq(rows[1][2], "300", "Vorrat dieser Sorte")
    eq(rows[2][1], "Bullets", "Kugeln getrennt")
    eq(rows[3][2], "340 / 600", "Gesamt mit Platz im Köcher (Pfeile 400 + Kugeln 200)")
    eq(rows[3][1], "Total", "Köcher: alles zusammen")
    eq(#rows, 3, "ohne Messung keine Verbrauchszeilen")
    local single = ammo:TooltipRows(20)
    eq(#single, 1, "Munition: nur die eigene Sorte")
    eq(single[1][2], "300", "Pfeile")

    -- Verbrauch im Kampf messen
    ammo.ready = true
    state.combat = true
    stub.now = 1000
    ammo.combatStart = 1000
    ammo.count, ammo.time = 300, 1000
    api.GetInventoryItemID = function(_, slot) return slot == 0 and 20 or 1 end -- Pfeile 20 angelegt
    for i = 1, 4 do
        stub.now = 1000 + i * 15
        ammo:Track(300 - i * 5, stub.now)
        ammo.count, ammo.time = 300 - i * 5, stub.now
    end
    state.combat = false
    ammo:EndCombat()
    local average, last = ammo:Rates()
    eq(math.abs(average - 20) < 0.01 and math.abs(last - 20) < 0.01, true, "20 Schuss in 60 s = 20 pro Minute")
    rows = ammo:TooltipRows()
    eq(rows[4][1] == "Average" and rows[5][1] == "Last combat", true, "Verbrauchszeilen")
    eq(rows[6][2], "15 min", "300 Pfeile bei 20 pro Minute (Bogen getragen)")

    eq(ammo:IsAmmoItem(20), true, "Munition")
    eq(ammo:IsAmmoItem(40), true, "Köcher")
    eq(ammo:IsAmmoItem(50), false, "andere Gegenstände")
    eq(#ammo.OnItem(nil, { id = 40 }), 6 + 0, "Tooltip des Köchers: Arten, Gesamt, Verbrauch, Zeit")
    local ammoRows = ammo.OnItem(nil, { id = 30 })
    eq(ammoRows[1][1], "Bullets", "Tooltip der Kugeln zeigt nur Kugeln")
    eq(#ammoRows, 4, "Kugeln: Vorrat, Durchschnitt, letzter Kampf, Zeit insgesamt")
    eq(ammo.OnItem(nil, { id = 50 }), nil, "kein Tooltip auf Rüstung")
    ammo:Settings().tooltip = false
    eq(ammo.OnItem(nil, { id = 20 }), nil, "abgeschaltet")
end)

