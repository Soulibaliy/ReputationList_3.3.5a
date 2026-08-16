ReputationList = ReputationList or {}
local RL = ReputationList

if not RL.GetRealmData then
    return
end

RL.Transfer = RL.Transfer or {}
local T = RL.Transfer
local L = RL.L or ReputationListLocale or {}

local FORMAT_TAG = "RLv1:" 

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64_encode(data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b64chars:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function base64_decode(data)
    data = string.gsub(data, '[^' .. b64chars .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b64chars:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

local function SerializeValue(v)
    local t = type(v)
    if v == nil then
        return "n;"
    elseif t == "boolean" then
        return (v and "T;" or "F;")
    elseif t == "number" then
        return "#" .. tostring(v) .. ";"
    elseif t == "string" then
        return "$" .. tostring(#v) .. ":" .. v
    elseif t == "table" then
        local parts = {}
        for k, val in pairs(v) do
            if type(k) == "string" or type(k) == "number" then
                parts[#parts + 1] = SerializeValue(k) .. SerializeValue(val)
            end
        end
        return "{" .. table.concat(parts) .. "}"
    else
        return "n;"
    end
end

local DeserializeValue

local function ParseTable(p)
    local tbl = {}
    while true do
        if p.s:sub(p.pos, p.pos) == "}" then
            p.pos = p.pos + 1
            break
        end
        if p.pos > #p.s then break end
        local k = DeserializeValue(p)
        local v = DeserializeValue(p)
        if k == nil then break end
        tbl[k] = v
    end
    return tbl
end

DeserializeValue = function(p)
    local tag = p.s:sub(p.pos, p.pos)
    if tag == "n" then
        p.pos = p.pos + 2
        return nil
    elseif tag == "T" then
        p.pos = p.pos + 2
        return true
    elseif tag == "F" then
        p.pos = p.pos + 2
        return false
    elseif tag == "#" then
        local semi = p.s:find(";", p.pos + 1, true)
        if not semi then error("malformed number") end
        local numStr = p.s:sub(p.pos + 1, semi - 1)
        p.pos = semi + 1
        return tonumber(numStr)
    elseif tag == "$" then
        local colon = p.s:find(":", p.pos + 1, true)
        if not colon then error("malformed string") end
        local lenStr = p.s:sub(p.pos + 1, colon - 1)
        local len = tonumber(lenStr)
        if not len then error("malformed string length") end
        local strStart = colon + 1
        local str = p.s:sub(strStart, strStart + len - 1)
        p.pos = strStart + len
        return str
    elseif tag == "{" then
        p.pos = p.pos + 1
        return ParseTable(p)
    else
        error(string.format(L["TR_ERR_INVALID_AT"], p.pos))
    end
end

local function Serialize(v)
    return SerializeValue(v)
end

local function Deserialize(str)
    local p = { s = str, pos = 1 }
    local ok, result = pcall(DeserializeValue, p)
    if not ok then
        return nil, result
    end
    return result
end

function T:Export(listTypes)
    listTypes = listTypes or { "blacklist", "whitelist", "notelist" }
    local realmData = RL:GetRealmData()
    if not realmData then return nil end

    local payload = {
        exportVersion = 1,
        exportedBy = UnitName("player") or "?",
        exportedRealm = RL.GetCurrentRealmName and RL.GetCurrentRealmName() or (GetRealmName and GetRealmName()) or "?",
        exportedDate = date("%d.%m.%Y %H:%M"),
        lists = {},
    }

    for _, listType in ipairs(listTypes) do
        local list = realmData[listType]
        if list then
            local copy = {}
            for key, entry in pairs(list) do
                copy[key] = {
                    name = entry.name,
                    note = entry.note,
                    guid = entry.guid,
                    class = entry.class,
                    race = entry.race,
                    level = entry.level,
                    guild = entry.guild,
                    faction = entry.faction,
                    tags = entry.tags,
                    addedDate = entry.addedDate,
                    addedBy = entry.addedBy,
                    armoryLink = entry.armoryLink,
                    history = entry.history,
                    lastUpdateDate = entry.lastUpdateDate,
                }
            end
            payload.lists[listType] = copy
        end
    end

    local serialized = Serialize(payload)
    local encoded = base64_encode(serialized)
    collectgarbage("collect")
    return FORMAT_TAG .. encoded
end

function T:ExportEntry(listType, key)
    local realmData = RL:GetRealmData()
    if not realmData or not realmData[listType] or not realmData[listType][key] then
        return nil, L["TR_ERR_NOT_FOUND"]
    end

    local entry = realmData[listType][key]
    local payload = {
        exportVersion = 1,
        exportedBy = UnitName("player") or "?",
        exportedRealm = RL.GetCurrentRealmName and RL.GetCurrentRealmName() or (GetRealmName and GetRealmName()) or "?",
        exportedDate = date("%d.%m.%Y %H:%M"),
        lists = {
            [listType] = {
                [key] = {
                    name = entry.name,
                    note = entry.note,
                    guid = entry.guid,
                    class = entry.class,
                    race = entry.race,
                    level = entry.level,
                    guild = entry.guild,
                    faction = entry.faction,
                    tags = entry.tags,
                    addedDate = entry.addedDate,
                    addedBy = entry.addedBy,
                    armoryLink = entry.armoryLink,
                    history = entry.history,
                    lastUpdateDate = entry.lastUpdateDate,
                }
            }
        }
    }

    local serialized = Serialize(payload)
    local encoded = base64_encode(serialized)
    return FORMAT_TAG .. encoded
end

function T:ParseDateSortable(dateStr)
    if not dateStr then return 0 end
    local d, m, y, H, M = dateStr:match("(%d+)%.(%d+)%.(%d+)%s+(%d+):(%d+)")
    if not d then return 0 end
    return tonumber(y) * 100000000 + tonumber(m) * 1000000 + tonumber(d) * 10000 + tonumber(H) * 100 + tonumber(M)
end

local function FindKeyByGuid(targetList, guid)
    if not guid or guid == "" then return nil end
    if RL.FindByGUID then
        local data, key = RL.FindByGUID(guid)
        if data and key and targetList[key] == data then
            return key
        end
    end
    for existingKey, existingEntry in pairs(targetList) do
        if existingEntry.guid and existingEntry.guid == guid then
            return existingKey
        end
    end
    return nil
end

local MAX_MERGED_HISTORY = 20

local function MergeHistory(existingHistory, incomingHistory)
    if type(incomingHistory) ~= "table" or #incomingHistory == 0 then
        return existingHistory
    end

    local merged = {}
    local seen = {}
    for _, h in ipairs(existingHistory or {}) do
        local mkey = tostring(h.date) .. "|" .. tostring(h.by) .. "|" .. tostring(h.change)
        if not seen[mkey] then
            seen[mkey] = true
            merged[#merged + 1] = h
        end
    end
    for _, h in ipairs(incomingHistory) do
        if type(h) == "table" then
            local mkey = tostring(h.date) .. "|" .. tostring(h.by) .. "|" .. tostring(h.change)
            if not seen[mkey] then
                seen[mkey] = true
                merged[#merged + 1] = h
            end
        end
    end

    table.sort(merged, function(a, b)
        return T:ParseDateSortable(a.date) > T:ParseDateSortable(b.date)
    end)
    for i = #merged, MAX_MERGED_HISTORY + 1, -1 do
        table.remove(merged, i)
    end
    return merged
end

function T:MergeEntry(targetList, key, entry, mode)
    if type(entry) ~= "table" or not entry.name then return "skipped" end

    local existingKey = FindKeyByGuid(targetList, entry.guid) or (targetList[key] and key or nil)
    local existing = existingKey and targetList[existingKey]

    local result, overwriteCore
    if not existing then
        result, overwriteCore = "added", true
        existingKey = key
    elseif mode == "overwrite" then
        result, overwriteCore = "overwritten", true
    elseif mode == "newest" then
        local incomingTime = self:ParseDateSortable(entry.lastUpdateDate or entry.addedDate)
        local existingTime = self:ParseDateSortable(existing.lastUpdateDate or existing.addedDate)
        if incomingTime > existingTime then
            result, overwriteCore = "overwritten", true
        else
            result, overwriteCore = "skipped", false
        end
    else
        result, overwriteCore = "skipped", false
    end

    if not existing and not overwriteCore then
        return result
    end

    local newEntry = existing or {}
    if overwriteCore then
        newEntry.name = entry.name
        newEntry.note = entry.note or newEntry.note
        newEntry.guid = entry.guid or newEntry.guid
        newEntry.class = entry.class or newEntry.class
        newEntry.race = entry.race or newEntry.race
        newEntry.level = entry.level or newEntry.level
        newEntry.guild = entry.guild or newEntry.guild
        newEntry.faction = entry.faction or newEntry.faction
        newEntry.addedDate = entry.addedDate or newEntry.addedDate or date("%d.%m.%Y %H:%M")
        newEntry.addedBy = newEntry.addedBy or entry.addedBy or "Sync"
        newEntry.key = existingKey
    end
    newEntry.tags = entry.tags or newEntry.tags
    newEntry.armoryLink = entry.armoryLink or newEntry.armoryLink
    newEntry.history = MergeHistory(newEntry.history, entry.history) or newEntry.history or {}
    newEntry.lastUpdateDate = entry.lastUpdateDate or newEntry.lastUpdateDate

    targetList[existingKey] = newEntry
    return result
end

function T:DecodePayload(importString)
    if not importString or importString == "" then
        return nil, L["TR_ERR_EMPTY_IMPORT"]
    end

    importString = importString:gsub("^%s+", ""):gsub("%s+$", "")

    if importString:sub(1, #FORMAT_TAG) ~= FORMAT_TAG then
        return nil, string.format(L["TR_ERR_UNKNOWN_FORMAT"], FORMAT_TAG)
    end

    local encoded = importString:sub(#FORMAT_TAG + 1)
    local ok, decoded = pcall(base64_decode, encoded)
    if not ok then
        return nil, L["TR_ERR_BASE64"]
    end

    local payload, err = Deserialize(decoded)
    if not payload then
        return nil, string.format(L["TR_ERR_PARSE"], tostring(err))
    end

    if type(payload) ~= "table" or not payload.lists then
        return nil, L["TR_ERR_CORRUPT"]
    end

    return payload
end

function T:ImportPayload(payload, mode, listFilter)
    mode = mode or "merge"
    local realmData = RL:GetRealmData()
    if not realmData then
        return false, L["TR_ERR_REALM"]
    end

    local stats = { added = 0, skipped = 0, overwritten = 0 }

    if RL.BuildGUIDIndex then RL.BuildGUIDIndex() end

    for listType, entries in pairs(payload.lists) do
        if (listType == "blacklist" or listType == "whitelist" or listType == "notelist")
            and (not listFilter or listFilter[listType]) then
            realmData[listType] = realmData[listType] or {}
            local targetList = realmData[listType]

            for key, entry in pairs(entries) do
                local result = self:MergeEntry(targetList, key, entry, mode)
                stats[result] = (stats[result] or 0) + 1
            end
        end
    end

    if RL.InvalidateCache then RL.InvalidateCache() end
    if RL.BuildGUIDIndex then RL.BuildGUIDIndex() end
    if RL.SaveSettings then RL:SaveSettings() end
    collectgarbage("collect")

    return true, stats
end

function T:ImportSelectedEntries(selections, mode)
    mode = mode or "newest"
    local realmData = RL:GetRealmData()
    if not realmData then
        return false, L["TR_ERR_REALM"]
    end

    local stats = { added = 0, skipped = 0, overwritten = 0 }

    if RL.BuildGUIDIndex then RL.BuildGUIDIndex() end

    for _, sel in ipairs(selections) do
        realmData[sel.listType] = realmData[sel.listType] or {}
        local result = self:MergeEntry(realmData[sel.listType], sel.key, sel.entry, mode)
        stats[result] = (stats[result] or 0) + 1
    end

    if RL.InvalidateCache then RL.InvalidateCache() end
    if RL.BuildGUIDIndex then RL.BuildGUIDIndex() end
    if RL.SaveSettings then RL:SaveSettings() end
    collectgarbage("collect")

    return true, stats
end

function T:Import(importString, mode, listFilter)
    local payload, err = self:DecodePayload(importString)
    if not payload then
        return false, err
    end
    return self:ImportPayload(payload, mode, listFilter)
end

local transferFrame

local function DetectLegacyTextFormat(text)
    if not text or text == "" then return nil, L["TR_ERR_EMPTY"] end
    if text:match("ReputationList_Import") or text:match("realms%s*=") then return "ReputationList", nil end
    if text:match("BlackListDB") or text:match("BLackListDB") then return "BlackList", nil end
    if text:match("ElitistGroupDB") or (text:match("badlisted") and text:match("note")) then return "ElitistGroup", nil end
    return nil, L["TR_ERR_TEXT_FORMAT"]
end

local function ImportLegacyReputationList(data)
    local imported, skipped = 0, 0
    local normalizedRealm = RL.NormalizeRealm(GetRealmName())
    ReputationListDB.realms = ReputationListDB.realms or {}
    ReputationListDB.realms[normalizedRealm] = ReputationListDB.realms[normalizedRealm] or { blacklist = {}, whitelist = {}, notelist = {} }

    if data and data.realms then
        for _, realmData in pairs(data.realms) do
            if type(realmData) == "table" then
                for listType, listData in pairs(realmData) do
                    if listType == "blacklist" or listType == "whitelist" or listType == "notelist" then
                        for playerName, playerData in pairs(listData) do
                            if type(playerData) == "table" then
                                local key = string.lower(playerName)
                                if not ReputationListDB.realms[normalizedRealm][listType][key] then
                                    local newData = {}
                                    for k, v in pairs(playerData) do newData[k] = v end
                                    ReputationListDB.realms[normalizedRealm][listType][key] = newData
                                    imported = imported + 1
                                else
                                    skipped = skipped + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return imported, skipped
end

local function ImportLegacyBlackList(data)
    local imported, skipped = 0, 0
    local normalizedRealm = RL.NormalizeRealm(GetRealmName())
    ReputationListDB.realms = ReputationListDB.realms or {}
    ReputationListDB.realms[normalizedRealm] = ReputationListDB.realms[normalizedRealm] or { blacklist = {}, whitelist = {}, notelist = {} }

    if data then
        for _, players in pairs(data) do
            if type(players) == "table" then
                for playerName, playerData in pairs(players) do
                    if type(playerData) == "table" then
                        local key = string.lower(playerName)
                        if not ReputationListDB.realms[normalizedRealm].blacklist[key] then
                            ReputationListDB.realms[normalizedRealm].blacklist[key] = {
                                name = playerName,
                                note = playerData.note or playerData.reason or "",
                                addedDate = playerData.date or date("%d.%m.%Y %H:%M"),
                                addedBy = playerData.by or "Import",
                                key = key:gsub("[^%w]", ""):lower(),
                            }
                            imported = imported + 1
                        else
                            skipped = skipped + 1
                        end
                    end
                end
            end
        end
    end
    return imported, skipped
end

local function ImportLegacyElitistGroup(data)
    local imported, skipped = 0, 0
    local normalizedRealm = RL.NormalizeRealm(GetRealmName())
    ReputationListDB.realms = ReputationListDB.realms or {}
    ReputationListDB.realms[normalizedRealm] = ReputationListDB.realms[normalizedRealm] or { blacklist = {}, whitelist = {}, notelist = {} }

    if data and data.badlisted then
        for playerName, playerData in pairs(data.badlisted) do
            if type(playerData) == "table" then
                local key = string.lower(playerName)
                if not ReputationListDB.realms[normalizedRealm].blacklist[key] then
                    ReputationListDB.realms[normalizedRealm].blacklist[key] = {
                        name = playerName,
                        note = playerData.note or "",
                        addedDate = date("%d.%m.%Y %H:%M"),
                        addedBy = "Import",
                        key = key:gsub("[^%w]", ""):lower(),
                    }
                    imported = imported + 1
                else
                    skipped = skipped + 1
                end
            end
        end
    end
    return imported, skipped
end

local function ExportLegacyText(callback, listTypes)
    if not (RL.UICommon and RL.UICommon.AsyncSerialize) then
        callback(nil, L["TR_ERR_COMMON"])
        return
    end
    local normalizedRealm = RL.NormalizeRealm(GetRealmName())
    local realmData = RL:GetRealmData()
    local filteredData = {}
    if realmData then
        listTypes = listTypes or { "blacklist", "whitelist", "notelist" }
        for _, listType in ipairs(listTypes) do
            filteredData[listType] = realmData[listType]
        end
    end
    local data = { realms = { [normalizedRealm] = filteredData } }
    RL.UICommon.AsyncSerialize(data, function(resultString)
        callback(resultString)
    end, L)
end

local function ImportLegacyText(text)
    if not text or text == "" then
        return false, L["TR_ERR_EMPTY"]
    end

    local format, detectErr = DetectLegacyTextFormat(text)
    if not format then
        return false, detectErr
    end

    local textToLoad = text
    if not text:match("^%s*return%s+") then
        if format == "ReputationList" then
            textToLoad = text .. "\nreturn ReputationList_Import"
        elseif format == "BlackList" then
            textToLoad = text .. "\nreturn BlackListDB or BLackListDB"
        elseif format == "ElitistGroup" then
            textToLoad = text .. "\nreturn ElitistGroupDB"
        end
    end

    local chunk, loadErr = loadstring(textToLoad)
    if not chunk then
        return false, string.format(L["TR_ERR_TEXT"], tostring(loadErr))
    end

    local ok, result = pcall(chunk)
    if not ok or type(result) ~= "table" then
        return false, L["TR_ERR_EXEC"]
    end

    local imported, skipped = 0, 0
    if format == "ReputationList" then
        imported, skipped = ImportLegacyReputationList(result)
    elseif format == "BlackList" then
        imported, skipped = ImportLegacyBlackList(result)
    elseif format == "ElitistGroup" then
        imported, skipped = ImportLegacyElitistGroup(result)
    end

    if RL.InvalidateCache then RL.InvalidateCache() end
    if RL.BuildGUIDIndex then RL.BuildGUIDIndex() end
    if RL.SaveSettings then RL:SaveSettings() end
    if RL.UI2 and RL.UI2.Refresh and RL.UI2.frame and RL.UI2.frame:IsShown() then
        RL.UI2:Refresh()
    end
    collectgarbage("collect")

    return true, { added = imported, skipped = skipped }
end

local function GetStyle()
    return RL.UI2Style
end

local function CreateTransferFrame()
    local S = GetStyle()

    local f = CreateFrame("Frame", "RepListTransferFrame", UIParent)
    f:SetSize(500, 380)
    f:SetPoint("CENTER")
    if RL.FixElvUIScale then RL.FixElvUIScale(f) end
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:Hide()

    if S then
        S.CreatePanelBackdrop(f)
    else

        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 32, edgeSize = 18,
            insets = { left = 6, right = 6, top = 6, bottom = 6 },
        })
        f:SetBackdropColor(0.106, 0.106, 0.106, 0.95)
        f:SetBackdropBorderColor(0.482, 0.353, 0.169, 1)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    if S then
        title:SetFont(S.FONT_HEADER, 18, "")
        title:SetTextColor(S.PAL.gold[1], S.PAL.gold[2], S.PAL.gold[3])
    end
    title:SetText(L["TR_TITLE"])
    f.title = title

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -10)
    hint:SetText(L["TR_HINT"])
    if S then hint:SetTextColor(S.PAL.text[1], S.PAL.text[2], S.PAL.text[3]) end
    f.hint = hint

    f.exportAsText = false
    local formatBtn = S and S.CreateButton(f, 150, 20, "") or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    formatBtn:SetPoint("TOP", hint, "BOTTOM", 0, -6)
    local function UpdateFormatBtnText()
        formatBtn:SetText(f.exportAsText and L["TR_FORMAT_TEXT"] or L["TR_FORMAT_BASE64"])
    end
    UpdateFormatBtnText()
    formatBtn:SetScript("OnClick", function()
        f.exportAsText = not f.exportAsText
        UpdateFormatBtnText()
    end)
    f.formatBtn = formatBtn

    local scrollFrame = CreateFrame("ScrollFrame", "RepListTransferScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -96)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 90)
    if S then
        S.CreateInnerPanelBackdrop(scrollFrame)
        scrollFrame:SetBackdropColor(0, 0, 0, 0.75)
    else
        scrollFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        scrollFrame:SetBackdropColor(0, 0, 0, 0.75)
    end

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    if S then editBox:SetTextColor(S.PAL.text[1], S.PAL.text[2], S.PAL.text[3]) end
    editBox:SetWidth(430)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)
    f.editBox = editBox

    local scrollBar = _G["RepListTransferScrollFrameScrollBar"]
    if scrollBar and S then
        local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
        if thumb then thumb:SetVertexColor(S.PAL.bronze[1], S.PAL.bronze[2], S.PAL.bronze[3]) end
        local up = _G["RepListTransferScrollFrameScrollBarScrollUpButton"]
        local down = _G["RepListTransferScrollFrameScrollBarScrollDownButton"]
        for _, b in ipairs({ up, down }) do
            if b then
                local nt = b:GetNormalTexture()
                if nt then nt:SetVertexColor(S.PAL.gold[1], S.PAL.gold[2], S.PAL.gold[3]) end
            end
        end
    end

    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMLEFT", 20, 76)
    statusText:SetPoint("BOTTOMRIGHT", -20, 76)
    statusText:SetJustifyH("LEFT")
    f.statusText = statusText

    local function MakeExportButton(label, listTypes, xOffset)
        local btn = S and S.CreateButton(f, 110, 22, label) or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetPoint("BOTTOMLEFT", xOffset, 48)
        if not S then btn:SetText(label) end
        btn:SetScript("OnClick", function()
            if f.exportAsText then
                f.statusText:SetText(L["TR_EXPORTING"])
                ExportLegacyText(function(str, err)
                    if str then
                        editBox:SetText(str)
                        editBox:HighlightText()
                        editBox:SetFocus()
                        f.statusText:SetText(L["TR_EXPORTED_TEXT"])
                    else
                        f.statusText:SetText(string.format(L["TR_EXPORT_ERROR_DETAIL"], tostring(err)))
                    end
                end, listTypes)
                return
            end
            local str = T:Export(listTypes)
            if str then
                editBox:SetText(str)
                editBox:HighlightText()
                editBox:SetFocus()
                f.statusText:SetText(L["TR_EXPORTED_BASE64"])
            else
                f.statusText:SetText(L["TR_EXPORT_ERROR"])
            end
        end)
        return btn
    end

    MakeExportButton(L["TR_EXPORT_ALL"], nil, 20)
    MakeExportButton("Blacklist", { "blacklist" }, 130)
    MakeExportButton("Whitelist", { "whitelist" }, 240)
    MakeExportButton("Notelist", { "notelist" }, 350)

    local function DoImport(listFilter)
        local text = editBox:GetText()
        if text and text:sub(1, #FORMAT_TAG) == FORMAT_TAG then

            local success, stats = T:Import(text, "merge", listFilter)
            if success then
                f.statusText:SetText(string.format(
                    L["TR_IMPORTED_BASE64"],
                    stats.added, stats.skipped))
                if RL.UI2 and RL.UI2.Refresh and RL.UI2.frame and RL.UI2.frame:IsShown() then
                    RL.UI2:Refresh()
                end
            else
                f.statusText:SetText(string.format(L["TR_IMPORT_ERROR"], tostring(stats)))
            end
        else

            local success, stats = ImportLegacyText(text)
            if success then
                f.statusText:SetText(string.format(
                    L["TR_IMPORTED_TEXT"],
                    stats.added, stats.skipped))
            else
                f.statusText:SetText(string.format(L["TR_IMPORT_ERROR"], tostring(stats)))
            end
        end
    end

    local function MakeImportButton(label, listFilter, xOffset)
        local btn = S and S.CreateButton(f, 110, 22, label, "primary") or CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetPoint("BOTTOMLEFT", xOffset, 20)
        if not S then btn:SetText(label) end
        btn:SetScript("OnClick", function() DoImport(listFilter) end)
        return btn
    end

    MakeImportButton(L["TR_IMPORT"], nil, 20)
    MakeImportButton("Blacklist", { blacklist = true }, 130)
    MakeImportButton("Whitelist", { whitelist = true }, 240)
    MakeImportButton("Notelist", { notelist = true }, 350)

    return f
end

function T:ShowUI()
    if not transferFrame then
        transferFrame = CreateTransferFrame()
    end
    transferFrame.statusText:SetText("")
    transferFrame.editBox:SetText("")
    transferFrame:Show()
end

SLASH_RLEXPORT1 = "/rlexport"
SlashCmdList["RLEXPORT"] = function()
    T:ShowUI()
end

SLASH_RLIMPORT1 = "/rlimport"
SlashCmdList["RLIMPORT"] = function()
    T:ShowUI()
end
