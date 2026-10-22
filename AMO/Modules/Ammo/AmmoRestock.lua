local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")
local L = AMO.L
local Ammo = AMO.ammo

-- Jäger: Beim Händler fragen, ob der Köcher mit der besten nutzbaren Munition aufgefüllt werden soll, wenn weniger als
-- "restock" Schuss da sind. Gekauft wird so viel, wie in den Köcher passt und das Geld reicht.

local PROJECTILE = 6 -- Gegenstandsklasse Geschosse

-- Händlerfunktionen wandern zwischen Client-Ständen (global oder C_MerchantFrame), deshalb mit Rückfall
local Merchant = C_MerchantFrame or {}
Ammo.api.GetMerchantNumItems = GetMerchantNumItems or Merchant.GetNumItems
Ammo.api.BuyMerchantItem = BuyMerchantItem or Merchant.BuyItem
Ammo.api.GetMerchantItemLink = GetMerchantItemLink or Merchant.GetItemLink
Ammo.api.GetMerchantItemID = GetMerchantItemID or Merchant.GetItemID
Ammo.api.GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
Ammo.api.GetMoney = GetMoney
Ammo.api.GetMerchantItemMaxStack = GetMerchantItemMaxStack or Merchant.GetItemMaxStack
Ammo.api.UnitLevel = UnitLevel
Ammo.api.StaticPopup_Show = StaticPopup_Show
Ammo.api.MoneyText = GetCoinTextureString or GetMoneyString
Ammo.api.GetMerchantItemInfo = function(index)
    if GetMerchantItemInfo then return GetMerchantItemInfo(index) end
    local info = Merchant.GetItemInfo and Merchant.GetItemInfo(index)
    if not info then return nil end
    return info.name, info.texture, info.price, info.stackCount, info.numAvailable, info.isPurchasable, info.isUsable,
        info.hasExtendedCost
end

--- Gegenstand des Händlerplatzes: Link, sonst die ID
function Ammo:MerchantItem(index)
    local api = self.api
    if api.GetMerchantItemLink then
        local link = api.GetMerchantItemLink(index)
        if link then return link end
    end
    return api.GetMerchantItemID and api.GetMerchantItemID(index) or nil
end

--- Stärkste nutzbare Munition des Händlers: { index, price, batch, stack, link, name } oder nil
function Ammo:BestOffer(kind)
    local api = self.api
    if not (api.GetMerchantNumItems and api.GetMerchantItemInfo and api.GetItemInfoInstant and api.GetItemInfo) then
        return nil
    end

    local level = api.UnitLevel("player")
    local best
    for index = 1, api.GetMerchantNumItems() or 0 do
        local name, _, price, batch, available, purchasable, usable, extended = api.GetMerchantItemInfo(index)
        local link = self:MerchantItem(index)
        if link and name and purchasable ~= false and usable ~= false and not extended and available ~= 0 then
            local _, _, _, _, _, class, subclass = api.GetItemInfoInstant(link)
            if class == PROJECTILE and subclass == kind then
                local _, _, _, itemLevel, minLevel, _, _, stack = api.GetItemInfo(link)
                if itemLevel and (minLevel or 0) <= level
                    and (not best or itemLevel > best.itemLevel) then
                    best = { index = index, price = price or 0, batch = math.max(batch or 1, 1), stack = stack or 200,
                        link = link, name = name, itemLevel = itemLevel, available = available }
                end
            end
        end
    end
    return best
end

--- Was gekauft werden soll: { offer, amount (Schuss), cost (Kupfer) } oder nil wenn nichts zu tun ist.
-- Der Preis des Händlers gilt für eine Packung (batch Stück); BuyMerchantItem zählt Stück.
function Ammo:RestockPlan()
    local settings = Ammo:Settings()
    local count = self:Ammo(true) -- beim Einkaufen zählen nur die Köcher
    local kind = self:AmmoKind()
    if not (settings and settings.restock > 0 and count and kind) or count >= settings.restock then return nil end

    local offer = self:BestOffer(kind)
    if not offer then return nil end

    local _, total = self:Slots(count)
    local amount = total * offer.stack - count -- bis der Köcher voll ist
    local unitPrice = offer.price / offer.batch
    if offer.available and offer.available > 0 then amount = math.min(amount, offer.available * offer.batch) end
    if unitPrice > 0 then amount = math.min(amount, math.floor(self.api.GetMoney() / unitPrice)) end
    if amount < 1 then return nil end
    return { offer = offer, amount = amount, cost = math.ceil(amount * unitPrice) }
end

--- Beim Öffnen eines Händlers: Popup mit dem Angebot
function Ammo:OnMerchant()
    if not self:IsOn() then return end
    local plan = self:RestockPlan()
    if not plan then return end
    self.plan = plan
    -- Der Popup nimmt nur zwei Textwerte; den ganzen Satz setze ich selbst zusammen
    local text = format(L["Fill your quiver? Buy %d x %s for %s."], plan.amount, plan.offer.name,
        self.api.MoneyText(plan.cost))
    self.api.StaticPopup_Show("GLIMPSE_RESTOCK_AMMO", text)
end

function Ammo:BuyPlan()
    local plan = self.plan
    self.plan = nil
    if not plan then return end

    local api = self.api
    local chunk = api.GetMerchantItemMaxStack and api.GetMerchantItemMaxStack(plan.offer.index) or plan.offer.stack
    local stop = api.GetMoney() - plan.cost -- darunter wird nicht weiter gekauft
    local left = plan.amount
    while left > 0 and api.GetMoney() > stop do
        local count = math.min(chunk, left)
        api.BuyMerchantItem(plan.offer.index, count)
        left = left - count
    end
end

function Ammo:EnableRestock()
    AMO:Listen("MERCHANT_SHOW", function() Ammo:OnMerchant() end)
    if StaticPopupDialogs then
        StaticPopupDialogs["GLIMPSE_RESTOCK_AMMO"] = {
            text = "%s",
            button1 = YES, button2 = NO,
            OnAccept = function() Ammo:BuyPlan() end,
            timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
        }
    end
end
