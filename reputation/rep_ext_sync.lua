ReputationList = ReputationList or {}
local RL = ReputationList
local L = RL.L or ReputationListLocale or {}

if not RL.GetRealmData or not RL.Transfer then
    return
end

RL.Sync = RL.Sync or {}
local SYNC = RL.Sync

local PREFIX = "RepListSync"
local CHUNK_SIZE = 200
local TRANSFER_TIMEOUT = 45

local function EnsureDefaults()
    ReputationListDB = ReputationListDB or {}
    ReputationListDB.sync = ReputationListDB.sync or {
        autoAccept = false,
    }
    return ReputationListDB.sync
end

local CFG = EnsureDefaults()
if RL.Initialize then
    hooksecurefunc(RL, "Initialize", function()
        CFG = EnsureDefaults()
    end)
end


if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(PREFIX)
end

local outgoingTransfers = {}

local function GenerateTransferId()
    return tostring(math.random(100000, 999999)) .. tostring(math.floor(GetTime() * 10) % 1000)
end

local function SendBase64Payload(targetName, base64Str, extraInfo)
    local transferId = GenerateTransferId()
    local totalParts = math.ceil(#base64Str / CHUNK_SIZE)
    if totalParts == 0 then totalParts = 1 end

    for partIndex = 1, totalParts do
        local startPos = (partIndex - 1) * CHUNK_SIZE + 1
        local chunk = base64Str:sub(startPos, startPos + CHUNK_SIZE - 1)
        local msg = string.format("D~%s~%d~%d~%s", transferId, partIndex, totalParts, chunk)
        SendAddonMessage(PREFIX, msg, "WHISPER", targetName)
    end

    outgoingTransfers[transferId] = {
        target = targetName,
        totalParts = totalParts,
        sentAt = GetTime(),
        extraInfo = extraInfo,
    }

    return true, transferId, totalParts
end

function SYNC:SendListTo(targetName, listTypes)
    targetName = RL.NormalizeName and RL.NormalizeName(targetName) or targetName
    if not targetName or targetName == "" then
        return false, "Не указано имя игрока"
    end

    local base64Str = RL.Transfer:Export(listTypes)
    if not base64Str then
        return false, "Не удалось подготовить данные для отправки"
    end

    return SendBase64Payload(targetName, base64Str, { listTypes = listTypes })
end

function SYNC:SendEntryTo(targetName, listType, key)
    targetName = RL.NormalizeName and RL.NormalizeName(targetName) or targetName
    if not targetName or targetName == "" then
        return false, "Не указано имя игрока"
    end
    if not listType or not key then
        return false, "У этого игрока нет записи ни в одном списке"
    end

    local base64Str, err = RL.Transfer:ExportEntry(listType, key)
    if not base64Str then
        return false, err or "Не удалось подготовить данные для отправки"
    end

    return SendBase64Payload(targetName, base64Str, { singleEntry = true, listType = listType, key = key })
end

local incomingBuffers = {}
SYNC.pendingQueue = SYNC.pendingQueue or {}

local function CountPayloadEntries(payload)
    local counts = { blacklist = 0, whitelist = 0, notelist = 0, total = 0 }
    if payload and payload.lists then
        for listType, entries in pairs(payload.lists) do
            if counts[listType] ~= nil then
                local n = 0
                for _ in pairs(entries) do n = n + 1 end
                counts[listType] = n
                counts.total = counts.total + n
            end
        end
    end
    return counts
end

local function HandleCompletedTransfer(sender, fullText)
    local payload, err = RL.Transfer:DecodePayload(fullText)
    if not payload then
        print("|cFFFF0000[ReputationList]|r Ошибка синхронизации от " .. sender .. ": " .. tostring(err))
        return
    end

    local counts = CountPayloadEntries(payload)

    if CFG.autoAccept then
        local ok, stats = RL.Transfer:ImportPayload(payload, "newest")
        if ok then
            print(string.format(
                "|cFF00FF00[ReputationList]|r Автоматически синхронизировано от %s: добавлено %d, обновлено %d, пропущено %d.",
                sender, stats.added, stats.overwritten, stats.skipped))
        end
    else
        table.insert(SYNC.pendingQueue, {
            from = sender,
            payload = payload,
            receivedAt = time(),
            counts = counts,
        })
        print(string.format(
            "|cFF00FF00[ReputationList]|r Получены данные синхронизации от %s (%d записей) - автоприём выключен, откройте \"Входящие синхронизации\" в окне Модули, чтобы просмотреть.",
            sender, counts.total))
    end
end

local msgFrame = CreateFrame("Frame")
msgFrame:RegisterEvent("CHAT_MSG_ADDON")
msgFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix ~= PREFIX then return end
    if not message or message == "" then return end

    local senderClean = RL.NormalizeName and RL.NormalizeName(sender) or sender

    local kind = message:sub(1, 1)

    if kind == "D" then
        local transferId, partIndex, totalParts, chunk = message:match("^D~([^~]+)~(%d+)~(%d+)~(.*)$")
        if not transferId then return end
        partIndex = tonumber(partIndex)
        totalParts = tonumber(totalParts)

        local bufKey = senderClean .. "|" .. transferId
        local buf = incomingBuffers[bufKey]
        if not buf then
            buf = { parts = {}, total = totalParts, sender = senderClean, startedAt = GetTime() }
            incomingBuffers[bufKey] = buf
        end
        buf.parts[partIndex] = chunk or ""

        local receivedCount = 0
        for _ in pairs(buf.parts) do receivedCount = receivedCount + 1 end

        if receivedCount >= buf.total then
            local fullParts = {}
            for i = 1, buf.total do
                fullParts[i] = buf.parts[i] or ""
            end
            local fullText = table.concat(fullParts)
            incomingBuffers[bufKey] = nil

            HandleCompletedTransfer(senderClean, fullText)

            SendAddonMessage(PREFIX, "A~" .. transferId .. "~received~" .. tostring(receivedCount), "WHISPER", sender)
        end
    elseif kind == "A" then
        local transferId, status = message:match("^A~([^~]+)~([^~]+)~")
        if transferId and outgoingTransfers[transferId] then
            print("|cFF00FF00[ReputationList]|r " .. senderClean .. " получил(а) данные синхронизации.")
            outgoingTransfers[transferId] = nil
        end
    end
end)

if RL.TimerManager then
    RL.TimerManager:Register("RL_SyncCleanup", 15, function()
        local now = GetTime()
        for bufKey, buf in pairs(incomingBuffers) do
            if now - buf.startedAt > TRANSFER_TIMEOUT then
                incomingBuffers[bufKey] = nil
            end
        end
        for transferId, tr in pairs(outgoingTransfers) do
            if now - tr.sentAt > TRANSFER_TIMEOUT then
                outgoingTransfers[transferId] = nil
            end
        end
    end)
end

local syncFrame
local incomingFrame

local function CreateSyncFrame()
    local f = CreateFrame("Frame", "RepListSyncFrame", UIParent)
    f:SetSize(400, 300)
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
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(L["EXT_SYNC_TITLE"])

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local autoCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    autoCb:SetPoint("TOPLEFT", 20, -45)
    local autoText = autoCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    autoText:SetPoint("LEFT", autoCb, "RIGHT", 5, 0)
    autoText:SetText(L["V2_SYNC_AUTO"])
    autoCb:SetScript("OnShow", function(self) self:SetChecked(CFG.autoAccept) end)
    autoCb:SetChecked(CFG.autoAccept)
    autoCb:SetScript("OnClick", function(self)
        CFG.autoAccept = self:GetChecked() and true or false
    end)

    local listLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", 20, -80)
    listLabel:SetText(L["V2_SYNC_WHAT"])

    local blCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    blCb:SetSize(24, 24)
    blCb:SetPoint("TOPLEFT", 20, -103)
    blCb:SetChecked(true)
    local blText = blCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    blText:SetPoint("LEFT", blCb, "RIGHT", 3, 0)
    blText:SetText("Blacklist")

    local wlCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    wlCb:SetSize(24, 24)
    wlCb:SetPoint("LEFT", blText, "RIGHT", 15, 0)
    wlCb:SetChecked(true)
    local wlText = wlCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    wlText:SetPoint("LEFT", wlCb, "RIGHT", 3, 0)
    wlText:SetText("Whitelist")

    local nlCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    nlCb:SetSize(24, 24)
    nlCb:SetPoint("LEFT", wlText, "RIGHT", 15, 0)
    nlCb:SetChecked(true)
    local nlText = nlCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nlText:SetPoint("LEFT", nlCb, "RIGHT", 3, 0)
    nlText:SetText("Notelist")

    local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 20, -140)
    nameLabel:SetText(L["V2_SYNC_NAME"])

    local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    nameBox:SetSize(200, 20)
    nameBox:SetPoint("TOPLEFT", 25, -163)
    nameBox:SetAutoFocus(false)

    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", 20, -230)
    statusText:SetPoint("RIGHT", -20, 0)
    statusText:SetJustifyH("LEFT")
    f.statusText = statusText

    local sendBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    sendBtn:SetSize(100, 22)
    sendBtn:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
    sendBtn:SetText(L["V2_SEND"])
    sendBtn:SetScript("OnClick", function()
        local name = nameBox:GetText()
        if name == "" then
            statusText:SetText("|cFFFF0000" .. L["V2_SYNC_ENTER"] .. ".|r")
            return
        end

        local listTypes = {}
        if blCb:GetChecked() then table.insert(listTypes, "blacklist") end
        if wlCb:GetChecked() then table.insert(listTypes, "whitelist") end
        if nlCb:GetChecked() then table.insert(listTypes, "notelist") end
        if #listTypes == 0 then
            statusText:SetText("|cFFFF0000" .. L["V2_SYNC_SELECT"] .. ".|r")
            return
        end

        local ok, transferIdOrErr, totalParts = SYNC:SendListTo(name, listTypes)
        if ok then
            statusText:SetText(string.format(
                "|cFF00FF00Отправлено %s (%d частей). Ждём подтверждения...|r", name, totalParts))
        else
            statusText:SetText("|cFFFF0000" .. string.format(L["V2_ERROR"], tostring(transferIdOrErr)) .. "|r")
        end
    end)

    local incomingBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    incomingBtn:SetSize(200, 22)
    incomingBtn:SetPoint("BOTTOM", 0, 20)
    incomingBtn:SetScript("OnShow", function(self)
        self:SetText(string.format(L["EXT_INCOMING"], #SYNC.pendingQueue))
    end)
    incomingBtn:SetText(string.format(L["EXT_INCOMING"], 0))
    incomingBtn:SetScript("OnClick", function(self)
        SYNC:ShowIncoming()
    end)
    f.incomingBtn = incomingBtn

    syncFrame = f
    return f
end

function SYNC:ShowUI()
    local ok, err = pcall(function()
        if not syncFrame then
            CreateSyncFrame()
        end
        syncFrame.incomingBtn:SetText(string.format(L["EXT_INCOMING"], #self.pendingQueue))
        syncFrame:Show()
    end)
    if not ok then
        print("|cFFFF0000[ReputationList]|r Ошибка открытия окна синхронизации: " .. tostring(err))
    end
end

local currentReviewIndex = 1

local function CreateIncomingFrame()
    local f = CreateFrame("Frame", "RepListIncomingSyncFrame", UIParent)
    f:SetSize(460, 480)
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
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(L["EXT_INCOMING_TITLE"])

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local infoText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    infoText:SetPoint("TOPLEFT", 20, -45)
    infoText:SetPoint("RIGHT", -20, 0)
    infoText:SetJustifyH("LEFT")
    f.infoText = infoText

    local scrollFrame = CreateFrame("ScrollFrame", "RepListIncomingSyncScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 90)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(390, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
    f.entryCheckboxes = {}
    f.reviewRows = {}

    local acceptSelectedBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    acceptSelectedBtn:SetSize(150, 22)
    acceptSelectedBtn:SetPoint("BOTTOMLEFT", 20, 55)
    acceptSelectedBtn:SetText(L["V2_ACCEPT_SELECTED"])

    local acceptAllBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    acceptAllBtn:SetSize(100, 22)
    acceptAllBtn:SetPoint("LEFT", acceptSelectedBtn, "RIGHT", 10, 0)
    acceptAllBtn:SetText(L["V2_ACCEPT_ALL"])

    local rejectBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    rejectBtn:SetSize(100, 22)
    rejectBtn:SetPoint("LEFT", acceptAllBtn, "RIGHT", 10, 0)
    rejectBtn:SetText(L["V2_REJECT"])

    local skipBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    skipBtn:SetSize(100, 22)
    skipBtn:SetPoint("BOTTOMRIGHT", -20, 55)
    skipBtn:SetText(L["V2_SKIP"])

    f.acceptSelectedBtn = acceptSelectedBtn
    f.acceptAllBtn = acceptAllBtn
    f.rejectBtn = rejectBtn
    f.skipBtn = skipBtn

    incomingFrame = f
    return f
end

local LIST_LABELS = { blacklist = "|cFFFF4444Blacklist|r", whitelist = "|cFF44FF44Whitelist|r", notelist = "|cFFFFAA00Notelist|r" }

local function RefreshIncomingReview()
    local f = incomingFrame
    if not f then return end

    if #SYNC.pendingQueue == 0 then
        f.infoText:SetText(L["EXT_NO_PENDING"])
        for i = 1, #f.reviewRows do f.reviewRows[i]:Hide() end
        for i = #f.entryCheckboxes, 1, -1 do f.entryCheckboxes[i] = nil end
        f.acceptSelectedBtn:Disable()
        f.acceptAllBtn:Disable()
        f.rejectBtn:Disable()
        f.skipBtn:Disable()
        return
    end

    if currentReviewIndex > #SYNC.pendingQueue then
        currentReviewIndex = 1
    end

    local sync = SYNC.pendingQueue[currentReviewIndex]
    f.acceptSelectedBtn:Enable()
    f.acceptAllBtn:Enable()
    f.rejectBtn:Enable()
    f.skipBtn:Enable()

    f.infoText:SetText(string.format(
        L["V2_SYNC_INFO"],
        sync.from, currentReviewIndex, #SYNC.pendingQueue, sync.counts.total))

    for i = 1, #f.reviewRows do f.reviewRows[i]:Hide() end
    for i = #f.entryCheckboxes, 1, -1 do f.entryCheckboxes[i] = nil end

    local yOffset = 0
    local rowIndex = 0
    for listType, entries in pairs(sync.payload.lists) do
        if LIST_LABELS[listType] then
            for key, entry in pairs(entries) do
                rowIndex = rowIndex + 1
                local row = f.reviewRows[rowIndex]
                if not row then
                    row = CreateFrame("Frame", nil, f.scrollChild)
                    row:SetSize(380, 22)
                    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    cb:SetSize(22, 22)
                    cb:SetPoint("LEFT", 0, 0)
                    row.checkbox = cb

                    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    fs:SetPoint("LEFT", cb, "RIGHT", 5, 0)
                    fs:SetWidth(340)
                    fs:SetJustifyH("LEFT")
                    row.text = fs
                    row.info = { checkbox = cb }
                    f.reviewRows[rowIndex] = row
                end
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -yOffset)
                local cb = row.checkbox
                cb:SetChecked(true)
                local notePreview = (entry.note and entry.note ~= "") and (" - " .. entry.note) or ""
                row.text:SetText(LIST_LABELS[listType] .. " " .. (entry.name or key) .. notePreview)
                row.info.listType, row.info.key, row.info.entry = listType, key, entry
                f.entryCheckboxes[#f.entryCheckboxes + 1] = row.info
                row:Show()
                yOffset = yOffset + 22
            end
        end
    end
    f.scrollChild:SetHeight(math.max(yOffset, 1))
end

function SYNC:ShowIncoming()
    local ok, err = pcall(function()
    if not incomingFrame then
        CreateIncomingFrame()

        incomingFrame.acceptSelectedBtn:SetScript("OnClick", function()
            local selections = {}
            for _, row in ipairs(incomingFrame.entryCheckboxes) do
                if row.checkbox:GetChecked() then
                    table.insert(selections, { listType = row.listType, key = row.key, entry = row.entry })
                end
            end
            local ok, stats = RL.Transfer:ImportSelectedEntries(selections, "newest")
            if ok then
                print(string.format("|cFF00FF00[ReputationList]|r Принято выбранных записей: добавлено %d, обновлено %d, пропущено %d.",
                    stats.added, stats.overwritten, stats.skipped))
            end
            table.remove(SYNC.pendingQueue, currentReviewIndex)
            RefreshIncomingReview()
        end)

        incomingFrame.acceptAllBtn:SetScript("OnClick", function()
            local sync = SYNC.pendingQueue[currentReviewIndex]
            if sync then
                local ok, stats = RL.Transfer:ImportPayload(sync.payload, "newest")
                if ok then
                    print(string.format("|cFF00FF00[ReputationList]|r Принято от %s: добавлено %d, обновлено %d, пропущено %d.",
                        sync.from, stats.added, stats.overwritten, stats.skipped))
                end
                table.remove(SYNC.pendingQueue, currentReviewIndex)
            end
            RefreshIncomingReview()
        end)

        incomingFrame.rejectBtn:SetScript("OnClick", function()
            local sync = SYNC.pendingQueue[currentReviewIndex]
            if sync then
                print("|cFFFFAA00[ReputationList]|r Синхронизация от " .. sync.from .. " отклонена.")
                table.remove(SYNC.pendingQueue, currentReviewIndex)
            end
            RefreshIncomingReview()
        end)

        incomingFrame.skipBtn:SetScript("OnClick", function()
            currentReviewIndex = currentReviewIndex + 1
            if currentReviewIndex > #SYNC.pendingQueue then
                currentReviewIndex = 1
            end
            RefreshIncomingReview()
        end)
    end

    currentReviewIndex = 1
    RefreshIncomingReview()
    incomingFrame:Show()
    end)
    if not ok then
        print("|cFFFF0000[ReputationList]|r Ошибка открытия окна входящих синхронизаций: " .. tostring(err))
    end
end

local sendSingleFrame

local function CreateSendSingleFrame()
    local f = CreateFrame("Frame", "RepListSyncSingleFrame", UIParent)
    f:SetSize(320, 175)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
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
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(L["EXT_SEND_FRIEND"])

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local playerLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerLabel:SetPoint("TOPLEFT", 20, -45)
    playerLabel:SetPoint("RIGHT", -20, 0)
    playerLabel:SetJustifyH("LEFT")
    f.playerLabel = playerLabel

    local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 20, -80)
    nameLabel:SetText(L["EXT_FRIEND_NAME"])

    local nameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    nameBox:SetSize(160, 20)
    nameBox:SetPoint("TOPLEFT", 25, -103)
    nameBox:SetAutoFocus(false)
    f.nameBox = nameBox

    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", 20, -135)
    statusText:SetPoint("RIGHT", -20, 0)
    statusText:SetJustifyH("LEFT")
    f.statusText = statusText

    local sendBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    sendBtn:SetSize(100, 22)
    sendBtn:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
    sendBtn:SetText(L["V2_SEND"])
    sendBtn:SetScript("OnClick", function()
        local target = nameBox:GetText()
        if target == "" then
            statusText:SetText("|cFFFF0000" .. L["V2_SYNC_ENTER"] .. ".|r")
            return
        end
        local ok, err, totalParts = SYNC:SendEntryTo(target, f.entryListType, f.entryKey)
        if ok then
            statusText:SetText(string.format(L["EXT_SENT_WAIT"], target, totalParts))
        else
            statusText:SetText("|cFFFF0000" .. string.format(L["V2_ERROR"], tostring(err)) .. "|r")
        end
    end)
    nameBox:SetScript("OnEnterPressed", function(self)
        sendBtn:Click()
    end)

    sendSingleFrame = f
    return f
end

function SYNC:ShowSendSingleDialog(key, listType, displayName)
    if not key or not listType then
        print("|cFFFFAA00[ReputationList]|r У этого игрока нет записи ни в одном из ваших списков - нечего отправлять.")
        return
    end

    local ok, err = pcall(function()
        if not sendSingleFrame then
            CreateSendSingleFrame()
        end
        sendSingleFrame.entryKey = key
        sendSingleFrame.entryListType = listType
        sendSingleFrame.playerLabel:SetText(string.format(L["EXT_PLAYER"], displayName or key, LIST_LABELS[listType] or listType))
        sendSingleFrame.nameBox:SetText("")
        sendSingleFrame.statusText:SetText("")
        sendSingleFrame:Show()
    end)
    if not ok then
        print("|cFFFF0000[ReputationList]|r Ошибка открытия окна отправки: " .. tostring(err))
    end
end

SLASH_RLSYNC1 = "/rlsync"
SlashCmdList["RLSYNC"] = function(msg)
    msg = msg or ""
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "show" then
        SYNC:ShowUI()
    elseif cmd == "send" and rest ~= "" then
        local ok, err, totalParts = SYNC:SendListTo(rest, nil)
        if ok then
            print("|cFF00FF00[ReputationList]|r Отправлено " .. rest .. " (" .. totalParts .. " частей).")
        else
            print("|cFFFF0000[ReputationList]|r Ошибка: " .. tostring(err))
        end
    elseif cmd == "auto" then
        CFG.autoAccept = not CFG.autoAccept
        print("|cFF00FF00[ReputationList]|r Автоприём синхронизаций: " .. (CFG.autoAccept and "включён" or "выключен"))
    elseif cmd == "incoming" then
        SYNC:ShowIncoming()
    else
        print("|cFF00FF00[ReputationList]|r Синхронизация со списком друга:")
        print("  /rlsync - открыть окно синхронизации")
        print("  /rlsync send <имя> - отправить все списки указанному игроку")
        print("  /rlsync auto - переключить автоматический приём")
        print("  /rlsync incoming - открыть окно входящих синхронизаций")
    end
end
