-- ============================================================================
-- Reputation List - ElvUI Style
-- ============================================================================

local RL = ReputationList
if not RL then return end

local E, L, V, P, G = unpack(ElvUI or {})
if not E then
    return
end


local UI = {}
RL.UI = RL.UI or {}
RL.UI.ElvUI = UI

local L = ReputationList.L or ReputationListLocale

local Common = RL.UICommon

local CONFIG = {
    FRAME_WIDTH = 500,
    FRAME_HEIGHT = 400,
    ROW_HEIGHT = 24,
    VISIBLE_ROWS = 9,
    SEARCH_WIDTH = 100,
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
    lastListVersion = 0,
}

UI.framePool = {}

local function GetPooledFrame(parent)
    return Common.GetPooledFrame(parent, UI.framePool, RL.UICommon)
end

local function ReleaseFrame(frame)
    Common.ReleaseFrame(frame, UI.framePool, RL.UICommon)
end


local ELVUI_COLORS = {
    ACCENT = {1, 1, 1},
    BLACKLIST = {1, 0.3, 0.3},
    WHITELIST = {0.3, 1, 0.3},
    NOTELIST = {1, 0.8, 0.3},
    SETTINGS = {1, 0.82, 0},
}

local function StyleElvUIFrame(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
end

local function StyleElvUIButton(button, isIcon)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    if isIcon then
        button:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    else
        button:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end
    button:SetBackdropBorderColor(0, 0, 0, 1)
    button:HookScript("OnEnter", function(self)
        if not isIcon then self:SetBackdropColor(0.25, 0.25, 0.25, 1) end
        self:SetBackdropBorderColor(1, 0.5, 0, 1)
    end)
    button:HookScript("OnLeave", function(self)
        if not isIcon then self:SetBackdropColor(0.15, 0.15, 0.15, 1) end
        self:SetBackdropBorderColor(0, 0, 0, 1)
    end)
end

local function StyleElvUIEditBox(editbox)
    editbox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    editbox:SetBackdropColor(0, 0, 0, 0.5)
    editbox:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    editbox:HookScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(1, 0.5, 0, 1)
    end)
    editbox:HookScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end)
end

local function StyleElvUITab(tab, isActive)
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    if isActive then
        tab:SetBackdropColor(0.2, 0.2, 0.2, 1)
        tab:SetBackdropBorderColor(1, 0.5, 0, 1)
    else
        tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        tab:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
    end
end


function UI:CreateMainFrame()
    if CACHE.mainFrame then return CACHE.mainFrame end
    
    local f = CreateFrame("Frame", "ReputationListFrameElvUI", UIParent)
    f:SetSize(CONFIG.FRAME_WIDTH, CONFIG.FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(10)
    
    StyleElvUIFrame(f)
    
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
    title:SetPoint("TOPLEFT", 20, -15)
    title:SetText("Reputation List - Blacklist (0)")
    title:SetTextColor(ELVUI_COLORS.ACCENT[1], ELVUI_COLORS.ACCENT[2], ELVUI_COLORS.ACCENT[3])
    parent.titleText = title
    
    local whoHereLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whoHereLabel:SetPoint("TOPRIGHT", -70, -15)
    whoHereLabel:SetText(L["UI_WHO_HERE"] or "Кто здесь?")
    whoHereLabel:SetTextColor(1, 1, 1)
    parent.whoHereLabel = whoHereLabel
    
    local whoHereCheckbox = CreateFrame("CheckButton", "ReputationWhoHereCheckboxElvUI", parent, "UICheckButtonTemplate")
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
        
        if isChecked then
            for key, tab in pairs(CACHE.tabs or {}) do
                StyleElvUITab(tab, false)
                tab.text:SetTextColor(0.7, 0.7, 0.7)
            end
            UI:RefreshList()
        else
            UI:SwitchTab("blacklist")
        end
    end)
    
    whoHereCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["WH_D03"] or "Кто здесь?", 1, 1, 0)
        GameTooltip:AddLine(L["WH_D04"] or "Показать игроков в текущей группе/рейде", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    whoHereCheckbox:SetScript("OnLeave", GameTooltip_Hide)
    
    parent.whoHereCheckbox = whoHereCheckbox
    
    local closeBtn = CreateFrame("Button", nil, parent)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    StyleElvUIButton(closeBtn, true)
    
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", 0, 1)
    closeText:SetText("×")
    closeText:SetTextColor(1, 0.3, 0.3)
    closeText:SetFont(closeText:GetFont(), 16, "OUTLINE")
    
    closeBtn:SetScript("OnClick", function() parent:Hide() end)
    closeBtn:SetScript("OnEnter", function(self)
        closeText:SetTextColor(1, 0.5, 0.5)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        closeText:SetTextColor(1, 0.3, 0.3)
    end)
    parent.closeButton = closeBtn
end


function UI:CreateToolbar(parent)
    local tabs = {}
    
    local tabData = {
        {key = "blacklist", label = "Blacklist"},
        {key = "whitelist", label = "Whitelist"},
        {key = "notelist", label = "Notelist"},
        {key = "settings", label = L["UI_SETTINGS"]},
    }
    
    local startX = 20
    local tabWidth = 110
    local tabHeight = 28
    local spacing = 4
    
    for i, data in ipairs(tabData) do
        local tab = CreateFrame("Button", nil, parent)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", startX + (i-1) * (tabWidth + spacing), -42)
        
        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText(data.label)
        tab.text = text
        
        tab:SetScript("OnClick", function()
            UI:SwitchTab(data.key)
        end)
        
        tabs[data.key] = tab
    end
    
    CACHE.tabs = tabs
end

function UI:SwitchTab(tabName)
    if CACHE.mainFrame and CACHE.mainFrame.whoHereCheckbox and CACHE.mainFrame.whoHereCheckbox:GetChecked() then
        CACHE.mainFrame.whoHereCheckbox:SetChecked(false)
        STATE.showGroupMembers = false
    end
    
    STATE.currentTab = tabName
    STATE.scrollOffset = 0
    
    for key, tab in pairs(CACHE.tabs) do
        StyleElvUITab(tab, key == tabName)
        if key == tabName then
            local color = ELVUI_COLORS[key:upper()] or ELVUI_COLORS.ACCENT
            tab.text:SetTextColor(color[1], color[2], color[3])
        else
            tab.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end
    
    if tabName == "settings" then
        self:ShowSettingsInline()
    else
        self:RefreshList()
    end
end


function UI:CreateTableHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(CONFIG.FRAME_WIDTH - 40, 24)
    header:SetPoint("TOPLEFT", 20, -75)
    
    StyleElvUIFrame(header)
    header:SetBackdropColor(0.1, 0.1, 0.1, 1)
    
    local columns = {
        {label = L["UI_PLR"], width = 0.35, align = "LEFT"},
        {label = L["UI_NOTE"], width = 0.35, align = "LEFT"},
        {label = L["UI_ACTION"], width = 0.3, align = "CENTER"},
    }
    
    local offsetX = 8
    for i, col in ipairs(columns) do
        local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        local colWidth = (CONFIG.FRAME_WIDTH - 40) * col.width
        
        if col.align == "LEFT" then
            text:SetPoint("LEFT", offsetX, 0)
        elseif col.align == "CENTER" then
            text:SetPoint("LEFT", offsetX + colWidth/2 - 30, 0)
        end
        
        text:SetText(col.label)
        text:SetTextColor(ELVUI_COLORS.ACCENT[1], ELVUI_COLORS.ACCENT[2], ELVUI_COLORS.ACCENT[3])
        offsetX = offsetX + colWidth
    end
    
    parent.tableHeader = header
    CACHE.tableHeader = header
end


function UI:CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", "RepListScrollElvUI", parent)
    scrollFrame:SetPoint("TOPLEFT", 20, -100)
    scrollFrame:SetSize(CONFIG.FRAME_WIDTH - 60, CONFIG.ROW_HEIGHT * CONFIG.VISIBLE_ROWS)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(CONFIG.FRAME_WIDTH - 60, CONFIG.ROW_HEIGHT * CONFIG.VISIBLE_ROWS)
    scrollFrame:SetScrollChild(content)
    scrollFrame.content = content
    
    local scrollbar = CreateFrame("Slider", "RepListScrollbarElvUI", scrollFrame)
    scrollbar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -100)
    scrollbar:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", -10, -100 - CONFIG.ROW_HEIGHT * CONFIG.VISIBLE_ROWS)
    scrollbar:SetWidth(16)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetValueStep(1)
    
    StyleElvUIFrame(scrollbar)
    scrollbar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetSize(14, 40)
    thumb:SetVertexColor(0.3, 0.3, 0.3)
    scrollbar:SetThumbTexture(thumb)
    
    scrollbar:SetScript("OnValueChanged", function(self, value)
        local newOffset = math.floor(value)
        if STATE.scrollOffset ~= newOffset then
            STATE.scrollOffset = newOffset
            UI:UpdateVisibleRows()
            
            collectgarbage("step", 200)
        end
    end)
    
    scrollbar:SetScript("OnEnter", function(self)
        thumb:SetVertexColor(0.4, 0.4, 0.4)
    end)
    scrollbar:SetScript("OnLeave", function(self)
        thumb:SetVertexColor(0.3, 0.3, 0.3)
    end)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local newValue = math.max(min, math.min(max, current - delta * 3))
        scrollbar:SetValue(newValue)
    end)
    
    CACHE.scrollFrame = scrollFrame
    CACHE.scrollbar = scrollbar
    
    CACHE.rows = {}
    for i = 1, CONFIG.VISIBLE_ROWS do
        self:CreateRow(content, i)
    end
end

function UI:CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(CONFIG.FRAME_WIDTH - 60, CONFIG.ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * CONFIG.ROW_HEIGHT)
    
    StyleElvUIFrame(row)
    row:SetBackdropColor(0.08, 0.08, 0.08, 0.8)
    
    row:EnableMouse(true)
    row.index = index
    
    row:SetScript("OnEnter", function(self)
        if self.playerName then
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        end
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.08, 0.8)
    end)
    
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("LEFT", 8, 0)
    row.nameText:SetWidth((CONFIG.FRAME_WIDTH - 60) * 0.35 - 16)
    row.nameText:SetJustifyH("LEFT")
    
    row.noteText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.noteText:SetPoint("LEFT", (CONFIG.FRAME_WIDTH - 60) * 0.35, 0)
    row.noteText:SetWidth((CONFIG.FRAME_WIDTH - 60) * 0.35 - 8)
    row.noteText:SetJustifyH("LEFT")
    row.noteText:SetTextColor(0.7, 0.7, 0.7)
    
    row.buttons = UI:CreateRowButtons(row)
    
    row:Hide()
    CACHE.rows[index] = row
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
        local color = ELVUI_COLORS[STATE.currentTab:upper()] or {1, 1, 1}
        nameColor = color
    end
    
    row.nameText:SetText(data.name or "???")
    row.nameText:SetTextColor(nameColor[1], nameColor[2], nameColor[3])
    row.playerName = data.name
    
    row.noteText:SetText(data.note or "")
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
    if row.buttons.ignore and row.buttons.ignore.text then
        row.buttons.ignore.text:SetText(ignoreText)
    end
end

function UI:CreateRowButtons(row)
    local buttons = {}
    local buttonSize = CONFIG.BUTTON_SIZE
    local startX = -8
    
    local deleteBtn = CreateFrame("Button", nil, row)
    deleteBtn:SetSize(20, buttonSize)
    deleteBtn:SetPoint("RIGHT", startX, 0)
    StyleElvUIButton(deleteBtn)
    
    local deleteText = deleteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deleteText:SetPoint("CENTER")
    deleteText:SetText("X")
    deleteText:SetTextColor(1, 0.3, 0.3)
    
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
    deleteBtn:SetScript("OnLeave", GameTooltip_Hide)
    buttons.delete = deleteBtn
    
    local editBtn = CreateFrame("Button", nil, row)
    editBtn:SetSize(20, buttonSize)
    editBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -3, 0)
    StyleElvUIButton(editBtn)
    
    local editText = editBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editText:SetPoint("CENTER")
    editText:SetText("✎")
    editText:SetTextColor(0.3, 0.8, 1)
    
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
    editBtn:SetScript("OnLeave", GameTooltip_Hide)
    buttons.edit = editBtn
    
    local ignoreBtn = CreateFrame("Button", nil, row)
    ignoreBtn:SetSize(42, buttonSize)
    ignoreBtn:SetPoint("RIGHT", editBtn, "LEFT", -3, 0)
    StyleElvUIButton(ignoreBtn)
    
    local ignoreText = ignoreBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ignoreText:SetPoint("CENTER")
    ignoreText:SetText(L["UI_IG"])
    ignoreBtn.text = ignoreText
    
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
    ignoreBtn:SetScript("OnLeave", GameTooltip_Hide)
    buttons.ignore = ignoreBtn
    
    local infoBtn = CreateFrame("Button", nil, row)
    infoBtn:SetSize(20, buttonSize)
    infoBtn:SetPoint("RIGHT", ignoreBtn, "LEFT", -3, 0)
    StyleElvUIButton(infoBtn)
    
    local infoText = infoBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("CENTER")
    infoText:SetText("i")
    infoText:SetTextColor(1, 0.8, 0.3)
    
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
    infoBtn:SetScript("OnLeave", GameTooltip_Hide)
    buttons.info = infoBtn
    
    local dropdown = CreateFrame("Frame", "ReputationListRowDropdownElvUI"..tostring(row.index), row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("RIGHT", infoBtn, "LEFT", 105, -7)
    UIDropDownMenu_SetWidth(dropdown, 20)
    UIDropDownMenu_SetText(dropdown, "BL")
    
    local left = _G[dropdown:GetName().."Left"]
    local middle = _G[dropdown:GetName().."Middle"]
    local right = _G[dropdown:GetName().."Right"]
    if left then left:SetTexture(nil) end
    if middle then middle:SetTexture(nil) end
    if right then right:SetTexture(nil) end
    
    local dropdownButton = _G[dropdown:GetName().."Button"]
    if dropdownButton then
        StyleElvUIButton(dropdownButton)
        dropdownButton:SetSize(20, 20)
    end
    
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
    
    local addToListBtn = CreateFrame("Button", nil, row)
    addToListBtn:SetSize(20, buttonSize)
    addToListBtn:SetPoint("RIGHT", startX, 0)
    StyleElvUIButton(addToListBtn)
    
    local addText = addToListBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addText:SetPoint("CENTER")
    addText:SetText("+")
    addText:SetTextColor(0.3, 1, 0.3)
    
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
    addToListBtn:SetScript("OnLeave", GameTooltip_Hide)
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
    
    if CACHE.actionPanel then CACHE.actionPanel:Show() end
    if CACHE.settingsPanel then CACHE.settingsPanel:Hide() end
    if CACHE.scrollFrame then CACHE.scrollFrame:Show() end
    if CACHE.addPlayerForm then CACHE.addPlayerForm:Show() end
    if CACHE.tableHeader then CACHE.tableHeader:Show() end
    
    local realmData = RL:GetRealmData()
    if not realmData then return end
    
    local list = realmData[STATE.currentTab]
    if not list then return end
    
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
        return a.name < b.name
    end)
    
    local title = "Reputation List - "
    if STATE.currentTab == "blacklist" then
        title = title .. "Blacklist"
    elseif STATE.currentTab == "whitelist" then
        title = title .. "Whitelist"
    else
        title = title .. "Notelist"
    end
    title = title .. " (" .. count .. ")"
    
    if CACHE.mainFrame and CACHE.mainFrame.titleText then
        CACHE.mainFrame.titleText:SetText(title)
    end
    
    if CACHE.scrollbar then
        local maxScroll = math.max(0, count - CONFIG.VISIBLE_ROWS)
        CACHE.scrollbar:SetMinMaxValues(0, maxScroll)
        if STATE.scrollOffset > maxScroll then
            STATE.scrollOffset = maxScroll
            CACHE.scrollbar:SetValue(maxScroll)
        end
    end
    
    self:UpdateVisibleRows()
end


function UI:UpdateVisibleRows()
    if STATE.showGroupMembers then
        UI:UpdateGroupMembersVisibleRows()
        return
    end
    
    local players = CACHE.filteredPlayers
    
    if not CACHE.rows or #CACHE.rows == 0 then
        return
    end
    
    for i = 1, CONFIG.VISIBLE_ROWS do
        local row = CACHE.rows[i]
        if not row then
            break
        end
        
        local dataIndex = i + STATE.scrollOffset
        
        if dataIndex <= #players then
            local data = players[dataIndex]
            UI:UpdateRowDisplay(row, data, false)
            
            if not row:IsShown() then
                row:Show()
            end
        else
            if row:IsShown() then
                row.playerName = nil
                row.playerNote = nil
                row.playerData = nil
                row.nameText:SetText("")
                row.noteText:SetText("")
                row:Hide()
            end
        end
    end
end

function UI:CreateAddPlayerForm(parent)
    local actionPanel = CreateFrame("Frame", nil, parent)
    actionPanel:SetHeight(30)
    actionPanel:SetPoint("BOTTOM", parent, "BOTTOM", 0, 45)
    actionPanel:SetWidth(CONFIG.FRAME_WIDTH - 40)
    actionPanel:SetPoint("LEFT", parent, "LEFT", 20, 0)
    
    local searchLabel = actionPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", 5, 0)
    searchLabel:SetText(L["UI_SEARCH"])
    searchLabel:SetTextColor(ELVUI_COLORS.ACCENT[1], ELVUI_COLORS.ACCENT[2], ELVUI_COLORS.ACCENT[3])
    
    local searchBox = CreateFrame("EditBox", nil, actionPanel)
    searchBox:SetSize(CONFIG.SEARCH_WIDTH, 24)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject(GameFontNormal)
    StyleElvUIEditBox(searchBox)
    searchBox:SetTextInsets(6, 6, 0, 0)
    searchBox:SetScript("OnTextChanged", function(self)
        STATE.searchText = self:GetText():lower()
        STATE.scrollOffset = 0
        UI:RefreshList()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    
    local notifyBtn = CreateFrame("Button", nil, actionPanel)
    notifyBtn:SetSize(80, 24)
    notifyBtn:SetPoint("LEFT", searchBox, "RIGHT", 120, 0)
    StyleElvUIButton(notifyBtn)
    local notifyText = notifyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    notifyText:SetPoint("CENTER")
    notifyText:SetText(L["UI_CB37"])
    notifyText:SetTextColor(1, 1, 1)
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
    
    local kickBtn = CreateFrame("Button", nil, actionPanel)
    kickBtn:SetSize(60, 24)
    kickBtn:SetPoint("RIGHT", notifyBtn, "LEFT", -5, 0)
    StyleElvUIButton(kickBtn)
    local kickText = kickBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kickText:SetPoint("CENTER")
    kickText:SetText(L["UI_CB38"])
    kickText:SetTextColor(1, 1, 1)
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
    
    parent.searchBox = searchBox
    parent.notifyBtn = notifyBtn
    parent.kickBtn = kickBtn
    CACHE.actionPanel = actionPanel
    
    local form = CreateFrame("Frame", nil, parent)
    form:SetPoint("BOTTOM", parent, "BOTTOM", 0, 10)
    form:SetHeight(30)
    form:SetWidth(CONFIG.FRAME_WIDTH - 40)
    form:SetPoint("LEFT", parent, "LEFT", 20, 0)
    
    local nameLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("LEFT", 5, 0)
    nameLabel:SetText(L["UI_CB39"])
    nameLabel:SetTextColor(ELVUI_COLORS.ACCENT[1], ELVUI_COLORS.ACCENT[2], ELVUI_COLORS.ACCENT[3])
    
    local nameBox = CreateFrame("EditBox", nil, form)
    nameBox:SetSize(100, 24)
    nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 5, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetFontObject(GameFontNormal)
    nameBox:SetMaxLetters(12)
    StyleElvUIEditBox(nameBox)
    nameBox:SetTextInsets(6, 6, 0, 0)
    nameBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        UI:AddPlayer()
    end)
    nameBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    form.nameBox = nameBox
    
    local noteLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noteLabel:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
    noteLabel:SetText(L["UI_CB40"])
    noteLabel:SetTextColor(ELVUI_COLORS.ACCENT[1], ELVUI_COLORS.ACCENT[2], ELVUI_COLORS.ACCENT[3])
    
    local noteBox = CreateFrame("EditBox", nil, form)
    noteBox:SetSize(180, 24)
    noteBox:SetPoint("LEFT", noteLabel, "RIGHT", 8, 0)
    noteBox:SetAutoFocus(false)
    noteBox:SetFontObject(GameFontNormal)
    noteBox:SetMaxLetters(50)
    StyleElvUIEditBox(noteBox)
    noteBox:SetTextInsets(6, 6, 0, 0)
    noteBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        UI:AddPlayer()
    end)
    noteBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    form.noteBox = noteBox
    
    local addBtn = CreateFrame("Button", nil, form)
    addBtn:SetSize(60, 24)
    addBtn:SetPoint("LEFT", noteBox, "RIGHT", 8, 0)
    StyleElvUIButton(addBtn)
    local addText = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addText:SetPoint("CENTER")
    addText:SetText("+" .. L["UI_ADD"])
    addText:SetTextColor(0.3, 1, 0.3)
    addBtn:SetScript("OnClick", function()
        UI:AddPlayer()
    end)
    
    form:Hide()
    CACHE.addPlayerForm = form
    parent.addPlayerForm = form
end


function UI:AddPlayer()
    local name = CACHE.addPlayerForm.nameBox:GetText()
    local note = CACHE.addPlayerForm.noteBox:GetText()
    
    if not name or name == "" then
        print(L["UI_NM_INPT"])
        return
    end
    
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    
    if RL and RL.AddPlayerDirect then
        RL:AddPlayerDirect(name, STATE.currentTab, note, "manual")
        CACHE.addPlayerForm.nameBox:SetText("")
        CACHE.addPlayerForm.noteBox:SetText("")
        self:RefreshList()
    end
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
                if button.text then
                    button.text:SetText(L["UI_IG"])
                end
                print("|cFF00FF00ReputationList:|r " .. playerName .. L["UI_RM_IG"])
                return
            end
        end
    else
        if GetNumIgnores() >= 50 then
            print("|cFFFF0000ReputationList:|r" .. L["UI_BLIZ_F"])
            return
        end
        AddIgnore(playerName)
        if button.text then
            button.text:SetText(L["UI_UNLOCK"])
        end
        print("|cFF00FF00ReputationList:|r " .. playerName .. L["UI_BLACK"])
    end
end


function UI:CreatePlayerInfoFrame()
    local function applyElvUIStyle(frame, elementType, element)
        if elementType == "frame" then
            StyleElvUIFrame(frame)
            frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        elseif elementType == "editbox" then
            StyleElvUIEditBox(element)
        elseif elementType == "button" then
            StyleElvUIButton(element)
        elseif elementType == "closebutton" then
            StyleElvUIButton(element)
        end
    end
    
    return Common.CreatePlayerCardBase(L, {
        frameName = "RepListPlayerInfoFrameElvUI",
        applyStyle = applyElvUIStyle,
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
    f.guildValue:SetText(data.guild or L["UI_NO"])
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
        if listType == "whohere" or STATE.showGroupMembers then
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
    
    if STATE.showGroupMembers and not data.inList then
        f.title:SetText(L["UI_POP_GROUP"])
        f.title:SetTextColor(0.5, 0.7, 1)
        f:SetBackdropBorderColor(0.5, 0.7, 1, 1)
    elseif STATE.currentTab == "blacklist" or (data.inList and data.listType == "blacklist") then
        f.title:SetText(L["UI_POP1"] .. "- BLACKLIST")
        f.title:SetTextColor(1, 0, 0)
        f:SetBackdropBorderColor(0.8, 0.1, 0.1, 1)
    elseif STATE.currentTab == "whitelist" or (data.inList and data.listType == "whitelist") then
        f.title:SetText(L["UI_POP2"] .. "- WHITELIST")
        f.title:SetTextColor(0, 1, 0)
        f:SetBackdropBorderColor(0.1, 0.8, 0.1, 1)
    elseif STATE.currentTab == "notelist" or (data.inList and data.listType == "notelist") then
        f.title:SetText(L["UI_POP3"] .. "- NOTELIST")
        f.title:SetTextColor(1, 0.84, 0)
        f:SetBackdropBorderColor(1, 0.84, 0, 1)
    else
        f.title:SetText(L["UI_INF"])
        f.title:SetTextColor(1, 1, 1)
        f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end
    
    f:Show()
end


function UI:CreateSettingsPanel(parent)
    if CACHE.settingsPanel then return CACHE.settingsPanel end
    
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", 10, -75)
    panel:SetPoint("BOTTOMRIGHT", -10, 50)
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
    StyleElvUIFrame(scrollbar)
    scrollbar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetSize(14, 40)
    thumb:SetVertexColor(0.3, 0.3, 0.3)
    scrollbar:SetThumbTexture(thumb)
    
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
    mainTitle:SetTextColor(ELVUI_COLORS.SETTINGS[1], ELVUI_COLORS.SETTINGS[2], ELVUI_COLORS.SETTINGS[3])
    yOffset = yOffset - 35
    
    local notifyHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notifyHeader:SetPoint("TOPLEFT", 20, yOffset)
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
    
    local exportBtn = CreateFrame("Button", nil, content)
    exportBtn:SetSize(140, 30)
    exportBtn:SetPoint("TOP", content, "TOP", -75, yOffset)
    StyleElvUIButton(exportBtn)
    
    local exportBtnText = exportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exportBtnText:SetPoint("CENTER")
    exportBtnText:SetText(L["UI_CB9"])
    
    exportBtn:SetScript("OnClick", function()
        UI:ShowExport()
    end)
    
    local importBtn = CreateFrame("Button", nil, content)
    importBtn:SetSize(140, 30)
    importBtn:SetPoint("TOP", content, "TOP", 75, yOffset)
    StyleElvUIButton(importBtn)
    
    local importBtnText = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importBtnText:SetPoint("CENTER")
    importBtnText:SetText(L["UI_CB10"])
    
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
	if CACHE.actionPanel then CACHE.actionPanel:Hide() end
    CACHE.settingsPanel:Show()
    
    if CACHE.mainFrame and CACHE.mainFrame.titleText then
        CACHE.mainFrame.titleText:SetText(L["SETTINGS_TITLE"])
    end
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
                if currentRealm then table.insert(resultParts, "    },\n") end
                currentRealm = entry.realm
                table.insert(resultParts, '    ["' .. entry.realm .. '"] = {\n')
                currentListType = nil
            end
            
            if currentListType ~= entry.listType then
                if currentListType then table.insert(resultParts, "      },\n") end
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
            if pd.date then table.insert(resultParts, '          date = "' .. tostring(pd.date) .. '",\n') end
            
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
            local str = (#v > 200) and (v:sub(1, 200) .. "...") or v
            table.insert(result, space .. key .. ' = "' .. str:gsub('"', '\\"') .. '",\n')
        elseif type(v) == "number" or type(v) == "boolean" then
            table.insert(result, space .. key .. " = " .. tostring(v) .. ",\n")
        end
    end
    return table.concat(result)
end

local function CreateProgressBar()
    if exportState.frame then return end
    
    local E = ElvUI and ElvUI[1]
    local frame = CreateFrame("Frame", "RepListExportProgress", UIParent)
    frame:SetSize(400, 80)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    
    if E and E.SetTemplate then
        E:SetTemplate(frame, "Transparent")
    else
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.9)
    end
    
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
    if text:find("ReputationList_Import") or text:find("realms") then return "ReputationList" end
    if text:find("BlackListDB") or text:find("BLackListDB") then return "BlackList" end
    if text:find("ElitistGroupDB") then return "ElitistGroup" end
    return nil, L["UI_CB17"]
end

local function ImportFromReputationList(data)
    if not data or not data.realms then return 0 end
    local imported = 0
    local myRealm = RL.NormalizeRealm(GetRealmName())
    
    for realm, lists in pairs(data.realms) do
        for listType, list in pairs(lists) do
            if type(list) == "table" then
                ReputationListDB.realms[myRealm] = ReputationListDB.realms[myRealm] or {}
                ReputationListDB.realms[myRealm][listType] = ReputationListDB.realms[myRealm][listType] or {}
                for name, info in pairs(list) do
                    if not ReputationListDB.realms[myRealm][listType][name] then
                        ReputationListDB.realms[myRealm][listType][name] = info
                        imported = imported + 1
                    end
                end
            end
        end
    end
    return imported
end

local function ImportFromBlackList(data)
    if not data then return 0 end
    local imported = 0
    local myRealm = RL.NormalizeRealm(GetRealmName())
    
    ReputationListDB.realms[myRealm] = ReputationListDB.realms[myRealm] or {}
    ReputationListDB.realms[myRealm].blacklist = ReputationListDB.realms[myRealm].blacklist or {}
    
    for name, info in pairs(data) do
        if type(info) == "table" and not ReputationListDB.realms[myRealm].blacklist[name] then
            ReputationListDB.realms[myRealm].blacklist[name] = {
                note = info.reason or info.note,
                date = info.date or date("%d.%m.%y"),
            }
            imported = imported + 1
        end
    end
    return imported
end

local function ImportFromElitistGroup(data)
    if not data or not data.blacklist then return 0 end
    local imported = 0
    local myRealm = RL.NormalizeRealm(GetRealmName())
    
    ReputationListDB.realms[myRealm] = ReputationListDB.realms[myRealm] or {}
    ReputationListDB.realms[myRealm].blacklist = ReputationListDB.realms[myRealm].blacklist or {}
    
    for name, info in pairs(data.blacklist) do
        if not ReputationListDB.realms[myRealm].blacklist[name] then
            ReputationListDB.realms[myRealm].blacklist[name] = {
                note = info.reason or "Из ElitistGroup",
                date = date("%d.%m.%y"),
            }
            imported = imported + 1
        end
    end
    return imported
end


function UI:CreateExportImportFrames()
    if self.exportFrame then return end
    local E = ElvUI and ElvUI[1]
    local parent = CACHE.mainFrame or UIParent
    
    local ef = CreateFrame("Frame", "RepExportFrameElvUI", parent)
    ef:SetSize(520, 420)
    ef:SetPoint("CENTER")
    
    StyleElvUIFrame(ef)
    
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
    ef.title:SetTextColor(1, 0.82, 0)
    
    local scroll = CreateFrame("ScrollFrame", "RepExportScrollElvUI", ef, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -40)
    scroll:SetPoint("BOTTOMRIGHT", -36, 44)
    
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(scroll:GetWidth() - 20)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    
    StyleElvUIEditBox(edit)
    
    edit:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local lines = 1
        for _ in text:gmatch("\n") do lines = lines + 1 end
        self:SetHeight(math.max(200, lines * 14))
    end)
    
    local copyBtn = CreateFrame("Button", nil, ef)
    copyBtn:SetSize(120, 28)
    copyBtn:SetPoint("BOTTOMLEFT", 16, 12)
    copyBtn:SetScript("OnClick", function() edit:HighlightText(); edit:SetFocus() end)
    StyleElvUIButton(copyBtn)
    local copyText = copyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    copyText:SetPoint("CENTER")
    copyText:SetText(L["UI_CB21"])
    copyText:SetTextColor(1, 1, 1)
    
    local closeBtn = CreateFrame("Button", nil, ef)
    closeBtn:SetSize(80, 28)
    closeBtn:SetPoint("BOTTOMRIGHT", -16, 12)
    closeBtn:SetScript("OnClick", function() ef:Hide() end)
    StyleElvUIButton(closeBtn)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER")
    closeText:SetText(L["UI_CLOSE"])
    closeText:SetTextColor(1, 1, 1)
    
    local closeX = CreateFrame("Button", nil, ef)
    closeX:SetSize(20, 20)
    closeX:SetPoint("TOPRIGHT", -8, -8)
    closeX:SetScript("OnClick", function() ef:Hide() end)
    StyleElvUIButton(closeX, true)
    local closeXText = closeX:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeXText:SetPoint("CENTER", 0, 1)
    closeXText:SetText("×")
    closeXText:SetTextColor(1, 0.3, 0.3)
    
    ef.edit = edit
    ef:Hide()
    self.exportFrame = ef
    
    local inf = CreateFrame("Frame", "RepImportFrameElvUI", parent)
    inf:SetSize(520, 420)
    inf:SetPoint("CENTER")
    
    StyleElvUIFrame(inf)
    
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
    inf.title:SetTextColor(1, 0.82, 0)
    
    local scroll2 = CreateFrame("ScrollFrame", "RepImportScrollElvUI", inf, "UIPanelScrollFrameTemplate")
    scroll2:SetPoint("TOPLEFT", 16, -40)
    scroll2:SetPoint("BOTTOMRIGHT", -36, 44)
    
    local edit2 = CreateFrame("EditBox", nil, scroll2)
    edit2:SetMultiLine(true)
    edit2:SetAutoFocus(false)
    edit2:SetFontObject(ChatFontNormal)
    edit2:SetWidth(scroll2:GetWidth() - 20)
    edit2:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll2:SetScrollChild(edit2)
    
    StyleElvUIEditBox(edit2)
    
    edit2:SetScript("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local lines = 1
        for _ in text:gmatch("\n") do lines = lines + 1 end
        self:SetHeight(math.max(200, lines * 14))
    end)
    
    local importBtn = CreateFrame("Button", nil, inf)
    importBtn:SetSize(120, 28)
    importBtn:SetPoint("BOTTOMLEFT", 16, 12)
    importBtn:SetScript("OnClick", function()
        local text = edit2:GetText()
        if not text or text == "" then print(L["UI_CB22"]) return end
        
        local format, error = DetectImportFormat(text)
        if not format then print(L["UI_CB23"] .. error .. "|r") return end
        
        print(L["UI_CB24"] .. format)
        
        local textToLoad = text
        if not text:match("^%s*return%s+") then
            if format == "ReputationList" then textToLoad = text .. "\nreturn ReputationList_Import"
            elseif format == "BlackList" then textToLoad = text .. "\nreturn BlackListDB or BLackListDB"
            elseif format == "ElitistGroup" then textToLoad = text .. "\nreturn ElitistGroupDB" end
        end
        
        local func, err = loadstring(textToLoad)
        if not func then print("|cFFFF0000Неверный формат|r") return end
        
        local success, result = pcall(func)
        if not success or type(result) ~= "table" then print("|cFFFF0000Ошибка|r") return end
        
        local imported = 0
        if format == "ReputationList" then imported = ImportFromReputationList(result)
        elseif format == "BlackList" then imported = ImportFromBlackList(result)
        elseif format == "ElitistGroup" then imported = ImportFromElitistGroup(result) end
        
        if imported > 0 then
             print(L["UI_CB27"] .. imported .. "|r")
            UI:RefreshList()
            inf:Hide()
        else print(L["UI_CB28"]) end
    end)
    StyleElvUIButton(importBtn)
    local importText = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importText:SetPoint("CENTER")
    importText:SetText(L["UI_CB47"])
    importText:SetTextColor(1, 1, 1)
    
    local closeBtn2 = CreateFrame("Button", nil, inf)
    closeBtn2:SetSize(80, 28)
    closeBtn2:SetPoint("BOTTOMRIGHT", -16, 12)
    closeBtn2:SetScript("OnClick", function() inf:Hide() end)
    StyleElvUIButton(closeBtn2)
    local closeText2 = closeBtn2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText2:SetPoint("CENTER")
    closeText2:SetText(L["UI_CLOSE"])
    closeText2:SetTextColor(1, 1, 1)
    
    local closeX2 = CreateFrame("Button", nil, inf)
    closeX2:SetSize(20, 20)
    closeX2:SetPoint("TOPRIGHT", -8, -8)
    closeX2:SetScript("OnClick", function() inf:Hide() end)
    StyleElvUIButton(closeX2, true)
    local closeXText2 = closeX2:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeXText2:SetPoint("CENTER", 0, 1)
    closeXText2:SetText("×")
    closeXText2:SetTextColor(1, 0.3, 0.3)
    
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
    
    self:SwitchTab("blacklist")
    
    mainFrame:Hide()
    
    self.frame = mainFrame
    
    mainFrame:SetScript("OnShow", function(self)
        UI:RefreshList()
    end)
    
    mainFrame:SetScript("OnHide", function(self)
        for i = #CACHE.filteredPlayers, 1, -1 do
            CACHE.filteredPlayers[i] = nil
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
    
    if CACHE.actionPanel then CACHE.actionPanel:Show() end
    if CACHE.settingsPanel then CACHE.settingsPanel:Hide() end
    if CACHE.scrollFrame then CACHE.scrollFrame:Show() end
    if CACHE.addPlayerForm then CACHE.addPlayerForm:Hide() end
    if CACHE.tableHeader then CACHE.tableHeader:Show() end
    
    local members = RL.GroupTracker:GetAllGroupMembersWithListInfo()
    
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
    
    local title = "Reputation List - " .. (L["UI_WHO_HERE"] or "Кто здесь?") .. " (" .. count .. ")"
    if CACHE.mainFrame and CACHE.mainFrame.titleText then
        CACHE.mainFrame.titleText:SetText(title)
    end
    
    if CACHE.scrollbar then
        local maxScroll = math.max(0, count - CONFIG.VISIBLE_ROWS)
        CACHE.scrollbar:SetMinMaxValues(0, maxScroll)
    end
    
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
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    
    if ElvUI then
        UI:Initialize()
        
        SLASH_REPLISTNEW1 = "/rlnew"
        SLASH_REPLISTNEW2 = "/rlelvui"
        SlashCmdList["REPLISTNEW"] = function()
            if RL.UI and RL.UI.ElvUI and RL.UI.ElvUI.Toggle then
                RL.UI.ElvUI:Toggle()
            else
                print(L and L["UI_CB55"] or "|cFFFF8800ReputationList:|r UI not initialized. Try /rlnew")
            end
        end
        
        print(L and L["UI_CB48"] or "|cFF00FF00ReputationList:|r ElvUI style loaded! Commands: /rlelvui or /rlnew")
    else
        print(L["UI_CB50"])
    end
end)