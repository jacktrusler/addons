------------ Youtube Tutorial ---------------
-- Much of this is taken from Mayron's awesome youtube series on how to make a WoW addon.
-- https://www.youtube.com/watch?v=nfaE7NQhMlc&list=PL3wt7cLYn4N-3D3PTTUZBM2t1exFmoA2G&index=1

--[[
... is a variable operator, it's all of the variables that are supplied to the function or file
in this case you are automatically given 2 arguments, name and namespace of the addon
by default the second name is a table that is automatically shared between all files in the namespace
]]
local addonName, gambling = ...

-- GLOBAL VARS --
local gameStates = {
    "REGISTRATION",
    "ROLLING",
}

-- Spoilers!
local gameModes = {
    "ROLL",
    "ROULETTE",
    "WOM",
}

local chatChannels = {
    "SAY", 
    "PARTY",
    "RAID",
    "GUILD",
}

gambling.theme = {
    r = 0,
    g = 0.8, -- 204/255
    b = 1,
    hex = "00ccff",
}

---------------------------------
-- Defaults (usually a database!)
---------------------------------
gambling.defaults = {
    game = {
        enterMessage = "gamba gamba",
        leaveMessage = "job done",
        mode = gameModes[1],
        chatChannel = chatChannels[1],
        houseCut = 0,
        min = 1,
        max = 100,
    },
    stats = {
        player = {},
        aliases = {},
        house = 0
    },
}

session = {
    currentChatMethod = chatChannels[2],
    wager = 1,
    players = {},
    payout = 0,
    gameState = gameStates[1],
}

local game = gambling.defaults.game


-------------------------
-- Game Functions
-------------------------
function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
          print(formatting)
          tprint(v, indent+1)
        elseif type(v) == 'boolean' then
          print(formatting .. tostring(v))      
        else
          print(formatting .. v)
        end
    end
end

function addPlayer(name)
    -- Ignore entry if player is already entered
    for i = 1, #session.players do
        if (session.players[i].name == playerName) then
            return
        end
    end
    newPlayer = {
        name = playerName,
        roll = nil,
    }
    tinsert(session.players, newPlayer)
    print("player added")
end

function removePlayer(name)
    for i = 1, #session.players do 
        if (session.players[i].name == playerName) then
            tremove(session.players, i)
            print("player removed")
            return
        end
    end
end

function makeNameString(players)
    local nameString = players[1].name
    if (#players > 1) then
        for i = 2, #players do
            if (i == #players) then
                nameString = nameString .. " and " .. players[i].name
            else
                nameString = nameString .. ", " .. players[i].name
            end
        end
    end

    return nameString
end

function checkPlayerRolls(participants)
    local playersToRoll = {}
    for i = 1, #participants do 
        if (participants[i].roll == nil) then
            table.insert(playersToRoll, participants[i].name)
        end
    end
    return playersToRoll
end

function chatMsg(msg, chatType, language, channel)
	chatType = session.currentChatMethod
	SendChatMessage(msg, chatType, language, channelnum)
end

function handleSystemMessage(_, text)
    -- Parses system messages recieved by the Event Listener to find and record player rolls
    local playerName, actualRoll, minRoll, maxRoll = strmatch(text, "^([^ ]+) .+ (%d+) %((%d+)-(%d+)%)%.?$")
    print(playerName, "---", actualRoll, "---", minRoll, "---", maxRoll);
    recordRoll(playerName, actualRoll, minRoll, maxRoll);
end

function recordRoll(playerName, actualRoll, minRoll, maxRoll)
    print(playerName, "---", actualRoll, "---", minRoll, "---", maxRoll);
    if (tonumber(minRoll) == 1 and tonumber(maxRoll) == game.max) then
        for i = 1, #session.players do 
            if (session.players[i].name == playerName and session.players[i].roll == nil) then
                session.players[i].roll = tonumber(actualRoll)
                print (session.players[i].roll)
            end
        end
    end
end

function determineResults(participants)
    local winners = {participants[1]}
    local losers = {participants[1]}
    local amountOwed = 0
    for i = 2, #participants do 
        if (participants[i].roll < losers[1].roll) then
            losers = {participants[i]}
        elseif (participants[i].roll > winners[1].roll) then
            winners = {participants[i]} 
        else 
            -- Handle Ties
            if (participants[i].roll == winners[1].roll) then
                table.insert(winners, participants[i])
            end
            if (participants[i].roll == losers[1].roll) then
                table.insert(losers, participants[i])
            end
        end
    end
    amountOwed = (winners[1].roll - losers[1].roll) * session.wager
    return {
        winners = winners,
        losers = losers,
        amountOwed = amountOwed,
    }
end

--Create frame to handle chat messages
local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_SAY")
chatFrame:RegisterEvent("CHAT_MSG_PARTY")
chatFrame:RegisterEvent("CHAT_MSG_RAID")
chatFrame:RegisterEvent("CHAT_MSG_SYSTEM")

-------------------------
-- Running the Game
-------------------------
function openEntries()
    if (session.gameState == "REGISTRATION") then
        chatMsg(format(".:MommaDeez's Casino:. --Classic Roll Off!-- Please type `%s` to join the round (type `%s` to leave). Current Stakes are: %sg", game.enterMessage, game.leaveMessage, session.wager))
        chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
            -- Name comes in like this [playerName]-[realm]
            -- i.e. Mommadeez-CrusaderStrike
            -- So we must split name before adding to table.
            playerName, _ = string.split('-', name)
            
            if ( ((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID")) and msg == game.enterMessage ) then
                addPlayer(playerName)
            elseif ( ((event == "CHAT_MSG_SAY") or (event == "CHAT_MSG_PARTY") or (event == "CHAT_MSG_RAID")) and msg == game.leaveMessage ) then
                print("here!")
                removePlayer(playerName)
            end
        end)
    else 
        print("Incorrect game state, cannot open entries")
    end
end

function startRoll()
    if (session.gameState == gameStates[1]) then
        session.gameState = gameStates[2]
    else 
        print(format("Rolls already begun. Current state is %s", session.gameState));
        return
    end

    chatMsg("Begin Rolling you Degenerate Gamblers!")
    --chatMsg(format("Begin Rolling you Degenerate Gamblers!"))
    chatFrame:SetScript("OnEvent", function(self, event, msg, name, ...)
        -- Name comes in like this [playerName]-[realm]
        -- i.e. Mommadeez-CrusaderStrike
        -- So we must split name before adding to table.
        playerName, _ = string.split('-', name)
        
        if (event == "CHAT_MSG_SYSTEM") then
            handleSystemMessage(self, msg)
        end
    end)
end

function finishRoll()
    local playersToRoll = checkPlayerRolls(session.players); 
    if (#playersToRoll > 0) then
        chatMsg("Some players still need to roll!")
    else 
        local results = determineResults(session.players)
        print(results)
        if (session.payout == 0) then 
            session.payout = results.amountOwed
        end
        -- Handle Ties
        tieBreakers = {}
        if (#results.winners > 1 and #results.losers ~= 0) then
            -- High End Tie Breaker
            tieBreakers = results.winners
            chatMsg("There's a high end tiebreaker!")
        elseif (#results.losers > 1 and #results.winners ~= 0) then
            -- Low End Tie Breaker
            tieBreakers = results.losers
            chatMsg("There's a low end tiebreaker!")
        end
        if (#tieBreakers > 0) then
            session.players = tieBreakers
            if (results.winners > 1) then 
                chatMsg("High end tie breaker! " .. makeNameString(session.players) .. " /roll " .. game.max .. " now!", game.chatChannel) 
            elseif (results.losers > 1) then 
                chatMsg("Low end tie breaker! " .. makeNameString(session.players) .. " /roll " .. game.max .. " now!", game.chatChannel) 
            end
            for _, player in ipairs(session.players) do
                v.roll = nil
            end
        end
        chatMsg(format("%s owes %s: %d Gold %d Silver! Lmao rekt and also got em.", results.winners[1].name, results.losers[1].name, math.floor(session.payout/100), session.payout % 100))
    end
end

-------------------------
-- Game UI
-------------------------
gambling.UI = {};
local UI = gambling.UI;

function UI:GetThemeColor()
	local c = gambling.theme;
	return c.r, c.g, c.b, c.hex;
end

function UI:Toggle()
    if not Interface then
        Interface = UI:CreateMenu();
    end
    Interface:SetShown(not Interface:IsShown());
end

function UI:CreateMenu()
    --[[ Args 
        1. Type of frame - "Frame"
        2. Name to access from with
        3. The parent frame, UIParent by default
        4. A comma separated list of XML templates to inherit from (can be > 1)
    ]]
    local UI = CreateFrame("Frame", "Gambling", UIParent, "BasicFrameTemplate");
    --[[ Layers order of lowest to highest 
        BACKGROUND
        BORDER
        ARTWORK
        OVERLAY
        HIGHLIGHT
    ]]

    UI:SetSize(200,240); --width / height
    UI:SetPoint("CENTER") -- point, relativeFrame, relativePoint, xOffset, yOffset
    -- Point and relativePoint "CENTER" could have been: 
    --[[
       "TOPLEFT" 
       "TOP" 
       "TOPRIGHT" 
       "LEFT" 
       "BOTTOMLEFT"
       "BOTTOM"
       "BOTTOMRIGHT"
       "RIGHT"
    ]]
    
    UI.title = UI:CreateFontString(nil, "OVERLAY");
    UI.title:SetFontObject("GameFontHighlight");
    UI.title:SetPoint("LEFT", UI.TitleBg, "LEFT", 5, 0);
    UI.title:SetText("MommaG's Casino");

    UI:SetMovable(true)
    UI:EnableMouse(true)

    UI:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)

    UI:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)

    -- UI Open Entries Button: 
    UI.openEntries = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.openEntries:SetPoint("CENTER", UI, "TOP", 0, -50);
    UI.openEntries:SetSize(110, 30);
    UI.openEntries:SetText("Open Entries");
    UI.openEntries:SetNormalFontObject("GameFontNormal");
    UI.openEntries:SetHighlightFontObject("GameFontHighlight");
    
    UI.openEntries:SetScript("OnClick", openEntries); 

    -- UI Close Entries Button: 
    UI.startRoll = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.startRoll:SetPoint("CENTER", UI, "TOP", 0, -90);
    UI.startRoll:SetSize(110, 30);
    UI.startRoll:SetText("Start Roll");
    UI.startRoll:SetNormalFontObject("GameFontNormal");
    UI.startRoll:SetHighlightFontObject("GameFontHighlight");

    UI.startRoll:SetScript("OnClick", startRoll); 

    -- UI Finish Roll Button: 
    UI.finishRoll = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.finishRoll:SetPoint("CENTER", UI, "TOP", 0, -130);
    UI.finishRoll:SetSize(110, 30);
    UI.finishRoll:SetText("Finish Roll");
    UI.finishRoll:SetNormalFontObject("GameFontNormal");
    UI.finishRoll:SetHighlightFontObject("GameFontHighlight");

    UI.finishRoll:SetScript("OnClick", finishRoll); 

    -- UI Gold Amount Slider
    UI.goldSlider = CreateFrame("Slider", nil, UI, "OptionsSliderTemplate");
    UI.goldSlider:SetPoint("CENTER", UI, "TOP", 0, -170);
    UI.goldSlider:SetMinMaxValues(1, 10);
    UI.goldSlider:SetValue(session.wager);
    UI.goldSlider:SetValueStep(1);
    UI.goldSlider:SetObeyStepOnDrag(true);

    -- UI New Game Function
    UI.finishRoll = CreateFrame("Button", nil, UI, "GameMenuButtonTemplate");
    UI.finishRoll:SetPoint("CENTER", UI, "TOP", 0, -130);
    UI.finishRoll:SetSize(110, 30);
    UI.finishRoll:SetText("Finish Roll");
    UI.finishRoll:SetNormalFontObject("GameFontNormal");
    UI.finishRoll:SetHighlightFontObject("GameFontHighlight");

    UI.finishRoll:SetScript("OnClick", finishRoll); 
    
    -- Assuming UI.goldSlider is already created
    UI.goldSlider.text = UI.goldSlider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    UI.goldSlider.text:SetPoint("TOP", UI.goldSlider, "BOTTOM", 0, -5)  -- Adjust the position as needed

    -- Set initial text
    UI.goldSlider.text:SetText(string.format("%dg", UI.goldSlider:GetValue()))
    
    UI.goldSlider:SetScript("OnValueChanged", function(self, value)
        self.text:SetText(string.format("%dg", math.floor(value)))  -- Update the text display
        -- Store the value
        -- Assuming you have a table for your addon's data
        session.wager = math.floor(value)
    end)

    UI:Hide();
    return UI;
end

--[[Initializes all of the /slash commands to be used in the app
    Loads on the event "ADDON_LOADED"
    Adds 2 convenience functions: 
    /fa - for frame stack access 
    /rl - shortened /reload
]]

-------------------------
-- Slash Commands
-------------------------

gambling.commands = {
    menu = gambling.UI.Toggle,
    help = function() 
        gambling:Print("List of all slash commands:")
        gambling:Print("|cff00cc66/gamba help|r - Shows all commands")
        gambling:Print("|cff00cc66/gamba menu|r - Opens the gambling menu")
    end,
};

local function HandleSlashCommands(str)
    if (#str == 0) then
        gambling.commands.help();
    end
    
    local args = {};
    for _, arg in pairs({string.split(' ', str)}) do 
        if (#arg > 0) then
            table.insert(args, arg);
        end
    end
    
    local path = gambling.commands;
    
    for id, arg in ipairs(args) do 
        arg = string.lower(arg);
        
        if (path[arg]) then 
            if (type(path[arg]) == "function") then 
                path[arg](select(id + 1, unpack(args)));
                return;
        elseif (type(path[arg]) == "table") then
            path = path[arg]; 
        else 
            gambling.commands.help();
            return;
        end
    end
end
end

function gambling:Print(...)
    local hex = select(4, self.UI:GetThemeColor());
    local prefix = string.format("|cff%s%s|r", hex:upper(), "MommaG's Casino")
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, tostringall(...)));
end

-- Self automatically becomes events frame!
function gambling:init(event, name)
    if (addonName ~= "Gambling") then return end
    
    -- Register Slash Commands!
    SLASH_RELOADUI1 = "/rl" -- reload UI shortened from /reload
    SlashCmdList.RELOADUI = ReloadUI;
    SLASH_FRAMESTK1 = "/fa" -- access to the frame stack
    SlashCmdList.FRAMESTK = function()
        LoadAddOn('Blizzard_DebugTools')
        FrameStackTooltip_Toggle()
    end

    SLASH_Gamba1 = "/gamba" -- main entry point into addon
    SlashCmdList.Gamba = HandleSlashCommands;
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", gambling.init);