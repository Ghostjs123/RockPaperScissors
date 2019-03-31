rps_IncomingChallenges = {}
rps_OutgoingChallenges = {}
rps_SpecialChallenge = {}

SlashCmdList["SLASH_RockPaperScissors"] = function() end

SLASH_ROCKPAPERSCISSORS1, SLASH_ROCKPAPERSCISSORS2 = "/rps", "/rockpaperscissors"
function SlashCmdList.ROCKPAPERSCISSORS(args)

    local selection, name

    if string.find(args, "rock") then
        selection = "rock"
    elseif string.find(args, "paper") then
        selection = "paper"
    elseif string.find(args, "scissors") then
        selection = "scissors"
    end

    local temp = split(args, " ")
    if(type(temp) == "string") then
        temp = {temp} -- need it to be a table, even if just one value
    end

    if table.getn(temp) > 1 then
        name = temp[2]
    else
        DEFAULT_CHAT_FRAME:AddMessage("Incorrect format: /rps (choice) (name) or /rps (name) (name)")
    end

    if selection ~= nil and name ~= nil then
        for id, tab in rps_IncomingChallenges do
            if tab.name == name then
                SendChatMessage(selection, "WHISPER", GetDefaultLanguage("player"), tab.name)
                table.remove(rps_IncomingChallenges, id)
                return
            end
        end

        local tab = {}
        tab.name = name
        tab.selection = selection
        table.insert(rps_OutgoingChallenges, tab)
        SendChatMessage("I challenge you to rock paper scissors, whisper me your choice", "WHISPER", GetDefaultLanguage("player"), tab.name)
    elseif name ~= nil then -- we have 2 arguments in temp so try to setup a match btwn them
        local tab = {}
        tab.name1 = temp[1]
        tab.name2 = temp[2]
        tab.selection1 = ""
        tab.selection2 = ""
        rps_SpecialChallenge = tab
        SendChatMessage("RPS between " .. temp[1] .. " and " .. temp[2] .. " whisper me your choice", "RAID")
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
    elseif msg == "rock" or msg == "paper" or msg == "scissors" then
        rps_HandleSelectionMsg(msg, author)
    end
end

function rps_HandlePartyMsg(msg, author)
    if msg == "rock" or msg == "paper" or msg == "scissors" then
        rps_HandleSelectionMsg(msg, author)
    end
end

function rps_HandleRaidMsg(msg, author)
    if msg == "rock" or msg == "paper" or msg == "scissors" then
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
    if rps_SpecialChallenge.name1 == author or rps_SpecialChallenge.name2 == author then
        if rps_SpecialChallenge.name1 == author then
            rps_SpecialChallenge.selection1 = msg
        else
            rps_SpecialChallenge.selection2 = msg
        end
        if rps_SpecialChallenge.selection1 ~= nil and rps_SpecialChallenge.selection1 ~= "" and rps_SpecialChallenge.selection2 ~= nil and rps_SpecialChallenge.selection2 ~= "" then
            local winner = rps_GetSpecialWinOrLoss(rps_SpecialChallenge.name1, rps_SpecialChallenge.selection1, rps_SpecialChallenge.name2, rps_SpecialChallenge.selection2)
            if winner == "tie" then
                SendChatMessage(rps_SpecialChallenge.name1 .. " and " .. rps_SpecialChallenge.name2 .. " tied with " .. rps_SpecialChallenge.selection1, "RAID")
            else
                SendChatMessage(rps_SpecialChallenge.name1 .. " chose " .. rps_SpecialChallenge.selection1 .. " and " .. rps_SpecialChallenge.name2 .. " chose " .. rps_SpecialChallenge.selection2 .. ", " .. winner .. " wins", "RAID")
            end
            rps_SpecialChallenge = {}
        end
    else
        for id, tab in rps_OutgoingChallenges do
            if tab.name == author then
                SendChatMessage(tab.selection .. rps_GetWinOrLoss(msg, tab.selection), "WHISPER", GetDefaultLanguage("player"), tab.name)
                table.remove(rps_OutgoingChallenges, id)
                return
            end
        end
    end
end

function rps_GetWinOrLoss(opponentMsg, mySelection)
    local opponenetSelection
    if string.find(opponentMsg, "rock") then
        opponenetSelection = "rock"
    elseif string.find(opponentMsg, "paper") then
        opponenetSelection = "paper"
    elseif string.find(opponentMsg, "scissors") then
        opponenetSelection = "scissors"
    end

    -- ties
    if opponenetSelection == "rock" and mySelection == "rock" then
        return ", tie"
    elseif opponenetSelection == "paper" and mySelection == "paper" then
        return ", tie"
    elseif opponenetSelection == "scissors" and mySelection == "scissors" then
        return ", tie"
    -- i win
    elseif opponenetSelection == "rock" and mySelection == "paper" then
        return ", I win"
    elseif opponenetSelection == "paper" and mySelection == "scissors" then
        return ", I win"
    elseif opponenetSelection == "scissors" and mySelection == "rock" then
        return ", I win"
    -- i lose
    else
        return ", I lose"
    end
end

function rps_GetSpecialWinOrLoss(name1, selection1, name2, selection2)
    if selection1 == "rock" and selection2 == "rock" then
        return "tie"
    elseif selection1 == "paper" and selection2 == "paper" then
        return "tie"
    elseif selection1 == "scissors" and selection2 == "scissors" then
        return "tie"
    elseif selection1 == "rock" and selection2 == "paper" then
        return name2
    elseif selection1 == "paper" and selection2 == "scissors" then
        return name2
    elseif selection1 == "scissors" and selection2 == "rock" then
        return name2
    else
        return name1
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
    DEFAULT_CHAT_FRAME:AddMessage("rps_IncomingChallenges:")
    rps_tprint(rps_IncomingChallenges)
    DEFAULT_CHAT_FRAME:AddMessage("rps_OutgoingChallenges:")
    rps_tprint(rps_OutgoingChallenges)
    DEFAULT_CHAT_FRAME:AddMessage("rps_SpecialChallenge:")
    rps_tprint(rps_SpecialChallenge)
    DEFAULT_CHAT_FRAME:AddMessage("rps_test() end")
end