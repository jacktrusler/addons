---------------------------
---- Lottery Functions
---------------------------
function ConvertMoney(money)
   local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
   local silver = floor((money % (COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
   local copper = money % COPPER_PER_SILVER
   return gold, silver, copper
end

CURRENT_TRADE = nil

local function currentTrade()
   if (not CURRENT_TRADE) then
      CURRENT_TRADE = CreateNewTrade();
   end
   return CURRENT_TRADE;
end

function CreateNewTrade()
   local trade = {
      id = nil,
      when = nil,
      where = nil,
      who = nil,
      player = UnitName("player"),
      playerMoney = 0,
      targetMoney = 0,
      playerItems = {},
      targetItems = {},
      events = {},  -- to determine cancel reason
      toofar = nil, -- common specific cancel reason
      result = nil, --[cancelled | complete | error]
      reason = nil, --["self" | "selfrunaway" | "toofar" | "other" | "selfhideui" | ERR_TRADE_BAG_FULL | ERR_TRADE_MAX_COUNT_EXCEEDED | ERR_TRADE_TARGET_BAG_FULL | ERR_TRADE_TARGET_MAX_COUNT_EXCEEDED]
   };
   return trade;
end

function Lottery_OnLoad(self)
   local Lottery = CreateFrame("Frame", "TBT_AnnounceChannelDropDown", TradeFrame, "UIDropDownMenuTemplate");
   self:RegisterEvent("VARIABLES_LOADED");
   self:RegisterEvent("TRADE_SHOW");
   self:RegisterEvent("TRADE_CLOSED");
   self:RegisterEvent("TRADE_REQUEST_CANCEL");
   self:RegisterEvent("PLAYER_TRADE_MONEY");

   self:RegisterEvent("TRADE_MONEY_CHANGED");
   --self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED"); --this is an uncertain problem, seems TRADE_PLAYER_ITEM_CHANGED always fire 2 times?
   self:RegisterEvent("TRADE_TARGET_ITEM_CHANGED");
   self:RegisterEvent("TRADE_ACCEPT_UPDATE");
   self:RegisterEvent("UI_INFO_MESSAGE");
   self:RegisterEvent("UI_ERROR_MESSAGE");
end

function CaptureMoneyTraded()
   local playerMoney = GetPlayerTradeMoney()
   local targetMoney = GetTargetTradeMoney()

   local playerGold, playerSilver, playerCopper = ConvertMoney(playerMoney)
   local targetGold, targetSilver, targetCopper = ConvertMoney(targetMoney)

   return playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper
end

function TradeHandler(self, event, ...)
   print("Event: " .. event)
function tradeHandler(self, event, ...)
    print("Event: " .. event)

    local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper
    if event == "TRADE_ACCEPT_UPDATE" then
        local playerAccept, targetAccept = ...
        local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper = captureMoneyTraded()
        if targetAccept == 1 and targetCopper == 1 then
            print('playerCopper: ', playerCopper, "targetCopper: ", targetCopper)
            AcceptTrade()
        end
    end
    if event == "TRADE_REQUEST_CANCEL" then
end
end
   local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper
   if event == "TRADE_ACCEPT_UPDATE" then
      local playerAccept, targetAccept = ...
      local playerGold, playerSilver, playerCopper, targetGold, targetSilver, targetCopper = CaptureMoneyTraded()
      if targetAccept == 1 and targetCopper == 1 then
         print('playerCopper: ', playerCopper, "targetCopper: ", targetCopper)
         AcceptTrade()
      end
   end
   if event == "TRADE_REQUEST_CANCEL" then
   end
end

local tradeFrame = CreateFrame("Frame")
tradeFrame:RegisterEvent("TRADE_SHOW")
tradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
tradeFrame:RegisterEvent("TRADE_CLOSED")
tradeFrame:SetScript("OnEvent", TradeHandler)
