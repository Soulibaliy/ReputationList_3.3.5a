ReputationList = ReputationList or {}
local RL = ReputationList
local L = RL.L or ReputationListLocale or {}

if not RL.GetRealmData or not RL.TimerManager then
    return
end

RL.OnlineToast = RL.OnlineToast or {}
local OT = RL.OnlineToast

local function EnsureDefaults()
    ReputationListDB = ReputationListDB or {}
    ReputationListDB.onlineToast = ReputationListDB.onlineToast or {
        enabled = false, 
        interval = 4, 
        watchBlacklist = true,
        watchWhitelist = true,
        watchNotelist = false,
        sound = true,
    }
    return ReputationListDB.onlineToast
end

local CFG = EnsureDefaults()
if RL.Initialize then
    hooksecurefunc(RL, "Initialize", function()
        CFG = EnsureDefaults()
    end)
end

local onlineState = {}      
local missCount = {}        
local REQUIRED_MISSES = 3   
                              
                              
local nameQueue = {}         
local queuePos = 1
local pendingQuery = nil     
local pendingQueryMatched = false 
local PENDING_TIMEOUT = 10   
local WATCH_LIST_TYPES = { "blacklist", "whitelist", "notelist" }

local function RebuildQueue()
    local oldCount = #nameQueue
    queuePos = 1

    local realmData = RL:GetRealmData()
    if not realmData then
        for i = oldCount, 1, -1 do nameQueue[i] = nil end
        return
    end

    local writeIndex = 1
    for i = 1, 3 do
        local listType = WATCH_LIST_TYPES[i]
        local enabled = (listType == "blacklist" and CFG.watchBlacklist)
            or (listType == "whitelist" and CFG.watchWhitelist)
            or (listType == "notelist" and CFG.watchNotelist)
        local list = enabled and realmData[listType]
        if list then
            for key, entry in pairs(list) do
                local cleanName = RL.NormalizeName and RL.NormalizeName(entry.name) or entry.name
                local queued = nameQueue[writeIndex]
                if not queued then queued = {}; nameQueue[writeIndex] = queued end
                queued.key, queued.name, queued.listType = key, cleanName, listType
                writeIndex = writeIndex + 1
            end
        end
    end
    for i = oldCount, writeIndex, -1 do nameQueue[i] = nil end
end


local activeToasts = {}
local freeToastPool = {}    
local TOAST_WIDTH = 260
local TOAST_HEIGHT = 56
local TOAST_LIFETIME = 6 
local MAX_POOL_SIZE = 20  


local TOAST_TEXT_WIDTH = TOAST_WIDTH - 32 - 10 - 8 - 14

local function TruncateToFit(fontString, text, maxWidth)
    fontString:SetText(text)
    if fontString:GetStringWidth() <= maxWidth then
        return text
    end
    local lo, hi = 0, text:len()
    while lo < hi do
        local mid = lo + math.ceil((hi - lo) / 2)
        fontString:SetText(text:sub(1, mid) .. "...")
        if fontString:GetStringWidth() <= maxWidth then
            lo = mid
        else
            hi = mid - 1
        end
    end
    local result = text:sub(1, lo) .. "..."
    fontString:SetText(result)
    return result
end

local function TruncateNoteToFit(fontString, label, note, maxWidth)
    if not note or note == "" then
        fontString:SetText(label)
        return label
    end
    local prefix = " - "
    fontString:SetText(label .. prefix .. note)
    if fontString:GetStringWidth() <= maxWidth then
        return label .. prefix .. note
    end
    local lo, hi = 0, note:len()
    while lo < hi do
        local mid = lo + math.ceil((hi - lo) / 2)
        fontString:SetText(label .. prefix .. note:sub(1, mid) .. "...")
        if fontString:GetStringWidth() <= maxWidth then
            lo = mid
        else
            hi = mid - 1
        end
    end
    if lo <= 0 then
        fontString:SetText(label)
        return label
    end
    local result = label .. prefix .. note:sub(1, lo) .. "..."
    fontString:SetText(result)
    return result
end

local ADDON_FOLDER = "reputation"
local function Icon(name)
    return "Interface\\AddOns\\" .. ADDON_FOLDER .. "\\textures\\" .. name
end

local FALLBACK_ICONS = {
    blacklist = Icon("skull_icon.tga"),
    whitelist = Icon("hands_icon.tga"),
    notelist  = Icon("notelist_icon.tga"),
}

local function RepositionToasts()
    local yOffset = 100
    for _, toast in ipairs(activeToasts) do
        if toast:IsShown() then
            toast:ClearAllPoints()
            toast:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, yOffset)
            yOffset = yOffset + TOAST_HEIGHT + 8
        end
    end
end

local function RemoveToast(toast)
    for i, t in ipairs(activeToasts) do
        if t == toast then
            table.remove(activeToasts, i)
            break
        end
    end
    toast:Hide()
    toast.playerName = nil
    toast.playerData = nil

    if #freeToastPool < MAX_POOL_SIZE then
        table.insert(freeToastPool, toast)
    end
    RepositionToasts()
end


local PAL3 = {
    bg2    = {0.106, 0.106, 0.106, 1},
    bronze = {0.482, 0.353, 0.169, 1},
    gold   = {0.827, 0.651, 0.227, 1},
    text   = {0.941, 0.847, 0.627, 1},
    red    = {0.86, 0.27, 0.27, 1},
    green  = {0.35, 0.75, 0.35, 1},
}

local function CreateToastFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    f:SetFrameStrata("HIGH")
    if RL.FixElvUIScale then RL.FixElvUIScale(f) end
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    f:SetBackdropColor(PAL3.bg2[1], PAL3.bg2[2], PAL3.bg2[3], 0.95)
    f:SetBackdropBorderColor(PAL3.bronze[1], PAL3.bronze[2], PAL3.bronze[3], 1)
    f:EnableMouse(true)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(32, 32)
    f.icon:SetPoint("LEFT", 10, 0)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 8, -2)
    f.title:SetWidth(TOAST_TEXT_WIDTH)
    f.title:SetWordWrap(false)
    f.title:SetJustifyH("LEFT")
    f.title:SetTextColor(PAL3.gold[1], PAL3.gold[2], PAL3.gold[3])

    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -4)
    f.subtitle:SetWidth(TOAST_TEXT_WIDTH)
    f.subtitle:SetWordWrap(false)
    f.subtitle:SetJustifyH("LEFT")
    f.subtitle:SetTextColor(PAL3.text[1], PAL3.text[2], PAL3.text[3])

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() RemoveToast(f) end)
    local closeNT = closeBtn:GetNormalTexture()
    if closeNT then closeNT:SetVertexColor(PAL3.gold[1], PAL3.gold[2], PAL3.gold[3]) end
    f.closeBtn = closeBtn

    f:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and f.playerName then
            if RL.ShowPlayerCard and f.playerData then
                RL:ShowPlayerCard(f.playerName, f.playerData, true)
            end
            RemoveToast(f)
        end
    end)

    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, delta)
        self.elapsed = self.elapsed + delta
        if self.elapsed >= TOAST_LIFETIME then
            RemoveToast(self)
        end
    end)

    return f
end

local function AcquireToastFrame()
    local f = table.remove(freeToastPool)
    if not f then
        f = CreateToastFrame()
    end
    f.elapsed = 0
    return f
end

local function ShowToast(playerName, playerData, listType)

    local ok, err = pcall(function()
        local f = AcquireToastFrame()

        local icon = FALLBACK_ICONS[listType] or FALLBACK_ICONS.whitelist
        f.icon:SetTexture(icon)

        local listLabel = listType == "blacklist" and string.format("|cFF%02x%02x%02xBlacklist|r", PAL3.red[1]*255, PAL3.red[2]*255, PAL3.red[3]*255)
            or listType == "whitelist" and string.format("|cFF%02x%02x%02xWhitelist|r", PAL3.green[1]*255, PAL3.green[2]*255, PAL3.green[3]*255)
            or string.format("|cFF%02x%02x%02xNotelist|r", PAL3.gold[1]*255, PAL3.gold[2]*255, PAL3.gold[3]*255)

        TruncateToFit(f.title, string.format(L["ONLINE_TITLE"], playerName), TOAST_TEXT_WIDTH)
        TruncateNoteToFit(f.subtitle, listLabel, playerData and playerData.note, TOAST_TEXT_WIDTH)

        f.playerName = playerName
        f.playerData = playerData

        table.insert(activeToasts, f)
        f:Show()
        RepositionToasts()

        if CFG.sound then
            PlaySound("igQuestLogOpen")
        end
    end)

    if not ok then
        print("|cFFFF0000[ReputationList]|r " .. string.format(L["ONLINE_SHOW_ERROR"], tostring(err)))
    end
end


local suppressUntil = 0

local function SystemMessageFilter(self, event, msg, ...)
    if GetTime() < suppressUntil then

        if pendingQuery and msg then
            local targetFolded = RL.FoldCaseRU and RL.FoldCaseRU(pendingQuery.name) or pendingQuery.name:lower()
            local msgFolded = RL.FoldCaseRU and RL.FoldCaseRU(msg) or msg:lower()
            if msgFolded:find(targetFolded, 1, true) then
                pendingQueryMatched = true
                local key = pendingQuery.key
                missCount[key] = 0
                if not onlineState[key] then
                    local realmData = RL:GetRealmData()
                    local entry = realmData and realmData[pendingQuery.listType] and realmData[pendingQuery.listType][key]
                    ShowToast(pendingQuery.name, entry or { name = pendingQuery.name }, pendingQuery.listType)
                end
                onlineState[key] = true
            end
        end
        return true 
    end
    return false
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)


local function FinalizePendingQuery()

    if pendingQuery then
        local key = pendingQuery.key
        if pendingQueryMatched then
            missCount[key] = 0
        else
            missCount[key] = (missCount[key] or 0) + 1
            if missCount[key] >= REQUIRED_MISSES then
                onlineState[key] = false
                missCount[key] = 0
            end
        end
    end
    pendingQuery = nil
    pendingQueryMatched = false
end

local function Tick()
    if not CFG.enabled then return end

    if pendingQuery then
        local elapsed = GetTime() - (pendingQuery.sentAt or 0)

        if elapsed < PENDING_TIMEOUT and GetTime() < suppressUntil then
            return
        end
        FinalizePendingQuery()
    end

    if #nameQueue == 0 then
        RebuildQueue()
        if #nameQueue == 0 then return end
    end

    if queuePos > #nameQueue then
        RebuildQueue() 
        if #nameQueue == 0 then return end
    end

    local entry = nameQueue[queuePos]
    queuePos = queuePos + 1

    if entry and entry.name then
        pendingQuery = entry
        pendingQuery.sentAt = GetTime()
        pendingQueryMatched = false
        suppressUntil = GetTime() + 3 
        SendWho(entry.name)
    end
end

RL.TimerManager:Register("RL_OnlineToastTick", CFG.interval or 4, Tick)

SLASH_RLTOAST1 = "/rltoast"
SlashCmdList["RLTOAST"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "on" then
        CFG.enabled = true
        RebuildQueue()
        print("|cFF00FF00[ReputationList]|r Уведомления \"игрок в сети\" включены. Проверяю " .. #nameQueue .. " игроков.")
    elseif msg == "off" then
        CFG.enabled = false
        print("|cFF00FF00[ReputationList]|r Уведомления \"игрок в сети\" выключены.")
    elseif msg:match("^interval%s+%d+$") then
        local v = tonumber(msg:match("%d+"))
        CFG.interval = math.max(3, v)
        RL.TimerManager:Unregister("RL_OnlineToastTick")
        RL.TimerManager:Register("RL_OnlineToastTick", CFG.interval, Tick)
        print("|cFF00FF00[ReputationList]|r Интервал проверки: " .. CFG.interval .. " сек.")
    elseif msg == "blacklist" then
        CFG.watchBlacklist = not CFG.watchBlacklist
        print("|cFF00FF00[ReputationList]|r Отслеживание Blacklist: " .. (CFG.watchBlacklist and "вкл" or "выкл"))
    elseif msg == "whitelist" then
        CFG.watchWhitelist = not CFG.watchWhitelist
        print("|cFF00FF00[ReputationList]|r Отслеживание Whitelist: " .. (CFG.watchWhitelist and "вкл" or "выкл"))
    elseif msg == "notelist" then
        CFG.watchNotelist = not CFG.watchNotelist
        print("|cFF00FF00[ReputationList]|r Отслеживание Notelist: " .. (CFG.watchNotelist and "вкл" or "выкл"))
    elseif msg == "sound" then
        CFG.sound = not CFG.sound
        print("|cFF00FF00[ReputationList]|r Звук уведомлений: " .. (CFG.sound and "вкл" or "выкл"))
    elseif msg == "test" then
        ShowToast(UnitName("player") or "Тест", { note = "Тестовое уведомление" }, "whitelist")
    elseif msg == "reset" then
        onlineState = {}
        print("|cFF00FF00[ReputationList]|r Статус \"онлайн\" сброшен для всех игроков - следующее обнаружение снова покажет уведомление.")
    elseif msg == "debug" then
        print("|cFF00FF00[ReputationList]|r Онлайн-тост: enabled=" .. tostring(CFG.enabled)
            .. ", очередь=" .. #nameQueue .. ", позиция=" .. queuePos
            .. ", ожидание ответа=" .. tostring(pendingQuery ~= nil))
        if pendingQuery then
            print("  Ждём ответ по игроку: " .. pendingQuery.name .. " (запрос отправлен " .. math.floor(GetTime() - (pendingQuery.sentAt or 0)) .. " сек назад, совпадение в чате: " .. tostring(pendingQueryMatched) .. ")")
        end
    else
        print("|cFF00FF00[ReputationList]|r Уведомления \"игрок в сети\":")
        print("  /rltoast on|off - включить/выключить (использует /who, раз в " .. (CFG.interval or 4) .. " сек)")
        print("  /rltoast interval <сек> - интервал проверки (мин. 5)")
        print("  /rltoast blacklist|whitelist|notelist - переключить отслеживаемые списки")
        print("  /rltoast sound - переключить звук")
        print("  /rltoast test - показать тестовое уведомление")
        print("  /rltoast reset - сбросить сохранённый статус \"онлайн\" (для повторного теста)")
        print("  /rltoast debug - показать состояние очереди /who")
    end
end
