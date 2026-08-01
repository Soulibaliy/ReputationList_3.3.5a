
ReputationList = ReputationList or {}
local RL = ReputationList
local L = RL.L or ReputationListLocale or {}

if not RL.SanitizeString then
    return 
end

RL.WordFilter = RL.WordFilter or {}
local WF = RL.WordFilter

local function EnsureDefaults()
    ReputationListDB = ReputationListDB or {}
    ReputationListDB.wordFilter = ReputationListDB.wordFilter or {
        enabled = true,
        caseSensitive = false,
        filterMode = "hide",
        phrases = {},
        channels = {
            SAY = true,
            YELL = true,
            CHANNEL = true,
            WHISPER = true,
            PARTY = true,
            PARTY_LEADER = true,
            RAID = true,
            RAID_LEADER = true,
            GUILD = false,
            EMOTE = false,
            TEXT_EMOTE = false,
        },
    }

    ReputationListDB.wordFilter.filterMode = ReputationListDB.wordFilter.filterMode or "hide"
    return ReputationListDB.wordFilter
end

local RebuildFoldedCache

local CFG = EnsureDefaults()
if RL.Initialize then
    hooksecurefunc(RL, "Initialize", function()
        CFG = EnsureDefaults()
        if RebuildFoldedCache then RebuildFoldedCache() end
    end)
end

local function FoldCase(str)
    return RL.FoldCaseRU and RL.FoldCaseRU(str) or (str and str:lower())
end

local foldedPhraseCache = {}

RebuildFoldedCache = function()
    for i = #foldedPhraseCache, 1, -1 do foldedPhraseCache[i] = nil end
    for i, phrase in ipairs(CFG.phrases) do
        foldedPhraseCache[i] = FoldCase(phrase)
    end
end

function WF:AddPhrase(phrase)
    phrase = RL.SanitizeString(phrase or "", 100)
    phrase = phrase:gsub("^%s+", ""):gsub("%s+$", "")
    if phrase == "" then
        print("|cFFFF0000[ReputationList]|r Пустая фраза.")
        return false
    end

    local folded = FoldCase(phrase)
    for _, existing in ipairs(CFG.phrases) do
        if FoldCase(existing) == folded then
            print("|cFFFFAA00[ReputationList]|r Фраза '" .. phrase .. "' уже в списке фильтра.")
            return false
        end
    end

    table.insert(CFG.phrases, phrase)
    RebuildFoldedCache()
    print("|cFF00FF00[ReputationList]|r Фраза '" .. phrase .. "' добавлена в фильтр чата.")
    return true
end

function WF:RemovePhrase(phrase)
    local folded = FoldCase(phrase)
    for i, existing in ipairs(CFG.phrases) do
        if FoldCase(existing) == folded then
            table.remove(CFG.phrases, i)
            RebuildFoldedCache()
            print("|cFF00FF00[ReputationList]|r Фраза '" .. existing .. "' удалена из фильтра чата.")
            return true
        end
    end
    print("|cFFFFAA00[ReputationList]|r Фраза '" .. phrase .. "' не найдена в фильтре.")
    return false
end

function WF:ClearPhrases()
    CFG.phrases = {}
    RebuildFoldedCache()
    print("|cFF00FF00[ReputationList]|r Список фраз фильтра очищен.")
end

function WF:List()
    return CFG.phrases
end

function WF:MessageMatches(msg)
    if not msg or msg == "" then return false end
    if #CFG.phrases == 0 then return false end

    local haystack = CFG.caseSensitive and msg or FoldCase(msg)

    for i, phrase in ipairs(CFG.phrases) do
        local needle = CFG.caseSensitive and phrase or foldedPhraseCache[i]
        if needle and needle ~= "" and haystack:find(needle, 1, true) then
            return true, phrase
        end
    end
    return false
end


local EVENT_TO_CHANNEL_KEY = {
    CHAT_MSG_SAY = "SAY",
    CHAT_MSG_YELL = "YELL",
    CHAT_MSG_CHANNEL = "CHANNEL",
    CHAT_MSG_WHISPER = "WHISPER",
    CHAT_MSG_PARTY = "PARTY",
    CHAT_MSG_PARTY_LEADER = "PARTY_LEADER",
    CHAT_MSG_RAID = "RAID",
    CHAT_MSG_RAID_LEADER = "RAID_LEADER",
    CHAT_MSG_GUILD = "GUILD",
    CHAT_MSG_EMOTE = "EMOTE",
    CHAT_MSG_TEXT_EMOTE = "TEXT_EMOTE",
}

local function WordFilterCallback(self, event, msg, ...)
    if not CFG.enabled then return false end

    local channelKey = EVENT_TO_CHANNEL_KEY[event]
    if channelKey and not CFG.channels[channelKey] then
        return false 
    end

    local matches = WF:MessageMatches(msg)

    if CFG.filterMode == "showonly" then
        if #CFG.phrases == 0 then return false end
        return not matches 
    end

    return matches and true or false
end

for event in pairs(EVENT_TO_CHANNEL_KEY) do
    ChatFrame_AddMessageEventFilter(event, WordFilterCallback)
end

local managerFrame

local function RefreshManagerList()
    if not managerFrame then return end
    local scrollChild = managerFrame.scrollChild

    managerFrame.rows = managerFrame.rows or {}
    for i = 1, #managerFrame.rows do managerFrame.rows[i]:Hide() end

    local yOffset = 0
    for i, phrase in ipairs(CFG.phrases) do
        local line = managerFrame.rows[i]
        if not line then
            line = CreateFrame("Frame", nil, scrollChild)
            line:SetSize(300, 20)
            local fs = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", 0, 0)
            fs:SetWidth(230)
            fs:SetJustifyH("LEFT")
            line.text = fs

            local delBtn = CreateFrame("Button", nil, line, "UIPanelCloseButton")
            delBtn:SetSize(20, 20)
            delBtn:SetPoint("RIGHT", 0, 0)
            delBtn:SetScript("OnClick", function(self)
                local owner = self:GetParent()
                local currentPhrase = CFG.phrases[owner.phraseIndex]
                if currentPhrase then WF:RemovePhrase(currentPhrase) end
                RefreshManagerList()
            end)
            managerFrame.rows[i] = line
        end
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", 0, -yOffset)
        line.phraseIndex = i
        line.text:SetText(phrase)
        line:Show()

        yOffset = yOffset + 20
    end
    scrollChild:SetHeight(math.max(yOffset, 1))
    managerFrame.countText:SetText(string.format(L["WF_COUNT"], #CFG.phrases))
end

function WF:ShowManager()
    if managerFrame then
        managerFrame:Show()
        RefreshManagerList()
        return
    end

    local f = CreateFrame("Frame", "RepListWordFilterFrame", UIParent)
    f:SetSize(360, 450)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(L["WF_TITLE"])

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local enableCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    enableCb:SetPoint("TOPLEFT", 20, -45)
    enableCb:SetChecked(CFG.enabled)
    local enableText = enableCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    enableText:SetPoint("LEFT", enableCb, "RIGHT", 5, 0)
    enableText:SetText(L["V2_FILTER_ENABLED"])
    enableCb:SetScript("OnClick", function(self)
        CFG.enabled = self:GetChecked() and true or false
    end)

    local modeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    modeBtn:SetSize(230, 22)
    modeBtn:SetPoint("TOPLEFT", 20, -72)
    local function UpdateModeBtnText()
        if CFG.filterMode == "showonly" then
            modeBtn:SetText(L["WF_MODE_SHOW"])
        else
            modeBtn:SetText(L["WF_MODE_HIDE"])
        end
    end
    UpdateModeBtnText()
    modeBtn:SetScript("OnClick", function()
        CFG.filterMode = (CFG.filterMode == "showonly") and "hide" or "showonly"
        UpdateModeBtnText()
    end)

    local addBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    addBox:SetSize(240, 20)
    addBox:SetPoint("TOPLEFT", 25, -105)
    addBox:SetAutoFocus(false)
    addBox:SetScript("OnEnterPressed", function(self)
        if self:GetText() ~= "" then
            WF:AddPhrase(self:GetText())
            self:SetText("")
            RefreshManagerList()
        end
    end)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(70, 22)
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    addBtn:SetText(L["V2_ADD"])
    addBtn:SetScript("OnClick", function()
        if addBox:GetText() ~= "" then
            WF:AddPhrase(addBox:GetText())
            addBox:SetText("")
            RefreshManagerList()
        end
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "RepListWordFilterScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -140)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 80)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(300, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    local countText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countText:SetPoint("BOTTOMLEFT", 20, 50)
    f.countText = countText

    local chanLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chanLabel:SetPoint("BOTTOMLEFT", 20, 20)
    chanLabel:SetText(L["WF_CHANNEL_HINT"])
    chanLabel:SetTextColor(0.7, 0.7, 0.7)

    managerFrame = f
    RefreshManagerList()
end

SLASH_RLFILTER1 = "/rlfilter"
SlashCmdList["RLFILTER"] = function(msg)
    msg = msg or ""
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "show" then
        WF:ShowManager()
    elseif cmd == "add" and rest ~= "" then
        WF:AddPhrase(rest)
    elseif cmd == "remove" and rest ~= "" then
        WF:RemovePhrase(rest)
    elseif cmd == "list" then
        local phrases = WF:List()
        print("|cFF00FF00[ReputationList]|r Фразы фильтра чата (" .. #phrases .. "):")
        for i, p in ipairs(phrases) do
            print("  " .. i .. ". " .. p)
        end
    elseif cmd == "clear" then
        WF:ClearPhrases()
    elseif cmd == "on" then
        CFG.enabled = true
        print("|cFF00FF00[ReputationList]|r Фильтр чата по словам включён.")
    elseif cmd == "off" then
        CFG.enabled = false
        print("|cFF00FF00[ReputationList]|r Фильтр чата по словам выключен.")
    elseif cmd == "case" then
        CFG.caseSensitive = not CFG.caseSensitive
        print("|cFF00FF00[ReputationList]|r Учитывать регистр: " .. (CFG.caseSensitive and "да" or "нет"))
    elseif cmd == "mode" then
        CFG.filterMode = (CFG.filterMode == "showonly") and "hide" or "showonly"
        print("|cFF00FF00[ReputationList]|r Режим фильтра: " .. (CFG.filterMode == "showonly" and "показывать только совпадения" or "скрывать совпадения"))
    elseif cmd == "channel" then
        local chanName = rest:upper():gsub("%s+", "_")
        if CFG.channels[chanName] == nil then
            print("|cFFFF0000[ReputationList]|r Неизвестный канал. Доступные: SAY, YELL, CHANNEL, WHISPER, PARTY, PARTY_LEADER, RAID, RAID_LEADER, GUILD, EMOTE, TEXT_EMOTE")
        else
            CFG.channels[chanName] = not CFG.channels[chanName]
            print("|cFF00FF00[ReputationList]|r Канал " .. chanName .. ": " .. (CFG.channels[chanName] and "фильтруется" or "не фильтруется"))
        end
    elseif cmd == "test" then
        if rest == "" then
            print("|cFFFF0000[ReputationList]|r Использование: /rlfilter test <текст сообщения>")
        else
            local matched, phrase = WF:MessageMatches(rest)
            if CFG.filterMode == "showonly" then
                if matched then
                    print("|cFF00FF00[ReputationList]|r Сообщение было бы показано (совпадение с фразой '" .. phrase .. "').")
                else
                    print("|cFFFF0000[ReputationList]|r Сообщение было бы скрыто (нет совпадений, режим \"только совпадения\").")
                end
            else
                if matched then
                    print("|cFFFF0000[ReputationList]|r Сообщение было бы скрыто (совпадение с фразой '" .. phrase .. "').")
                else
                    print("|cFF00FF00[ReputationList]|r Сообщение не совпадает ни с одной фразой фильтра.")
                end
            end
        end
    else
        print("|cFF00FF00[ReputationList]|r Фильтр чата по словам/фразам (не зависит от автора сообщения):")
        print("  /rlfilter add <фраза> - добавить фразу")
        print("  /rlfilter remove <фраза> - удалить фразу")
        print("  /rlfilter list - показать все фразы")
        print("  /rlfilter clear - очистить список")
        print("  /rlfilter on|off - включить/выключить фильтр")
        print("  /rlfilter case - переключить учёт регистра")
        print("  /rlfilter mode - переключить режим: скрывать совпадения / показывать только совпадения")
        print("  /rlfilter channel <SAY|YELL|CHANNEL|WHISPER|PARTY|RAID|GUILD|EMOTE|...> - переключить канал")
        print("  /rlfilter test <текст> - проверить, сработает ли фильтр")
    end
end
