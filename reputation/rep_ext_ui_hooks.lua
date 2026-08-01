ReputationList = ReputationList or {}
local RL = ReputationList
local L = RL.L or ReputationListLocale or {}

if not RL.GetRealmData then
    return
end

RL.sortByTagMode = RL.sortByTagMode or false

local function GetNameplateCFG()
    ReputationListDB = ReputationListDB or {}
    ReputationListDB.nameplateIcons = ReputationListDB.nameplateIcons or { enabled = true, useCustomIcons = false }
    return ReputationListDB.nameplateIcons
end

local function GetToastCFG()
    ReputationListDB = ReputationListDB or {}
    ReputationListDB.onlineToast = ReputationListDB.onlineToast or {
        enabled = false, interval = 8, watchBlacklist = true, watchWhitelist = true, watchNotelist = false, sound = true,
    }
    return ReputationListDB.onlineToast
end

local function GetWordFilterCFG()
    ReputationListDB = ReputationListDB or {}
    ReputationListDB.wordFilter = ReputationListDB.wordFilter or {
        enabled = true, caseSensitive = false, filterMode = "hide", phrases = {}, channels = {},
    }
    return ReputationListDB.wordFilter
end

local modulesFrame

local function AddCheckbox(parent, x, y, label, getChecked, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 3, 0)
    text:SetText(label)
    cb:SetScript("OnShow", function(self)
        self:SetChecked(getChecked() and true or false)
    end)
    cb:SetChecked(getChecked() and true or false)
    cb:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
    end)
    return cb, text
end

local function CreateModulesPanel()
    local f = CreateFrame("Frame", "RepListModulesFrame", UIParent)
    f:SetSize(420, 470)
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
    title:SetText(L["MOD_TITLE"])

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local npHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    npHeader:SetPoint("TOPLEFT", 20, -45)
    npHeader:SetText(L["MOD_NAMEPLATES"])

    AddCheckbox(f, 20, -68, L["SET_ENABLED"],
        function() return GetNameplateCFG().enabled end,
        function(checked) if RL.Nameplates then RL.Nameplates:Toggle(checked) end end)

    local npCustomBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    npCustomBtn:SetSize(160, 22)
    npCustomBtn:SetPoint("TOPLEFT", 150, -68)
    local function UpdateNpBtnText()
        npCustomBtn:SetText(GetNameplateCFG().useCustomIcons and L["MOD_ICONS_CUSTOM"] or L["MOD_ICONS_STANDARD"])
    end
    npCustomBtn:SetScript("OnShow", UpdateNpBtnText)
    UpdateNpBtnText()
    npCustomBtn:SetScript("OnClick", function()
        local cfg = GetNameplateCFG()
        cfg.useCustomIcons = not cfg.useCustomIcons
        UpdateNpBtnText()
    end)

    local tagHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tagHeader:SetPoint("TOPLEFT", 20, -105)
    tagHeader:SetText(L["V2_TAGS"])

    local tagHint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tagHint:SetPoint("TOPLEFT", 20, -128)
    tagHint:SetText(L["MOD_TAG_HINT"])
    tagHint:SetTextColor(0.75, 0.75, 0.75)

    local wfHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wfHeader:SetPoint("TOPLEFT", 20, -160)
    wfHeader:SetText(L["MOD_WORD_FILTER"])

    AddCheckbox(f, 20, -183, L["SET_ENABLED"],
        function() return GetWordFilterCFG().enabled end,
        function(checked) GetWordFilterCFG().enabled = checked end)

    local wfManageBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    wfManageBtn:SetSize(160, 22)
    wfManageBtn:SetPoint("TOPLEFT", 150, -183)
    wfManageBtn:SetText(L["MOD_PHRASES"])
    wfManageBtn:SetScript("OnClick", function()
        if RL.WordFilter then RL.WordFilter:ShowManager() end
    end)

    local otHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    otHeader:SetPoint("TOPLEFT", 20, -220)
    otHeader:SetText(L["MOD_ONLINE"])

    AddCheckbox(f, 20, -243, L["SET_ENABLED"],
        function() return GetToastCFG().enabled end,
        function(checked) GetToastCFG().enabled = checked end)

    AddCheckbox(f, 20, -271, "Blacklist",
        function() return GetToastCFG().watchBlacklist end,
        function(checked) GetToastCFG().watchBlacklist = checked end)

    AddCheckbox(f, 150, -271, "Whitelist",
        function() return GetToastCFG().watchWhitelist end,
        function(checked) GetToastCFG().watchWhitelist = checked end)

    AddCheckbox(f, 280, -271, L["SET_SOUND"],
        function() return GetToastCFG().sound end,
        function(checked) GetToastCFG().sound = checked end)

    local otHint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    otHint:SetPoint("TOPLEFT", 20, -300)
    otHint:SetPoint("RIGHT", -20, 0)
    otHint:SetJustifyH("LEFT")
    otHint:SetText(L["SET_ONLINE_HINT"])
    otHint:SetTextColor(0.75, 0.75, 0.75)

    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(170, 22)
    exportBtn:SetPoint("TOPLEFT", 20, -330)
    exportBtn:SetText(L["MOD_EXPORT"])
    exportBtn:SetScript("OnClick", function()
        if RL.Transfer then RL.Transfer:ShowUI() end
    end)

    local syncBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    syncBtn:SetSize(170, 22)
    syncBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
    syncBtn:SetText(L["MOD_SYNC"])
    syncBtn:SetScript("OnClick", function()
        if RL.Sync then
            RL.Sync:ShowUI()
        else
            print("|cFFFF0000[ReputationList]|r Модуль синхронизации не загружен (RL.Sync отсутствует) - проверьте, что файл rep_ext_sync.lua есть в папке аддона и перечислен в reputation.toc.")
        end
    end)

    local debugHint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    debugHint:SetPoint("BOTTOMLEFT", 20, 15)
    debugHint:SetPoint("RIGHT", -20, 0)
    debugHint:SetJustifyH("LEFT")
    debugHint:SetText(L["MOD_DEBUG"])
    debugHint:SetTextColor(0.55, 0.55, 0.55)

    modulesFrame = f
    return f
end

local function ShowModulesPanel()
    if not modulesFrame then
        CreateModulesPanel()
    end
    modulesFrame:Show()
end

local tagPopup

local function ApplySearchText(text)
    if RL.UI2 and RL.UI2.frame and RL.UI2.frame.searchBox then
        RL.UI2.frame.searchBox:SetText(text)
    end
end

local function RefreshTagPopup()
    if not tagPopup then return end
    local scrollChild = tagPopup.scrollChild

    tagPopup.rows = tagPopup.rows or {}
    for i = 1, #tagPopup.rows do tagPopup.rows[i]:Hide() end

    local names, counts = {}, {}
    if RL.Tags then
        names, counts = RL.Tags:GetSortedTagNames()
    end

    if #names == 0 then
        local fs = tagPopup.emptyText
        if not fs then
            fs = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            tagPopup.emptyText = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", 0, 0)
        fs:SetText(L["MOD_NO_TAGS"])
        fs:SetTextColor(0.7, 0.7, 0.7)
        fs:Show()
        scrollChild:SetHeight(20)
        return
    end
    if tagPopup.emptyText then tagPopup.emptyText:Hide() end

    local yOffset = 0
    for i, tagName in ipairs(names) do
        local btn = tagPopup.rows[i]
        if not btn then
            btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
            btn:SetSize(220, 22)
            btn:SetScript("OnClick", function(self)
                ApplySearchText("#" .. self.tagName)
                tagPopup:Hide()
            end)
            tagPopup.rows[i] = btn
        end
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", 0, -yOffset)
        btn.tagName = tagName
        btn:SetText(tagName .. " (" .. (counts[tagName] or 0) .. ")")
        btn:Show()
        yOffset = yOffset + 26
    end
    scrollChild:SetHeight(math.max(yOffset, 1))
end

local function CreateTagPopup()
    local f = CreateFrame("Frame", "RepListTagPopup", UIParent)
    f:SetSize(260, 320)
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

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -12)
    title:SetText(L["MOD_TAG_TITLE"])

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -3, -3)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local allBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    allBtn:SetSize(220, 22)
    allBtn:SetPoint("TOP", 0, -35)
    allBtn:SetText(L["MOD_SHOW_ALL"])
    allBtn:SetScript("OnClick", function()
        ApplySearchText("")
        f:Hide()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "RepListTagPopupScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -65)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(220, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    tagPopup = f
    return f
end

local function ShowTagPopup()
    if not tagPopup then
        CreateTagPopup()
    end
    tagPopup:Show()
    RefreshTagPopup()
end

local function AddExtraButtons(parent)
    if not parent or parent.rlExtraButtonsAdded then return end
    if not parent.searchBox then return end
    parent.rlExtraButtonsAdded = true

    local tagBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    tagBtn:SetSize(60, 22)
    tagBtn:SetPoint("RIGHT", parent.searchBox, "LEFT", -5, 0)
    tagBtn:SetText(L["V2_TAGS"])
    tagBtn:SetScript("OnClick", function()
        ShowTagPopup()
    end)

    local sortBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    sortBtn:SetSize(90, 22)
    sortBtn:SetPoint("RIGHT", tagBtn, "LEFT", -5, 0)
    local function UpdateSortBtnText()
        sortBtn:SetText(RL.sortByTagMode and L["MOD_SORT_TAG"] or L["MOD_SORT_NAME"])
    end
    UpdateSortBtnText()
    sortBtn:SetScript("OnClick", function()
        RL.sortByTagMode = not RL.sortByTagMode
        UpdateSortBtnText()
        if RL.UI2 and RL.UI2.Refresh then
            pcall(function() RL.UI2:Refresh() end)
        end
    end)

    local modulesBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    modulesBtn:SetSize(80, 22)
    modulesBtn:SetPoint("RIGHT", sortBtn, "LEFT", -5, 0)
    modulesBtn:SetText(L["MOD_MODULES"])
    modulesBtn:SetScript("OnClick", function()
        ShowModulesPanel()
    end)
end

RL.ShowModulesPanel = ShowModulesPanel
RL.ShowTagPopup = ShowTagPopup
RL.ApplySearchText = ApplySearchText

SLASH_RLMEMREAL1 = "/rlmemreal"
SlashCmdList["RLMEMREAL"] = function()
    collectgarbage("collect")
    UpdateAddOnMemoryUsage()
    local kb = GetAddOnMemoryUsage("reputation")
    print(string.format("|cFF00FF00[ReputationList]|r Реальная память аддона (после полной сборки мусора): %.1f КБ (%.2f МБ)", kb, kb / 1024))
    print("|cFF888888Совет: в самом ядре аддона уже есть более полная команда /rlstatus (тоже форсирует сборку мусора) - можно использовать любую из двух.|r")
end

SLASH_RLMODULES1 = "/rlmodules"
SlashCmdList["RLMODULES"] = function()
    ShowModulesPanel()
end

SLASH_RLTAGSMENU1 = "/rltagsmenu"
SlashCmdList["RLTAGSMENU"] = function()
    ShowTagPopup()
end
