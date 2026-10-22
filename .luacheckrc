-- luacheck-Konfiguration für AMO (WoW Forever, Lua 5.1-Dialekt)
std = "lua51"
max_line_length = false
codes = true
exclude_files = { "**/Libs/**" }
ignore = {
    "212/self",   -- ungenutztes self
    "212/_.*",    -- ungenutzte Argumente mit Unterstrich
}

-- Globale, die das Addon selbst setzt
globals = { "AMO", "AMODB", "SLASH_AMO1", "StaticPopupDialogs", "SlashCmdList" }

-- Blizzard-API und Mixins (nur lesen)
read_globals = {
    "UnitClassification", "UnitIsTameable", "UnitIsPlayer", "C_PetInfo", "GetPetLoyalty", "UnitBuff", "PetFrame", "StatusBar", "UnitCanAttack", "UnitReaction", "UnitThreatSituation", "CheckInteractDistance", "GetCVar", "C_NamePlate", "IsItemInRange", "IsSpellInRange", "GetSpellInfo",
    "UnitCreatureFamily", "UnitCreatureType", "UnitHealthMax", "UnitPower", "UnitPowerMax", "GetPetHappiness", "GetPetFoodTypes", "GetPetExperience", "GetPetTrainingPoints",
    "GetContainerItemID", "UseContainerItem", "PickupContainerItem", "PickupInventoryItem", "CursorHasItem", "ClearCursor", "GetContainerItemInfo", "GetMerchantItemMaxStack", "C_MerchantFrame", "GetMerchantItemID", "UnitRace", "GetMerchantNumItems", "GetMerchantItemInfo", "GetMerchantItemLink", "BuyMerchantItem", "GetMoney", "GetCoinTextureString", "GetMoneyString", "StaticPopup_Show", "YES", "NO", "UnitAffectingCombat", "GetContainerNumSlots", "GetContainerNumFreeSlots", "NUM_BAG_SLOTS", "PlaySound", "RAID_CLASS_COLORS", "GetInventoryItemCount", "GetInventoryItemID", "FCF_OpenNewWindow", "GetChatWindowInfo", "NUM_CHAT_WINDOWS", "C_MountJournal", "UnitBuff", "UIErrorsFrame", "ChatTypeInfo", "RaidWarningFrame", "RaidNotice_AddMessage",
    "GetItemCount", "GetMerchantItemCostInfo", "GetMerchantItemCostItem", "SetItemButtonTexture", "SetItemButtonQuality", "CreateColor", "BANK_CONTAINER", "NUM_BANKBAGSLOTS", "GetRealmName", "GetServerTime", "MERCHANT_ITEMS_PER_PAGE", "ITEM_SPELL_KNOWN", "ITEM_MIN_SKILL", "ITEM_REQ_REPUTATION", "UnitFactionGroup", "GetSubZoneText", "MerchantFrame", "MerchantFrame_UpdateMerchantInfo", "SetItemButtonNameFrameVertexColor", "SetItemButtonSlotVertexColor", "SetItemButtonNormalTextureVertexColor",
    "LibStub", "CreateFrame", "C_Timer", "C_Item", "C_Loot", "C_AddOns", "C_ClickBindings", "C_Spell",
    "C_Container", "C_TooltipInfo", "C_ActionBar", "Enum", "TooltipDataProcessor",
    "GameTooltip", "AddonCompartmentFrame", "PixelUtil", "InterfaceOptions_AddCategory", "InterfaceOptionsFrame_OpenToCategory", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "UIParent", "Settings",
    "GetTime", "UnitGUID", "C_Texture", "C_UnitAuras", "UnitName", "UnitLevel", "GetLocale", "GetAddOnMetadata", "IsAddOnLoaded",
    "IsShiftKeyDown", "IsControlKeyDown", "IsAltKeyDown", "issecretvalue", "UnitXP", "UnitXPMax", "GetXPExhaustion", "hooksecurefunc",
    "GetProfessions", "GetProfessionInfo", "GetItemInfoInstant", "GetNumLootItems", "GetLootSlotType",
    "GetLootSlotLink", "GetLootSourceInfo", "GetBindingKey", "GetBindingText", "GetBindingAction",
    "GetActionInfo", "GetMacroInfo", "GetMacroBody", "GetShapeshiftForm", "GetBonusBarOffset",
    "GetActionBarPage", "GetOverrideBarIndex", "HasVehicleActionBar", "HasOverrideActionBar",
    "HasBonusActionBar", "GetNumShapeshiftForms", "InCombatLockdown", "IsResting", "UnitIsDeadOrGhost", "ReloadUI", "GetCVar",
    "tinsert", "tremove", "wipe", "format", "strsplit", "strjoin", "strmatch", "strtrim", "strlower",
    "strupper", "strfind", "gsub", "strsub", "tostringall", "date", "time", "ceil", "floor",
    "tContains", "CopyTable", "Mixin", "_G",
    "SlashCmdList", "NUM_ACTIONBAR_BUTTONS", "bit", "geterrorhandler", "issecrettable", "TooltipUtil",
    "GetBuildInfo", "GetNumAddOns", "GetAddOnInfo", "GetAddOnDependencies", "MAX_ACCOUNT_MACROS",
    "GetNumBindings", "GetBinding", "GetShapeshiftFormInfo", "GetNumMacros", "GetMacroItem",
    "GetMacroSpell", "ITEM_QUALITY_COLORS",
    -- Doppelklick-Verteiler (Core/DoubleClick)
    "GetUnitSpeed", "IsFalling", "IsFlying", "IsFlyableArea", "IsSubmerged", "GetMirrorTimerInfo", "IsIndoors", "IsOutdoors", "UnitAffectingCombat",
    "C_TaxiMap", "GetTaxiMapID",
    "SetOverrideBindingClick", "ClearOverrideBindings", "IsMouselooking", "MouselookStop", "IsMouseButtonDown",
    "SHIFT_KEY_TEXT", "CTRL_KEY_TEXT", "ALT_KEY_TEXT",
    -- Orte, Wegpunkte und Fehlerfenster (Modul Locations, GatheringTooltip); TomTom ist optional
    "C_Map", "C_SuperTrack", "UiMapPoint", "CreateVector2D", "IsInInstance", "GetInstanceInfo", "TomTom",
    "StaticPopup_Show", "OKAY", "UISpecialFrames", "YES", "NO",
    -- Module Kampf und Reisen, ID-Helfer; Glimpse_Database ist optional
    "Item", "GetItemInfo", "GetSpellInfo", "UnitIsDead", "UnitHealth", "UnitExists", "UnitIsUnit",
    "UnitCanAttack", "UnitIsTapDenied", "IsFishingLoot", "UnitOnTaxi", "UnitIsGhost", "IsSwimming", "IsMounted",
    -- Glimpse_Database
    "GetServerTime", "UnitClass", "GetRealmName", "debugprofilestop", "debugstack", "unpack",
}
