rps_IncomingChallenges = {}
rps_OutgoingChallenges = {}

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
    end

    if selection ~= nil then
        local temp = split(args, " ")

        if(type(temp) == "string") then
            temp = {temp} -- need it to be a table, even if just one value
        end

        if table.getn(temp) > 1 then
            name = temp[2]
        else
            DEFAULT_CHAT_FRAME:AddMessage("Incorrect format: missing name")
        end
    end

    if name ~= nil then
        for id, tab in rps_IncomingChallenges do
            if tab.name == name then
                local chatType = rps_GetChatType(tab.name)
                if chatType == "WHISPER" then
                    SendChatMessage(selection, chatType, tab.name)
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
    end
end

function RockPaperScissors_OnLoad()
    this:RegisterEvent("CHAT_MSG_WHISPER")
    this:RegisterEvent("CHAT_MSG_PARTY")
    this:RegisterEvent("CHAT_MSG_RAID")
end

-- arg1 is msg, arg2 is author
function RockPaperScissors_OnEvent(event, arg1, arg2)
    if(event == "CHAT_MSG_WHISPER") then
        rps_HandleWhisperMsg(arg1, arg2)
    elseif(event == "CHAT_MSG_PARTY") then
        rps_HandlePartyMsg(arg1, arg2)
    elseif(event == "CHAT_MSG_RAID") then
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
    else
        local isSelection = string.find(msg, "Rock") or string.find(msg, "Paper") or string.find(msg, "Scissors")
        if isSelection then
            rps_HandleSelectionMsg(msg, author)
        end
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
    end
end

function rps_HandleSelectionMsg(msg, author)
    for id, tab in rps_OutgoingChallenges do
        if tab.name == author then
            local chatType = rps_GetChatType(tab.name)
            if chatType == "WHISPER" then
                SendChatMessage(tab.selection .. rps_GetWinOrLoss(msg, tab.selection), chatType, tab.name)
            else
                SendChatMessage(tab.selection .. rps_GetWinOrLoss(msg, tab.selection), chatType)
            end
            table.remove(rps_OutgoingChallenges, id)
            return
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
        return ", I win"
    elseif opponenetSelection == "Paper" and mySelection == "Scissors" then
        return ", I win"
    elseif opponenetSelection == "Scissors" and mySelection == "Rock" then
        return ", I win"
    -- i lose
    else
        return ", I lose"
    end
end

function rps_GetChatType(playerName)
    if UnitInRaid("player") then
        local name
        for i = 1, GetNumRaidMembers() do
            name = GetRaidRosterInfo(i)
            if name == playerName then
                return "RAID"
            end
        end
    elseif UnitInParty("player") then
        -- todo find a way to check for the player in a party
        for i = 1, GetNumPartyMembers() do

        end
    end
    return "WHISPER"
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