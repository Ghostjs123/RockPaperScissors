rps_IncomingChallenges = {}
rps_OutgoingChallenges = {}
rps_SpecialChallenge = {}

SlashCmdList["SLASH_RockPaperScissors"] = function() end

SLASH_ROCKPAPERSCISSORS1, SLASH_ROCKPAPERSCISSORS2 = "/rps", "/rockpaperscissors"
function SlashCmdList.ROCKPAPERSCISSORS(args)
    local selection, name
    if string.find(args, "rock") then
        selection = "Rock"
    elseif string.find(args, "paper") then
        selection = "Paper"
    elseif string.find(args, "scissors") then
        selection = "Scissors"
    else
        DEFAULT_CHAT_FRAME:AddMessage("Incorrect format: /rps (choice) (name)")
        DEFAULT_CHAT_FRAME:AddMessage("Choices are: rock, paper, scissors")
    end

    local temp = split(args, " ")

    if(type(temp) == "string") then
        temp = {temp} -- need it to be a table, even if just one value
    end

    if table.getn(temp) > 1 then
        name = temp[2]
    elseif rps_SpecialChallenge.name ~= nil and selection ~= nil then
        rps_SpecialChallenge.selection = selection
        SendChatMessage("I've locked in", "WHISPER", GetDefaultLanguage("player"), rps_SpecialChallenge.name)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Incorrect format: missing name")
    end

    if selection ~= nil and name ~= nil then
        for id, tab in rps_IncomingChallenges do
            if tab.name == name then
                local chatType = rps_GetChatType(tab.name)
                if chatType == "WHISPER" then
                    SendChatMessage(selection, chatType, GetDefaultLanguage("player"), tab.name)
                else
                    SendChatMessage(selection, chatType)
                end
                table.remove(rps_IncomingChallenges, id)
                return
            end
        end

        local tab = {}
        tab.name = name
        tab.selection = selection
        table.insert(rps_OutgoingChallenges, tab)
        local chatType = rps_GetChatType(tab.name)
        if chatType == "WHISPER" then
            SendChatMessage("I challenge you to rock paper scissors", chatType, GetDefaultLanguage("player"), tab.name)
        else
            SendChatMessage("I challenge you to rock paper scissors", chatType)
        end
    elseif name ~= nil then -- we have 2 arguments in temp so try to setup a match btwn them
        if UnitInRaid("player") and rps_NameInRaid(temp[1] and rps_NameInRaid(temp[2])) then
            SendChatMessage("Rock paper scissors between " .. temp[1] .. " and " .. temp[2])
        end
    end
end

function RockPaperScissors_OnLoad()
    this:RegisterEvent("CHAT_MSG_WHISPER")
    this:RegisterEvent("CHAT_MSG_PARTY")
    this:RegisterEvent("CHAT_MSG_RAID")
    this:RegisterEvent("CHAT_MSG_RAID_LEADER")
end

-- arg1 is msg, arg2 is author
function RockPaperScissors_OnEvent(event, arg1, arg2)
    if(event == "CHAT_MSG_WHISPER") then
        rps_HandleWhisperMsg(arg1, arg2)
    elseif(event == "CHAT_MSG_PARTY") then
        rps_HandlePartyMsg(arg1, arg2)
    elseif(event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
        rps_HandleRaidMsg(arg1, arg2)
    end
end

function rps_HandleWhisperMsg(msg, author)
    if string.find(msg, "I challenge you to rock paper scissors") then
        local challengedAlreadyPresent = false
        for _, tab in rps_IncomingChallenges do
            if tab.name == author then
                challengedAlreadyPresent = true
            end
        end
        if not challengedAlreadyPresent then
            local tab = {}
            tab.name = author
            tab.selection = ""
            table.insert(rps_IncomingChallenges, tab)
        end
    elseif string.find("I've locked in") then
        if rps_SpecialChallenge.selection ~= "" and rps_SpecialChallenge.selection ~= nil then
            SendChatMessage(rps_SpecialChallenge.selection, "RAID")
        end
    elseif string.find(msg, "Rock") or string.find(msg, "Paper") or string.find(msg, "Scissors") then
        rps_HandleSelectionMsg(msg, author)
    end
end

function rps_HandlePartyMsg(msg, author)
    local isSelection = string.find(msg, "Rock") or string.find(msg, "Paper") or string.find(msg, "Scissors")
    if isSelection then
        rps_HandleSelectionMsg(msg, author)
    end
end

function rps_HandleRaidMsg(msg, author)
    local isSelection = string.find(msg, "Rock") or string.find(msg, "Paper") or string.find(msg, "Scissors")
    if isSelection then
        rps_HandleSelectionMsg(msg, author)
    elseif string.find(msg, "Rock paper scissors between") then
        local temp = split(msg, " ")
        local name1 = temp[5]
        local name2 = temp[7]
        if name1 == UnitName("player") then
            local tab = {}
            tab.name = name2
            tab.selection = ""
            rps_SpecialChallenge = tab
        elseif name2 == UnitName("player") then
            local tab = {}
            tab.name = name2
            tab.selection = ""
            rps_SpecialChallenge = tab
        end
    end
end

function rps_HandleSelectionMsg(msg, author)
    if rps_SpecialChallenge.name == author then
        SendChatMessage(rps_SpecialChallenge.selection .. rps_GetWinOrLoss(msg, rps_SpecialChallenge.selection), "RAID")
        rps_SpecialChallenge = {}
    else
        for id, tab in rps_OutgoingChallenges do
            if tab.name == author then
                local chatType = rps_GetChatType(tab.name)
                if chatType == "WHISPER" then
                    SendChatMessage(tab.selection .. rps_GetWinOrLoss(msg, tab.selection), chatType, GetDefaultLanguage("player"), tab.name)
                else
                    SendChatMessage(tab.selection .. rps_GetWinOrLoss(msg, tab.selection), chatType)
                end
                table.remove(rps_OutgoingChallenges, id)
                return
            end
        end
    end
end

function rps_GetWinOrLoss(opponentMsg, mySelection)
    local opponenetSelection
    if string.find(opponentMsg, "rock") then
        opponenetSelection = "Rock"
    elseif string.find(opponentMsg, "paper") then
        opponenetSelection = "Paper"
    elseif string.find(opponentMsg, "scissors") then
        opponenetSelection = "Scissors"
    end

    -- ties
    if opponenetSelection == "Rock" and mySelection == "Rock" then
        return ", tie"
    elseif opponenetSelection == "Paper" and mySelection == "Paper" then
        return ", tie"
    elseif opponenetSelection == "Scissors" and mySelection == "Scissors" then
        return ", tie"
    -- i win
    elseif opponenetSelection == "Rock" and mySelection == "Paper" then
        return ", I lose"
    elseif opponenetSelection == "Paper" and mySelection == "Scissors" then
        return ", I lose"
    elseif opponenetSelection == "Scissors" and mySelection == "Rock" then
        return ", I lose"
    -- i lose
    else
        return ", I win"
    end
end

function rps_GetChatType(playerName)
    if UnitInRaid("player") then
        if rps_NameInRaid(playerName) then
            return "RAID"
        end
    elseif UnitInParty("player") then
        -- todo find a way to check for the player in a party
        for i = 1, GetNumPartyMembers() do

        end
    end
    return "WHISPER"
end

function rps_NameInRaid(playerName)
    local name
    for i = 1, GetNumRaidMembers() do
        name = GetRaidRosterInfo(i)
        if name == playerName then
            return true
        end
    end
end

function split(s, delimiter)
    local result = {}
    for match in string.gmatch(s..delimiter, "(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

-- credit Sol
string.gmatch = string.gmatch or function(str, pattern)
    local init = 0

    return function()
        local tbl = { string.find(str, pattern, init) }

        local start_pos = tbl[1]
        local end_pos = tbl[2]

        if start_pos then
            init = end_pos + 1

            if tbl[3] then
                return unpack({select(3, unpack(tbl))})
            else
                return string.sub(str, start_pos, end_pos)
            end
        end
    end
end

function rps_tprint(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            DEFAULT_CHAT_FRAME:AddMessage(formatting)
            rps_tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            DEFAULT_CHAT_FRAME:AddMessage(formatting .. tostring(v))
        else
            DEFAULT_CHAT_FRAME:AddMessage(formatting .. v)
        end
    end
end

function rps_test()
    DEFAULT_CHAT_FRAME:AddMessage("rps_test() start")
    rps_tprint(rps_IncomingChallenges)
    rps_tprint(rps_OutgoingChallenges)
    DEFAULT_CHAT_FRAME:AddMessage("rps_test() end")
end