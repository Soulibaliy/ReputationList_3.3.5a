-- ====================================================================
-- ReputationList UI Common Module for WoW 3.3.5a
-- Общие функции для Classic и ElvUI интерфейсов
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList

RL.UICommon = RL.UICommon or {}
local Common = RL.UICommon


function Common.CreateSettingsPanelWrapper(CACHE, parent, createFunc)
    if CACHE.settingsPanel then 
        return CACHE.settingsPanel 
    end
    if createFunc then
        CACHE.settingsPanel = createFunc(parent)
        return CACHE.settingsPanel
    end
    return nil
end

function Common.ShowSettingsInlineWrapper(CACHE, createFunc)
    if not CACHE.settingsPanel and createFunc then
        createFunc()
    end
end

function Common.ShowPlayerInfoWrapper(CACHE, data, createFunc)
    if not CACHE.infoFrame and createFunc then
        CACHE.infoFrame = createFunc()
    end
    return CACHE.infoFrame
end

function Common.CreateProgressBarWrapper(parent, createFunc)
    if createFunc then
        return createFunc(parent)
    end
    return nil
end

function Common.DetectImportFormatWrapper(text, detectFunc)
    if detectFunc then
        return detectFunc(text)
    end
    return nil
end

function Common.CreateExportImportFramesWrapper(CACHE, createFunc)
    if CACHE.exportFrame and CACHE.importFrame then
        return
    end
    if createFunc then
        createFunc()
    end
end


function Common.ShowExportWrapper(UI, L)
    if UI.CreateExportImportFrames then
        UI:CreateExportImportFrames()
    end
    
    if not UI.exportFrame or not UI.exportFrame.edit then
        print(L and L["UI_CB29"] or "Export frame not initialized")
        return
    end
    
    UI.exportFrame.edit:SetText(L and L["UI_CB30"] or "Preparing data...\n\nPlease wait...")
    UI.exportFrame:Show()
    UI.exportFrame.edit:SetFocus()
    
    if not Common.exportState.frame then
        Common.CreateProgressBar(L)
    end
    if Common.exportState.frame then
        Common.exportState.frame:Show()
    end
    
    local currentRealm = RL.NormalizeRealm(GetRealmName())
    local currentRealmData = {}
    if ReputationListDB and ReputationListDB.realms and ReputationListDB.realms[currentRealm] then
        currentRealmData[currentRealm] = ReputationListDB.realms[currentRealm]
    end
    
    local data = { realms = currentRealmData }
    print(L and L["UI_CB31"] or "|cFF00FF00ReputationList:|r Export starting...")
    
    if RL and RL.UICommon and RL.UICommon.AsyncSerialize then
        RL.UICommon.AsyncSerialize(data, function(resultString, count)
            if UI.exportFrame and UI.exportFrame.edit then
                UI.exportFrame.edit:SetText(resultString)
                UI.exportFrame.edit:HighlightText()
                print(string.format(L and L["UI_CB32"] or "|cFF00FF00ReputationList:|r Export completed! Records: %d", count or 0))
            end
        end, L)
    else
        UI.exportFrame:Show()
    end
end


function Common.ShowImportWrapper(UI, L)
    if UI.CreateExportImportFrames then
        UI:CreateExportImportFrames()
    end
    
    if UI.importFrame and UI.importFrame.edit then
        UI.importFrame.edit:SetText("")
        UI.importFrame.edit:SetFocus()
        UI.importFrame:Show()
    else
        print(L and L["UI_CB33"] or "Import frame not initialized")
    end
end

function Common.ToggleMainWindowWrapper(UI, CACHE)
    local mainFrame = CACHE.mainFrame
    if not mainFrame and UI.Initialize then
        UI:Initialize()
        mainFrame = CACHE.mainFrame
    end
    
    if mainFrame then
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()

        end
    end
end

function Common.CreateBlacklistDialogHandlers(L)
    return {
        OnShow = function(self)
            self.editBox:SetText(L and L["UI_BAD_P"] or "Bad player")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self, data)
            local playerName = data.name
            local note = self.editBox:GetText() or (L and L["UI_BAD_P"] or "Bad player")
            
            if RL and RL.AddPlayerDirect then
                RL:AddPlayerDirect(playerName, "blacklist", note, "target")
            end
        end
    }
end

function Common.SimpleSerialize(t, indent, maxDepth)
    indent = indent or 0
    maxDepth = maxDepth or 10
    if indent >= maxDepth then return "  ..." end
    
    local result = {}
    local space = string.rep("  ", indent)
    local count = 0
    
    for k, v in pairs(t) do
        count = count + 1
        if count > 1000 then
            table.insert(result, space .. "-- ...\n")
            break
        end
        
        local key = type(k) == "string" and '["'..k..'"]' or "["..k.."]"
        if type(v) == "table" then
            table.insert(result, space .. key .. " = {\n" .. Common.SimpleSerialize(v, indent+1, maxDepth) .. space .. "},\n")
        elseif type(v) == "string" then
            local str = (#v > 500) and (v:sub(1, 500) .. "...") or v
            table.insert(result, space .. key .. ' = "' .. str:gsub('"', '\\"') .. '",\n')
        else
            table.insert(result, space .. key .. " = " .. tostring(v) .. ",\n")
        end
    end
    return table.concat(result)
end

Common.exportState = Common.exportState or {
    inProgress = false,
    frame = nil,
    progressBar = nil,
    progressText = nil
}

function Common.CreateProgressBar(L)
    if Common.exportState.frame then return end
    
    local frame = CreateFrame("Frame", "RepListExportProgress", UIParent)
    frame:SetSize(400, 80)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(L and L["UI_CB15"] or "|cFF00FF00Data Export|r")
    
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetSize(360, 24)
    bar:SetPoint("CENTER", 0, -5)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0, 0.8, 0)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints(bar)
    barBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    barBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER", 0, 0)
    text:SetText(L and L["UI_CB46"] or "Processing: 0%")
    
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("BOTTOM", 0, 12)
    hint:SetText(L and L["UI_CB16"] or "|cFFFFFFFFGame is not frozen, processing...|r")
    
    frame:Hide()
    
    Common.exportState.frame = frame
    Common.exportState.progressBar = bar
    Common.exportState.progressText = text
end

function Common.AsyncSerialize(data, callback, L)
    if Common.exportState.inProgress then
        print(L and L["UI_CB11"] or "Export already in progress")
        return
    end
    
    Common.exportState.inProgress = true
    
    local allPlayers = {}
    if data.realms then
        for realm, lists in pairs(data.realms) do
            if type(lists) == "table" then
                for listType, list in pairs(lists) do
                    if type(list) == "table" then
                        for playerName, playerData in pairs(list) do
                            table.insert(allPlayers, {
                                realm = realm,
                                listType = listType,
                                playerName = playerName,
                                playerData = playerData
                            })
                        end
                    end
                end
            end
        end
    end
    
    local totalToProcess = #allPlayers
    if totalToProcess == 0 then
        Common.exportState.inProgress = false
        if Common.exportState.frame then Common.exportState.frame:Hide() end
        callback("ReputationList_Import = {\n  realms = {}\n}")
        return
    end
    
    local currentIndex = 1
    local BATCH_SIZE = 200
    local totalPlayers = 0
    local playerQueue = {}
    
    if Common.exportState.progressText then
        Common.exportState.progressText:SetText(L and L["UI_CB12"] or "Processing...")
    end
    
    local preparationFrame = CreateFrame("Frame")
    preparationFrame:SetScript("OnUpdate", function(self, elapsed)
        if currentIndex > totalToProcess then
            self:SetScript("OnUpdate", nil)
            allPlayers = nil
            
            if totalPlayers == 0 then
                Common.exportState.inProgress = false
                if Common.exportState.frame then Common.exportState.frame:Hide() end
                callback("ReputationList_Import = {\n  realms = {}\n}")
                return
            end
            
            Common.StartBatchSerialization(playerQueue, callback, L)
            return
        end
        
        local batchEnd = math.min(currentIndex + BATCH_SIZE - 1, totalToProcess)
        for i = currentIndex, batchEnd do
            local entry = allPlayers[i]
            table.insert(playerQueue, entry)
            totalPlayers = totalPlayers + 1
        end
        
        if Common.exportState.progressBar then
            local progress = (currentIndex / totalToProcess) * 50
            Common.exportState.progressBar:SetValue(progress)
            if Common.exportState.progressText then
                Common.exportState.progressText:SetText(string.format(L and L["UI_CB46"] or "Processing: %d%%", math.floor(progress)))
            end
        end
        
        currentIndex = batchEnd + 1
    end)
end

function Common.StartBatchSerialization(playerQueue, callback, L)
    local result = {"ReputationList_Import = {\n  realms = {\n"}
    local currentRealm = nil
    local currentListType = nil
    local currentIndex = 1
    local total = #playerQueue
    local BATCH_SIZE = 100
    
    if Common.exportState.progressText then
        Common.exportState.progressText:SetText(L and L["UI_CB13"] or "Serializing...")
    end
    
    local serializationFrame = CreateFrame("Frame")
    serializationFrame:SetScript("OnUpdate", function(self, elapsed)
        if currentIndex > total then
            self:SetScript("OnUpdate", nil)
            
            if currentListType then table.insert(result, "      }\n") end
            if currentRealm then table.insert(result, "    }\n") end
            table.insert(result, "  }\n}")
            
            Common.exportState.inProgress = false
            if Common.exportState.frame then 
                Common.exportState.frame:Hide() 
            end
            
            callback(table.concat(result), total)
            return
        end
        
        local batchEnd = math.min(currentIndex + BATCH_SIZE - 1, total)
        for i = currentIndex, batchEnd do
            local entry = playerQueue[i]
            
            if entry.realm ~= currentRealm then
                if currentListType then table.insert(result, "      }\n") currentListType = nil end
                if currentRealm then table.insert(result, "    }\n") end
                currentRealm = entry.realm
                table.insert(result, '    ["' .. entry.realm .. '"] = {\n')
            end
            
            if entry.listType ~= currentListType then
                if currentListType then table.insert(result, "      }\n") end
                currentListType = entry.listType
                table.insert(result, '      ["' .. entry.listType .. '"] = {\n')
            end
            
            local playerName = entry.playerName:gsub('"', '\\"')
            
            table.insert(result, '        ["' .. playerName .. '"] = {\n')
            
            local pd = entry.playerData
            if pd.note then
                local note = tostring(pd.note):gsub('"', '\\"')
                if #note > 500 then note = note:sub(1, 500) .. "..." end
                table.insert(result, '          note = "' .. note .. '",\n')
            end
            if pd.guid then table.insert(result, '          guid = "' .. tostring(pd.guid) .. '",\n') end
            if pd.class then table.insert(result, '          class = "' .. tostring(pd.class) .. '",\n') end
            if pd.race then table.insert(result, '          race = "' .. tostring(pd.race) .. '",\n') end
            if pd.level then table.insert(result, '          level = ' .. tostring(pd.level) .. ',\n') end
            if pd.guild then table.insert(result, '          guild = "' .. tostring(pd.guild):gsub('"', '\\"') .. '",\n') end
            if pd.faction then table.insert(result, '          faction = "' .. tostring(pd.faction) .. '",\n') end
            if pd.addedBy then table.insert(result, '          addedBy = "' .. tostring(pd.addedBy) .. '",\n') end
            if pd.timestamp then table.insert(result, '          timestamp = ' .. tostring(pd.timestamp) .. ',\n') end
            if pd.addedDate then table.insert(result, '          addedDate = "' .. tostring(pd.addedDate):gsub('"', '\\"') .. '",\n') end
            if pd.name then table.insert(result, '          name = "' .. tostring(pd.name):gsub('"', '\\"') .. '",\n') end
            if pd.key then table.insert(result, '          key = "' .. tostring(pd.key):gsub('"', '\\"') .. '",\n') end
            if pd.armoryLink then table.insert(result, '          armoryLink = "' .. tostring(pd.armoryLink):gsub('"', '\\"') .. '",\n') end
            
            table.insert(result, '        },\n')
        end
        
        if Common.exportState.progressBar then
            local progress = 50 + ((currentIndex / total) * 50)
            Common.exportState.progressBar:SetValue(progress)
            if Common.exportState.progressText then
                Common.exportState.progressText:SetText(string.format(L and L["UI_CB47"] or "Serializing: %d%%", math.floor(progress)))
            end
        end
        
        currentIndex = batchEnd + 1
    end)
end

Common.NormalizeName = function(name) return RL.NormalizeName(name) end
Common.IsInBlizzardIgnore = function(name)
    if RL.Security and RL.Security.IsInBlizzardIgnore then
        return RL.Security:IsInBlizzardIgnore(name)
    end
    return false, nil
end

function Common.DeletePlayerDialog(playerName, UI, STATE, L)
    StaticPopupDialogs["REPUTATION_DELETE_CONFIRM"] = {
        text = (L and L["CONFIRM_DELETE"] or "Delete %s from the list?"):format(playerName),
        button1 = L and L["UI_YES"] or "Yes",
        button2 = L and L["UI_NO"] or "No",
        OnAccept = function()
            if RL and RL.RemovePlayer then

                local listType = STATE.currentTab
                
                if listType == "whohere" then
                    local realmData = RL:GetRealmData()
                    local searchKey = string.lower(RL.NormalizeName(playerName))
                    
                    if realmData.blacklist[searchKey] then
                        listType = "blacklist"
                    elseif realmData.whitelist[searchKey] then
                        listType = "whitelist"
                    elseif realmData.notelist[searchKey] then
                        listType = "notelist"
                    else
                        print("|cFFFF0000ReputationList:|r Player not found in any list!")
                        return
                    end
                end
                
                local shortType = listType
                if listType == "blacklist" then
                    shortType = "black"
                elseif listType == "whitelist" then
                    shortType = "white"
                elseif listType == "notelist" then
                    shortType = "note"
                end
                RL:RemovePlayer(shortType, playerName)
            end
            if UI and UI.RefreshList then
                UI:RefreshList()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("REPUTATION_DELETE_CONFIRM")
end

function Common.EditPlayerDialog(playerName, currentNote, UI, STATE, L)
    StaticPopupDialogs["REPUTATION_EDIT_NOTE"] = {
        text = (L and L["UI_EDIT_NOTE"] or "Edit note for %s:"):format(playerName),
        button1 = L and L["UI_SAVE"] or "Save",
        button2 = L and L["UI_CANCEL"] or "Cancel",
        hasEditBox = true,
        maxLetters = 500,
        OnShow = function(self)
            self.editBox:SetText(currentNote or "")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local newNote = self.editBox:GetText()

            if RL then
                local realmData = RL:GetRealmData()
                local listType = STATE.currentTab
                
                if listType == "whohere" then
                    local searchKey = string.lower(RL.NormalizeName(playerName))
                    
                    if realmData.blacklist[searchKey] then
                        listType = "blacklist"
                    elseif realmData.whitelist[searchKey] then
                        listType = "whitelist"
                    elseif realmData.notelist[searchKey] then
                        listType = "notelist"
                    else
                        print("|cFFFF0000ReputationList:|r Player not found in any list!")
                        return
                    end
                end
                
                local targetList = nil
                
                if listType == "blacklist" then
                    targetList = realmData.blacklist
                elseif listType == "whitelist" then
                    targetList = realmData.whitelist
                elseif listType == "notelist" then
                    targetList = realmData.notelist
                end
                
                if targetList then
                    local key = string.lower(playerName)
                    if targetList[key] then
                        newNote = newNote or ""
                        if targetList[key].note ~= newNote and RL.AddHistoryRecord then
                            RL.AddHistoryRecord(targetList[key], L and L["HIST_CHANGE_NOTE"] or "Note changed")
                        end
                        targetList[key].note = newNote
                        RL.InvalidateCache()
                        RL:SaveSettings()
                    end
                end
            end
            if UI and UI.RefreshList then
                UI:RefreshList()
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local newNote = self:GetText()

            if RL then
                local realmData = RL:GetRealmData()
                local listType = STATE.currentTab
                
                if listType == "whohere" then
                    local searchKey = string.lower(RL.NormalizeName(playerName))
                    
                    if realmData.blacklist[searchKey] then
                        listType = "blacklist"
                    elseif realmData.whitelist[searchKey] then
                        listType = "whitelist"
                    elseif realmData.notelist[searchKey] then
                        listType = "notelist"
                    else
                        print("|cFFFF0000ReputationList:|r Player not found in any list!")
                        parent:Hide()
                        return
                    end
                end
                
                local targetList = nil
                
                if listType == "blacklist" then
                    targetList = realmData.blacklist
                elseif listType == "whitelist" then
                    targetList = realmData.whitelist
                elseif listType == "notelist" then
                    targetList = realmData.notelist
                end
                
                if targetList then
                    local key = string.lower(playerName)
                    if targetList[key] then
                        newNote = newNote or ""
                        if targetList[key].note ~= newNote and RL.AddHistoryRecord then
                            RL.AddHistoryRecord(targetList[key], L and L["HIST_CHANGE_NOTE"] or "Note changed")
                        end
                        targetList[key].note = newNote
                        RL.InvalidateCache()
                        RL:SaveSettings()
                    end
                end
            end
            if UI and UI.RefreshList then
                UI:RefreshList()
            end
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("REPUTATION_EDIT_NOTE")
end

function Common.KickPlayerDialog(playerName, UI, L)
    StaticPopupDialogs["REPUTATION_KICK_PROMPT"] = {
        text = (L and L["UI_CB9"] or "Kick %s from group?"):format(playerName),
        button1 = L and L["UI_YES"] or "Yes",
        button2 = L and L["UI_NO"] or "No",
        OnAccept = function(self, data)
            if GetNumRaidMembers() > 0 then
                for i = 1, GetNumRaidMembers() do
                    local name = UnitName("raid" .. i)
                    if name and RL.NormalizeName(name):lower() == playerName:lower() then
                        UninviteUnit(name)
                        print("|cFFFF0000ReputationList:|r " .. playerName .. (L and L["UI_OUT_G"] or " kicked from group"))
                        break
                    end
                end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do
                    local name = UnitName("party" .. i)
                    if name and RL.NormalizeName(name):lower() == playerName:lower() then
                        UninviteUnit(name)
                        print("|cFFFF0000ReputationList:|r " .. playerName .. (L and L["UI_OUT_G"] or " kicked from group"))
                        break
                    end
                end
            end
            if UI and UI.RefreshList then
                UI:RefreshList()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("REPUTATION_KICK_PROMPT", nil, nil, {name = playerName})
end

local HISTORY_MAX_VISIBLE_ROWS = 20
local HISTORY_ROW_HEIGHT = 16

function Common.CreatePlayerCardBase(L, options)
    
    options = options or {}
    
    local f = CreateFrame("Frame", options.frameName or "RepListPlayerCardBase", UIParent)
    f:SetSize(400, 350)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    
    if options.applyStyle then
        options.applyStyle(f, "frame", f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        f:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    end
    
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -15)
    f.title:SetTextColor(1, 0, 0)
    f.title:SetText(L["UI_POP1"] .. "BLACKLIST")
    
    f.factionLogo = f:CreateTexture(nil, "ARTWORK")
    f.factionLogo:SetSize(80, 80)
    f.factionLogo:SetPoint("TOPLEFT", 20, -50)
    
    local startY = -50
    local leftX = 110
    
    f.nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.nameLabel:SetPoint("TOPLEFT", leftX, startY)
    f.nameLabel:SetText(L["UI_LBL_NM"])
    f.nameValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.nameValue:SetPoint("LEFT", f.nameLabel, "RIGHT", 5, 0)
    f.nameValue:SetWidth(200)
    f.nameValue:SetJustifyH("LEFT")
    
    f.classLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.classLabel:SetPoint("TOPLEFT", leftX, startY - 25)
    f.classLabel:SetText(L["UI_LBL_CL"])
    f.classValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.classValue:SetPoint("LEFT", f.classLabel, "RIGHT", 5, 0)
    
    f.raceLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.raceLabel:SetPoint("TOPLEFT", leftX, startY - 45)
    f.raceLabel:SetText(L["UI_LBL_RC"])
    f.raceValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.raceValue:SetPoint("LEFT", f.raceLabel, "RIGHT", 5, 0)
    
    f.levelLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.levelLabel:SetPoint("TOPLEFT", leftX, startY - 65)
    f.levelLabel:SetText(L["UI_CB45"])
    f.levelValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.levelValue:SetPoint("LEFT", f.levelLabel, "RIGHT", 5, 0)
    
    f.guildLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.guildLabel:SetPoint("TOPLEFT", leftX, startY - 85)
    f.guildLabel:SetText(L["UI_LBL_GLD"])
    f.guildValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.guildValue:SetPoint("LEFT", f.guildLabel, "RIGHT", 5, 0)
    f.guildValue:SetWidth(200)
    f.guildValue:SetJustifyH("LEFT")
    
    f.guidLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.guidLabel:SetPoint("TOPLEFT", 20, startY - 110)
    f.guidLabel:SetText("|cFFFFFF00GUID:|r")
    f.guidValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.guidValue:SetPoint("LEFT", f.guidLabel, "RIGHT", 5, 0)
    f.guidValue:SetWidth(300)
    f.guidValue:SetJustifyH("LEFT")
    
    if options.withArmoryLink then
        f.armoryLinkLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.armoryLinkLabel:SetPoint("TOPLEFT", 20, startY - 135)
        f.armoryLinkLabel:SetText(L["WH_D07"])
        
        f.armoryLinkEditBox = CreateFrame("EditBox", nil, f)
        f.armoryLinkEditBox:SetSize(220, 20)
        f.armoryLinkEditBox:SetPoint("LEFT", f.armoryLinkLabel, "RIGHT", 5, 0)
        f.armoryLinkEditBox:SetAutoFocus(false)
        f.armoryLinkEditBox:SetFontObject(GameFontNormalSmall)
        f.armoryLinkEditBox:SetTextInsets(5, 5, 3, 3)
        f.armoryLinkEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        f.armoryLinkEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        
        if options.applyStyle then
            options.applyStyle(f, "editbox", f.armoryLinkEditBox)
        else
            f.armoryLinkEditBox:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            f.armoryLinkEditBox:SetBackdropColor(0, 0, 0, 0.5)
            f.armoryLinkEditBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
        
        f.armoryLinkSaveBtn = CreateFrame("Button", nil, f)
        f.armoryLinkSaveBtn:SetSize(20, 20)
        f.armoryLinkSaveBtn:SetPoint("LEFT", f.armoryLinkEditBox, "RIGHT", 5, 0)
        f.armoryLinkSaveBtn:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Check")
        f.armoryLinkSaveBtn:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        
        if options.applyStyle then
            options.applyStyle(f, "button", f.armoryLinkSaveBtn)
        else
            f.armoryLinkSaveBtn:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            f.armoryLinkSaveBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            f.armoryLinkSaveBtn:SetBackdropBorderColor(1.0, 1.0, 0.0, 1.0)
        end
        
        f.currentPlayerData = nil
    end
    
    f.noteLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.noteLabel:SetPoint("TOPLEFT", 20, -210)
    f.noteLabel:SetText(L["UI_LBL_NT"])
    
    f.noteText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.noteText:SetPoint("TOPLEFT", 20, -230)
    f.noteText:SetPoint("BOTTOMRIGHT", -20, 40)
    f.noteText:SetJustifyH("LEFT")
    f.noteText:SetJustifyV("TOP")
    f.noteText:SetTextColor(1, 1, 0.5)

    f.infoElements = {
        f.factionLogo,
        f.nameLabel, f.nameValue,
        f.classLabel, f.classValue,
        f.raceLabel, f.raceValue,
        f.levelLabel, f.levelValue,
        f.guildLabel, f.guildValue,
        f.guidLabel, f.guidValue,
        f.noteLabel, f.noteText,
    }
    if options.withArmoryLink then
        table.insert(f.infoElements, f.armoryLinkLabel)
        table.insert(f.infoElements, f.armoryLinkEditBox)
        table.insert(f.infoElements, f.armoryLinkSaveBtn)
    end
    
    local closeBtn
    if options.applyStyle then
        closeBtn = CreateFrame("Button", nil, f)
    else
        closeBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    end
    closeBtn:SetSize(100, 25)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    
    if options.applyStyle then
        options.applyStyle(f, "closebutton", closeBtn)
        local closeBtnText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        closeBtnText:SetPoint("CENTER")
        closeBtnText:SetText(L["UI_CLOSE"])
    else
        closeBtn:SetText(L["UI_CLOSE"])
    end
    
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local historyBtn
    if options.applyStyle then
        historyBtn = CreateFrame("Button", nil, f)
    else
        historyBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    end
    historyBtn:SetSize(90, 22)
    historyBtn:SetPoint("TOPRIGHT", -10, -12)

    local historyBtnTextFS
    if options.applyStyle then
        options.applyStyle(f, "closebutton", historyBtn)
        historyBtnTextFS = historyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        historyBtnTextFS:SetPoint("CENTER")
        historyBtnTextFS:SetText(L["HIST_BTN"])
    else
        historyBtn:SetText(L["HIST_BTN"])
    end

    local function SetHistoryBtnText(text)
        if historyBtnTextFS then
            historyBtnTextFS:SetText(text)
        else
            historyBtn:SetText(text)
        end
    end

    local sectionX = 20
    local hy = -50

    f.histPlayerLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.histPlayerLine:SetPoint("TOPLEFT", sectionX, hy)
    f.histPlayerLine:SetPoint("RIGHT", f, "RIGHT", -20, 0)
    f.histPlayerLine:SetJustifyH("LEFT")
    if f.histPlayerLine.SetWordWrap then f.histPlayerLine:SetWordWrap(false) end
    hy = hy - 18

    f.histAddedLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.histAddedLine:SetPoint("TOPLEFT", sectionX, hy)
    f.histAddedLine:SetPoint("RIGHT", f, "RIGHT", -20, 0)
    f.histAddedLine:SetJustifyH("LEFT")
    if f.histAddedLine.SetWordWrap then f.histAddedLine:SetWordWrap(false) end
    hy = hy - 16

    f.histAddedByLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.histAddedByLine:SetPoint("TOPLEFT", sectionX, hy)
    f.histAddedByLine:SetPoint("RIGHT", f, "RIGHT", -20, 0)
    f.histAddedByLine:SetJustifyH("LEFT")
    if f.histAddedByLine.SetWordWrap then f.histAddedByLine:SetWordWrap(false) end
    hy = hy - 18

    f.histDataHeader = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.histDataHeader:SetPoint("TOPLEFT", sectionX, hy)
    f.histDataHeader:SetText(L["HIST_ADDED_DATA"])
    hy = hy - 15

    f.histDataValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.histDataValue:SetPoint("TOPLEFT", sectionX + 5, hy)
    f.histDataValue:SetPoint("RIGHT", f, "RIGHT", -20, 0)
    f.histDataValue:SetJustifyH("LEFT")
    f.histDataValue:SetJustifyV("TOP")
    f.histDataValue:SetSpacing(2)
    hy = hy - 32

    f.histLastSeenLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.histLastSeenLine:SetPoint("TOPLEFT", sectionX, hy)
    f.histLastSeenLine:SetPoint("RIGHT", f, "RIGHT", -20, 0)
    f.histLastSeenLine:SetJustifyH("LEFT")
    if f.histLastSeenLine.SetWordWrap then f.histLastSeenLine:SetWordWrap(false) end
    hy = hy - 18

    f.histDivider = f:CreateTexture(nil, "ARTWORK")
    f.histDivider:SetHeight(1)
    f.histDivider:SetPoint("TOPLEFT", sectionX, hy)
    f.histDivider:SetPoint("RIGHT", f, "RIGHT", -20, 0)
    f.histDivider:SetTexture(1, 1, 1, 0.2)
    hy = hy - 10

    f.histUpdatesSectionLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.histUpdatesSectionLabel:SetPoint("TOPLEFT", sectionX, hy)
    f.histUpdatesSectionLabel:SetText(L["HIST_UPDATES_SECTION"])
    f.histUpdatesSectionLabel:SetTextColor(1, 0.82, 0)
    hy = hy - 16

    f.histLastUpdateValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.histLastUpdateValue:SetPoint("TOPLEFT", sectionX, hy)
    f.histLastUpdateValue:SetPoint("RIGHT", f, "RIGHT", -20, 0)
    f.histLastUpdateValue:SetJustifyH("LEFT")
    f.histLastUpdateValue:SetTextColor(0.6, 1, 0.6)
    hy = hy - 32

    local histScrollFrame = CreateFrame("ScrollFrame", nil, f)
    histScrollFrame:SetPoint("TOPLEFT", sectionX, hy)
    histScrollFrame:SetPoint("BOTTOMRIGHT", -34, 40)

    local histContent = CreateFrame("Frame", nil, histScrollFrame)
    histContent:SetSize(1, 1)
    histScrollFrame:SetScrollChild(histContent)

    local histScrollbar = CreateFrame("Slider", nil, f)
    histScrollbar:SetPoint("TOPLEFT", histScrollFrame, "TOPRIGHT", 4, 0)
    histScrollbar:SetPoint("BOTTOMLEFT", histScrollFrame, "BOTTOMRIGHT", 4, 0)
    histScrollbar:SetWidth(16)
    histScrollbar:SetOrientation("VERTICAL")
    histScrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    histScrollbar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })
    histScrollbar:SetMinMaxValues(0, 100)
    histScrollbar:SetValueStep(1)
    histScrollbar:SetValue(0)
    histScrollbar:SetScript("OnValueChanged", function(self, value)
        histScrollFrame:SetVerticalScroll(value)
    end)

    histScrollFrame:EnableMouseWheel(true)
    histScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = histScrollbar:GetValue()
        local minV, maxV = histScrollbar:GetMinMaxValues()
        local newV = math.max(minV, math.min(maxV, current - delta * (HISTORY_ROW_HEIGHT * 3)))
        histScrollbar:SetValue(newV)
    end)

    f.histScrollFrame = histScrollFrame
    f.histContent = histContent
    f.histScrollbar = histScrollbar

    f.histRows = {}
    for i = 1, HISTORY_MAX_VISIBLE_ROWS do
        local row = histContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row:SetPoint("TOPLEFT", 0, 0)
        row:SetPoint("RIGHT", histContent, "RIGHT", 0, 0)
        row:SetJustifyH("LEFT")
        row:SetJustifyV("TOP")
        if row.SetWordWrap then row:SetWordWrap(true) end
        row:Hide()
        f.histRows[i] = row
    end

    f.histNoUpdatesText = histContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.histNoUpdatesText:SetPoint("TOPLEFT", 0, 0)
    f.histNoUpdatesText:SetText(L["HIST_NO_UPDATES"])
    f.histNoUpdatesText:SetTextColor(0.6, 0.6, 0.6)
    f.histNoUpdatesText:Hide()

    f.histNoDataText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.histNoDataText:SetPoint("CENTER", 0, -20)
    f.histNoDataText:SetTextColor(1, 0.5, 0.5)
    f.histNoDataText:SetText(L["HIST_NO_DATA"])
    f.histNoDataText:Hide()

    f.historyElements = {
        f.histPlayerLine, f.histAddedLine, f.histAddedByLine,
        f.histDataHeader, f.histDataValue, f.histLastSeenLine,
        f.histDivider, f.histUpdatesSectionLabel, f.histLastUpdateValue,
        f.histScrollFrame, f.histScrollbar,
    }

    f.viewMode = "info"

    f.SetViewMode = function(mode)
        f.viewMode = mode
        local showInfo = (mode ~= "history")

        for _, el in ipairs(f.infoElements) do
            if el then
                if showInfo then el:Show() else el:Hide() end
            end
        end
        for _, el in ipairs(f.historyElements) do
            if el then
                if showInfo then el:Hide() else el:Show() end
            end
        end

        if showInfo then
            f.histNoDataText:Hide()
            SetHistoryBtnText(L["HIST_BTN"])
        else
            SetHistoryBtnText(L["HIST_BACK_BTN"])
        end
    end

    historyBtn:SetScript("OnClick", function()
        if f.viewMode == "history" then
            f.SetViewMode("info")
        else

            local histData = f.currentPlayerData
            if histData and histData.listData then
                histData = histData.listData
            end
            Common.PopulateHistoryWindow(f, histData, L)
            f.SetViewMode("history")
        end
    end)

    f.historyBtn = historyBtn

    f.SetViewMode("info")

    f:Hide()
    return f
end

function Common.PopulateHistoryWindow(f, data, L)
    if not f then return end

    if not data or not data.addedDate then
        f.histNoDataText:SetText(L["HIST_NO_DATA"])
        f.histNoDataText:Show()

        f.histPlayerLine:Hide()
        f.histAddedLine:Hide()
        f.histAddedByLine:Hide()
        f.histDataHeader:Hide(); f.histDataValue:Hide()
        f.histLastSeenLine:Hide()
        f.histDivider:Hide()
        f.histUpdatesSectionLabel:Hide()
        f.histLastUpdateValue:Hide()
        f.histScrollFrame:Hide()
        f.histScrollbar:Hide()

        for i = 1, #f.histRows do
            f.histRows[i]:Hide()
        end
        f.histNoUpdatesText:Hide()

        return
    end

    f.histNoDataText:Hide()
    f.histPlayerLine:Show()
    f.histAddedLine:Show()
    f.histAddedByLine:Show()
    f.histDataHeader:Show(); f.histDataValue:Show()
    f.histLastSeenLine:Show()
    f.histDivider:Show()
    f.histUpdatesSectionLabel:Show()
    f.histLastUpdateValue:Show()
    f.histScrollFrame:Show()

    local unknown = L["HIST_UNKNOWN"]

    f.histPlayerLine:SetText((L["HIST_PLAYER"] or "") .. " " .. (data.name or "?"))
    f.histAddedLine:SetText(L["HIST_ADDED_DATE"] .. " " .. (data.addedDate or unknown) .. "   " .. L["HIST_ADDED_REALM"] .. " " .. (data.addedRealm or unknown))
    f.histAddedByLine:SetText(L["HIST_ADDED_BY"] .. " " .. (data.addedBy or unknown))

    local snap = data.addedSnapshot
    local dataLines
    if snap then
        dataLines = string.format(
            "%s %s   %s %s   %s %s\n%s %s   %s %s",
            L["HIST_CLASS"], snap.class or unknown,
            L["HIST_RACE"], snap.race or unknown,
            L["HIST_LEVEL"], tostring(snap.level or unknown),
            L["HIST_GUILD"], snap.guild or unknown,
            L["HIST_FACTION"], snap.faction or unknown
        )
    else
        dataLines = unknown
    end
    f.histDataValue:SetText(dataLines)

    f.histLastSeenLine:SetText(L["HIST_LAST_SEEN"] .. " " .. (data.lastSeenDate or unknown))

    if data.lastUpdateDate then
        f.histLastUpdateValue:SetText(
            L["HIST_LAST_UPDATE"] .. " " .. data.lastUpdateDate ..
            " (" .. (L["HIST_BY"] or "") .. " " .. (data.lastUpdateBy or unknown) .. ")\n" ..
            (data.lastUpdateChange or "")
        )
    else
        f.histLastUpdateValue:SetText(L["HIST_NO_UPDATES"])
    end

    local history = data.history
    local count = history and #history or 0

    if count == 0 then
        for i = 1, #f.histRows do
            f.histRows[i]:Hide()
        end
        f.histNoUpdatesText:Show()
        f.histScrollbar:Hide()
        f.histContent:SetHeight(20)
        f.histScrollbar:SetMinMaxValues(0, 0)
        f.histScrollbar:SetValue(0)
    else
        f.histNoUpdatesText:Hide()
        local visible = math.min(count, HISTORY_MAX_VISIBLE_ROWS)
        local ROW_GAP = 4
        local cumulativeY = 0

        local contentWidth = f.histScrollFrame:GetWidth() or 0
        if contentWidth > 0 then
            f.histContent:SetWidth(contentWidth)
        end

        for i = 1, visible do
            local entry = history[i]
            local row = f.histRows[i]
            row:SetText("|cFFAAAAAA" .. (entry.date or "") .. "|r  " .. (entry.change or ""))
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -cumulativeY)
            row:SetPoint("RIGHT", f.histContent, "RIGHT", 0, 0)
            row:Show()
            local rowHeight = row:GetStringHeight() or HISTORY_ROW_HEIGHT
            if rowHeight < HISTORY_ROW_HEIGHT then rowHeight = HISTORY_ROW_HEIGHT end
            cumulativeY = cumulativeY + rowHeight + ROW_GAP
        end
        for i = visible + 1, #f.histRows do
            f.histRows[i]:Hide()
        end

        f.histContent:SetHeight(math.max(1, cumulativeY))

        local frameHeight = f.histScrollFrame:GetHeight() or 0
        local maxScroll = math.max(0, cumulativeY - frameHeight)
        if maxScroll > 0 then
            f.histScrollbar:Show()
            f.histScrollbar:SetMinMaxValues(0, maxScroll)
        else
            f.histScrollbar:Hide()
            f.histScrollbar:SetMinMaxValues(0, 0)
        end
        f.histScrollbar:SetValue(0)
        f.histScrollFrame:SetVerticalScroll(0)
    end
end

function Common.CreateStandardCloseButton(frame)
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)
    return closeBtn
end

function Common.CreateFrameTitle(frame, titleText, L)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText(titleText or (L and L["UI_CB15"] or "Settings"))
    return title
end

function Common.CreateStandardScrollBar(scrollFrame)
    local scrollbar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetMinMaxValues(0, 100)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    return scrollbar
end

function Common.CreateRaidPlayerMarkup(button, cleanName, listType, color)
    if not button.repHighlight then
        local highlight = CreateFrame("Frame", nil, button)
        highlight:SetAllPoints(button)
        highlight:SetFrameLevel(button:GetFrameLevel() + 1)
        
        local texture = highlight:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight.texture = texture
        
        button.repHighlight = highlight
    end
    
    button.repHighlight:SetFrameLevel(button:GetFrameLevel() + 1)
    button.repHighlight.texture:SetVertexColor(color[1], color[2], color[3], 0.15)
    button.repHighlight:Show()
    
    button.repMarkup = button.repHighlight
end

function Common.CreateGuildPlayerMarkup(button, nameFS, cleanName, listType, markup, color, L, CACHE, STATE, SocialUI, isElvUI)
    if not button.repHighlight then
        local highlight = CreateFrame("Frame", nil, button)
        highlight:SetFrameLevel(button:GetFrameLevel() + 1)
        
        local texture = highlight:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight.texture = texture
        
        button.repHighlight = highlight
    end
    
    button.repHighlight:SetFrameLevel(button:GetFrameLevel() + 1)
    
    if not isElvUI then
        button.repHighlight:ClearAllPoints()
        button.repHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 10, 0)
        button.repHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    else
        button.repHighlight:SetAllPoints(button)
    end
    
    button.repHighlight.texture:SetVertexColor(color[1], color[2], color[3], 0.15)
    button.repHighlight:Show()
    
    if not button.repMarkupBtn then
        local markupBtn = CreateFrame("Button", nil, button)
        markupBtn:SetSize(20, 12)
        markupBtn:SetPoint("LEFT", nameFS, "RIGHT", 85, 0)
        markupBtn:SetFrameLevel(button:GetFrameLevel() + 2)
        
        local markupText = markupBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        markupText:SetPoint("CENTER", 0, 0)
        markupBtn.text = markupText
        
        markupBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText((L and L["UI_CB51"] or "View info: ") .. self.playerName, 1, 1, 1)
            GameTooltip:AddLine(L and L["UI_CB52"] or "Click to view in ReputationList", 0.7, 0.7, 0.7)
            GameTooltip:Show()
            self.text:SetTextColor(1, 1, 0)
        end)
        
        markupBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            local col = self.markupColor
            if col then
                self.text:SetTextColor(col[1], col[2], col[3])
            end
        end)
        
        markupBtn:SetScript("OnClick", function(self)
            if not FriendsFrame:IsShown() then
                ShowUIPanel(FriendsFrame)
            end
            
            if CACHE.tab then
                PanelTemplates_Tab_OnClick(CACHE.tab, FriendsTabHeader)
                SocialUI:ShowReputationList()
                STATE.currentTab = self.listType
                SocialUI:UpdateTabAppearance()
                SocialUI:RefreshList()
                
                if CACHE.container and CACHE.container.searchBox then
                    CACHE.container.searchBox:SetText(self.playerName)
                end
            end
        end)
        
        button.repMarkupBtn = markupBtn
    end
    
    button.repMarkupBtn.text:SetText(markup)
    button.repMarkupBtn.text:SetTextColor(color[1], color[2], color[3])
    button.repMarkupBtn.playerName = cleanName
    button.repMarkupBtn.listType = listType
    button.repMarkupBtn.markupColor = color
    button.repMarkupBtn:Show()
    
    button.repMarkup = button.repMarkupBtn
end

function Common.CreatePlayerMarkupButton(button, nameFS, cleanName, listType, markup, color, L, CACHE, STATE, SocialUI)
    Common.CreateGuildPlayerMarkup(button, nameFS, cleanName, listType, markup, color, L, CACHE, STATE, SocialUI, false)
end

return Common
