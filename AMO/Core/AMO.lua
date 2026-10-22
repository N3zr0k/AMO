local ADDON_NAME = ...

-- AMO - Ammunition Management Organizer: Munitionshelfer für Jäger. Das Addon arbeitet allein, ohne Glimpse.
-- Aufbau: Core/ (Gerüst), Modules/Ammo/ (die Funktion), Locales/. Die Funktion hängt sich mit AMO:Listen an Ereignisse und
-- meldet über AMO:Notify; ihre Einstellungen liegen in AMO.db.profile.ammo.
local AMO = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0")
_G.AMO = AMO -- luacheck: ignore 122

AMO.name = ADDON_NAME
AMO.L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
AMO.api = {
    UnitClass = UnitClass,
    UnitRace = UnitRace,
    GetTime = GetTime,
    PlaySound = PlaySound,
    RaidNotice_AddMessage = RaidNotice_AddMessage,
    RaidWarningFrame = RaidWarningFrame,
    UIErrorsFrame = UIErrorsFrame,
    ChatTypeInfo = ChatTypeInfo,
    CreateFrame = CreateFrame,
    UIParent = UIParent,
    After = C_Timer and C_Timer.After,
}

AMO.defaults = { profile = { enabled = true, debug = false } }

function AMO:OnInitialize()
    self.defaults.profile.ammo = self.ammo.defaults
    self.db = LibStub("AceDB-3.0"):New("AMODB", self.defaults, true)
    self:SetupOptions()
end

--- Ist der Charakter ein Jäger? Nur dann läuft die Funktion.
function AMO:IsHunter()
    local _, token = self.api.UnitClass("player")
    return token == "HUNTER"
end

function AMO:OnEnable()
    self:Announce()
    if self:IsHunter() then self.ammo:Enable() end
end

--- Ereignis abonnieren. AceEvent kennt pro Objekt nur einen Handler je Ereignis (ein zweites RegisterEvent ersetzt den ersten),
-- deshalb melden sich alle Teile hier an und teilen sich eine Anmeldung. fn(event, ...)
function AMO:Listen(event, fn)
    self.listeners = self.listeners or {}
    local list = self.listeners[event]
    if not list then
        list = {}
        self.listeners[event] = list
        self:RegisterEvent(event, function(...)
            for _, listener in ipairs(list) do
                local ok, err = pcall(listener, ...)
                if not ok then geterrorhandler()(err) end
            end
        end)
    end
    list[#list + 1] = fn
end

--- Texte hinzufügen: texts[sprache][schlüssel] und races[sprache][volk][schlüssel], jeweils Listen
function AMO:AddTexts(texts, races)
    local locale = GetLocale and GetLocale() or "enUS"
    self.texts = self.texts or {}
    self.raceTexts = self.raceTexts or {}
    for key, pool in pairs(texts[locale] or texts.enUS) do self.texts[key] = pool end
    for race, keys in pairs((races or {})[locale] or (races or {}).enUS or {}) do
        self.raceTexts[race] = self.raceTexts[race] or {}
        for key, pool in pairs(keys) do self.raceTexts[race][key] = pool end
    end
end

--- Zufälliger Text zum Schlüssel (AmmoTexts.lua), %d wird mit count gefüllt
function AMO:Say(key, count)
    local _, race = self.api.UnitRace("player")
    local byRace = race and self.raceTexts and self.raceTexts[race]
    local pool = (byRace and byRace[key]) or (self.texts and self.texts[key])
    if not pool or #pool == 0 then return "" end
    return format(pool[math.random(#pool)], count or 0)
end

--- Prüfung für /amo <name> anmelden; func(args) gibt eine Zeile oder eine Liste von Zeilen zurück
AMO.probes = {}

function AMO:RegisterProbe(name, func, help)
    self.probes[strlower(name)] = { func = func, help = help }
end

function AMO:Print(text)
    print("|cff33ff99AMO|r: " .. text)
end
