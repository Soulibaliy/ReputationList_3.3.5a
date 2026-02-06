-- ============================================================================
-- Reputation List - Classic UI
-- ============================================================================

local RL = ReputationList
if not RL then return end

if ElvUI and RL.UI and RL.UI.ElvUI then
    return
end


local UI = {}
RL.UI = RL.UI or {}
RL.UI.Classic = UI

local L = ReputationList.L or ReputationListLocale

local Common = RL.UICommon

local CONFIG = {
    FRAME_WIDTH = 500,
    FRAME_HEIGHT = 400,
    ROW_HEIGHT = 24,
    VISIBLE_ROWS = 12,
    SEARCH_WIDTH = 150,
    BUTTON_SIZE = 20,
    PADDING = 6,
}

local STATE = {
    currentTab = "blacklist",
    searchText = "",
    scrollOffset = 0,
    selectedPlayer = nil,
    showGroupMembers = false,
}

local CACHE = {
    mainFrame = nil,
    tabs = {},
    rows = {},
    scrollFrame = nil,
    settingsFrame = nil,
    filteredPlayers = {},
}

UI.framePool = {}

local function GetPooledFrame(parent)
    return Common.GetPooledFrame(parent, UI.framePool, RL.UICommon)
end

local function ReleaseFrame(frame)
    Common.ReleaseFrame(frame, UI.framePool, RL.UICommon)
end


function UI:CreateMainFrame()
    if CACHE.mainFrame then return CACHE.mainFrame end
    
    local f = CreateFrame("Frame", "ReputationListFrameNew", UIParent)
    f:SetSize(CONFIG.FRAME_WIDTH, CONFIG.FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)
    
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetBackdropColor(0, 0, 0, 1)
    
    f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end)
    f:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)
    
    CACHE.mainFrame = f
    return f
end


function UI:CreateHeader(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("Reputation List - Blacklist (0)")
    title:SetTextColor(0, 1, 0)
    parent.titleText = title
    
    local kickBtn = CreateFrame("Button", nil, parent)
    kickBtn:SetSize(24, 24)
    kickBtn:SetPoint("TOPRIGHT", -45, -15)
    
    kickBtn:SetNormalTexture("Interface\\GossipFrame\\Battlemastergossipicon")
    kickBtn:SetHighlightTexture("Interface\\GossipFrame\\Battlemastergossipicon")
    kickBtn:GetHighlightTexture():SetAlpha(0.5)
    
    kickBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["UI_GT"], 1, 0.3, 0.3)
        GameTooltip:AddLine(L["UI_GTline"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    kickBtn:SetScript("OnLeave", GameTooltip_Hide)
    kickBtn:SetScript("OnClick", function()
        if UnitExists("target") and UnitIsPlayer("target") then
            local targetName = UnitName("target")
            if targetName then
                targetName = RL.NormalizeName(targetName)
                StaticPopup_Show("REPUTATION_KICK_PROMPT", targetName, nil, {name = targetName})
            end
        else
            print("|cFFFF0000ReputationList:|r " .. L["UI_TGTPL"])
        end
    end)
    parent.kickBtn = kickBtn
    
    local notifyBtn = CreateFrame("Button", nil, parent)
    notifyBtn:SetSize(24, 24)
    notifyBtn:SetPoint("RIGHT", kickBtn, "LEFT", -5, 0)
    
    notifyBtn:SetNormalTexture("Interface\\GossipFrame\\Petitiongossipicon")
    notifyBtn:SetHighlightTexture("Interface\\GossipFrame\\Petitiongossipicon")
    notifyBtn:GetHighlightTexture():SetAlpha(0.5)
    
    notifyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["UI_CHECK"], 0.5, 1, 0.5)
        GameTooltip:AddLine(L["UI_CHKGR"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    notifyBtn:SetScript("OnLeave", GameTooltip_Hide)
    notifyBtn:SetScript("OnClick", function()
        if RL.ManualNotify then RL:ManualNotify() end
    end)
    parent.notifyBtn = notifyBtn
    
    local whoHereLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whoHereLabel:SetPoint("RIGHT", notifyBtn, "LEFT", -95, 0)
    whoHereLabel:SetText(L["UI_WHO_HERE"] or "Кто здесь?")
    whoHereLabel:SetTextColor(1, 1, 1)
    parent.whoHereLabel = whoHereLabel
    
    local whoHereCheckbox = CreateFrame("CheckButton", "ReputationWhoHereCheckbox", parent, "UICheckButtonTemplate")
    whoHereCheckbox:SetSize(24, 24)
    whoHereCheckbox:SetPoint("LEFT", whoHereLabel, "RIGHT", 5, 0)
    
     whoHereCheckbox:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        
        if isChecked then
            local hasGroup = RL.GroupTracker and RL.GroupTracker:IsInGroup()
            local hasSavedGroup = false
            
            if RL.GroupTracker then
                local saved = RL.GroupTracker:GetSavedGroup()
                if saved and saved.members and next(saved.members) then
                    hasSavedGroup = true
                end
            end
            
            local hasCachedData = false
            if ReputationGroupTrackerDB and ReputationGroupTrackerDB.whoHereCache then
                hasCachedData = next(ReputationGroupTrackerDB.whoHereCache) ~= nil
            end
            
            if not hasGroup and not hasSavedGroup and not hasCachedData then
                self:SetChecked(false)
                print(L["WH_D01"])
                return
            end
            
            if not hasGroup and (hasSavedGroup or hasCachedData) then
                print(L["WH_D02"])
            end
        end
        
        STATE.showGroupMembers = isChecked
		
		
        STATE.currentTab = isChecked and "whohere" or "blacklist"
        
        UI:UpdateTabAppearance()
        UI:RefreshList()
    end)
    
    whoHereCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["WH_D03"] or "Кто здесь?", 1, 1, 0)
        GameTooltip:AddLine(L["WH_D04"] or "Показать игроков в текущей группе/рейде", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    whoHereCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    
    parent.whoHereCheckbox = whoHereCheckbox
    
    local closeBtn = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -10, -10)
    closeBtn:SetScript("OnClick", function()
        parent:Hide()
    end)
    
    return title, closeBtn
end


function UI:CreateToolbar(parent)
    local toolbar = CreateFrame("Frame", nil, parent)
    toolbar:SetPoint("TOPLEFT", 30, -40)
    toolbar:SetPoint("TOPRIGHT", -10, -40)
    toolbar:SetHeight(28)
    
    local tabs = {}
    local tabData = {
        {key = "blacklist", text = "Blacklist", color = {1, 0, 0}},
        {key = "whitelist", text = "Whitelist", color = {0, 1, 0}},
        {key = "notelist", text = "Notelist", color = {1, 0.66, 0}},
        {key = "settings", text = L["UI_SETTINGS"], color = {1, 0.82, 0}},
    }
    
    for i, data in ipairs(tabData) do
        local tab = CreateFrame("Button", "$parentTab"..i, toolbar)
        local tabWidth = 75
        local tabSpacing = 2
        local startOffset = -5
        
        tab:SetSize(tabWidth, 28)
        tab:SetPoint("LEFT", startOffset + (i-1) * (tabWidth + tabSpacing), 0)
        tab:SetID(i)
        
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        tab:SetBackdropColor(0, 0, 0, 0.7)
        tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER", 0, 0)
        text:SetText(data.text)
        text:SetTextColor(data.color[1], data.color[2], data.color[3])
        tab.text = text
        
        tab:SetScript("OnEnter", function(self)
            if STATE.currentTab ~= data.key then
                self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            end
            self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        end)
        
        tab:SetScript("OnLeave", function(self)
            if STATE.currentTab ~= data.key then
                self:SetBackdropColor(0, 0, 0, 0.7)
            end
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end)
        
        tab:SetScript("OnClick", function()
            if parent.whoHereCheckbox and parent.whoHereCheckbox:GetChecked() then
                parent.whoHereCheckbox:SetChecked(false)
                STATE.showGroupMembers = false
            end
            
            STATE.currentTab = data.key
            UI:UpdateTabAppearance()
            if data.key == "settings" then
                UI:ShowSettingsInline()
            else
                UI:RefreshList()
            end
        end)
        
        tab.data = data
        tabs[data.key] = tab
    end
    
    CACHE.tabs = tabs
    
    local searchBox = CreateFrame("EditBox", nil, toolbar)
    searchBox:SetSize(CONFIG.SEARCH_WIDTH, 26)
    searchBox:SetPoint("RIGHT", -5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject(GameFontNormalSmall)
    
    searchBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    searchBox:SetBackdropColor(0, 0, 0, 0.5)
    searchBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    searchBox:SetTextInsets(8, 5, 3, 3)
    
    searchBox:SetScript("OnTextChanged", function(self)
        STATE.searchText = self:GetText():lower()
        STATE.scrollOffset = 0
        UI:RefreshList()
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    
    parent.searchBox = searchBox
end


function UI:UpdateTabAppearance()
    if not CACHE.tabs then return end
    
    if STATE.showGroupMembers then
        for key, tab in pairs(CACHE.tabs) do
            tab:SetBackdropColor(0, 0, 0, 0.7)
            tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            if tab.text then
                tab.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
        
        if CACHE.mainFrame and CACHE.mainFrame.titleText then
            local count = 0
            if RL.GroupTracker then
                local members = RL.GroupTracker:GetCurrentGroupMembers()
                for _ in pairs(members) do
                    count = count + 1
                end
            end
            CACHE.mainFrame.titleText:SetText("Reputation List - " .. (L["UI_WHO_HERE"] or "Кто здесь?") .. " (" .. count .. ")")
        end
        return
    end
    
    for key, tab in pairs(CACHE.tabs) do
        local isActive = (key == STATE.currentTab)
        
        if isActive then
            tab:SetBackdropColor(0, 0, 0, 0.9)
            tab:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        else
            tab:SetBackdropColor(0, 0, 0, 0.7)
            tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
        
        if tab.text then
            if isActive then
                tab.text:SetTextColor(tab.data.color[1], tab.data.color[2], tab.data.color[3])
            else
                tab.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end
    
    local titleMap = {
        blacklist = "Blacklist",
        whitelist = "Whitelist",
        notelist = "Notelist",
        settings = "Settings"
    }
    
    if CACHE.mainFrame and CACHE.mainFrame.titleText then
        local tabTitle = titleMap[STATE.currentTab] or "Reputation List"
        local count = 0
        
        if STATE.currentTab ~= "settings" then
            local realmData = RL:GetRealmData()
            if realmData and realmData[STATE.currentTab] then
                for _ in pairs(realmData[STATE.currentTab]) do
                    count = count + 1
                end
            end
            CACHE.mainFrame.titleText:SetText(string.format("Reputation List - %s (%d)", tabTitle, count))
        else
            CACHE.mainFrame.titleText:SetText("Reputation List - " .. L["UI_SETTINGS"])
        end
    end
end


function UI:CreateTableHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", 10, -75)
    header:SetPoint("TOPRIGHT", -10, -75)
    header:SetHeight(20)
    
    header:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true, tileSize = 16,
    })
    header:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    
    local nameText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", 8, 0)
    nameText:SetText(L["UI_PLAYER_NAME"])
    nameText:SetTextColor(1, 1, 1)
    
    local noteText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteText:SetPoint("LEFT", 100, 0)
    noteText:SetText(L["UI_NOTE"])
    noteText:SetTextColor(1, 1, 1)
    
    local actionsText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    actionsText:SetPoint("RIGHT", -8, 0)
    actionsText:SetText(L["UI_ACTION"])
    actionsText:SetTextColor(1, 1, 1)
    
    CACHE.tableHeader = header
    return header
end


function UI:CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", 10, -98)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 60)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    
    local scrollbar = CreateFrame("Slider", nil, scrollFrame)
    scrollbar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -98)
    scrollbar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 60)
    scrollbar:SetWidth(16)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollbar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })
    
    scrollbar:SetMinMaxValues(0, 100)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    
    scrollbar:SetScript("OnValueChanged", function(self, value)
        local newOffset = math.floor(value)
        if STATE.scrollOffset ~= newOffset then
            STATE.scrollOffset = newOffset
            UI:UpdateVisibleRows()
            
            collectgarbage("step", 100)
        end
    end)
    
    scrollFrame.scrollbar = scrollbar
    CACHE.scrollFrame = scrollFrame
    
    UI:CreateRows(content)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local new = math.max(min, math.min(max, current - delta * 3))
        scrollbar:SetValue(new)
    end)
    
    return scrollFrame
end

function UI:CreateRows(parent)
    CACHE.rows = {}
    
    for i = 1, CONFIG.VISIBLE_ROWS do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(CONFIG.FRAME_WIDTH - 40, CONFIG.ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i-1) * CONFIG.ROW_HEIGHT)
        
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetTexture(1, 1, 1, 1)
        if i % 2 == 0 then
            row.bg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
        else
            row.bg:SetVertexColor(0.1, 0.1, 0.1, 0.3)
        end
        
        row.index = i
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            self.bg:SetVertexColor(0.3, 0.3, 0.4, 0.5)
        end)
        row:SetScript("OnLeave", function(self)
            if self.index % 2 == 0 then
                self.bg:SetVertexColor(0.15, 0.15, 0.15, 0.5)
            else
                self.bg:SetVertexColor(0.1, 0.1, 0.1, 0.3)
            end
        end)
        
        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", 8, 0)
        row.nameText:SetWidth(90)
        row.nameText:SetJustifyH("LEFT")
        
        row.noteText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.noteText:SetPoint("LEFT", 100, 0)
        row.noteText:SetWidth(240)
        row.noteText:SetJustifyH("LEFT")
        
        row.buttons = UI:CreateRowButtons(row)
        
        row:Hide()
        CACHE.rows[i] = row
    end
end

function UI:UpdateRowDisplay(row, data, isWhoHereMode)
    if not row or not data then return end
    
    local nameColor = {1, 1, 1}
    
    if isWhoHereMode then
        if data.inList then
            if data.listType == "blacklist" then
                nameColor = {1, 0, 0}
            elseif data.listType == "whitelist" then
                nameColor = {0, 1, 0}
            elseif data.listType == "notelist" then
                nameColor = {1, 0.66, 0}
            end
        end
    else
        if STATE.currentTab == "blacklist" then
            nameColor = {1, 0, 0}
        elseif STATE.currentTab == "whitelist" then
            nameColor = {0, 1, 0}
        elseif STATE.currentTab == "notelist" then
            nameColor = {1, 0.66, 0}
        end
    end
    
    row.nameText:SetText(data.name or "???")
    row.nameText:SetTextColor(nameColor[1], nameColor[2], nameColor[3])
    row.playerName = data.name
    
    row.noteText:SetText(data.note or "")
    row.noteText:SetTextColor(0.9, 0.9, 0.9)
    row.playerNote = data.note
    
    row.playerData = data
    
    if row.buttons.info then row.buttons.info:Show() end
    if row.buttons.ignore then row.buttons.ignore:Show() end
    
    if isWhoHereMode then
        if data.inList then
            if row.buttons.edit then row.buttons.edit:Show() end
            if row.buttons.delete then row.buttons.delete:Show() end
            if row.buttons.addToList then row.buttons.addToList:Hide() end
            if row.listTypeDropdown then row.listTypeDropdown:Hide() end
        else
            if row.buttons.edit then row.buttons.edit:Hide() end
            if row.buttons.delete then row.buttons.delete:Hide() end
            if row.buttons.addToList then row.buttons.addToList:Show() end
            if row.listTypeDropdown then row.listTypeDropdown:Show() end
        end
    else
        if row.buttons.edit then row.buttons.edit:Show() end
        if row.buttons.delete then row.buttons.delete:Show() end
        if row.buttons.addToList then row.buttons.addToList:Hide() end
        if row.listTypeDropdown then row.listTypeDropdown:Hide() end
    end
    
    local ignored = RL.IsInBlizzardIgnore(data.name)
    local ignoreText = ignored and (L["UI_UNLOCK"] or "Разблок") or (L["UI_IG"] or "Игнор")
    row.buttons.ignore:SetText(ignoreText)
end


function UI:CreateRowButtons(row)
    local buttons = {}
    local buttonSize = CONFIG.BUTTON_SIZE
    local startX = -8
    
    local deleteBtn = CreateFrame("Button", nil, row)
    deleteBtn:SetSize(buttonSize, buttonSize)
    deleteBtn:SetPoint("RIGHT", startX, 0)
    deleteBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    deleteBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
    deleteBtn:SetScript("OnClick", function()
        if row.playerName then
            UI:DeletePlayer(row.playerName)
        end
    end)
    deleteBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["UI_DELETE"])
        GameTooltip:Show()
    end)
    deleteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons.delete = deleteBtn
    
    local editBtn = CreateFrame("Button", nil, row)
    editBtn:SetSize(buttonSize, buttonSize)
    editBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -3, 0)
    editBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    editBtn:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Highlight")
    editBtn:SetScript("OnClick", function()
        if row.playerName then
            UI:EditPlayer(row.playerName, row.playerNote)
        end
    end)
    editBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["UI_EDITT"])
        GameTooltip:Show()
    end)
    editBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons.edit = editBtn
    
    local ignoreBtn = CreateFrame("Button", nil, row)
    ignoreBtn:SetSize(42, buttonSize)
    ignoreBtn:SetPoint("RIGHT", editBtn, "LEFT", -3, 0)
    ignoreBtn:SetNormalFontObject(GameFontNormalSmall)
    ignoreBtn:SetHighlightFontObject(GameFontHighlightSmall)
    ignoreBtn:SetText(L["UI_IG"])
    
    ignoreBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    ignoreBtn:SetScript("OnClick", function()
        if row.playerName then
            UI:ToggleIgnore(row.playerName, ignoreBtn)
        end
    end)
    ignoreBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local ignored = RL.IsInBlizzardIgnore(row.playerName)
        GameTooltip:SetText(ignored and L["UI_UNL_F"] or L["UI_IG_F"])
        GameTooltip:Show()
    end)
    ignoreBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons.ignore = ignoreBtn
    
    local infoBtn = CreateFrame("Button", nil, row)
    infoBtn:SetSize(buttonSize, buttonSize)
    infoBtn:SetPoint("RIGHT", ignoreBtn, "LEFT", -3, 0)
    infoBtn:SetNormalTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    infoBtn:SetHighlightTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    infoBtn:GetHighlightTexture():SetAlpha(0.5)
    infoBtn:SetScript("OnClick", function()
        if row.playerData then
            UI:ShowPlayerInfo(row.playerData)
        end
    end)
    infoBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["UI_INF"])
        GameTooltip:Show()
    end)
    infoBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons.info = infoBtn
    
    local dropdown = CreateFrame("Frame", "ReputationListRowDropdown"..tostring(row.index), row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("RIGHT", infoBtn, "LEFT", 105, -2)
    UIDropDownMenu_SetWidth(dropdown, 8)
    UIDropDownMenu_SetText(dropdown, "BL")
    
    row.selectedListType = "blacklist"
    
    local function OnDropdownClick(self)
        UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
        row.selectedListType = self.value
        local shortNames = {blacklist = "BL", whitelist = "WL", notelist = "NL"}
        UIDropDownMenu_SetText(dropdown, shortNames[self.value])
    end
    
    local function InitializeDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Blacklist"
        info.value = "blacklist"
        info.func = OnDropdownClick
        info.checked = (row.selectedListType == "blacklist")
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Whitelist"
        info.value = "whitelist"
        info.func = OnDropdownClick
        info.checked = (row.selectedListType == "whitelist")
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Notelist"
        info.value = "notelist"
        info.func = OnDropdownClick
        info.checked = (row.selectedListType == "notelist")
        UIDropDownMenu_AddButton(info, level)
    end
    
    UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
    dropdown:Hide()
    row.listTypeDropdown = dropdown
    
    local addToListBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    addToListBtn:SetSize(20, buttonSize)
    addToListBtn:SetPoint("RIGHT", startX, 0)
    addToListBtn:SetText("+")
    addToListBtn:SetScript("OnClick", function()
        if row.playerData and row.selectedListType then
            local listType = row.selectedListType or "blacklist"
            local note = L["UI_ADDED_FROM_GROUP"] or "Добавлен из группы"
            
            local unit = nil
            if RL.FindPlayerInGroup then
                unit = RL.FindPlayerInGroup(row.playerData.name)
            end
            
            RL:AddPlayerDirect(row.playerData.name, listType, note, unit, row.playerData)
            UI:RefreshList()
        end
    end)
    addToListBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L["UI_ADD"] or "Добавить", 0, 1, 0)
        GameTooltip:Show()
    end)
    addToListBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    addToListBtn:Hide()
    buttons.addToList = addToListBtn
    
    return buttons
end


function UI:RefreshList()
    if STATE.currentTab == "settings" then
        return
    end
    
    if STATE.showGroupMembers then
        UI:RefreshGroupMembersList()
        return
    end
    
    if CACHE.settingsPanel then CACHE.settingsPanel:Hide() end
    if CACHE.scrollFrame then CACHE.scrollFrame:Show() end
    if CACHE.addPlayerForm then CACHE.addPlayerForm:Show() end
    if CACHE.tableHeader then CACHE.tableHeader:Show() end
    
    local realmData = RL:GetRealmData()
    if not realmData then return end
    
    local list = realmData[STATE.currentTab]
    if not list then return end
    
    if not CACHE.filteredPlayers then
        CACHE.filteredPlayers = {}
    end
    
    for i = #CACHE.filteredPlayers, 1, -1 do
        CACHE.filteredPlayers[i] = nil
    end
    
    local count = 0
    for key, data in pairs(list) do
        if data and data.name then
            if STATE.searchText == "" or 
               data.name:lower():find(STATE.searchText, 1, true) or
               (data.note and data.note:lower():find(STATE.searchText, 1, true)) then
                count = count + 1
                CACHE.filteredPlayers[count] = data
            end
        end
    end
    
    table.sort(CACHE.filteredPlayers, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    
    local maxScroll = math.max(0, count - CONFIG.VISIBLE_ROWS)
    CACHE.scrollFrame.scrollbar:SetMinMaxValues(0, maxScroll)
    
    STATE.filteredPlayers = CACHE.filteredPlayers
    
    if CACHE.mainFrame and CACHE.mainFrame.titleText then
        local tabName = STATE.currentTab:gsub("^%l", string.upper)
        CACHE.mainFrame.titleText:SetText(string.format("Reputation List - %s (%d)", tabName, count))
    end
    
    UI:UpdateVisibleRows()
end

function UI:UpdateVisibleRows()
    if STATE.showGroupMembers then
        UI:UpdateGroupMembersVisibleRows()
        return
    end
    
    local players = CACHE.filteredPlayers or STATE.filteredPlayers or {}
    
    for i = 1, CONFIG.VISIBLE_ROWS do
        local row = CACHE.rows[i]
        if not row then break end
        
        local dataIndex = STATE.scrollOffset + i
        
        if dataIndex <= #players then
            local data = players[dataIndex]
            UI:UpdateRowDisplay(row, data, false)
            row:Show()
        else
            row:Hide()
            row.playerName = nil
            row.playerNote = nil
            row.playerData = nil
        end
    end
end


function UI:CreateAddPlayerForm(parent)
    local form = CreateFrame("Frame", nil, parent)
    form:SetPoint("BOTTOMLEFT", 10, 8)
    form:SetPoint("BOTTOMRIGHT", -10, 8)
    form:SetHeight(45)
    
    form:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    form:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    form:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
       
    local nameInput = CreateFrame("EditBox", nil, form)
    nameInput:SetSize(100, 24)
    nameInput:SetPoint("TOPLEFT", 8, -10)
    nameInput:SetAutoFocus(false)
    nameInput:SetFontObject(GameFontNormalSmall)
    nameInput:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    nameInput:SetBackdropColor(0, 0, 0, 0.5)
    nameInput:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	nameInput:SetTextInsets(8, 5, 3, 3)
    
    local namePlaceholder = nameInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    namePlaceholder:SetPoint("LEFT", 5, 0)
    namePlaceholder:SetText(L["UI_NM"])
    nameInput:HookScript("OnEditFocusGained", function() namePlaceholder:Hide() end)
    nameInput:HookScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then namePlaceholder:Show() end
    end)
    
    local noteInput = CreateFrame("EditBox", nil, form)
    noteInput:SetSize(180, 24)
    noteInput:SetPoint("LEFT", nameInput, "RIGHT", 8, 0)
    noteInput:SetAutoFocus(false)
    noteInput:SetFontObject(GameFontNormalSmall)
    noteInput:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    noteInput:SetBackdropColor(0, 0, 0, 0.5)
    noteInput:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	noteInput:SetTextInsets(8, 5, 3, 3)
    
    local notePlaceholder = noteInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    notePlaceholder:SetPoint("LEFT", 5, 0)
    notePlaceholder:SetText(L["UI_NOTE"])
    noteInput:HookScript("OnEditFocusGained", function() notePlaceholder:Hide() end)
    noteInput:HookScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then notePlaceholder:Show() end
    end)
    
    local dropdown = CreateFrame("Frame", "ReputationListTypeDropdownNew", form, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", noteInput, "RIGHT", -15, -2)
    UIDropDownMenu_SetWidth(dropdown, 70)
    UIDropDownMenu_SetText(dropdown, "BL")
    
    local function OnClick(self)
        UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
        STATE.selectedListType = self.value
        local shortNames = {blacklist = "BL", whitelist = "WL", notelist = "NL"}
        UIDropDownMenu_SetText(dropdown, shortNames[self.value])
    end
    
    local function Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Blacklist"
        info.value = "blacklist"
        info.func = OnClick
        info.checked = (STATE.selectedListType == "blacklist")
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Whitelist"
        info.value = "whitelist"
        info.func = OnClick
        info.checked = (STATE.selectedListType == "whitelist")
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Notelist"
        info.value = "notelist"
        info.func = OnClick
        info.checked = (STATE.selectedListType == "notelist")
        UIDropDownMenu_AddButton(info, level)
    end
    
    UIDropDownMenu_Initialize(dropdown, Initialize)
    STATE.selectedListType = "blacklist"
    
    local addBtn = CreateFrame("Button", nil, form, "UIPanelButtonTemplate")
    addBtn:SetSize(80, 24)
    addBtn:SetPoint("RIGHT", -8, 0)
    addBtn:SetText("+" .. L["UI_ADD"])
    addBtn:SetScript("OnClick", function()
        local name = nameInput:GetText()
        local note = noteInput:GetText()
        local listType = STATE.selectedListType or "blacklist"
        
        if name and name ~= "" then
            RL:AddPlayerDirect(name, listType, note)
            nameInput:SetText("")
            noteInput:SetText("")
            nameInput:ClearFocus()
            noteInput:ClearFocus()
            UI:RefreshList()
        else
            print("|cFFFF0000ReputationList:|r" .. L["UI_NM_INPT"])
        end
    end)
    
    CACHE.addPlayerForm = form
    return form
end


function UI:DeletePlayer(playerName)
    RL.UICommon.DeletePlayerDialog(playerName, UI, STATE, L)
end

function UI:EditPlayer(playerName, currentNote)
    RL.UICommon.EditPlayerDialog(playerName, currentNote, UI, STATE, L)
end

StaticPopupDialogs["REPUTATION_KICK_PROMPT"] = {
    text = L["UI_DAL"],
    button1 = L["YES"],
    button2 = L["NO"],
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self)
        self.editBox:SetText(L["UI_BAD_P"])
        self.editBox:SetFocus()
    end,
    OnAccept = function(self, data)
        local playerName = data.name
        local note = self.editBox:GetText() or L["UI_BAD_P"]
        
        local isLeader = false
        if UnitInRaid("player") then
            if GetNumRaidMembers() > 0 then
                local _, rank = GetRaidRosterInfo(UnitInRaid("player"))
                isLeader = (rank == 2)
            end
        elseif GetNumPartyMembers() > 0 then
            isLeader = (GetPartyLeaderIndex() == 0)
        end
        
        if not isLeader then
            print(L["WH_D05"])
            return
        end
        
        if RL and RL.AddPlayerDirect then
            RL:AddPlayerDirect(playerName, "blacklist", note, "target")
        end
        
        if UnitInRaid("player") then
            for i = 1, GetNumRaidMembers() do
                local name = GetRaidRosterInfo(i)
                if name and RL.NormalizeName(name):lower() == playerName:lower() then
                    UninviteUnit(name)
                    print("|cFFFF0000ReputationList:|r " .. playerName .. L["UI_OUT_R"])
                    break
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                local name = UnitName("party" .. i)
                if name and RL.NormalizeName(name):lower() == playerName:lower() then
                    UninviteUnit(name)
                    print("|cFFFF0000ReputationList:|r " .. playerName .. L["UI_OUT_G"])
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

function UI:ToggleIgnore(playerName, button)
    local ignored, ignoredName = RL.IsInBlizzardIgnore(playerName)
    
    if ignored then
        for i = 1, GetNumIgnores() do
            local name = GetIgnoreName(i)
            if name and RL.NormalizeName(name):lower() == playerName:lower() then
                DelIgnore(name)
                button:SetText(L["UI_IG"])
                print("|cFF00FF00ReputationList:|r " .. playerName .. L["UI_RM_IG"])
                return
            end
        end
    else
        if GetNumIgnores() >= 50 then
            print("|cFFFF0000ReputationList:|r " .. L["UI_BLIZ_F"])
            return
        end
        AddIgnore(playerName)
        button:SetText(L["UI_UNLOCK"])
        print("|cFF00FF00ReputationList:|r " .. playerName .. L["UI_BLACK"])
    end
end

function UI:CreatePlayerInfoFrame()
    return Common.CreatePlayerCardBase(L, {
        frameName = "RepListPlayerInfoFrame",
        applyStyle = nil,
        withArmoryLink = true
    })
end

function UI:ShowPlayerInfo(data)
    if not CACHE.infoFrame then
        CACHE.infoFrame = self:CreatePlayerInfoFrame()
    end
    
    local f = CACHE.infoFrame
    
    if not data.faction and data.race then
        local hordeRaces = {["Орк"] = true, ["Нежить"] = true, ["Таурен"] = true, ["Тролль"] = true, ["Эльф крови"] = true}
        local allianceRaces = {["Человек"] = true, ["Дворф"] = true, ["Ночной эльф"] = true, ["Гном"] = true, ["Дреней"] = true}
        
        if hordeRaces[data.race] then
            data.faction = "Horde"
        elseif allianceRaces[data.race] then
            data.faction = "Alliance"
        end
    end
    
    local classColors = RAID_CLASS_COLORS or {
        WARRIOR = {r=0.78, g=0.61, b=0.43},
        PALADIN = {r=0.96, g=0.55, b=0.73},
        HUNTER = {r=0.67, g=0.83, b=0.45},
        ROGUE = {r=1.00, g=0.96, b=0.41},
        PRIEST = {r=1.00, g=1.00, b=1.00},
        DEATHKNIGHT = {r=0.77, g=0.12, b=0.23},
        SHAMAN = {r=0.00, g=0.44, b=0.87},
        MAGE = {r=0.41, g=0.80, b=0.94},
        WARLOCK = {r=0.58, g=0.51, b=0.79},
        DRUID = {r=1.00, g=0.49, b=0.04}
    }
    
    local classColor = {r=1, g=0.82, b=0}
    if data.class and classColors[data.class] then
        classColor = classColors[data.class]
    end
    
    if data.faction == "Alliance" then
        f.factionLogo:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
    elseif data.faction == "Horde" then
        f.factionLogo:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
    else
        f.factionLogo:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    f.nameValue:SetText(data.name or L["UI_F_UN"])
    f.nameValue:SetTextColor(classColor.r, classColor.g, classColor.b)
    f.classValue:SetText(data.class or L["UI_F_UNO"])
    f.raceValue:SetText(data.race or L["UI_F_UN2"])
    f.levelValue:SetText(tostring(data.level or "?"))
    f.guildValue:SetText(data.guild or L["NO"])
    f.guidValue:SetText(data.guid or L["UI_F_V"])
    
    f.currentPlayerData = data
    
    f.armoryLinkEditBox:SetText(data.armoryLink or "")
    f.armoryLinkEditBox:SetCursorPosition(0)
    
    f.armoryLinkSaveBtn:SetScript("OnClick", function(self)
        local newLink = f.armoryLinkEditBox:GetText()
        local playerData = f.currentPlayerData
        
        if not playerData or not playerData.name then
            print(L["WH_D06"])
            return
        end
        
        local realmData = RL:GetRealmData()
        
        local listType = playerData.listType or STATE.currentTab
        if listType == "whohere" then
            local searchKey = string.lower(RL.NormalizeName(playerData.name))
            if realmData.blacklist[searchKey] then
                listType = "blacklist"
            elseif realmData.whitelist[searchKey] then
                listType = "whitelist"
            elseif realmData.notelist[searchKey] then
                listType = "notelist"
            else
                if not ReputationGroupTrackerDB then
                    ReputationGroupTrackerDB = {}
                end
                if not ReputationGroupTrackerDB.whoHereCache then
                    ReputationGroupTrackerDB.whoHereCache = {}
                end
                
                local key = string.lower(RL.NormalizeName(playerData.name))
                if not ReputationGroupTrackerDB.whoHereCache[key] then
                    ReputationGroupTrackerDB.whoHereCache[key] = {}
                end
                ReputationGroupTrackerDB.whoHereCache[key].armoryLink = newLink
                
                print(L["WH_SV"] .. playerData.name)
                return
            end
        end
        
        if listType and realmData[listType] then
            local key = string.lower(playerData.name)
            if realmData[listType][key] then
                realmData[listType][key].armoryLink = newLink
                RL:SaveSettings()
                print(L["WH_SV"] .. playerData.name)
            end
        end
    end)
    
    f.noteText:SetText(data.note or L["UI_F_N"])
    
    local key = string.lower(data.name or "")
    
    if STATE.showGroupMembers and not data.inList then
        f.title:SetText(L["UI_POP_GROUP"] or "Информация - В группе/рейде")
        f.title:SetTextColor(0.5, 0.7, 1)
        f:SetBackdropBorderColor(0.5, 0.7, 1, 1)
    elseif STATE.currentTab == "blacklist" or (data.inList and data.listType == "blacklist") then
        f.title:SetText(L["UI_POP1"] .. " - BLACKLIST")
        f.title:SetTextColor(1, 0, 0)
        f:SetBackdropBorderColor(0.8, 0.1, 0.1, 1)
    elseif STATE.currentTab == "whitelist" or (data.inList and data.listType == "whitelist") then
        f.title:SetText(L["UI_POP2"] .. " - WHITELIST")
        f.title:SetTextColor(0, 1, 0)
        f:SetBackdropBorderColor(0.1, 0.8, 0.1, 1)
    elseif STATE.currentTab == "notelist" or (data.inList and data.listType == "notelist") then
        f.title:SetText(L["UI_POP3"] .. " - NOTELIST")
        f.title:SetTextColor(1, 0.84, 0)
        f:SetBackdropBorderColor(1, 0.84, 0, 1)
    else
        f.title:SetText(L["UI_INF"] or "Информация")
        f.title:SetTextColor(1, 1, 1)
        f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end
    
    f:Show()
end


function UI:CreateSettingsPanel(parent)
    if CACHE.settingsPanel then return CACHE.settingsPanel end
    
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", 10, -98)
    panel:SetPoint("BOTTOMRIGHT", -10, 60)
    panel:Hide()
    
    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -20, 0)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(450, 400)
    scroll:SetScrollChild(content)
    
    local scrollbar = CreateFrame("Slider", nil, scroll)
    scrollbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    scrollbar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    scrollbar:SetWidth(16)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollbar:SetMinMaxValues(0, 100)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    scrollbar:SetScript("OnValueChanged", function(self, value)
        scroll:SetVerticalScroll(value)
    end)
    
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local new = math.max(min, math.min(max, current - delta * 20))
        scrollbar:SetValue(new)
    end)
    
	ReputationListDB = ReputationListDB or {}
    local settings = ReputationListDB
    
    local yOffset = -10
    
    local mainTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainTitle:SetPoint("TOP", 0, yOffset)
    mainTitle:SetText(L["SETTINGS_TITLE"])
    mainTitle:SetTextColor(1, 0.82, 0)
    yOffset = yOffset - 35
    
    local notifyHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notifyHeader:SetPoint("TOPLEFT", 25, yOffset)
    notifyHeader:SetText(L["UI_UVD"])
    notifyHeader:SetTextColor(1, 1, 0)
    
    local protectionHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    protectionHeader:SetPoint("TOPLEFT", 270, yOffset)
    protectionHeader:SetText(L["UI_DEF"])
    protectionHeader:SetTextColor(1, 1, 0)
    yOffset = yOffset - 25
    
    local cb1 = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb1:SetPoint("TOPLEFT", 20, yOffset)
    cb1.text = cb1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb1.text:SetPoint("LEFT", cb1, "RIGHT", 5, 0)
    cb1.text:SetText(L["UI_CB1"])
    cb1:SetChecked(settings.autoNotify)
    cb1:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
    ReputationListDB.autoNotify = checked
    RL.autoNotify = checked 
    
    print("|cFF00FF00RepList:|r " .. L["UI_CB2"])
	end)

	cb1:SetScript("OnShow", function(self)
    self:SetChecked(ReputationListDB.autoNotify or false)
	end)
    
    local cb5 = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb5:SetPoint("TOPLEFT", 270, yOffset)
    cb5.text = cb5:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb5.text:SetPoint("LEFT", cb5, "RIGHT", 5, 0)
    cb5.text:SetText(L["UI_CB3"])
    cb5:SetChecked(settings.blockInvites)
    cb5:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
    ReputationListDB.blockInvites = checked
    RL.blockInvites = checked 
    
    print("|cFF00FF00RepList:|r " .. L["UI_CB2"])
	end)
	cb5:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.blockInvites or false)
	end)
	
    yOffset = yOffset - 25
    
    local cb2 = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb2:SetPoint("TOPLEFT", 20, yOffset)
    cb2.text = cb2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb2.text:SetPoint("LEFT", cb2, "RIGHT", 5, 0)
    cb2.text:SetText(L["UI_CB4"])
    cb2:SetChecked(settings.selfNotify)
    cb2:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
    ReputationListDB.selfNotify = checked
    RL.selfNotify = checked 
    
    print("|cFF00FF00RepList:|r " .. L["UI_CB2"])
	end)
	cb2:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.selfNotify or false)
	end)		
    
    local cb6 = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb6:SetPoint("TOPLEFT", 270, yOffset)
    cb6.text = cb6:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb6.text:SetPoint("LEFT", cb6, "RIGHT", 5, 0)
    cb6.text:SetText(L["UI_CB5"])
    cb6:SetChecked(settings.blockTrade)
    cb6:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
    ReputationListDB.blockTrade = checked
    RL.blockTrade = checked 
    
    print("|cFF00FF00RepList:|r " .. L["UI_CB2"])
	end)
	cb6:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.blockTrade or false)
	end)		
    yOffset = yOffset - 25
    
    local cb3 = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb3:SetPoint("TOPLEFT", 20, yOffset)
    cb3.text = cb3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb3.text:SetPoint("LEFT", cb3, "RIGHT", 5, 0)
    cb3.text:SetText(L["UI_CB6"])
    cb3:SetChecked(settings.colorLFG)
    cb3:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
    ReputationListDB.colorLFG = checked
    RL.colorLFG = checked 
    
    print("|cFF00FF00RepList:|r " .. L["UI_CB2"])
	end)
	cb3:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.colorLFG or false)
	end)	
    
    local cb7 = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb7:SetPoint("TOPLEFT", 270, yOffset)
    cb7.text = cb7:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb7.text:SetPoint("LEFT", cb7, "RIGHT", 5, 0)
    cb7.text:SetText(L["UI_CB7"])
    cb7:SetChecked(settings.filterMessages)
    cb7:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    ReputationListDB.filterMessages = checked
    RL.filterMessages = checked
	end)
	cb7:SetScript("OnShow", function(self)
    self:SetChecked(ReputationListDB.filterMessages)
	end)
    yOffset = yOffset - 25
    
    local cb4 = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb4:SetPoint("TOPLEFT", 20, yOffset)
    cb4.text = cb4:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb4.text:SetPoint("LEFT", cb4, "RIGHT", 5, 0)
    cb4.text:SetText(L["UI_CB8"])
    cb4:SetChecked(settings.soundNotify)
    cb4:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    ReputationListDB.soundNotify = checked
    ReputationListDB.popupNotify = checked
    RL.soundNotify = checked 
    RL.popupNotify = checked
	end)
	cb4:SetScript("OnShow", function(self)
    self:SetChecked(ReputationListDB.soundNotify)
	end)
	
    yOffset = yOffset - 45
    
    local exportBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exportBtn:SetSize(140, 30)
    exportBtn:SetPoint("TOP", content, "TOP", -75, yOffset)
    exportBtn:SetText(L["UI_CB9"])
    exportBtn:SetScript("OnClick", function()
        UI:ShowExport()
    end)
    
    local importBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    importBtn:SetSize(140, 30)
    importBtn:SetPoint("TOP", content, "TOP", 75, yOffset)
    importBtn:SetText(L["UI_CB10"])
    importBtn:SetScript("OnClick", function()
        UI:ShowImport()
    end)
    yOffset = yOffset - 45
    
    CACHE.settingsPanel = panel
    return panel
end

function UI:ShowSettingsInline()
    if CACHE.scrollFrame then CACHE.scrollFrame:Hide() end
    if CACHE.addPlayerForm then CACHE.addPlayerForm:Hide() end
    if CACHE.tableHeader then CACHE.tableHeader:Hide() end
    
    if not CACHE.settingsPanel then
        UI:CreateSettingsPanel(CACHE.mainFrame)
    end
    CACHE.settingsPanel:Show()
    
    if CACHE.mainFrame and CACHE.mainFrame.titleText then
        CACHE.mainFrame.titleText:SetText(L["SETTINGS_TITLE"])
    end
end

function UI:ShowSettings()
    UI:ShowSettingsInline()
end



local exportState = {
    inProgress = false,
    frame = nil,
    progressBar = nil,
    progressText = nil
}


local function AsyncSerialize(data, callback)
    if exportState.inProgress then
        print(L["UI_CB11"])
        return
    end
    
    exportState.inProgress = true
    
    local playerQueue = {}
    local totalPlayers = 0
    
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
    local currentIndex = 1
    local BATCH_SIZE = 200
    
    local preparationFrame = CreateFrame("Frame")
    preparationFrame:SetScript("OnUpdate", function(self, elapsed)
        if currentIndex > totalToProcess then
            self:SetScript("OnUpdate", nil)
            allPlayers = nil
            
            if totalPlayers == 0 then
                exportState.inProgress = false
                if exportState.frame then exportState.frame:Hide() end
                callback("ReputationList_Import = {\n  realms = {}\n}")
                return
            end
            
            if exportState.progressText then
                exportState.progressText:SetText(L["UI_CB12"])
            end
            
            StartExportPhase(playerQueue, totalPlayers, callback)
            return
        end
        
        local endIndex = math.min(currentIndex + BATCH_SIZE - 1, totalToProcess)
        for i = currentIndex, endIndex do
            local entry = allPlayers[i]
            totalPlayers = totalPlayers + 1
            table.insert(playerQueue, entry)
        end
        
        if exportState.progressText then
            local progress = (endIndex / totalToProcess) * 100
            exportState.progressText:SetText(string.format(L["UI_CB13"], endIndex, totalToProcess, progress))
        end
        
        currentIndex = endIndex + 1
    end)
end

function StartExportPhase(playerQueue, totalPlayers, callback)
    local resultParts = {}
    resultParts[1] = "ReputationList_Import = {\n"
    resultParts[2] = "  realms = {\n"
    
    local currentIndex = 1
    local chunkSize = 250
    local currentRealm = nil
    local currentListType = nil
    
    local exportFrame = CreateFrame("Frame")
    local lastProgressUpdate = 0
    local PROGRESS_UPDATE_INTERVAL = 0.1
    
    exportFrame:SetScript("OnUpdate", function(self, elapsed)
        lastProgressUpdate = lastProgressUpdate + elapsed
        
        local endIndex = math.min(currentIndex + chunkSize - 1, totalPlayers)
        
        for i = currentIndex, endIndex do
            local entry = playerQueue[i]
            
            if currentRealm ~= entry.realm then
                if currentRealm then
                    table.insert(resultParts, "    },\n")
                end
                currentRealm = entry.realm
                table.insert(resultParts, '    ["' .. entry.realm .. '"] = {\n')
                currentListType = nil
            end
            
            if currentListType ~= entry.listType then
                if currentListType then
                    table.insert(resultParts, "      },\n")
                end
                currentListType = entry.listType
                table.insert(resultParts, '      ["' .. entry.listType .. '"] = {\n')
            end
            
            table.insert(resultParts, '        ["' .. entry.playerName:gsub('"', '\\"') .. '"] = {\n')
            
            local pd = entry.playerData
            if pd.note then
                local note = tostring(pd.note):gsub('"', '\\"')
                if #note > 500 then note = note:sub(1, 500) .. "..." end
                table.insert(resultParts, '          note = "' .. note .. '",\n')
            end
            if pd.guid then table.insert(resultParts, '          guid = "' .. tostring(pd.guid) .. '",\n') end
            if pd.class then table.insert(resultParts, '          class = "' .. tostring(pd.class) .. '",\n') end
            if pd.race then table.insert(resultParts, '          race = "' .. tostring(pd.race) .. '",\n') end
            if pd.level then table.insert(resultParts, '          level = ' .. tostring(pd.level) .. ',\n') end
            if pd.guild then table.insert(resultParts, '          guild = "' .. tostring(pd.guild):gsub('"', '\\"') .. '",\n') end
            if pd.faction then table.insert(resultParts, '          faction = "' .. tostring(pd.faction) .. '",\n') end
            if pd.addedBy then table.insert(resultParts, '          addedBy = "' .. tostring(pd.addedBy) .. '",\n') end
            if pd.timestamp then table.insert(resultParts, '          timestamp = ' .. tostring(pd.timestamp) .. ',\n') end
            
            table.insert(resultParts, "        },\n")
        end
        
        if lastProgressUpdate >= PROGRESS_UPDATE_INTERVAL then
            if exportState.progressBar and exportState.progressText then
                local progress = (endIndex / totalPlayers) * 100
                exportState.progressBar:SetValue(progress)
                exportState.progressText:SetText(string.format(L["UI_CB14"], endIndex, totalPlayers, progress))
            end
            lastProgressUpdate = 0
        end
        
        currentIndex = endIndex + 1
        
        if currentIndex > totalPlayers then
            if currentListType then table.insert(resultParts, "      },\n") end
            if currentRealm then table.insert(resultParts, "    },\n") end
            table.insert(resultParts, "  }\n}")
            
            local finalString = table.concat(resultParts)
            resultParts = nil
            playerQueue = nil
            
            self:SetScript("OnUpdate", nil)
            exportState.inProgress = false
            if exportState.frame then exportState.frame:Hide() end
            
            callback(finalString, totalPlayers)
        end
    end)
end

local function SimpleSerialize(t, indent, maxDepth)
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
            table.insert(result, space .. key .. " = {\n" .. SimpleSerialize(v, indent+1, maxDepth) .. space .. "},\n")
        elseif type(v) == "string" then
            local str = (#v > 500) and (v:sub(1, 500) .. "...") or v
            table.insert(result, space .. key .. ' = "' .. str:gsub('"', '\\"') .. '",\n')
        else
            table.insert(result, space .. key .. " = " .. tostring(v) .. ",\n")
        end
    end
    return table.concat(result)
end

local function CreateProgressBar()
    if exportState.frame then return end
    
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
    title:SetText(L["UI_CB15"])
    
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
    text:SetText(L["UI_CB46"])
    
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("BOTTOM", 0, 12)
    hint:SetText(L["UI_CB16"])
    
    frame:Hide()
    
    exportState.frame = frame
    exportState.progressBar = bar
    exportState.progressText = text
end


local function DetectImportFormat(text)
    if not text or text == "" then return nil, L["UI_CB18"] end
    if text:match("ReputationList_Import") or text:match("realms%s*=") then return "ReputationList", nil end
    if text:match("BlackListDB") or text:match("BLackListDB") then return "BlackList", nil end
    if text:match("ElitistGroupDB") or (text:match("badlisted") and text:match("note")) then return "ElitistGroup", nil end
    return nil, L["UI_CB17"]
end

local function ImportFromBlackList(data)
    local imported = 0
    local normalizedRealm = RL.NormalizeRealm(GetRealmName())
    
    ReputationListDB.realms = ReputationListDB.realms or {}
    ReputationListDB.realms[normalizedRealm] = ReputationListDB.realms[normalizedRealm] or {blacklist = {}, whitelist = {}, notelist = {}}
    
    if data then
        for realm, players in pairs(data) do
            if type(players) == "table" then
                for playerName, playerData in pairs(players) do
                    if type(playerData) == "table" then
                        local key = string.lower(playerName)
                        local convertedData = {
                            name = playerName,
                            note = playerData.note or playerData.reason or L["UI_CB19"],
                            addedDate = playerData.date or date("%d.%m.%Y %H:%M"),
                            addedBy = playerData.by or "Import",
                            key = key:gsub("[^%w]", ""):lower()
                        }
                        if not ReputationListDB.realms[normalizedRealm].blacklist[key] then
                            ReputationListDB.realms[normalizedRealm].blacklist[key] = convertedData
                            imported = imported + 1
                        end
                    end
                end
            end
        end
    end
    return imported
end

local function ImportFromElitistGroup(data)
    local imported = 0
    local normalizedRealm = RL.NormalizeRealm(GetRealmName())
    
    ReputationListDB.realms = ReputationListDB.realms or {}
    ReputationListDB.realms[normalizedRealm] = ReputationListDB.realms[normalizedRealm] or {blacklist = {}, whitelist = {}, notelist = {}}
    
    if data and data.badlisted then
        for playerName, playerData in pairs(data.badlisted) do
            if type(playerData) == "table" then
                local key = string.lower(playerName)
                local convertedData = {
                    name = playerName,
                    note = playerData.note or L["UI_CB20"],
                    addedDate = date("%d.%m.%Y %H:%M"),
                    addedBy = "Import",
                    key = key:gsub("[^%w]", ""):lower()
                }
                if not ReputationListDB.realms[normalizedRealm].blacklist[key] then
                    ReputationListDB.realms[normalizedRealm].blacklist[key] = convertedData
                    imported = imported + 1
                end
            end
        end
    end
    return imported
end

local function ImportFromReputationList(data)
    local imported = 0
    local normalizedRealm = RL.NormalizeRealm(GetRealmName())
    
    ReputationListDB.realms = ReputationListDB.realms or {}
    ReputationListDB.realms[normalizedRealm] = ReputationListDB.realms[normalizedRealm] or {blacklist = {}, whitelist = {}, notelist = {}}
    
    if data and data.realms then
        for realmName, realmData in pairs(data.realms) do
            if type(realmData) == "table" then
                for listType, listData in pairs(realmData) do
                    if listType == "blacklist" or listType == "whitelist" or listType == "notelist" then
                        for playerName, playerData in pairs(listData) do
                            if type(playerData) == "table" then
                                local key = string.lower(playerName)
                                if not ReputationListDB.realms[normalizedRealm][listType][key] then
                                    local newData = {}
                                    for k, v in pairs(playerData) do
                                        newData[k] = v
                                    end
                                    if playerData.armoryLink then
                                        newData.armoryLink = playerData.armoryLink
                                    end
                                    ReputationListDB.realms[normalizedRealm][listType][key] = newData
                                    imported = imported + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return imported
end


function UI:CreateExportImportFrames()
    if self.exportFrame then return end
    local parent = CACHE.mainFrame or UIParent
    
    local ef = CreateFrame("Frame", "RepExportFrameNew", parent)
    ef:SetSize(520, 420)
    ef:SetPoint("CENTER")
    ef:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    ef:SetFrameStrata("DIALOG")
    ef:SetFrameLevel(20)
    ef:EnableMouse(true)
    ef:SetMovable(true)
    ef:RegisterForDrag("LeftButton")
    ef:SetScript("OnDragStart", ef.StartMoving)
    ef:SetScript("OnDragStop", ef.StopMovingOrSizing)
    
    ef.title = ef:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ef.title:SetPoint("TOP", 0, -10)
    ef.title:SetText(L["UI_CB9"])
    
    local scroll = CreateFrame("ScrollFrame", "RepExportScrollNew", ef, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -40)
    scroll:SetPoint("BOTTOMRIGHT", -36, 44)
    
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(scroll:GetWidth() - 20)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    
    edit:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local lines = 1
        for _ in text:gmatch("\n") do lines = lines + 1 end
        self:SetHeight(math.max(200, lines * 14))
    end)
    
    local copyBtn = CreateFrame("Button", nil, ef, "GameMenuButtonTemplate")
    copyBtn:SetSize(120, 28)
    copyBtn:SetPoint("BOTTOMLEFT", 16, 12)
    copyBtn:SetText(L["UI_CB21"])
    copyBtn:SetScript("OnClick", function() edit:HighlightText(); edit:SetFocus() end)
    
    local closeBtn = CreateFrame("Button", nil, ef, "GameMenuButtonTemplate")
    closeBtn:SetSize(80, 28)
    closeBtn:SetPoint("BOTTOMRIGHT", -16, 12)
    closeBtn:SetText(L["UI_CLOSE"])
    closeBtn:SetScript("OnClick", function() ef:Hide() end)
    
    ef.edit = edit
    ef:Hide()
    self.exportFrame = ef
    
    local inf = CreateFrame("Frame", "RepImportFrameNew", parent)
    inf:SetSize(520, 420)
    inf:SetPoint("CENTER")
    inf:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    inf:SetFrameStrata("DIALOG")
    inf:SetFrameLevel(20)
    inf:EnableMouse(true)
    inf:SetMovable(true)
    inf:RegisterForDrag("LeftButton")
    inf:SetScript("OnDragStart", inf.StartMoving)
    inf:SetScript("OnDragStop", inf.StopMovingOrSizing)
    
    inf.title = inf:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    inf.title:SetPoint("TOP", 0, -10)
    inf.title:SetText(L["UI_CB10"])
    
    local scroll2 = CreateFrame("ScrollFrame", "RepImportScrollNew", inf, "UIPanelScrollFrameTemplate")
    scroll2:SetPoint("TOPLEFT", 16, -40)
    scroll2:SetPoint("BOTTOMRIGHT", -36, 44)
    
    local edit2 = CreateFrame("EditBox", nil, scroll2)
    edit2:SetMultiLine(true)
    edit2:SetAutoFocus(false)
    edit2:SetFontObject(ChatFontNormal)
    edit2:SetWidth(scroll2:GetWidth() - 20)
    edit2:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll2:SetScrollChild(edit2)
    
    edit2:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local lines = 1
        for _ in text:gmatch("\n") do lines = lines + 1 end
        self:SetHeight(math.max(200, lines * 14))
    end)
    
    local importBtn = CreateFrame("Button", nil, inf, "GameMenuButtonTemplate")
    importBtn:SetSize(120, 28)
    importBtn:SetPoint("BOTTOMLEFT", 16, 12)
    importBtn:SetText(L["UI_CB47"])
    importBtn:SetScript("OnClick", function()
        local text = edit2:GetText()
        if not text or text == "" then
            print(L["UI_CB22"])
            return
        end
        
        local format, error = DetectImportFormat(text)
        if not format then
            print(L["UI_CB23"] .. error .. "|r")
            return
        end
        
        print(L["UI_CB24"] .. format)
        
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
        
        local func, err = loadstring(textToLoad)
        if not func then
            print(L["UI_CB25"])
            return
        end
        
        local success, result = pcall(func)
        if not success or type(result) ~= "table" then
            print(L["UI_CB26"])
            return
        end
        
        local imported = 0
        if format == "ReputationList" then imported = ImportFromReputationList(result)
        elseif format == "BlackList" then imported = ImportFromBlackList(result)
        elseif format == "ElitistGroup" then imported = ImportFromElitistGroup(result) end
        
        if imported > 0 then
            print(L["UI_CB27"] .. imported .. "|r")
            UI:RefreshList()
            inf:Hide()
        else
            print(L["UI_CB28"])
        end
    end)
    
    local closeBtn2 = CreateFrame("Button", nil, inf, "GameMenuButtonTemplate")
    closeBtn2:SetSize(80, 28)
    closeBtn2:SetPoint("BOTTOMRIGHT", -16, 12)
    closeBtn2:SetText(L["UI_CLOSE"])
    closeBtn2:SetScript("OnClick", function() inf:Hide() end)
    
    inf.edit = edit2
    inf:Hide()
    self.importFrame = inf
end


function UI:ShowExport()
    RL.UICommon.ShowExportWrapper(self, L)
end

function UI:ShowImport()
    RL.UICommon.ShowImportWrapper(self, L)
end


function UI:Toggle()
    RL.UICommon.ToggleMainWindowWrapper(self, CACHE)
end

function UI:Initialize()
    
    local mainFrame = self:CreateMainFrame()
    
    self:CreateHeader(mainFrame)
    self:CreateToolbar(mainFrame)
    self:CreateTableHeader(mainFrame)
    self:CreateScrollFrame(mainFrame)
    self:CreateAddPlayerForm(mainFrame)
    
    mainFrame:Hide()
    
    self.frame = mainFrame
    
    mainFrame:SetScript("OnShow", function(self)
        UI:RefreshList()
    end)
    
    mainFrame:SetScript("OnHide", function(self)
        if CACHE.filteredPlayers then
            for i = #CACHE.filteredPlayers, 1, -1 do
                CACHE.filteredPlayers[i] = nil
            end
        end
        
        if CACHE.rows then
            for i = 1, #CACHE.rows do
                local row = CACHE.rows[i]
                if row then
                    row.playerName = nil
                    row.playerNote = nil
                    row.playerData = nil
                    if row.nameText then row.nameText:SetText("") end
                    if row.noteText then row.noteText:SetText("") end
                end
            end
        end
        
        GameTooltip:Hide()
        
        collectgarbage("collect")
    end)

end

function UI:RefreshGroupMembersList()
    if not RL.GroupTracker then return end
    
    if RL.GroupTracker.ForceUpdate then
        RL.GroupTracker:ForceUpdate()
    end
    
    if CACHE.settingsPanel then CACHE.settingsPanel:Hide() end
    if CACHE.scrollFrame then CACHE.scrollFrame:Show() end
    if CACHE.addPlayerForm then CACHE.addPlayerForm:Hide() end
    if CACHE.tableHeader then CACHE.tableHeader:Show() end
    
    local members = RL.GroupTracker:GetAllGroupMembersWithListInfo()
    
    if not CACHE.filteredPlayers then
        CACHE.filteredPlayers = {}
    end
    
    for i = #CACHE.filteredPlayers, 1, -1 do
        CACHE.filteredPlayers[i] = nil
    end
    
    local count = 0
    for _, member in ipairs(members) do
        if STATE.searchText == "" or 
           member.name:lower():find(STATE.searchText, 1, true) or
           (member.note and member.note:lower():find(STATE.searchText, 1, true)) then
            count = count + 1
            CACHE.filteredPlayers[count] = member
        end
    end
    
    local maxScroll = math.max(0, count - CONFIG.VISIBLE_ROWS)
    CACHE.scrollFrame.scrollbar:SetMinMaxValues(0, maxScroll)
    
    STATE.filteredPlayers = CACHE.filteredPlayers
    
    UI:UpdateGroupMembersVisibleRows()
end

function UI:UpdateGroupMembersVisibleRows()
    local players = CACHE.filteredPlayers or STATE.filteredPlayers or {}
    
    for i = 1, CONFIG.VISIBLE_ROWS do
        local row = CACHE.rows[i]
        if not row then break end
        
        local dataIndex = STATE.scrollOffset + i
        
        if dataIndex <= #players then
            local data = players[dataIndex]
            UI:UpdateRowDisplay(row, data, true)
            row:Show()
        else
            row:Hide()
        end
    end
end

function UI:OnGroupUpdate()
    if STATE.showGroupMembers then
        UI:RefreshList()
        UI:UpdateTabAppearance()
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    
    if ElvUI then
        return
    end
    
    UI:Initialize()
    
    SLASH_REPLISTNEW1 = "/rlnew"
    SlashCmdList["REPLISTNEW"] = function()
        if RL.UI and RL.UI.Classic and RL.UI.Classic.Toggle then
            RL.UI.Classic:Toggle()
        else
            print(L and L["UI_CB55"] or "|cFFFF8800ReputationList:|r UI not initialized. Try /rlnew")
        end
    end
    
    print(L and L["UI_CB34"] or "|cFF00FF00ReputationList:|r New UI loaded! Command: /rlnew")
end)