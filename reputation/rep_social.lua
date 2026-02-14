-- ============================================================================
-- Reputation List - Social Frame Integration
-- ============================================================================

local RL = ReputationList
if not RL then return end

local SocialUI = {}
RL.SocialUI = SocialUI

local E, L, V, P, G
local S
local useElvUI = false

if ElvUI then
    E, L, V, P, G = unpack(ElvUI)
    if E then
        S = E:GetModule('Skins')
        useElvUI = true
    end
end

local L = ReputationList.L or ReputationListLocale

local CONFIG_ELVUI = {
    ROW_HEIGHT = 24,
    VISIBLE_ROWS = 14,
    BUTTON_SIZE = 20,
    
    TAB_OFFSET_X = -115,
    TAB_OFFSET_Y = -5,
    TAB_TEXT_OFFSET_Y = 0,
    
    SETTINGS_BTN_SIZE = 24,
    SETTINGS_BTN_X = -50,
    SETTINGS_BTN_Y = -105,
    
    SEARCH_BOX_WIDTH = 120,
    SEARCH_BOX_HEIGHT = 20,
    SEARCH_BOX_X = 65,
    SEARCH_BOX_Y = -40,
    
    TAB_WIDTH = 90,
    TAB_HEIGHT = 24,
    TAB_START_X = 30,
    TAB_START_Y = -105,
    TAB_SPACING = 2,
    
    SETTINGS_PANEL_LEFT = 20,
    SETTINGS_PANEL_TOP = -90,
    SETTINGS_PANEL_RIGHT = -50,
    SETTINGS_PANEL_BOTTOM = 50,
    
    SCROLL_LEFT = 30,
    SCROLL_TOP = -140,
    SCROLL_RIGHT = -55,
    SCROLL_BOTTOM = 130,
    
    SCROLLBAR_WIDTH = 16,
    SCROLLBAR_RIGHT = -40,
    SCROLLBAR_TOP = -140,
    SCROLLBAR_BOTTOM = 130,
    
    ROW_WIDTH = 300,
    ROW_NAME_LEFT = 5,
    ROW_NAME_WIDTH = 170,
    
    FORM_LEFT = 20,
    FORM_RIGHT = -20,
    FORM_BOTTOM = 90,
    FORM_HEIGHT = 35,
    
    NAME_BOX_WIDTH = 100,
    NAME_BOX_HEIGHT = 25,
    NAME_BOX_LEFT = 5,
    NOTE_BOX_WIDTH = 120,
    NOTE_BOX_HEIGHT = 25,
    NOTE_BOX_SPACING = 5,
    
    ADD_BTN_WIDTH = 90,
    ADD_BTN_HEIGHT = 25,
    ADD_BTN_SPACING = 5,
	C5POINT = 170,
	C6POINT = 170,
	C2POINT = 20,
	C1POINT = 20,
	C3POINT = 20,
	C7POINT = 170,
	C4POINT = 20,
}

local CONFIG_CLASSIC = {
    ROW_HEIGHT = 24,
    VISIBLE_ROWS = 14,
    BUTTON_SIZE = 20,
    
    TAB_OFFSET_X = -110,
    TAB_OFFSET_Y = -2,
    TAB_TEXT_OFFSET_Y = -2,
    
    SETTINGS_BTN_SIZE = 24,
    SETTINGS_BTN_X = -65,
    SETTINGS_BTN_Y = -105,
    
    SEARCH_BOX_WIDTH = 120,
    SEARCH_BOX_HEIGHT = 20,
    SEARCH_BOX_X = 125,
    SEARCH_BOX_Y = -45,
    
    TAB_WIDTH = 85,
    TAB_HEIGHT = 24,
    TAB_START_X = 30,
    TAB_START_Y = -105,
    TAB_SPACING = 2,
    
    SETTINGS_PANEL_LEFT = 20,
    SETTINGS_PANEL_TOP = -90,
    SETTINGS_PANEL_RIGHT = -50,
    SETTINGS_PANEL_BOTTOM = 50,
    
    SCROLL_LEFT = 30,
    SCROLL_TOP = -135,
    SCROLL_RIGHT = -55,
    SCROLL_BOTTOM = 165,
    
    SCROLLBAR_WIDTH = 16,
    SCROLLBAR_RIGHT = -42,
    SCROLLBAR_TOP = -135,
    SCROLLBAR_BOTTOM = 160,
    
    ROW_WIDTH = 280,
    ROW_NAME_LEFT = 5,
    ROW_NAME_WIDTH = 160,
    
    FORM_LEFT = 20,
    FORM_RIGHT = -20,
    FORM_BOTTOM = 90,
    FORM_HEIGHT = 65,
    
    NAME_BOX_WIDTH = 100,
    NAME_BOX_HEIGHT = 25,
    NAME_BOX_LEFT = 5,
    NOTE_BOX_WIDTH = 120,
    NOTE_BOX_HEIGHT = 25,
    NOTE_BOX_SPACING = 5,
    
    ADD_BTN_WIDTH = 70,
    ADD_BTN_HEIGHT = 24,
    ADD_BTN_SPACING = 0,
	C5POINT = 160,
	C6POINT = 160,
	C2POINT = 10,
	C1POINT = 10,
	C3POINT = 10,
	C7POINT = 160,
	C4POINT = 10,
}

local CONFIG = useElvUI and CONFIG_ELVUI or CONFIG_CLASSIC

local clientLocale = GetLocale()

if clientLocale == "enUS" or clientLocale == "enGB" then
    if useElvUI then
        CONFIG.TAB_OFFSET_X = -75
    else
        CONFIG.TAB_OFFSET_X = -70
    end
elseif clientLocale == "ruRU" then
end

local STATE = {
    currentTab = "blacklist",
    searchText = "",
    scrollOffset = 0,
}

local CACHE = {
    container = nil,
    tab = nil,
    rows = {},
    maxCachedRows = CONFIG.VISIBLE_ROWS,
    settingsPanel = nil,
    addForm = nil,
    lastCleanup = 0,
}





local function CheckPlayerInLists(playerName)
    if not playerName or not RL then return nil end
    
    local normalizedName = RL.NormalizeName(playerName):lower()
    local realmData = RL:GetRealmData()
    if not realmData then return nil end
    
    if realmData.blacklist and realmData.blacklist[normalizedName] then
        return "blacklist"
    end
    
    if realmData.whitelist and realmData.whitelist[normalizedName] then
        return "whitelist"
    end
    
    if realmData.notelist and realmData.notelist[normalizedName] then
        return "notelist"
    end
    
    return nil
end

local function GetListMarkup(listType)
    if listType == "blacklist" then
        return "[BL]", {1, 0.3, 0.3}
    elseif listType == "whitelist" then
        return "[WL]", {0.3, 1, 0.3}
    elseif listType == "notelist" then
        return "[NL]", {1, 0.8, 0.3}
    end
    return nil, nil
end


local ELVUI_COLORS = {
    ACCENT = {0.3, 0.8, 1},
    BLACKLIST = {1, 0.3, 0.3},
    WHITELIST = {0.3, 1, 0.3},
    NOTELIST = {1, 0.8, 0.3},
}

local function StyleElvUIButton(button, isIcon)
    if not useElvUI then return end
    
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
        self:SetBackdropBorderColor(0.3, 0.8, 1, 1)
    end)
    button:HookScript("OnLeave", function(self)
        if not isIcon then self:SetBackdropColor(0.15, 0.15, 0.15, 1) end
        self:SetBackdropBorderColor(0, 0, 0, 1)
    end)
end

local function StyleElvUITab(tab, isActive)
    if not useElvUI then return end
    
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


function SocialUI:CreateReputationTab()
    if not FriendsFrame or CACHE.tab then return end
    
    local tab = CreateFrame("Button", "FriendsTabHeaderTab4", FriendsTabHeader, "TabButtonTemplate")
    tab:SetID(4)
    tab:SetText("ReputationList")
    
    tab:SetPoint("LEFT", FriendsTabHeaderTab3, "RIGHT", CONFIG.TAB_OFFSET_X, CONFIG.TAB_OFFSET_Y)
    PanelTemplates_TabResize(tab, 0)
    
    local fontString = tab:GetFontString()
	fontString:ClearAllPoints()
    if fontString then
        fontString:SetPoint("CENTER", tab, "CENTER", 0, CONFIG.TAB_TEXT_OFFSET_Y)
    end
    
    if not useElvUI then
        local name = tab:GetName()
    tab:SetBackdrop(nil)

    local name = tab:GetName()
    local extraRegions = {
        name.."HighlightLeft", name.."HighlightMiddle", name.."HighlightRight",
    }
    
    for _, regionName in ipairs(extraRegions) do
        local region = _G[regionName]
        if region then region:SetAlpha(0) end
    end

    tab.UpdateTextures = function(isSelected)
        if isSelected then
            tab:LockHighlight()
            PanelTemplates_SelectTab(tab)
        else
            tab:UnlockHighlight()
            PanelTemplates_DeselectTab(tab)
        end
    end

        
        tab:HookScript("OnShow", function(self)
            local selected = PanelTemplates_GetSelectedTab(FriendsTabHeader) == 4
            if self.UpdateTextures then
                self.UpdateTextures(selected)
            end
            if selected then
                PanelTemplates_Tab_OnClick(self, FriendsTabHeader)
            end
        end)
    else
        if tab.Left then tab.Left:SetTexture(nil) end
        if tab.Middle then tab.Middle:SetTexture(nil) end
        if tab.Right then tab.Right:SetTexture(nil) end
        if tab.LeftDisabled then tab.LeftDisabled:SetTexture(nil) end
        if tab.MiddleDisabled then tab.MiddleDisabled:SetTexture(nil) end
        if tab.RightDisabled then tab.RightDisabled:SetTexture(nil) end
        
        if S and S.HandleTab then
            S:HandleTab(tab)
        end
    end
	tab:SetHeight(28)
    
    tab:SetScript("OnClick", function(self)
        PanelTemplates_Tab_OnClick(self, FriendsTabHeader)
        SocialUI:ShowReputationList()
    end)
    
    CACHE.tab = tab
    tab:Show()
end



function SocialUI:CreateContainer()
    if CACHE.container then return CACHE.container end
    
    local container = CreateFrame("Frame", "ReputationListSocialContainer", FriendsFrame)
    container:SetAllPoints(FriendsFrame)
    container:Hide()
    
    table.insert(FRIENDSFRAME_SUBFRAMES, "ReputationListSocialContainer")
    
    self:CreateSettingsPanel(container)
    
    local settingsBtn = CreateFrame("Button", nil, container)
    settingsBtn:SetSize(CONFIG.SETTINGS_BTN_SIZE, CONFIG.SETTINGS_BTN_SIZE)
    settingsBtn:SetPoint("TOPRIGHT", CONFIG.SETTINGS_BTN_X, CONFIG.SETTINGS_BTN_Y)
	settingsBtn:SetNormalTexture(nil)
	settingsBtn:SetPushedTexture(nil)
	settingsBtn:SetHighlightTexture(nil)
	
	settingsBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	settingsBtn:SetBackdropColor(0, 0, 0, 0.8)
	if settingsBtn.SetBackdropBorderColor then
    settingsBtn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	end

	local txt = settingsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	txt:SetPoint("CENTER", settingsBtn, "CENTER", 0, 0)
	txt:SetText("O")
	settingsBtn.text = txt
    
    if useElvUI then
        StyleElvUIButton(settingsBtn, true)
    end
    
    settingsBtn:SetScript("OnClick", function()
        SocialUI:ToggleSettings()
    end)
    
    settingsBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["SETTINGS_TITLE"], 1, 1, 1)
		GameTooltip:Show()
		if self.SetBackdropBorderColor then
			self:SetBackdropBorderColor(1, 0.82, 0, 1)
		end
	end)
	settingsBtn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		if self.SetBackdropBorderColor then
			self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
		end
	end)
    
    container.settingsBtn = settingsBtn
    
    self:CreateTabs(container)
    
    local searchBox = CreateFrame("EditBox", nil, container)
    searchBox:SetSize(CONFIG.SEARCH_BOX_WIDTH, CONFIG.SEARCH_BOX_HEIGHT)
    searchBox:SetPoint("TOPLEFT", CONFIG.SEARCH_BOX_X, CONFIG.SEARCH_BOX_Y)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject(GameFontHighlight)
    
    if useElvUI then
        searchBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        searchBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        searchBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    else
        searchBox:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        searchBox:SetBackdropColor(0, 0, 0, 0.5)
        searchBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
    
    searchBox:SetTextInsets(5, 5, 0, 0)
    searchBox:SetScript("OnTextChanged", function(self)
        local newSearch = self:GetText():lower()
        if STATE.searchText ~= newSearch then
            STATE.searchText = newSearch
            STATE.scrollOffset = 0
            if CACHE.container and CACHE.container.scroll and CACHE.container.scroll.scrollbar then
                CACHE.container.scroll.scrollbar:SetValue(0)
            end
            
            for i = CONFIG.VISIBLE_ROWS + 1, #CACHE.rows do
                if CACHE.rows[i] then
                    CACHE.rows[i]:Hide()
                    CACHE.rows[i]:SetParent(nil)
                    CACHE.rows[i] = nil
                end
            end
            
            SocialUI:RefreshList()
        end
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    
    container.searchBox = searchBox
    
    self:CreateScrollFrame(container)
    
    self:CreateAddPlayerForm(container)
    
    CACHE.container = container
    return container
end


function SocialUI:CreateTabs(parent)
    local tabs = {}
    local tabData = {
        {key = "blacklist", text = "Blacklist", color = {1, 0.3, 0.3}},
        {key = "whitelist", text = "Whitelist", color = {0.3, 1, 0.3}},
        {key = "notelist", text = "Notelist", color = {1, 0.8, 0.3}},
    }
    
    local tabWidth = CONFIG.TAB_WIDTH
    local tabHeight = CONFIG.TAB_HEIGHT
    local startX = CONFIG.TAB_START_X
    local startY = CONFIG.TAB_START_Y
    
    for i, data in ipairs(tabData) do
        local tab = CreateFrame("Button", nil, parent)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", startX + (i-1) * (tabWidth + CONFIG.TAB_SPACING), startY)
        
        if not useElvUI then
            tab:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
            local normalTex = tab:GetNormalTexture()
            normalTex:SetVertexColor(0, 0, 0, 0.7)
            normalTex:SetAllPoints()
            
            tab:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
            local highlightTex = tab:GetHighlightTexture()
            highlightTex:SetVertexColor(0.2, 0.2, 0.2, 0.5)
            highlightTex:SetBlendMode("ADD")
            highlightTex:SetAllPoints()
            
            tab.normalTexture = normalTex
        else
            StyleElvUITab(tab, false)
        end
        
        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER", 0, 0)
        text:SetText(data.text)
        text:SetTextColor(data.color[1], data.color[2], data.color[3])
        tab.text = text
        
        tab:SetScript("OnClick", function()
            STATE.currentTab = data.key
            SocialUI:UpdateTabAppearance()
            
            for i = 1, #CACHE.rows do
                if CACHE.rows[i] then
                    CACHE.rows[i]:Hide()
                    CACHE.rows[i]:SetParent(nil)
                    CACHE.rows[i] = nil
                end
            end
            CACHE.rows = {}
            STATE.scrollOffset = 0
            if CACHE.container and CACHE.container.scroll and CACHE.container.scroll.scrollbar then
                CACHE.container.scroll.scrollbar:SetValue(0)
            end
            
            SocialUI:RefreshList()
        end)
        
        tab.data = data
        tabs[data.key] = tab
    end
    
    parent.tabs = tabs
    self:UpdateTabAppearance()
end

function SocialUI:UpdateTabAppearance()
    if not CACHE.container or not CACHE.container.tabs then return end
    
    for key, tab in pairs(CACHE.container.tabs) do
        local isActive = (key == STATE.currentTab)
        
        if not useElvUI then
            if tab.normalTexture then
                if isActive then
                    tab.normalTexture:SetVertexColor(0, 0, 0, 0.9)
                else
                    tab.normalTexture:SetVertexColor(0, 0, 0, 0.7)
                end
            end
        else
            StyleElvUITab(tab, isActive)
        end
        
        if tab.text then
            if isActive then
                tab.text:SetTextColor(tab.data.color[1], tab.data.color[2], tab.data.color[3])
            else
                tab.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end
end


function SocialUI:CreateSettingsPanel(parent)
    if CACHE.settingsPanel then return CACHE.settingsPanel end
    
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", CONFIG.SETTINGS_PANEL_LEFT, CONFIG.SETTINGS_PANEL_TOP)
    panel:SetPoint("BOTTOMRIGHT", CONFIG.SETTINGS_PANEL_RIGHT, CONFIG.SETTINGS_PANEL_BOTTOM)
    panel:Hide()
    
	ReputationListDB = ReputationListDB or {}
    local settings = ReputationListDB

    local yOffset = -10
    
    local mainTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainTitle:SetPoint("TOP", 0, yOffset)
    mainTitle:SetText(L["SETTINGS_TITLE"])
    mainTitle:SetTextColor(1, 0.82, 0)
    yOffset = yOffset - 35
    
    local notifyHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notifyHeader:SetPoint("TOPLEFT", 20, yOffset)
    notifyHeader:SetText(L["UI_UVD"])
    notifyHeader:SetTextColor(1, 1, 0)
    
    local protectionHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    protectionHeader:SetPoint("TOPLEFT", 170, yOffset)
    protectionHeader:SetText(L["UI_DEF"])
    protectionHeader:SetTextColor(1, 1, 0)
    yOffset = yOffset - 25
    
    local cb1 = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb1:SetPoint("TOPLEFT", CONFIG.C1POINT, yOffset)
    cb1.text = cb1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb1.text:SetPoint("LEFT", cb1, "RIGHT", 5, 0)
    cb1.text:SetText(L["UI_CB1"])
    cb1:SetChecked(settings.autoNotify)
    cb1:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
    ReputationListDB.autoNotify = checked
    RL.autoNotify = checked 
    
    print("|cFF00FF00RepList:|r" .. L["UI_CB2"])
	end)

	cb1:SetScript("OnShow", function(self)
    self:SetChecked(ReputationListDB.autoNotify or false)
	end)
    
    local cb5 = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb5:SetPoint("TOPLEFT", CONFIG.C5POINT, yOffset)
    cb5.text = cb5:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb5.text:SetPoint("LEFT", cb5, "RIGHT", 5, 0)
    cb5.text:SetText(L["UI_CB3"])
    cb5:SetChecked(settings.blockInvites)
    cb5:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
    ReputationListDB.blockInvites = checked
    RL.blockInvites = checked 
    
    print("|cFF00FF00RepList:|r" .. L["UI_CB2"])
	end)
	cb5:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.blockInvites or false)
	end)
    yOffset = yOffset - 25
    
    local cb2 = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb2:SetPoint("TOPLEFT", CONFIG.C2POINT, yOffset)
    cb2.text = cb2:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb2.text:SetPoint("LEFT", cb2, "RIGHT", 5, 0)
    cb2.text:SetText(L["UI_CB4"])
    cb2:SetChecked(settings.selfNotify)
    cb2:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
    ReputationListDB.selfNotify = checked
    RL.selfNotify = checked 
    
    print("|cFF00FF00RepList:|r" .. L["UI_CB2"])
	end)
	cb2:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.selfNotify or false)
	end)
    
    local cb6 = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb6:SetPoint("TOPLEFT", CONFIG.C6POINT, yOffset)
    cb6.text = cb6:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb6.text:SetPoint("LEFT", cb6, "RIGHT", 5, 0)
    cb6.text:SetText(L["UI_CB5"])
    cb6:SetChecked(settings.blockTrade)
    cb6:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
    ReputationListDB.blockTrade = checked
    RL.blockTrade = checked 
    
    print("|cFF00FF00RepList:|r" .. L["UI_CB2"])
	end)
	cb6:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.blockTrade or false)
	end)
    yOffset = yOffset - 25
    
    local cb3 = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb3:SetPoint("TOPLEFT", CONFIG.C3POINT, yOffset)
    cb3.text = cb3:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb3.text:SetPoint("LEFT", cb3, "RIGHT", 5, 0)
    cb3.text:SetText(L["UI_CB6"])
    cb3:SetChecked(settings.colorLFG)
    cb3:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
    ReputationListDB.colorLFG = checked
    RL.colorLFG = checked 
    
    print("|cFF00FF00RepList:|r" .. L["UI_CB2"])
	end)
	cb3:SetScript("OnShow", function(self)
		self:SetChecked(ReputationListDB.colorLFG or false)
	end)	
    
    local cb7 = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb7:SetPoint("TOPLEFT", CONFIG.C7POINT, yOffset)
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
    
    local cb4 = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb4:SetPoint("TOPLEFT", CONFIG.C4POINT, yOffset)
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
    
    CACHE.settingsPanel = panel
    return panel
end

function SocialUI:ToggleSettings()
    if not CACHE.settingsPanel then return end
    
    if CACHE.settingsPanel:IsShown() then
        CACHE.settingsPanel:Hide()
        if CACHE.container.scroll then CACHE.container.scroll:Show() end
        if CACHE.addForm then CACHE.addForm:Show() end
        if CACHE.container.tabs then
            for _, tab in pairs(CACHE.container.tabs) do
                tab:Show()
            end
        end
        if CACHE.container.searchBox then CACHE.container.searchBox:Show() end
    else
        if CACHE.container.scroll then CACHE.container.scroll:Hide() end
        if CACHE.addForm then CACHE.addForm:Hide() end
        if CACHE.container.tabs then
            for _, tab in pairs(CACHE.container.tabs) do
                tab:Hide()
            end
        end
        if CACHE.container.searchBox then CACHE.container.searchBox:Hide() end
        CACHE.settingsPanel:Show()
        
        for i = 1, #CACHE.rows do
            if CACHE.rows[i] then
                CACHE.rows[i]:Hide()
                CACHE.rows[i]:SetParent(nil)
                CACHE.rows[i] = nil
            end
        end
        CACHE.rows = {}
    end
end


function SocialUI:CreateScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", CONFIG.SCROLL_LEFT, CONFIG.SCROLL_TOP)
    scroll:SetPoint("BOTTOMRIGHT", CONFIG.SCROLL_RIGHT, CONFIG.SCROLL_BOTTOM)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    
    local scrollbar = CreateFrame("Slider", nil, scroll)
    scrollbar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", CONFIG.SCROLLBAR_RIGHT, CONFIG.SCROLLBAR_TOP)
    scrollbar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", CONFIG.SCROLLBAR_RIGHT, CONFIG.SCROLLBAR_BOTTOM)
    scrollbar:SetWidth(CONFIG.SCROLLBAR_WIDTH)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    
    if useElvUI then
        scrollbar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        scrollbar:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        scrollbar:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    else
        scrollbar:SetBackdrop({
            bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
            edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 3, right = 3, top = 6, bottom = 6 }
        })
    end
    
    scrollbar:SetMinMaxValues(0, 100)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    
    scrollbar:SetScript("OnValueChanged", function(self, value)
        local newOffset = math.floor(value)
        if STATE.scrollOffset ~= newOffset then
            STATE.scrollOffset = newOffset
            SocialUI:UpdateVisibleRows()
            
            collectgarbage("step", 100)
        end
    end)
    
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollbar:GetValue()
        local min, max = scrollbar:GetMinMaxValues()
        local new = math.max(min, math.min(max, current - delta * 3))
        scrollbar:SetValue(new)
    end)
    
    scroll.scrollbar = scrollbar
    scroll.content = content
    parent.scroll = scroll
end

function SocialUI:UpdateVisibleRows()
    if not CACHE.container or not CACHE.container.scroll then return end
    
    local content = CACHE.container.scroll.content
    
    if not CACHE.filteredPlayers then
        CACHE.filteredPlayers = {}
    end
    
    local filtered = CACHE.filteredPlayers
    local totalRows = #filtered
    local maxScroll = math.max(0, totalRows - CONFIG.VISIBLE_ROWS)
    CACHE.container.scroll.scrollbar:SetMinMaxValues(0, maxScroll)
    
    for i = 1, CONFIG.VISIBLE_ROWS do
        local row = CACHE.rows[i]
        local dataIndex = STATE.scrollOffset + i
        
        if dataIndex <= totalRows then
            if not row then
                row = self:CreateRow(content, i)
                CACHE.rows[i] = row
            end
            
            local entry = filtered[dataIndex]
            self:UpdateRow(row, entry, i)
            
            if not row:IsShown() then
                row:Show()
            end
        else
            if row and row:IsShown() then
                row:Hide()
                row.playerName = nil
                row.playerData = nil
            end
        end
    end
    
    content:SetHeight(math.max(totalRows * CONFIG.ROW_HEIGHT, 100))
end

function SocialUI:CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(CONFIG.ROW_WIDTH, CONFIG.ROW_HEIGHT)
    
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if index % 2 == 0 then
        bg:SetTexture(0.1, 0.1, 0.1, 0.3)
    else
        bg:SetTexture(0.05, 0.05, 0.05, 0.3)
    end
    
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", CONFIG.ROW_NAME_LEFT, 0)
    nameText:SetWidth(CONFIG.ROW_NAME_WIDTH)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText
    
    local function CreateActionButton(xOffset, texture, tooltip)
        local btn = CreateFrame("Button", nil, row)
        btn:SetSize(CONFIG.BUTTON_SIZE, CONFIG.BUTTON_SIZE)
        btn:SetPoint("RIGHT", xOffset, 0)
        btn:SetNormalTexture(texture)
        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        
        if useElvUI then
            StyleElvUIButton(btn, true)
        end
        
        btn.tooltip = tooltip
        
        return btn
    end
    
    row.deleteBtn = CreateActionButton(-10, "Interface\\Buttons\\UI-GroupLoot-Pass-Up", L["UI_REMOVE"])
    row.editBtn = CreateActionButton(-35, "Interface\\Buttons\\UI-GuildButton-PublicNote-Up", L["UI_EDIT_NOTE"])
    row.ignoreBtn = CreateActionButton(-60, "Interface\\FriendsFrame\\StatusIcon-Offline", L["UI_IG"])
    row.infoBtn = CreateActionButton(-85, "Interface\\GossipFrame\\AvailableQuestIcon", L["UI_INF"])
    
    row.infoBtn:SetScript("OnClick", function()
        if row.playerData and RL.ShowPlayerCard then
            RL:ShowPlayerCard(row.playerName, row.playerData, true)
        end
    end)
    
    row.editBtn:SetScript("OnClick", function()
        if row.playerName and row.playerData then
            SocialUI:EditPlayer(row.playerName, row.playerData.note)
        end
    end)
    
    row.ignoreBtn:SetScript("OnClick", function(self)
        if row.playerName then
            SocialUI:ToggleIgnore(row.playerName, self)
        end
    end)
    
    row.deleteBtn:SetScript("OnClick", function()
        if row.playerKey and row.playerName then
            SocialUI:DeletePlayer(row.playerKey, row.playerName)
        end
    end)
    
    return row
end

function SocialUI:UpdateRow(row, entry, index)
    local data = entry.data
    local key = entry.key
    
    row:SetPoint("TOPLEFT", 0, -(index - 1) * CONFIG.ROW_HEIGHT)
    
    if row.currentName ~= data.name then
        row.currentName = data.name
        row.nameText:SetText(data.name or "Unknown")
    end
    
    if not row.handlersSet then
        for _, btn in pairs({row.infoBtn, row.editBtn, row.ignoreBtn, row.deleteBtn}) do
            if btn and btn.tooltip then
                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.tooltip, 1, 1, 1)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
        end
        row.handlersSet = true
    end
    
    row.playerName = data.name
    row.playerData = data
    row.playerKey = key
    
    local isIgnored = RL.IsInBlizzardIgnore(data.name)
    local newTexture = isIgnored and "Interface\\FriendsFrame\\StatusIcon-Online" or "Interface\\FriendsFrame\\StatusIcon-Offline"
    if row.ignoreBtn.currentTexture ~= newTexture then
        row.ignoreBtn:SetNormalTexture(newTexture)
        row.ignoreBtn.currentTexture = newTexture
    end
end

function SocialUI:RefreshList()
    if CACHE.settingsPanel and CACHE.settingsPanel:IsShown() then
        return
    end
    
    if not CACHE.filteredPlayers then
        CACHE.filteredPlayers = {}
    end

    for i = #CACHE.filteredPlayers, 1, -1 do
        CACHE.filteredPlayers[i] = nil
    end
    
    local realmData = RL:GetRealmData()
    if not realmData then return end
    
    local list = realmData[STATE.currentTab] or {}
    
    local count = 0
    for key, data in pairs(list) do
        if data and data.name then
            local name = data.name:lower()
            if STATE.searchText == "" or name:find(STATE.searchText, 1, true) then
                count = count + 1
                CACHE.filteredPlayers[count] = {key = key, data = data}
            end
        end
    end
    
    table.sort(CACHE.filteredPlayers, function(a, b)
        return (a.data.name or ""):lower() < (b.data.name or ""):lower()
    end)
    
    self:UpdateVisibleRows()
end


function SocialUI:CreateAddPlayerForm(parent)
    if CACHE.addForm then return CACHE.addForm end
    
    local form = CreateFrame("Frame", nil, parent)
    form:SetPoint("BOTTOMLEFT", CONFIG.FORM_LEFT, CONFIG.FORM_BOTTOM)
    form:SetPoint("BOTTOMRIGHT", CONFIG.FORM_RIGHT, CONFIG.FORM_BOTTOM)
    form:SetHeight(CONFIG.FORM_HEIGHT)
    
    local nameBox = CreateFrame("EditBox", nil, form)
    nameBox:SetSize(CONFIG.NAME_BOX_WIDTH, CONFIG.NAME_BOX_HEIGHT)
    nameBox:SetPoint("LEFT", CONFIG.NAME_BOX_LEFT, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetFontObject(GameFontHighlight)
    
    if useElvUI then
        nameBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        nameBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        nameBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    else
        nameBox:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        nameBox:SetBackdropColor(0, 0, 0, 0.5)
        nameBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
    
    nameBox:SetTextInsets(5, 5, 0, 0)
    nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameBox:SetScript("OnEnterPressed", function()
        local name = nameBox:GetText()
        if name and name ~= "" then
            noteBox:SetFocus()
        end
    end)
    
    local namePlaceholder = nameBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    namePlaceholder:SetPoint("LEFT", 5, 0)
    namePlaceholder:SetText(L["UI_PLAYER_NAME"])
    nameBox:HookScript("OnEditFocusGained", function() namePlaceholder:Hide() end)
    nameBox:HookScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then namePlaceholder:Show() end
    end)
    
    local noteBox = CreateFrame("EditBox", nil, form)
    noteBox:SetSize(CONFIG.NOTE_BOX_WIDTH, CONFIG.NOTE_BOX_HEIGHT)
    noteBox:SetPoint("LEFT", nameBox, "RIGHT", CONFIG.NOTE_BOX_SPACING, 0)
    noteBox:SetAutoFocus(false)
    noteBox:SetFontObject(GameFontHighlight)
    
    if useElvUI then
        noteBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        noteBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        noteBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    else
        noteBox:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        noteBox:SetBackdropColor(0, 0, 0, 0.5)
        noteBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
    
    noteBox:SetTextInsets(5, 5, 0, 0)
    noteBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    noteBox:SetScript("OnEnterPressed", function()
        addBtn:Click()
    end)
    
    local notePlaceholder = noteBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    notePlaceholder:SetPoint("LEFT", 5, 0)
    notePlaceholder:SetText(L["UI_NOTE"])
    noteBox:HookScript("OnEditFocusGained", function() notePlaceholder:Hide() end)
    noteBox:HookScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then notePlaceholder:Show() end
    end)
    

local addBtn
if useElvUI then
    addBtn = CreateFrame("Button", nil, form)
    addBtn:SetSize(CONFIG.ADD_BTN_WIDTH, CONFIG.ADD_BTN_HEIGHT)
    addBtn:SetPoint("LEFT", noteBox, "RIGHT", CONFIG.ADD_BTN_SPACING, 0)
    addBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    addBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    addBtn:SetBackdropBorderColor(0, 0, 0, 1)
    addBtn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 1)
    end)
    addBtn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end)
    local btnText = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetText(L["UI_ADD"])
    addBtn.text = btnText
else
    addBtn = CreateFrame("Button", nil, form, "UIPanelButtonTemplate")
    addBtn:SetSize(CONFIG.ADD_BTN_WIDTH, CONFIG.ADD_BTN_HEIGHT)
    addBtn:SetPoint("LEFT", noteBox, "RIGHT", CONFIG.ADD_BTN_SPACING, 0)
    addBtn:SetText(L["UI_ADD"])
    
    local fs = addBtn:GetFontString()
    if fs then
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", addBtn, "CENTER", 0, 1)
    end
end
addBtn:SetScript("OnClick", function()
    local name = nameBox:GetText()
    local note = noteBox:GetText()
    if name and name ~= "" then
        if note == "" then note = L["UI_F_N"] end
        if RL.AddPlayerDirect then
            RL:AddPlayerDirect(name, STATE.currentTab, note)
            nameBox:SetText("")
            noteBox:SetText("")
            SocialUI:RefreshList()
        end
    else
        print("|cFFFF0000ReputationList:|r" .. L["UI_NM_INPT"])
    end
end)
    
    form.nameBox = nameBox
    form.noteBox = noteBox
    form.addBtn = addBtn
    
    CACHE.addForm = form
    return form
end


function SocialUI:DeletePlayer(key, playerName)
    StaticPopupDialogs["REPLIST_SOCIAL_DELETE"] = {
        text = L["UI_CB42"] .. playerName .. L["UI_CB41"],
        button1 = L["YES"],
        button2 = L["NO"],
        OnAccept = function()
            local realmData = RL:GetRealmData()
            local list = realmData[STATE.currentTab]
            if list and list[key] then
                list[key] = nil
                RL:SaveSettings()
                if RL.InvalidateCache then RL:InvalidateCache() end
                SocialUI:RefreshList()
                print("|cFF00FF00ReputationList:|r " .. L["UI_PLR"] .. playerName .. L["UI_DLPL"])
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("REPLIST_SOCIAL_DELETE")
end

function SocialUI:EditPlayer(playerName, currentNote)
    StaticPopupDialogs["REPLIST_SOCIAL_EDIT"] = {
        text = L["UI_CB43"] .. playerName,
        button1 = L["UI_CB44"],
        button2 = L["CANCEL"],
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self)
            self.editBox:SetText(currentNote or "")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local newNote = self.editBox:GetText()
            local key = string.lower(playerName)
            local realmData = RL:GetRealmData()
            local list = realmData[STATE.currentTab]
            if list and list[key] then
                list[key].note = newNote
                RL:SaveSettings()
                if RL.InvalidateCache then RL:InvalidateCache() end
                SocialUI:RefreshList()
                print("|cFF00FF00ReputationList:|r " .. L["UI_NT_UP"])
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("REPLIST_SOCIAL_EDIT")
end

function SocialUI:ToggleIgnore(playerName, button)
    local ignored, ignoredName = RL.IsInBlizzardIgnore(playerName)
    
    if ignored then
        for i = 1, GetNumIgnores() do
            local name = GetIgnoreName(i)
            if name and RL.NormalizeName(name):lower() == playerName:lower() then
                DelIgnore(name)
                print("|cFF00FF00ReputationList:|r " .. playerName .. L["UI_RM_IG"])
                break
            end
        end
    else
        AddIgnore(playerName)
        print("|cFF00FF00ReputationList:|r " .. playerName .. L["UI_BLACK"])
    end
    
    local updateFrame = CreateFrame("Frame")
    updateFrame.elapsed = 0
    updateFrame.button = button
    updateFrame.playerName = playerName
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 0.1 then
            self:SetScript("OnUpdate", nil)
            local newIgnored = RL.IsInBlizzardIgnore(self.playerName)
            self.button:SetNormalTexture(newIgnored and "Interface\\FriendsFrame\\StatusIcon-Online" or "Interface\\FriendsFrame\\StatusIcon-Offline")
        end
    end)
end

function SocialUI:ShowReputationList()
    if not CACHE.container then
        self:CreateContainer()
    end
    
    for _, frameName in ipairs(FRIENDSFRAME_SUBFRAMES) do
        local frame = _G[frameName]
        if frame and frameName ~= "ReputationListSocialContainer" then
            frame:Hide()
        end
    end
    
    CACHE.container:Show()
    
    FriendsFrameTitleText:SetText("Reputation List")
    
    if CACHE.settingsPanel then
        CACHE.settingsPanel:Hide()
    end
    
    if CACHE.container.scroll then CACHE.container.scroll:Show() end
    if CACHE.addForm then CACHE.addForm:Show() end
    if CACHE.container.tabs then
        for _, tab in pairs(CACHE.container.tabs) do
            tab:Show()
        end
    end
    if CACHE.container.searchBox then CACHE.container.searchBox:Show() end
    
    self:RefreshList()
end

local function UpdateRaidMarks()
    if not GetNumRaidMembers or GetNumRaidMembers() == 0 then return end
    
    for i = 1, MAX_RAID_MEMBERS do
        local button = _G["RaidGroupButton"..i]
        if button and button:IsShown() then
            local nameText = button.name
            
            if nameText then
                local cleanName = nameText:gsub("%[BL%]%s*", ""):gsub("%[WL%]%s*", ""):gsub("%[NL%]%s*", "")
                
                local nameFS = nil
                for _, region in pairs({button:GetRegions()}) do
                    if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                        local text = region:GetText()
                        if text and text:find(cleanName) then
                            nameFS = region
                            break
                        end
                    end
                end
                
                if nameFS then
                    nameFS:SetText(cleanName)
                    
                    if button.repMarkup then
                        if button.repMarkup.Hide then
                            button.repMarkup:Hide()
                        end
                        button.repMarkup = nil
                    end
                    
                    local listType = CheckPlayerInLists(cleanName)
                    if listType then
                        local markup, color = GetListMarkup(listType)
                        if color then
                            RL.UICommon.CreateRaidPlayerMarkup(button, cleanName, listType, color)
                        end
                    end
                end
            end
        end
    end
end

local function UpdateGuildMarks()
    if not GuildListScrollFrame then return end
    
    local offset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
    local totalMembers = GetNumGuildMembers and GetNumGuildMembers() or 0
    
    local isElvUI = (ElvUI and E and S) and true or false
    
    for i = 1, GUILDMEMBERS_TO_DISPLAY do
        local button = _G["GuildFrameButton"..i]
        local memberIndex = offset + i
        
        if button then
            if button.repMarkup then
                if button.repMarkup.Hide then
                    button.repMarkup:Hide()
                end
                button.repMarkup = nil
            end
            if button.repMarkupBtn then
                button.repMarkupBtn:Hide()
            end
            if button.repHighlight then
                button.repHighlight:Hide()
            end
        end
        
        if memberIndex <= totalMembers and button and button:IsShown() then
            local nameFS = nil
            for _, region in pairs({button:GetRegions()}) do
                if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                    local text = region:GetText()
                    if text and text ~= "" and not text:find("^%d+$") then
                        nameFS = region
                        break
                    end
                end
            end
            
            if nameFS then
                local nameText = nameFS:GetText()
                if nameText then
                    local cleanName = nameText:gsub("%[BL%]%s*", ""):gsub("%[WL%]%s*", ""):gsub("%[NL%]%s*", "")
                    nameFS:SetText(cleanName)
                    
                    local listType = CheckPlayerInLists(cleanName)
                    if listType then
                        local markup, color = GetListMarkup(listType)
                        if markup and color then
                            RL.UICommon.CreateGuildPlayerMarkup(button, nameFS, cleanName, listType, markup, color, L, CACHE, STATE, SocialUI, isElvUI)
                        end
                    end
                end
            end
        end
    end
end

local function HookRaidRoster()
    local raidFrame = CreateFrame("Frame")
    raidFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    raidFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    raidFrame:SetScript("OnEvent", function()
        local updateFrame = CreateFrame("Frame")
        updateFrame.elapsed = 0
        updateFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 0.1 then
                self:SetScript("OnUpdate", nil)
                UpdateRaidMarks()
            end
        end)
    end)
	hooksecurefunc("RaidGroupFrame_Update", function()
		UpdateRaidMarks()
	end)
end

local function HookGuildRoster()
    local guildFrame = CreateFrame("Frame")
    guildFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    guildFrame:SetScript("OnEvent", function()
        if FriendsFrame:IsShown() and PanelTemplates_GetSelectedTab(FriendsFrame) == 3 then
            UpdateGuildMarks()
        end
    end)
    
    hooksecurefunc("GuildStatus_Update", function()
        UpdateGuildMarks()
    end)
    
    hooksecurefunc("FauxScrollFrame_Update", function(frame)
        if frame == GuildListScrollFrame then
            UpdateGuildMarks()
        end
    end)
end

function SocialUI:Initialize()
    if not FriendsFrame then
        print(L["UI_CB53"])
        return
    end
    
    self:CreateReputationTab()
    
    HookRaidRoster()
    HookGuildRoster()
    
    hooksecurefunc("FriendsFrame_OnShow", function()
        if CACHE.tab and FriendsFrame:IsShown() then
            CACHE.tab:Show()
            
            if PanelTemplates_GetSelectedTab(FriendsTabHeader) == 4 then
                if CACHE.container and CACHE.container:IsShown() then
                    SocialUI:RefreshList()
                    
                    if CACHE.tab.UpdateTextures then
                        CACHE.tab.UpdateTextures(true)
                    end
                end
            else

                if CACHE.tab.UpdateTextures then
                    CACHE.tab.UpdateTextures(false)
                end
            end
        end
    end)
    
    hooksecurefunc("PanelTemplates_Tab_OnClick", function(self, frame)
        if frame == FriendsTabHeader and CACHE.tab then
            local isSelected = PanelTemplates_GetSelectedTab(FriendsTabHeader) == 4
            if CACHE.tab.UpdateTextures then
                CACHE.tab.UpdateTextures(isSelected)
            end
            
            if not isSelected then
                for i = 1, #CACHE.rows do
                    if CACHE.rows[i] then
                        CACHE.rows[i]:Hide()
                        CACHE.rows[i]:SetParent(nil)
                        CACHE.rows[i] = nil
                    end
                end
                CACHE.rows = {}
                STATE.scrollOffset = 0
                collectgarbage("collect")
            end
        end
        
        local selectedTab = PanelTemplates_GetSelectedTab(FriendsFrame)
        if selectedTab == 3 then

            local f = CreateFrame("Frame"); f.elapsed = 0; f:SetScript("OnUpdate", function(self, e) self.elapsed = self.elapsed + e; if self.elapsed >= 0.1 then self:SetScript("OnUpdate", nil); UpdateGuildMarks() end end)
        elseif selectedTab == 2 then

            local f = CreateFrame("Frame"); f.elapsed = 0; f:SetScript("OnUpdate", function(self, e) self.elapsed = self.elapsed + e; if self.elapsed >= 0.1 then self:SetScript("OnUpdate", nil); UpdateRaidMarks() end end)
        end
    end)
    
    hooksecurefunc("FriendsFrame_OnHide", function()

        for i = 1, #CACHE.rows do
            if CACHE.rows[i] then
                CACHE.rows[i]:Hide()
                CACHE.rows[i]:SetParent(nil)
                CACHE.rows[i] = nil
            end
        end
        CACHE.rows = {}
        
        STATE.scrollOffset = 0
        
        collectgarbage("collect")
    end)
    
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self.elapsed = 0
    self:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed >= 1 then
            frame:SetScript("OnUpdate", nil)
            if RL and RL.SocialUI then
                RL.SocialUI:Initialize()
            end
        end
    end)
end)