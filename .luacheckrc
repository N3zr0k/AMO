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
    "GetContainerItemID", "UseContainerItem", "PickupContainerItem", "PickupInventoryItem", "CursorHasItem",
    "ClearCursor", "GetContainerItemInfo", "GetMerchantItemMaxStack", "C_MerchantFrame", "GetMerchantItemID",
    "UnitRace", "GetMerchantNumItems", "GetMerchantItemInfo", "GetMerchantItemLink", "BuyMerchantItem", "GetMoney",
    "GetCoinTextureString", "GetMoneyString", "StaticPopup_Show", "YES", "NO", "UnitAffectingCombat",
    "GetContainerNumSlots", "GetContainerNumFreeSlots", "NUM_BAG_SLOTS", "PlaySound", "GetInventoryItemCount",
    "GetInventoryItemID", "UIErrorsFrame", "ChatTypeInfo", "RaidWarningFrame", "RaidNotice_AddMessage", "LibStub",
    "CreateFrame", "C_Timer", "C_Item", "C_AddOns", "C_Container", "Enum", "TooltipDataProcessor", "GameTooltip",
    "AddonCompartmentFrame", "PixelUtil", "InterfaceOptions_AddCategory", "InterfaceOptionsFrame_OpenToCategory",
    "UIParent", "Settings", "GetTime", "UnitGUID", "UnitName", "UnitLevel", "GetLocale", "GetAddOnMetadata",
    "IsShiftKeyDown", "IsControlKeyDown", "IsAltKeyDown", "issecretvalue", "GetItemInfoInstant", "InCombatLockdown",
    "tinsert", "tremove", "wipe", "format", "strsplit", "strmatch", "strtrim", "strlower", "gsub", "time", "ceil",
    "floor", "_G", "geterrorhandler", "IsInInstance", "Item", "GetItemInfo", "UnitClass", "unpack",
}
