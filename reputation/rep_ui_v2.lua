-- ============================================================================
-- Reputation List - New Classic UI (v2)
-- ============================================================================

local RL = ReputationList
if not RL then return end

local L = RL.L or ReputationListLocale or {}

local UI2 = {}
RL.UI2 = UI2

local PAL = {
    bg1        = {0.067, 0.067, 0.067, 1},   -- #111111 основной фон
    bg2        = {0.106, 0.106, 0.106, 1},   -- #1B1B1B вторичный
    bg3        = {0.149, 0.149, 0.149, 1},   -- #262626 третичный
    bronze     = {0.482, 0.353, 0.169, 1},   -- #7B5A2B
    gold       = {0.827, 0.651, 0.227, 1},   -- #D3A63A
    hover      = {0.702, 0.290, 0.133, 1},   -- #B34A22
    selected   = {0.455, 0.149, 0.118, 1},   -- #74261E
    red        = {0.710, 0.086, 0.086, 1},   -- #B51616
    green      = {0.235, 0.616, 0.224, 1},   -- #3C9D39
    text       = {0.941, 0.847, 0.627, 1},   -- #F0D8A0
    textDim    = {0.682, 0.635, 0.549, 1},   -- #AEA28C
}

local FONT_BODY = "Fonts\\FRIZQT__.TTF"
local FONT_HEADER = "Fonts\\MORPHEUS.TTF"

local C = {
    FRAME_W = 830, FRAME_H = 460,
    SIDEBAR_W = 118,
    HEADER_H = 40,
    TABBAR_H = 24,
    FILTERBAR_H = 24,
    TABLE_HEADER_H = 20,
    BOTTOM_H = 40,
    ROW_H = 22,
    VISIBLE_ROWS = 12,
}

local COL = {
    accent      = PAL.gold,
    rowBase1    = {0.086, 0.086, 0.086, 1},  
    rowBase2    = {0.110, 0.110, 0.110, 1}, 
    rowHover    = PAL.gold,
    rowSelected = PAL.selected,
}

local TAG_COLORS = {
    ["Скам"]              = {0.42, 0.08, 0.08, 1},
    ["Токсик"]            = {0.45, 0.20, 0.65, 1},
    ["Ниндзя-лут"]        = {0.80, 0.45, 0.10, 1},
    ["Спам"]              = {0.20, 0.45, 0.75, 1},
    ["Хороший трейдер"]   = PAL.green,
    ["Гриф"]              = PAL.selected,
    ["Без тегов"]         = {0.35, 0.35, 0.35, 1},
}

local ADDON_FOLDER = "reputation"
local function Icon(name)
    return "Interface\\AddOns\\" .. ADDON_FOLDER .. "\\textures\\" .. name
end

local function Tex(parent, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    return t
end

local function ColorFill(parent, color, layer)
    local t = Tex(parent, layer)
    t:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    return t
end

local function SetShownCompat(widget, shown)
    if shown then widget:Show() else widget:Hide() end
end

local function IsElvUI()
    return _G.ElvUI ~= nil
end
RL.IsElvUI = IsElvUI

local function FixScale(frame)
    if not IsElvUI() then return end
    local uiScale = UIParent:GetScale()
    if uiScale and uiScale > 0 then
        frame:SetScale(1 / uiScale)
    end
end
RL.FixElvUIScale = FixScale

local BUTTON_FILL = {
    default = { PAL.bg3[1], PAL.bg3[2], PAL.bg3[3], 0.9 },
    primary = { PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9 },
    danger  = { PAL.red[1], PAL.red[2], PAL.red[3], 0.85 },
}
local BUTTON_BORDER = {
    default = { PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9 },
    primary = { PAL.gold[1], PAL.gold[2], PAL.gold[3], 1 },
    danger  = { PAL.gold[1] * 0.9, PAL.gold[2] * 0.6, PAL.gold[3] * 0.5, 1 },
}

local function CreateFlatButton(parent, w, h, text, variant)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)

    local fillCol = BUTTON_FILL[variant] or BUTTON_FILL.default
    local fill = b:CreateTexture(nil, "BACKGROUND")
    fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    fill:SetVertexColor(fillCol[1], fillCol[2], fillCol[3], fillCol[4])
    fill:SetAllPoints()
    b.fill = fill

    local borderCol = BUTTON_BORDER[variant] or BUTTON_BORDER.default
    b:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 })
    b.borderCol = borderCol
    b:SetBackdropBorderColor(borderCol[1], borderCol[2], borderCol[3], borderCol[4] * 0.6)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    fs:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3])
    b.fs = fs
    b.SetText = function(self, t) fs:SetText(t) end
    b.GetFontString = function(self) return fs end
    b.SetNormalFontObject = function() end

    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(self.borderCol[1], self.borderCol[2], self.borderCol[3], self.borderCol[4] * 0.6)
    end)

    return b
end

local function CreateClassicButton(parent, w, h, text, variant)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetText(text)
    b:SetNormalFontObject(GameFontHighlight)
    b:GetFontString():SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3])

    local fillCol = BUTTON_FILL[variant] or BUTTON_FILL.default
    local fill = b:CreateTexture(nil, "BACKGROUND")
    fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    fill:SetVertexColor(fillCol[1], fillCol[2], fillCol[3], fillCol[4])
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    b.fill = fill

    local borderCol = BUTTON_BORDER[variant] or BUTTON_BORDER.default
    b:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
    })
    b.borderCol = borderCol
    b:SetBackdropBorderColor(borderCol[1], borderCol[2], borderCol[3], borderCol[4] * 0.6)

    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(self.borderCol[1], self.borderCol[2], self.borderCol[3], self.borderCol[4] * 0.6)
    end)

    return b
end

local function CreateButton(parent, w, h, text, variant)
    if IsElvUI() then
        return CreateFlatButton(parent, w, h, text, variant)
    end
    return CreateClassicButton(parent, w, h, text, variant)
end

local function CreatePanelBackdrop(f)
    if IsElvUI() then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        f:SetBackdropColor(PAL.bg2[1], PAL.bg2[2], PAL.bg2[3], 0.96)
        f:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
        return
    end

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 18,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetBackdropColor(1, 1, 1, 0.96)
    f:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 1)

    if not f.goldHairline then
        local hl = CreateFrame("Frame", nil, f)
        hl:SetPoint("TOPLEFT", 7, -7)
        hl:SetPoint("BOTTOMRIGHT", -7, 7)
        hl:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        hl:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0.55)
        f.goldHairline = hl
    end
end

local function CreateInnerPanelBackdrop(f, borderAlpha)
    if IsElvUI() then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        f:SetBackdropColor(0, 0, 0, 0.7)
        f:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], borderAlpha or 0.9)
        return
    end
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 32, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(1, 1, 1, 0.55)
    f:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], borderAlpha or 0.7)
end

local function StyleEditBox(editBox)
    local name = editBox:GetName()
    if name then
        for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
            local tex = _G[name .. suffix]
            if tex then tex:SetAlpha(0) end
        end
    end
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    editBox:SetBackdropColor(0, 0, 0, 0.75)
    editBox:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
    editBox:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3])
    editBox:HookScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 1) end)
    editBox:HookScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9) end)
end

RL.UI2Style = {
    PAL = PAL,
    FONT_BODY = FONT_BODY,
    FONT_HEADER = FONT_HEADER,
    Icon = Icon,
    Tex = Tex,
    ColorFill = ColorFill,
    CreateButton = CreateButton,
    CreatePanelBackdrop = CreatePanelBackdrop,
    CreateInnerPanelBackdrop = CreateInnerPanelBackdrop,
    StyleEditBox = StyleEditBox,
    SetShownCompat = SetShownCompat,
}

local OUR_STATIC_POPUPS = {
    REPUTATION_DELETE_CONFIRM = true,
    REPUTATION_EDIT_NOTE      = true,
    REPLIST_V2_ADD_TAG        = true,
    REPLIST_V2_SEND_ENTRY     = true,
}

local function StylePopupChrome(self)
    if not self.which or not OUR_STATIC_POPUPS[self.which] then return end
    self:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
    if self.editBox then StyleEditBox(self.editBox) end
    for _, btnName in ipairs({ "button1", "button2" }) do
        local btn = self[btnName]
        if btn then
            local fs = btn:GetFontString()
            if fs then fs:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3]) end
            if not btn.rlStyled then
                btn.rlStyled = true
                local nt = btn:GetNormalTexture()
                if nt then nt:SetVertexColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3]) end
                btn:HookScript("OnEnter", function(b)
                    local t = b:GetNormalTexture(); if t then t:SetVertexColor(PAL.gold[1], PAL.gold[2], PAL.gold[3]) end
                end)
                btn:HookScript("OnLeave", function(b)
                    local t = b:GetNormalTexture(); if t then t:SetVertexColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3]) end
                end)
            end
        end
    end
end

for i = 1, 4 do
    local popup = _G["StaticPopup" .. i]
    if popup then popup:HookScript("OnShow", StylePopupChrome) end
end

local OUR_DROPDOWNS = {}

local function StyleDropDown(dd)
    local name = dd:GetName()
    if not name then return end
    for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
        local tex = _G[name .. suffix]
        if tex then tex:SetAlpha(0) end
    end
    local btn = _G[name .. "Button"]
    if btn and btn:GetNormalTexture() then
        btn:GetNormalTexture():SetVertexColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])
    end
    local text = _G[name .. "Text"]
    if text then text:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3]) end

    OUR_DROPDOWNS[dd] = true
end

local function StyleOpenDropDownList()
    local menu = UIDROPDOWNMENU_OPEN_MENU
    if not menu or not OUR_DROPDOWNS[menu] then return end
    local level = UIDROPDOWNMENU_MENU_LEVEL or 1
    local listFrame = _G["DropDownList" .. level]
    if not listFrame then return end
    local target = _G["DropDownList" .. level .. "Backdrop"] or listFrame
    if target.SetBackdrop then
        target:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        target:SetBackdropColor(0, 0, 0, 0.9)
    end
    target:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
end

for i = 1, 2 do
    local list = _G["DropDownList" .. i]
    if list then list:HookScript("OnShow", StyleOpenDropDownList) end
end

local function StyleScrollBar(scrollFrame)
    local name = scrollFrame:GetName()
    if not name then return end
    local bar = _G[name .. "ScrollBar"]
    if not bar then return end
    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    if thumb then thumb:SetVertexColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3]) end
    local up = _G[name .. "ScrollBarScrollUpButton"]
    local down = _G[name .. "ScrollBarScrollDownButton"]
    for _, btn in ipairs({ up, down }) do
        if btn then
            local nt = btn:GetNormalTexture()
            if nt then nt:SetVertexColor(PAL.gold[1], PAL.gold[2], PAL.gold[3]) end
        end
    end
end

local function StubTooltip(widget, text)
    widget:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(text or L["V2_DEV"], 1, 0.82, 0)
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local copyPopup
local function ShowCopyableText(title, text)
    if not copyPopup then
        local f = CreateFrame("Frame", "ReputationListV2CopyPopup", UIParent)
        f:SetSize(420, 200)
        f:SetPoint("CENTER")
        FixScale(f)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetToplevel(true)
        CreatePanelBackdrop(f)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        local titleFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFS:SetPoint("TOP", 0, -12)
        f.titleFS = titleFS

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local scroll = CreateFrame("ScrollFrame", "ReputationListV2CopyPopupScroll", f, "UIPanelScrollFrameTemplate")
    StyleScrollBar(scroll)
        scroll:SetPoint("TOPLEFT", 14, -60)
        scroll:SetPoint("BOTTOMRIGHT", -30, 14)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(GameFontHighlightSmall)
        edit:SetWidth(360)
        edit:SetAutoFocus(true)
        scroll:SetScrollChild(edit)
        f.edit = edit

        local copyBtn = CreateButton(f, 110, 22, L["V2_SELECT"], "primary")
        copyBtn:SetPoint("BOTTOM", 0, 10)
        copyBtn:SetScript("OnClick", function()
            edit:SetFocus()
            edit:HighlightText()
        end)
        f.copyBtn = copyBtn
        StubTooltip(copyBtn, L["V2_COPY_HINT"])
        scroll:SetPoint("BOTTOMRIGHT", -30, 40)

        copyPopup = f
    end
    copyPopup.titleFS:SetText(title or L["V2_COPY"])
    copyPopup.edit:SetText(text or "")
    copyPopup.edit:HighlightText()
    copyPopup:Show()
    copyPopup:SetToplevel(true)
    copyPopup:Raise()
end

local STATE = {
    currentTab = "list",
    quickFilter = "all",
    tagFilter = nil,
    ignoreFilter = nil,
    search = "",
    classFilter = nil,
    raceFilter = nil,
    sortKey = "date",
    sortAsc = false,
    selected = nil,
}

local CACHE = { frame = nil, card = nil }

local uiDataRevision = 0
local FILTER_CACHE
local previousInvalidateCache = RL.InvalidateCache
RL.InvalidateCache = function(...)
    uiDataRevision = uiDataRevision + 1
    if FILTER_CACHE then
        for _, slot in pairs(FILTER_CACHE) do
            for i = #slot.items, 1, -1 do slot.items[i] = nil end
            slot.revision = -1
        end
    end
    if previousInvalidateCache then return previousInvalidateCache(...) end
end

local ENTRY_POOL = { blacklist = {}, whitelist = {}, notelist = {} }
local ENTRIES_OUT = {}
local entryGeneration = 0
local entriesRevision = -1

local function PushList(listType, list)
    local pool = ENTRY_POOL[listType]
    for key, data in pairs(list or {}) do
        local e = pool[key]
        if not e then
            e = {}
            pool[key] = e
        end
        e.key, e.listType, e.name = key, listType, data.name or key
        e.class, e.race, e.guild = data.class, data.race, data.guild
        e.note, e.addedDate, e.data = data.note, data.addedDate, data
        e._generation = entryGeneration
        ENTRIES_OUT[#ENTRIES_OUT + 1] = e
    end
end

local function CollectEntries()
    local realmData = RL:GetRealmData()
    entryGeneration = entryGeneration + 1
    for i = #ENTRIES_OUT, 1, -1 do ENTRIES_OUT[i] = nil end
    PushList("blacklist", realmData.blacklist)
    PushList("whitelist", realmData.whitelist)
    PushList("notelist", realmData.notelist)
    for _, pool in pairs(ENTRY_POOL) do
        for key, entry in pairs(pool) do
            if entry._generation ~= entryGeneration then pool[key] = nil end
        end
    end
    return ENTRIES_OUT
end

local function GetEntries()
    if entriesRevision ~= uiDataRevision then
        CollectEntries()
        entriesRevision = uiDataRevision
    end
    return ENTRIES_OUT
end

local COUNTS_CACHE = { all = 0, blacklist = 0, whitelist = 0, notelist = 0, tagged = 0 }
local countsRevision = -1

local function CountByList(entries)
    if countsRevision == uiDataRevision then return COUNTS_CACHE end
    COUNTS_CACHE.all, COUNTS_CACHE.blacklist, COUNTS_CACHE.whitelist = #entries, 0, 0
    COUNTS_CACHE.notelist, COUNTS_CACHE.tagged = 0, 0
    for _, e in ipairs(entries) do
        COUNTS_CACHE[e.listType] = (COUNTS_CACHE[e.listType] or 0) + 1
        if RL.Tags and RL.Tags:GetFirstTag(e.note) ~= "" then
            COUNTS_CACHE.tagged = COUNTS_CACHE.tagged + 1
        end
    end
    countsRevision = uiDataRevision
    return COUNTS_CACHE
end

local function IsIgnored(name)
    if not name then return false end
    local nameLower = string.lower(name)
    for i = 1, (GetNumIgnores() or 0) do
        local ignoreName = GetIgnoreName(i)
        if ignoreName then
            if RL.NormalizeName and RL.NormalizeName(ignoreName) == RL.NormalizeName(name) then
                return true
            elseif ignoreName == name then
                return true
            elseif string.lower(ignoreName) == nameLower then

                return true
            end
        end
    end
    return false
end

local afterTasks, afterTaskPool = {}, {}
local afterDriver = CreateFrame("Frame")
afterDriver:Hide()
afterDriver:SetScript("OnUpdate", function(self, elapsed)
    local i = #afterTasks
    while i >= 1 do
        local task = afterTasks[i]
        task.remaining = task.remaining - elapsed
        if task.remaining <= 0 then
            local fn = task.fn
            afterTasks[i] = afterTasks[#afterTasks]
            afterTasks[#afterTasks] = nil
            task.fn = nil
            afterTaskPool[#afterTaskPool + 1] = task
            fn()
        end
        i = i - 1
    end
    if #afterTasks == 0 then self:Hide() end
end)

local function After(delay, fn)
    local task = afterTaskPool[#afterTaskPool]
    if task then
        afterTaskPool[#afterTaskPool] = nil
    else
        task = {}
    end
    task.remaining, task.fn = delay, fn
    afterTasks[#afterTasks + 1] = task
    afterDriver:Show()
end

local function RefreshAfterIgnore() UI2:Refresh() end

local function ToggleIgnore(name)
    if not name then return end
    if IsIgnored(name) then
        DelIgnore(name)
    else
        AddIgnore(name)
    end
    UI2:Refresh()
    After(0.2, RefreshAfterIgnore)
    After(0.8, RefreshAfterIgnore)
end

local ignoreEventFrame = CreateFrame("Frame")
ignoreEventFrame:RegisterEvent("IGNORELIST_UPDATE")
ignoreEventFrame:SetScript("OnEvent", function()
    if CACHE.frame and CACHE.frame:IsShown() then
        UI2:Refresh()
    end
end)

local activeSearchLower = ""
local function PassesFilter(e)
    if STATE.quickFilter == "blacklist" or STATE.quickFilter == "whitelist" or STATE.quickFilter == "notelist" then
        if e.listType ~= STATE.quickFilter then return false end
    elseif STATE.quickFilter == "tagged" then
        if not (RL.Tags and RL.Tags:GetFirstTag(e.note) ~= "") then return false end
    elseif STATE.quickFilter == "proposed" or STATE.quickFilter == "recent" then
        return false
    end
    if STATE.tagFilter and STATE.tagFilter ~= "" then
        if not (RL.Tags and RL.Tags:HasTag(e.note, STATE.tagFilter)) then return false end
    end
    if STATE.search and STATE.search ~= "" then
        local q = activeSearchLower
        local nameMatch = string.find(string.lower(e.name), q, 1, true)
        local tagMatch = false
        if not nameMatch and RL.Tags then
            for tag in (e.note or ""):gmatch("#([^%s#]+)") do
                if string.find(string.lower(tag), q, 1, true) then
                    tagMatch = true
                    break
                end
            end
        end
        if not (nameMatch or tagMatch) then return false end
    end
    if STATE.classFilter and e.class ~= STATE.classFilter then return false end
    if STATE.raceFilter and e.race ~= STATE.raceFilter then return false end
    if STATE.ignoreFilter == "ignored" and not IsIgnored(e.name) then return false end
    return true
end

local FILTERED_OUT = {}
FILTER_CACHE = {}

local function SortComparator(a, b)
    if STATE.sortKey == "name" then
        if STATE.sortAsc then return a.name < b.name else return a.name > b.name end
    else
        if STATE.sortAsc then return (a.addedDate or "") < (b.addedDate or "") else return (a.addedDate or "") > (b.addedDate or "") end
    end
end

local function GetFilteredSorted()
    local cacheId = STATE.quickFilter or "all"
    local slot = FILTER_CACHE[cacheId]
    if not slot then
        slot = { items = {} }
        FILTER_CACHE[cacheId] = slot
    end
    if slot.revision == uiDataRevision
        and slot.tagFilter == STATE.tagFilter and slot.ignoreFilter == STATE.ignoreFilter
        and slot.search == STATE.search and slot.classFilter == STATE.classFilter
        and slot.raceFilter == STATE.raceFilter and slot.sortKey == STATE.sortKey
        and slot.sortAsc == STATE.sortAsc then
        FILTERED_OUT = slot.items
        local entries = GetEntries()
        return FILTERED_OUT, CountByList(entries)
    end

    local entries = GetEntries()
    FILTERED_OUT = slot.items
    for i = #FILTERED_OUT, 1, -1 do FILTERED_OUT[i] = nil end
    activeSearchLower = (STATE.search and STATE.search ~= "") and string.lower(STATE.search) or ""
    for _, e in ipairs(entries) do
        if PassesFilter(e) then FILTERED_OUT[#FILTERED_OUT + 1] = e end
    end
    table.sort(FILTERED_OUT, SortComparator)
    slot.revision, slot.tagFilter, slot.ignoreFilter = uiDataRevision, STATE.tagFilter, STATE.ignoreFilter
    slot.search, slot.classFilter, slot.raceFilter = STATE.search, STATE.classFilter, STATE.raceFilter
    slot.sortKey, slot.sortAsc = STATE.sortKey, STATE.sortAsc
    return FILTERED_OUT, CountByList(entries)
end

local function FindEntry(name, listType)
    local realmData = RL:GetRealmData()
    local list = realmData[listType]
    if not list then return nil end
    local key = string.lower(name)
    return list[key]
end

local function CreateHeader(f)

    local logoHolder = CreateFrame("Frame", nil, f)
    logoHolder:SetAllPoints(f)
    if f.goldHairline then
        logoHolder:SetFrameLevel(f.goldHairline:GetFrameLevel() + 1)
    end

    local logo = logoHolder:CreateTexture(nil, "ARTWORK")
    logo:SetSize(68, 68)
    logo:SetPoint("TOPLEFT", -10, 25)
    logo:SetTexture(Icon("logo_skull.tga"))

    local title = f:CreateFontString(nil, "ARTWORK")
    title:SetPoint("LEFT", logo, "RIGHT", 14, -15)
    title:SetFont(FONT_HEADER, 18, "")
    title:SetText("ReputationList")
    title:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])
    title:SetShadowColor(0, 0, 0, 0.9)
    title:SetShadowOffset(1, -1)

    local checkNotifyBtn = CreateButton(f, 165, 20, L["V2_CHECK_NOTIFY"])
    checkNotifyBtn:SetPoint("TOPRIGHT", -30, -12)
    checkNotifyBtn:SetScript("OnClick", function()
        if RL.ManualNotify then RL:ManualNotify() end
    end)
    StubTooltip(checkNotifyBtn, L["V2_CHECK_NOTIFY_HINT"])

    local kickBtn = CreateButton(f, 84, 20, L["V2_KICK"], "danger")
    kickBtn:SetPoint("RIGHT", checkNotifyBtn, "LEFT", -6, 0)
    kickBtn:SetScript("OnClick", function()
        if UnitExists("target") and UnitIsPlayer("target") then
            local targetName = UnitName("target")
            if targetName then
                targetName = RL.NormalizeName(targetName)
                StaticPopup_Show("REPUTATION_KICK_PROMPT", targetName, nil, { name = targetName })
            end
        else
            print("|cFFFF0000ReputationList:|r " .. L["V2_NO_TARGET"])
        end
    end)
    StubTooltip(kickBtn, L["V2_KICK_HINT"])

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() f:Hide() end)
end

local TABS = {
    { id = "list",       label = L["V2_TAB_LIST"] },
    { id = "whitelist",  label = "Whitelist" },
    { id = "blacklist",  label = "Blacklist" },
    { id = "notelist",   label = "Notelist" },
    { id = "whohere",    label = L["V2_TAB_WHO"] },
    { id = "history",    label = L["V2_TAB_HISTORY"] },
    { id = "sync",       label = L["V2_TAB_SYNC"] },
    { id = "chatfilter", label = L["V2_TAB_CHAT_FILTER"] },
    { id = "settings",   label = L["V2_TAB_SETTINGS"] },
}

local TAB_WIDTH = 66

local function UpdateTabsVisual(f)
    for id, b in pairs(f.tabButtons) do
        if id == STATE.currentTab then
            b.fs:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])
            b.underline:Show()
            b.activeBg:Show()
            b:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 1)
            b:SetPoint("TOPLEFT", b.origX, -(C.HEADER_H))
        else
            b.fs:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])
            b.underline:Hide()
            b.activeBg:Hide()
            b:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.8)
            b:SetPoint("TOPLEFT", b.origX, -(C.HEADER_H + 2))
        end
    end
end

local function CreateTabs(f)
    f.tabButtons = {}
    local x = 10

    local tabBarBg = ColorFill(f, {0, 0, 0, 0.25}, "BACKGROUND")
    tabBarBg:SetPoint("TOPLEFT", 8, -(C.HEADER_H))
    tabBarBg:SetPoint("TOPRIGHT", -8, -(C.HEADER_H))
    tabBarBg:SetHeight(C.TABBAR_H + 4)

    for _, t in ipairs(TABS) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(TAB_WIDTH, C.TABBAR_H - 2)
        b:SetPoint("TOPLEFT", x, -(C.HEADER_H + 2))
        b.origX = x
        x = x + TAB_WIDTH + 2

        b:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 })
        b:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.8)

        local baseBg = ColorFill(b, {PAL.bg3[1], PAL.bg3[2], PAL.bg3[3], 0.7}, "BACKGROUND")
        baseBg:SetAllPoints()

        local activeBg = ColorFill(b, { PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.55 }, "BACKGROUND")
        activeBg:SetAllPoints()
        activeBg:Hide()
        b.activeBg = activeBg

        b:SetScript("OnEnter", function(self) if STATE.currentTab ~= t.id then self:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0.7) end end)
        b:SetScript("OnLeave", function(self) if STATE.currentTab ~= t.id then self:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.8) end end)

        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("CENTER")
        fs:SetWidth(TAB_WIDTH - 4)
        fs:SetJustifyH("CENTER")
        fs:SetText(t.label)
        local font, size, flags = fs:GetFont()
        if font and size and size > 10 then fs:SetFont(font, 10, flags) end
        b.fs = fs

        local underline = ColorFill(b, COL.accent, "ARTWORK")
        underline:SetPoint("BOTTOMLEFT", 0, 0)
        underline:SetPoint("BOTTOMRIGHT", 0, 0)
        underline:SetHeight(2)
        underline:Hide()
        b.underline = underline

        b:SetScript("OnClick", function()
            STATE.currentTab = t.id
            if t.id == "whitelist" or t.id == "blacklist" or t.id == "notelist" then
                STATE.quickFilter = t.id
                STATE.tagFilter = nil
            elseif t.id == "list" then
                STATE.quickFilter = "all"
                STATE.tagFilter = nil
            end
            UI2:Refresh()
        end)

        f.tabButtons[t.id] = b
    end
end

local QUICK_FILTERS = {
    { id = "all",       label = L["V2_ALL"],                 real = true },
    { id = "blacklist", label = "Blacklist",            real = true, icon = "skull_icon.tga" },
    { id = "whitelist", label = "Whitelist",            real = true, icon = "hands_icon.tga" },
    { id = "notelist",  label = "Notelist",             real = true, icon = "notelist_icon.tga" },
    { id = "proposed",  label = L["V2_PROPOSED"],           real = true },
    { id = "tagged",    label = L["V2_TAGGED"],              real = true },
}

local function CreateSidebar(f)
    local side = CreateFrame("Frame", nil, f)
    side:SetPoint("TOPLEFT", 8, -(C.HEADER_H + C.TABBAR_H + 8))
    side:SetSize(C.SIDEBAR_W, C.FRAME_H - C.HEADER_H - C.TABBAR_H - 8 - C.BOTTOM_H - 8)
    f.sidebar = side

    local sideBg = ColorFill(f, { 0, 0, 0, 0.18 }, "BACKGROUND")
    sideBg:SetPoint("TOPLEFT", side, -4, 4)
    sideBg:SetPoint("BOTTOMRIGHT", side, 4, -4)

    local sep = ColorFill(f, COL.accent, "ARTWORK")
    sep:SetPoint("TOPLEFT", side, "TOPRIGHT", 8, 0)
    sep:SetPoint("BOTTOMLEFT", side, "BOTTOMRIGHT", 8, 0)
    sep:SetWidth(1)

    local allHdr = side:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    allHdr:SetPoint("TOPLEFT", 4, 0)
    allHdr:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3])
    f.allHeaderText = allHdr

    local filterHdr = side:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterHdr:SetPoint("TOPLEFT", allHdr, "BOTTOMLEFT", 0, -8)
    filterHdr:SetText(L["V2_FILTERS"])
    filterHdr:SetTextColor(0.7, 0.65, 0.6)

    side.filterButtons = {}
    local y = -46
    for _, qf in ipairs(QUICK_FILTERS) do
        local b = CreateFrame("Button", nil, side)
        b:SetSize(C.SIDEBAR_W - 8, 20)
        b:SetPoint("TOPLEFT", 2, y)
        y = y - 21

        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetVertexColor(PAL.hover[1], PAL.hover[2], PAL.hover[3], 0.30)
        hl:SetAllPoints()

        b:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 6 })
        b:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0)

        local activeBg = ColorFill(b, COL.rowSelected, "BACKGROUND")
        activeBg:SetAllPoints()
        activeBg:Hide()
        b.activeBg = activeBg

        local divider = ColorFill(b, {PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.35}, "BORDER")
        divider:SetPoint("BOTTOMLEFT", 0, 0)
        divider:SetPoint("BOTTOMRIGHT", 0, 0)
        divider:SetHeight(1)

        local qfIcon
        if qf.icon then
            qfIcon = b:CreateTexture(nil, "OVERLAY")
            qfIcon:SetSize(14, 14)
            qfIcon:SetPoint("LEFT", 4, 0)
            qfIcon:SetTexture(Icon(qf.icon))
        end

        local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", qfIcon and 22 or 4, 0)
        label:SetText(qf.label)

        local count = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        count:SetPoint("RIGHT", -4, 0)

        b.label, b.count, b.qf = label, count, qf

        if not qf.real then
            label:SetTextColor(0.45, 0.42, 0.4)
            StubTooltip(b, L["V2_DEV"])
        else
            b:SetScript("OnClick", function()
                STATE.tagFilter = nil
                STATE.quickFilter = qf.id
                if qf.id == "proposed" then
                    STATE.currentTab = "proposed"
                elseif qf.id == "blacklist" or qf.id == "whitelist" or qf.id == "notelist" then
                    STATE.currentTab = qf.id
                else
                    STATE.currentTab = "list"
                end
                UI2:Refresh()
            end)
        end
        side.filterButtons[qf.id] = b
    end

    local tagHdr = side:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tagHdr:SetPoint("TOPLEFT", 4, y - 8)
    tagHdr:SetText(L["V2_TAGS"])
    tagHdr:SetTextColor(0.7, 0.65, 0.6)
    y = y - 24

    side.tagButtons = {}
    local MAX_TAG_ROWS = 8
    for i = 1, MAX_TAG_ROWS do
        local b = CreateFrame("Button", nil, side)
        b:SetSize(C.SIDEBAR_W - 8, 17)
        b:SetPoint("TOPLEFT", 2, y)
        y = y - 18

        local dot = ColorFill(b, {0.5, 0.5, 0.5}, "ARTWORK")
        dot:SetSize(8, 8)
        dot:SetPoint("LEFT", 2, 0)

        local label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", dot, "RIGHT", 6, 0)
        label:SetJustifyH("LEFT")
        label:SetWidth(C.SIDEBAR_W - 44)

        local count = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        count:SetPoint("RIGHT", -4, 0)

        b.dot, b.label, b.count = dot, label, count
        b:Hide()
        b:SetScript("OnClick", function(self)
            local tagName = self.tagName
            if not tagName then return end
            if STATE.tagFilter == tagName then
                STATE.tagFilter = nil
            else
                STATE.tagFilter = tagName
                STATE.currentTab = "list"
                STATE.quickFilter = "all"
            end
            UI2:Refresh()
        end)
        side.tagButtons[i] = b
    end
    side.tagListBottomY = y

    return side
end

local TAG_FALLBACK_PALETTE = {
    {0.75, 0.15, 0.15}, {0.20, 0.45, 0.75}, {0.15, 0.65, 0.25}, {0.75, 0.55, 0.10},
    {0.45, 0.20, 0.65}, {0.65, 0.30, 0.10}, {0.20, 0.65, 0.65}, {0.65, 0.20, 0.45},
}

local function ColorForTag(tagName)
    if TAG_COLORS[tagName] then return TAG_COLORS[tagName] end
    local hash = 0
    for i = 1, #tagName do hash = hash + tagName:byte(i) end
    return TAG_FALLBACK_PALETTE[(hash % #TAG_FALLBACK_PALETTE) + 1]
end

local SIDEBAR_TAG_NAMES = {}
local SIDEBAR_TAG_COUNTS = {}
local SIDEBAR_TAG_FOLDED = {}
local sidebarTagsRevision = -1

local function SidebarTagComparator(a, b)
    if SIDEBAR_TAG_COUNTS[a] ~= SIDEBAR_TAG_COUNTS[b] then
        return SIDEBAR_TAG_COUNTS[a] > SIDEBAR_TAG_COUNTS[b]
    end
    return SIDEBAR_TAG_FOLDED[a] < SIDEBAR_TAG_FOLDED[b]
end

local function UpdateSidebarTags(side)
    if not RL.Tags then return end

    if sidebarTagsRevision ~= uiDataRevision then
        local sourceCounts = RL.Tags:GetAllTags()
        for tag in pairs(SIDEBAR_TAG_COUNTS) do
            SIDEBAR_TAG_COUNTS[tag], SIDEBAR_TAG_FOLDED[tag] = nil, nil
        end
        for i = #SIDEBAR_TAG_NAMES, 1, -1 do SIDEBAR_TAG_NAMES[i] = nil end
        for tag, count in pairs(sourceCounts) do
            SIDEBAR_TAG_COUNTS[tag] = count
            SIDEBAR_TAG_FOLDED[tag] = RL.FoldCaseRU and RL.FoldCaseRU(tag) or tag:lower()
            SIDEBAR_TAG_NAMES[#SIDEBAR_TAG_NAMES + 1] = tag
        end
        table.sort(SIDEBAR_TAG_NAMES, SidebarTagComparator)
        sidebarTagsRevision = uiDataRevision
    end
    local counts = SIDEBAR_TAG_COUNTS
    local names = SIDEBAR_TAG_NAMES

    for i, b in ipairs(side.tagButtons) do
        local tagName = names[i]
        b.tagName = tagName
        if tagName then
            local color = ColorForTag(tagName)
            b.dot:SetVertexColor(color[1], color[2], color[3], 1)
            b.label:SetText(tagName)
            b.count:SetText(tostring(counts[tagName] or 0))
            if STATE.tagFilter == tagName then
                b.label:SetTextColor(1, 0.82, 0.2)
            else
                b.label:SetTextColor(0.9, 0.85, 0.8)
            end
            b:Show()
        else
            b:Hide()
        end
    end
end

local function UpdateSidebarCounts(side, counts)
    for id, b in pairs(side.filterButtons) do
        local n
        if id == "proposed" then
            n = (RL.Sync and RL.Sync.pendingQueue and #RL.Sync.pendingQueue) or 0
        elseif id == "all" then
            n = counts.all or 0
        else
            n = counts[id] or 0
        end
        b.count:SetText(tostring(n))
        if id == STATE.quickFilter then
            b.label:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])
            b.activeBg:Show()
            b:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 1)
        else
            if b.qf.real then b.label:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3]) end
            b.activeBg:Hide()
            b:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0)
        end
    end
end

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "DEATHKNIGHT" }
local RACES = { "Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Orc", "Undead", "Tauren", "Troll", "BloodElf" }

local IGNORE_FILTER_OPTIONS = { { id = nil, label = L["V2_ALL"] }, { id = "ignored", label = L["V2_IGNORED"] } }

local function CreateFilterBar(f)
    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 16, 0)
    bar:SetPoint("RIGHT", -14, 0)
    bar:SetHeight(C.FILTERBAR_H)
    f.filterBar = bar

    local search = CreateFrame("EditBox", "ReputationListV2ListSearchBox", bar, "InputBoxTemplate")
    search:SetSize(150, 20)
    search:SetPoint("LEFT", 4, -2)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        STATE.search = self:GetText()
        UI2:Refresh()
    end)
    f.searchBox = search
    StyleEditBox(search)

    local ignoreDD = CreateFrame("Frame", "ReputationListV2IgnoreDD", bar, "UIDropDownMenuTemplate")
    ignoreDD:SetPoint("RIGHT", -60, -2)
    UIDropDownMenu_SetWidth(ignoreDD, 90)
    UIDropDownMenu_SetText(ignoreDD, L["V2_ALL"])
    UIDropDownMenu_Initialize(ignoreDD, function(self, level)
        for _, opt in ipairs(IGNORE_FILTER_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = opt.label, (STATE.ignoreFilter == opt.id)
            info.func = function() STATE.ignoreFilter = opt.id; UIDropDownMenu_SetText(ignoreDD, opt.label); UI2:Refresh() end
            UIDropDownMenu_AddButton(info)
        end
    end)
    StyleDropDown(ignoreDD)

    local raceDD = CreateFrame("Frame", "ReputationListV2RaceDD", bar, "UIDropDownMenuTemplate")
    raceDD:SetPoint("RIGHT", ignoreDD, "LEFT", -16, 0)
    UIDropDownMenu_SetWidth(raceDD, 80)
    UIDropDownMenu_SetText(raceDD, L["V2_ALL_RACES"])
    UIDropDownMenu_Initialize(raceDD, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.checked = L["V2_ALL_RACES"], (STATE.raceFilter == nil)
        info.func = function() STATE.raceFilter = nil; UIDropDownMenu_SetText(raceDD, L["V2_ALL_RACES"]); UI2:Refresh() end
        UIDropDownMenu_AddButton(info)
        for _, r in ipairs(RACES) do
            info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = r, (STATE.raceFilter == r)
            info.func = function() STATE.raceFilter = r; UIDropDownMenu_SetText(raceDD, r); UI2:Refresh() end
            UIDropDownMenu_AddButton(info)
        end
    end)
    StyleDropDown(raceDD)

    local classDD = CreateFrame("Frame", "ReputationListV2ClassDD", bar, "UIDropDownMenuTemplate")
    classDD:SetPoint("RIGHT", raceDD, "LEFT", -16, 0)
    UIDropDownMenu_SetWidth(classDD, 80)
    UIDropDownMenu_SetText(classDD, L["V2_ALL_CLASSES"])
    UIDropDownMenu_Initialize(classDD, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.checked = L["V2_ALL_CLASSES"], (STATE.classFilter == nil)
        info.func = function() STATE.classFilter = nil; UIDropDownMenu_SetText(classDD, L["V2_ALL_CLASSES"]); UI2:Refresh() end
        UIDropDownMenu_AddButton(info)
        for _, cls in ipairs(CLASSES) do
            info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = cls, (STATE.classFilter == cls)
            info.func = function() STATE.classFilter = cls; UIDropDownMenu_SetText(classDD, cls); UI2:Refresh() end
            UIDropDownMenu_AddButton(info)
        end
    end)
    StyleDropDown(classDD)

    return bar
end

local COLUMNS = {
    { key = "name",   label = L["V2_COL_NAME"],     width = 91,  sortable = true },
    { key = "class",  label = L["V2_COL_CLASS"],   width = 44,  sortable = false },
    { key = "race",   label = L["V2_COL_RACE"],    width = 80,  sortable = false },
    { key = "guild",  label = L["V2_COL_GUILD"], width = 77,  sortable = false },
    { key = "tags",   label = L["V2_COL_TAGS"],    width = 150, sortable = false },
    { key = "status", label = L["V2_COL_STATUS"], width = 55,  sortable = false },
    { key = "date",   label = L["V2_COL_DATE"],    width = 75,  sortable = true },
    { key = "ignore", label = "",        width = 60,  sortable = false },
}

local function CreateTableHeader(f)
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", f.filterBar, "BOTTOMLEFT", 0, -6)
    header:SetPoint("RIGHT", f.filterBar, "RIGHT", 0, 0)
    header:SetHeight(C.TABLE_HEADER_H)
    ColorFill(header, { PAL.bg3[1], PAL.bg3[2], PAL.bg3[3], 0.9 }, "BACKGROUND"):SetAllPoints()
    local headerLine = ColorFill(header, PAL.bronze, "ARTWORK")
    headerLine:SetPoint("BOTTOMLEFT", 0, 0)
    headerLine:SetPoint("BOTTOMRIGHT", 0, 0)
    headerLine:SetHeight(1)

    local x = 6
    for _, col in ipairs(COLUMNS) do
        local b = CreateFrame("Button", nil, header)
        b:SetSize(col.width, C.TABLE_HEADER_H)
        b:SetPoint("TOPLEFT", x, 0)
        x = x + col.width

        -- Бронзовый разделитель колонок (1px), как в ТЗ.
        local colSep = ColorFill(b, {PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.4}, "ARTWORK")
        colSep:SetPoint("TOPRIGHT", 0, 0)
        colSep:SetPoint("BOTTOMRIGHT", 0, 0)
        colSep:SetWidth(1)

        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", 4, 0)
        fs:SetText(col.label)
        fs:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

        if col.sortable then
            b:SetScript("OnClick", function()
                if STATE.sortKey == col.key then STATE.sortAsc = not STATE.sortAsc
                else STATE.sortKey = col.key; STATE.sortAsc = true end
                UI2:Refresh()
            end)
        end
    end
    return header
end

local STATUS_TEXTURE = {
    blacklist = Icon("skull_icon.tga"),
    whitelist = Icon("hands_icon.tga"),
    notelist  = Icon("notelist_icon.tga"),
}
local STATUS_TINT = {
    blacklist = {1, 1, 1},
    whitelist = {1, 1, 1},
    notelist  = {1, 1, 1},
}

local CARD_ICON_BY_LIST = {
    blacklist = Icon("skull_icon.tga"),
    whitelist = Icon("hands_icon.tga"),
    notelist  = Icon("notelist_icon.tga"),
}

local SEVERITY_SKULL = Icon("skull_icon.tga")

local CONTEXT_MENU = CreateFrame("Frame", "ReputationListV2ContextMenu", UIParent, "UIDropDownMenuTemplate")

local function ShowRowContextMenu(entry)
    local menuList = {
        { text = entry.name, isTitle = true, notCheckable = true },
        { text = L["V2_OPEN_CARD"], notCheckable = true, func = function() UI2:ShowCard(entry) end },
        {
            text = L["V2_EDIT_NOTE"], notCheckable = true,
            func = function()
                RL.UICommon.EditPlayerDialog(entry.name, entry.note,
                    { RefreshList = function() UI2:Refresh() end },
                    { currentTab = entry.listType }, L)
            end,
        },
        {
            text = L["V2_DELETE_LIST"], notCheckable = true,
            func = function()
                RL.UICommon.DeletePlayerDialog(entry.name,
                    { RefreshList = function() UI2:Refresh() end },
                    { currentTab = entry.listType }, L)
            end,
        },
    }
    EasyMenu(menuList, CONTEXT_MENU, "cursor", 0, 0, "MENU")
end

local function CreateRow(parent, anchorFrame, index, width)
    local row = CreateFrame("Button", nil, parent)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetSize(width, C.ROW_H)
    row:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -2 - (index - 1) * C.ROW_H)

    row.bg = ColorFill(row, {0, 0, 0, 0}, "BACKGROUND")
    row.bg:SetAllPoints()

    local baseColor = (index % 2 == 0) and COL.rowBase2 or COL.rowBase1
    row.bg:SetVertexColor(baseColor[1], baseColor[2], baseColor[3], baseColor[4])

    row:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 })
    row:SetBackdropBorderColor(COL.rowHover[1], COL.rowHover[2], COL.rowHover[3], 0)

    row.selectedOverlay = ColorFill(row, {COL.rowSelected[1], COL.rowSelected[2], COL.rowSelected[3], 0}, "BORDER")
    row.selectedOverlay:SetAllPoints()

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", 6, 0)
    row.name:SetWidth(85)
    row.name:SetJustifyH("LEFT")

    row.classIcon = row:CreateTexture(nil, "ARTWORK")
    row.classIcon:SetSize(18, 18)
    row.classIcon:SetPoint("LEFT", 100, 0)
    row.classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")

    row.raceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.raceText:SetPoint("LEFT", 141, 0)
    row.raceText:SetWidth(76)
    row.raceText:SetJustifyH("LEFT")
    row.raceText:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    row.guild = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.guild:SetPoint("LEFT", 221, 0)
    row.guild:SetWidth(73)
    row.guild:SetJustifyH("LEFT")
    row.guild:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    local TAG_CHIP_X = { 298, 356 }
    row.tagChips = {}
    for i = 1, 2 do
        local chip = {}
        chip.bg = ColorFill(row, TAG_COLORS["Без тегов"], "ARTWORK")
        chip.bg:SetPoint("LEFT", TAG_CHIP_X[i], 0)
        chip.bg:SetSize(50, 18)

        chip.shine = row:CreateTexture(nil, "ARTWORK")
        chip.shine:SetTexture("Interface\\Buttons\\WHITE8X8")
        chip.shine:SetVertexColor(1, 1, 1, 0.12)
        chip.shine:SetPoint("TOPLEFT", chip.bg, "TOPLEFT")
        chip.shine:SetPoint("TOPRIGHT", chip.bg, "TOPRIGHT")
        chip.shine:SetHeight(7)

        chip.shade = row:CreateTexture(nil, "ARTWORK")
        chip.shade:SetTexture("Interface\\Buttons\\WHITE8X8")
        chip.shade:SetVertexColor(0, 0, 0, 0.28)
        chip.shade:SetPoint("BOTTOMLEFT", chip.bg, "BOTTOMLEFT")
        chip.shade:SetPoint("BOTTOMRIGHT", chip.bg, "BOTTOMRIGHT")
        chip.shade:SetHeight(6)

        chip.border = CreateFrame("Frame", nil, row)
        chip.border:SetPoint("TOPLEFT", chip.bg, "TOPLEFT", -1, 1)
        chip.border:SetPoint("BOTTOMRIGHT", chip.bg, "BOTTOMRIGHT", 1, -1)
        chip.border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        chip.border:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.8)

        chip.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        chip.text:SetPoint("LEFT", chip.bg, "LEFT", 6, 0)

        row.tagChips[i] = chip
    end

    row.tagMoreText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.tagMoreText:SetPoint("LEFT", row.tagChips[2].bg, "RIGHT", 4, 0)
    row.tagMoreText:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    row.status = row:CreateTexture(nil, "ARTWORK")
    row.status:SetSize(16, 16)
    row.status:SetPoint("LEFT", 448, 0)

    row.date = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.date:SetPoint("LEFT", 503, 0)
    row.date:SetWidth(72)
    row.date:SetJustifyH("LEFT")
    row.date:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    row.ignoreBtn = CreateButton(row, 54, 18, L["V2_IGNORE"])
    row.ignoreBtn:SetPoint("LEFT", 578, 0)
    row.ignoreBtn:SetScript("OnClick", function()
        if row.entry then ToggleIgnore(row.entry.name) end
    end)

    row:SetScript("OnClick", function(self, button)
        local e = self.entry
        if not e then return end
        if button == "RightButton" then ShowRowContextMenu(e); return end
        STATE.selected = e.key
        UI2:Refresh()
        UI2:ShowCard(e)
    end)

    row:SetScript("OnEnter", function(self) if not self.selected then self:SetBackdropBorderColor(COL.rowHover[1], COL.rowHover[2], COL.rowHover[3], 1) end end)
    row:SetScript("OnLeave", function(self) if not self.selected then self:SetBackdropBorderColor(COL.rowHover[1], COL.rowHover[2], COL.rowHover[3], 0) end end)

    return row
end

local function FillRow(row, entry)
    row.entry = entry
    local classColors = RAID_CLASS_COLORS or {}
    local cc = entry.class and classColors[entry.class]
    row.name:SetTextColor(cc and cc.r or 0.9, cc and cc.g or 0.85, cc and cc.b or 0.8)
    row.name:SetText(entry.name)
    if entry.class and CLASS_ICON_TCOORDS[entry.class] then
        row.classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[entry.class]))
        row.classIcon:Show()
    else
        row.classIcon:Hide()
    end
    row.raceText:SetText(entry.race or "?")
    row.guild:SetText(entry.guild and entry.guild ~= "" and entry.guild or "—")

    local note = entry.note or ""
    if entry._tagsNote ~= note then
        entry._tagsNote = note
        entry._tags = (RL.Tags and RL.Tags:ExtractTags(note)) or {}
    end
    local tags = entry._tags
    for i = 1, 2 do
        local chip = row.tagChips[i]
        local tagName = tags[i]
        if tagName then

            local tagColor = ColorForTag(tagName)
            chip.bg:SetVertexColor(tagColor[1], tagColor[2], tagColor[3], tagColor[4] or 1)
            chip.text:SetText(tagName)
            chip.bg:SetWidth(math.min(50, 20 + (tagName:len() * 6)))
            chip.bg:Show(); chip.shine:Show(); chip.shade:Show(); chip.border:Show(); chip.text:Show()
        else
            chip.bg:Hide(); chip.shine:Hide(); chip.shade:Hide(); chip.border:Hide(); chip.text:Hide()
        end
    end
    if #tags > 2 then
        row.tagMoreText:SetText("+" .. (#tags - 2))
        row.tagMoreText:Show()
    else
        row.tagMoreText:Hide()
    end

    local statusTex = STATUS_TEXTURE[entry.listType]
    if statusTex then
        row.status:SetTexture(statusTex)
        local tint = STATUS_TINT[entry.listType] or {1, 1, 1}
        row.status:SetVertexColor(tint[1], tint[2], tint[3])
    end

    row.date:SetText(entry.addedDate or "?")

    if IsIgnored(entry.name) then
        row.ignoreBtn:SetText(L["V2_UNIGNORE"])
    else
        row.ignoreBtn:SetText(L["V2_IGNORE"])
    end
    row.selected = (STATE.selected == entry.key)
    if row.selected then
        row.selectedOverlay:SetVertexColor(COL.rowSelected[1], COL.rowSelected[2], COL.rowSelected[3], COL.rowSelected[4])
        row:SetBackdropBorderColor(COL.rowHover[1], COL.rowHover[2], COL.rowHover[3], 1)
    else
        row.selectedOverlay:SetVertexColor(COL.rowSelected[1], COL.rowSelected[2], COL.rowSelected[3], 0)
        row:SetBackdropBorderColor(COL.rowHover[1], COL.rowHover[2], COL.rowHover[3], 0)
    end

    row:Show()
end

local function RefreshVisibleRows(f, filtered)
    local offset = FauxScrollFrame_GetOffset(f.scroll)
    local rowError, shownRows = nil, 0
    for i = 1, C.VISIBLE_ROWS do
        local entry = filtered[i + offset]
        local row = f.rows[i]
        if entry then
            local ok, err = pcall(FillRow, row, entry)
            if ok then
                shownRows = shownRows + 1
            else
                rowError = rowError or tostring(err)
                row:Hide()
            end
        else
            row:Hide()
        end
    end
    return rowError, shownRows
end

local function CreateListArea(f)
    local scroll = CreateFrame("ScrollFrame", "ReputationListV2Scroll", f, "FauxScrollFrameTemplate")
    StyleScrollBar(scroll)
    scroll:SetPoint("TOPLEFT", f.tableHeader, "BOTTOMLEFT", 0, -2)

    local tableW = C.FRAME_W - C.SIDEBAR_W - 8 - 16 - 14 - 22
    local tableH = C.VISIBLE_ROWS * C.ROW_H
    scroll:SetSize(tableW, tableH)
    f.scroll = scroll

    f.rows = {}
    for i = 1, C.VISIBLE_ROWS do
        f.rows[i] = CreateRow(f, f.tableHeader, i, tableW)
    end

    local function RefreshScrollRows()
        RefreshVisibleRows(f, FILTERED_OUT)
    end
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, C.ROW_H, RefreshScrollRows)
    end)

    local emptyText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyText:SetPoint("TOP", f.tableHeader, "BOTTOM", 0, -30)
    emptyText:Hide()
    f.emptyText = emptyText

    return scroll
end

local LIST_TYPE_SHORT = { blacklist = "BL", whitelist = "WL", notelist = "NL" }

local function CreateAddForm(bar)
    local selectedListType = "blacklist"

    local nameInput = CreateFrame("EditBox", nil, bar)
    nameInput:SetSize(100, 22)
    nameInput:SetPoint("LEFT", 4, 0)
    nameInput:SetAutoFocus(false)
    nameInput:SetFontObject(GameFontNormalSmall)
    nameInput:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    nameInput:SetBackdropColor(0, 0, 0, 0.75)
    nameInput:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
    nameInput:SetTextInsets(6, 4, 2, 2)

    local namePlaceholder = nameInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    namePlaceholder:SetPoint("LEFT", 5, 0)
    namePlaceholder:SetText(L["V2_NAME"])
    nameInput:HookScript("OnEditFocusGained", function() namePlaceholder:Hide() end)
    nameInput:HookScript("OnEditFocusLost", function(self) if self:GetText() == "" then namePlaceholder:Show() end end)

    local noteInput = CreateFrame("EditBox", nil, bar)
    noteInput:SetSize(150, 22)
    noteInput:SetPoint("LEFT", nameInput, "RIGHT", 6, 0)
    noteInput:SetAutoFocus(false)
    noteInput:SetFontObject(GameFontNormalSmall)
    noteInput:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    noteInput:SetBackdropColor(0, 0, 0, 0.75)
    noteInput:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
    noteInput:SetTextInsets(6, 4, 2, 2)

    local notePlaceholder = noteInput:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    notePlaceholder:SetPoint("LEFT", 5, 0)
    notePlaceholder:SetText(L["V2_NOTE"])
    noteInput:HookScript("OnEditFocusGained", function() notePlaceholder:Hide() end)
    noteInput:HookScript("OnEditFocusLost", function(self) if self:GetText() == "" then notePlaceholder:Show() end end)

    local dropdown = CreateFrame("Frame", "ReputationListV2TypeDropdown", bar, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", noteInput, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(dropdown, 55)
    UIDropDownMenu_SetText(dropdown, "BL")
    StyleDropDown(dropdown)

    local function OnSelect(self)
        selectedListType = self.value
        UIDropDownMenu_SetText(dropdown, LIST_TYPE_SHORT[self.value])
        CloseDropDownMenus()
    end

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, lt in ipairs({ "blacklist", "whitelist", "notelist" }) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = LIST_TYPE_SHORT[lt] .. " (" .. lt .. ")"
            info.value = lt
            info.func = OnSelect
            info.checked = (selectedListType == lt)
            UIDropDownMenu_AddButton(info)
        end
    end)

    local addBtn = CreateButton(bar, 75, 22, "+" .. L["V2_ADD"], "primary")
    addBtn:SetPoint("LEFT", dropdown, "RIGHT", -5, 2)
    addBtn:SetScript("OnClick", function()
        local name = nameInput:GetText()
        local note = noteInput:GetText()
        if name and name ~= "" then
            RL:AddPlayerDirect(name, selectedListType, note ~= "" and note or nil)
            nameInput:SetText(""); noteInput:SetText("")
            nameInput:ClearFocus(); noteInput:ClearFocus()
            namePlaceholder:Show(); notePlaceholder:Show()
            UI2:Refresh()
        else
            print("|cFFFF0000ReputationList:|r " .. L["V2_ENTER_NAME"])
        end
    end)

    return addBtn
end

local function CreateBottomBar(f)
    local bar = CreateFrame("Frame", nil, f)
    bar:SetPoint("BOTTOMLEFT", 10, 8)
    bar:SetPoint("BOTTOMRIGHT", -10, 8)
    bar:SetHeight(C.BOTTOM_H)

    local addBtn = CreateAddForm(bar)

    local importBtn = CreateButton(bar, 80, 22, L["V2_IMPORT"])
    importBtn:SetPoint("LEFT", addBtn, "RIGHT", 6, 0)
    importBtn:SetScript("OnClick", function()
        if not RL.Transfer then
            print("|cFFFF0000ReputationList:|r " .. L["V2_TRANSFER_MISSING"])
            return
        end
        RL.Transfer:ShowUI()
        local tf = _G["RepListTransferFrame"]
        if tf and not tf._v2RefreshHooked then
            tf:HookScript("OnHide", function() UI2:Refresh() end)
            tf._v2RefreshHooked = true
        end
    end)

    local exportBtn = CreateButton(bar, 80, 22, L["V2_EXPORT"])
    exportBtn:SetPoint("LEFT", importBtn, "RIGHT", 6, 0)
    exportBtn:SetScript("OnClick", function()
        if not RL.Transfer then
            print("|cFFFF0000ReputationList:|r " .. L["V2_TRANSFER_MISSING"])
            return
        end
        RL.Transfer:ShowUI()
    end)

    local total = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    total:SetPoint("RIGHT", -4, 0)
    f.totalText = total
end

local function CreatePlaceholderPanel(f, text)
    local p = CreateFrame("Frame", nil, f)
    p:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 16, 0)
    p:SetPoint("BOTTOMRIGHT", -14, C.BOTTOM_H + 6)
    p:Hide()
    local fs = p:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    return p
end

local function CreateContentPage(f)
    local p = CreateFrame("Frame", nil, f)
    p:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 16, 0)
    p:SetPoint("BOTTOMRIGHT", -14, C.BOTTOM_H + 6)
    p:Hide()
    return p
end

local function RemoveChatPhraseChip(self)
    if self.phrase and RL.WordFilter then
        RL.WordFilter:RemovePhrase(self.phrase)
        UI2:RefreshChatFilterPage()
    end
end

local function CreateChatFilterPage(f)
    local p = CreateContentPage(f)
    local X = 6

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", X, -6)
    title:SetText(L["V2_CHAT_TITLE"])
    title:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    local function Divider(anchorTo, yOff)
        local d = ColorFill(p, { PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.4 }, "ARTWORK")
        d:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", -X, yOff)
        d:SetPoint("RIGHT", -6, 0)
        d:SetHeight(1)
        return d
    end

    local enableCb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
    enableCb:SetPoint("TOPLEFT", X, -32)
    local enableText = enableCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    enableText:SetPoint("LEFT", enableCb, "RIGHT", 4, 0)
    enableText:SetText(L["V2_FILTER_ENABLED"])
    enableCb:SetScript("OnClick", function(self)
        if RL.WordFilter then
            ReputationListDB.wordFilter.enabled = self:GetChecked() and true or false
        end
    end)
    p.enableCb = enableCb

    local modeLabel = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeLabel:SetPoint("TOPLEFT", enableCb, "BOTTOMLEFT", 0, -14)
    modeLabel:SetText(L["V2_MATCH_MODE"])

    local modeBtn = CreateButton(p, 110, 22, "")
    modeBtn:SetPoint("LEFT", modeLabel, "RIGHT", 8, 0)
    local function UpdateModeText()
        local mode = ReputationListDB.wordFilter and ReputationListDB.wordFilter.filterMode
        modeBtn:SetText(mode == "showonly" and L["V2_MODE_SHOW"] or L["V2_MODE_HIDE"])
    end
    modeBtn:SetScript("OnClick", function()
        if not RL.WordFilter then return end
        local cfg = ReputationListDB.wordFilter
        cfg.filterMode = (cfg.filterMode == "showonly") and "hide" or "showonly"
        UpdateModeText()
    end)
    p.UpdateModeText = UpdateModeText

    local div1 = Divider(modeLabel, -12)

    local channelLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    channelLabel:SetPoint("TOPLEFT", div1, "BOTTOMLEFT", X, -10)
    channelLabel:SetText(L["V2_FILTER_CHANNELS"])
    channelLabel:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    local CHANNEL_GROUPS = {
        { label = L["V2_CH_SAY"],  keys = { "SAY" } },
        { label = L["V2_CH_YELL"],  keys = { "YELL" } },
        { label = L["V2_CH_CHANNEL"], keys = { "CHANNEL" } },
        { label = L["V2_CH_WHISPER"],        keys = { "WHISPER" } },
        { label = L["V2_CH_PARTY"],       keys = { "PARTY", "PARTY_LEADER" } },
        { label = L["V2_CH_RAID"],         keys = { "RAID", "RAID_LEADER" } },
        { label = L["V2_CH_GUILD"],      keys = { "GUILD" } },
        { label = L["V2_CH_EMOTE"],       keys = { "EMOTE", "TEXT_EMOTE" } },
    }
    p.channelChecks = {}
    local col, row = 0, 0
    local lastChannelCb
    for _, group in ipairs(CHANNEL_GROUPS) do
        local cb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", channelLabel, "TOPLEFT", col * 220, -20 - row * 24)
        local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        fs:SetText(group.label)
        cb:SetScript("OnClick", function(self)
            local checked = self:GetChecked() and true or false
            local wfCfg = ReputationListDB and ReputationListDB.wordFilter
            if not wfCfg then return end
            for _, key in ipairs(group.keys) do
                wfCfg.channels[key] = checked
            end
        end)
        p.channelChecks[#p.channelChecks + 1] = { cb = cb, group = group }
        row = row + 1
        if row >= 4 then row = 0; col = 1 end
        lastChannelCb = cb
    end

    local div2 = Divider(channelLabel, -24 - 4 * 24)

    local addLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addLabel:SetPoint("TOPLEFT", div2, "BOTTOMLEFT", X, -10)
    addLabel:SetText(L["V2_ADD_PHRASE"])
    addLabel:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    local addBox = CreateFrame("EditBox", "ReputationListV2WFAddBox", p, "InputBoxTemplate")
    addBox:SetSize(200, 20)
    addBox:SetPoint("TOPLEFT", addLabel, "BOTTOMLEFT", 0, -6)
    addBox:SetAutoFocus(false)
    StyleEditBox(addBox)
    local addBtn = CreateButton(p, 80, 22, L["V2_ADD"])
    addBtn:SetPoint("LEFT", addBox, "RIGHT", 10, 0)
    local function DoAdd()
        if RL.WordFilter and addBox:GetText() ~= "" then
            RL.WordFilter:AddPhrase(addBox:GetText())
            addBox:SetText("")
            UI2:RefreshChatFilterPage()
        end
    end
    addBox:SetScript("OnEnterPressed", DoAdd)
    addBtn:SetScript("OnClick", DoAdd)

    local listHeader = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listHeader:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -14)
    p.listHeader = listHeader

    local phraseScroll = CreateFrame("ScrollFrame", "ReputationListV2ChatPhraseScroll", p, "UIPanelScrollFrameTemplate")
    phraseScroll:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -8)
    phraseScroll:SetPoint("RIGHT", -30, 0)
    phraseScroll:SetHeight(22)
    StyleScrollBar(phraseScroll)
    phraseScroll:EnableMouseWheel(true)
    phraseScroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        local value = (self:GetVerticalScroll() or 0) - delta * 26
        if value < 0 then value = 0 end
        if value > range then value = range end
        self:SetVerticalScroll(value)
    end)
    local phraseArea = CreateFrame("Frame", nil, phraseScroll)
    phraseArea:SetSize(510, 1)
    phraseScroll:SetScrollChild(phraseArea)
    p.phraseScroll = phraseScroll
    p.phraseArea = phraseArea
    p.rows = {}

    return p
end

function UI2:RefreshChatFilterPage()
    local p = CACHE.chatFilterPage
    if not p then return end
    local cfg = ReputationListDB and ReputationListDB.wordFilter
    if not cfg then return end

    p.enableCb:SetChecked(cfg.enabled)
    p.UpdateModeText()

    for _, entry in ipairs(p.channelChecks or {}) do

        local anyOn = false
        for _, key in ipairs(entry.group.keys) do
            if cfg.channels[key] then anyOn = true; break end
        end
        entry.cb:SetChecked(anyOn)
    end

    local phrases = RL.WordFilter and RL.WordFilter:List() or {}
    p.listHeader:SetText(string.format(L["V2_FILTER_PHRASES"], #phrases))

    for _, row in ipairs(p.rows) do row:Hide() end

    local xOff, yOff = 0, 0
    local areaWidth = 510
    for i, phrase in ipairs(phrases) do
        local chip = p.rows[i]
        if not chip then
            chip = CreateFrame("Button", nil, p.phraseArea)
            chip:SetHeight(22)
            chip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 })
            chip:SetBackdropColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.22)
            chip:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.8)
            local fs = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", 8, 0)
            chip.fs = fs
            local close = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            close:SetPoint("RIGHT", -7, 0)
            close:SetText("|cFFFF7777x|r")
            chip:SetScript("OnClick", RemoveChatPhraseChip)
            p.rows[i] = chip
        end
        chip.fs:SetText(phrase)
        local chipWidth = math.max(65, math.min(190, chip.fs:GetStringWidth() + 34))
        if xOff > 0 and xOff + chipWidth > areaWidth then
            xOff, yOff = 0, yOff + 26
        end
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", xOff, -yOff)
        chip:SetWidth(chipWidth)
        chip.fs:SetWidth(chipWidth - 34)
        chip.phrase = phrase
        chip:Show()
        xOff = xOff + chipWidth + 6
    end
    local contentHeight = (#phrases > 0) and (yOff + 22) or 1
    p.phraseArea:SetHeight(contentHeight)
    local scrollBar = _G["ReputationListV2ChatPhraseScrollScrollBar"]
    if contentHeight > 22 then
        if scrollBar then scrollBar:Show() end
    else
        p.phraseScroll:SetVerticalScroll(0)
        if scrollBar then scrollBar:Hide() end
    end
end


local function CreateSyncPage(f)
    local p = CreateContentPage(f)
    local X = 6

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", X, -6)
    title:SetText(L["V2_SYNC_TITLE"])
    title:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    local function Divider(anchorTo, yOff)
        local d = ColorFill(p, { PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.4 }, "ARTWORK")
        d:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, yOff)
        d:SetPoint("RIGHT", -6, 0)
        d:SetHeight(1)
        return d
    end

    local autoCb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
    autoCb:SetPoint("TOPLEFT", X, -32)
    local autoText = autoCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    autoText:SetPoint("LEFT", autoCb, "RIGHT", 4, 0)
    autoText:SetText(L["V2_SYNC_AUTO"])
    autoCb:SetScript("OnClick", function(self)
        ReputationListDB.sync = ReputationListDB.sync or {}
        ReputationListDB.sync.autoAccept = self:GetChecked() and true or false
    end)
    p.autoCb = autoCb

    local div1 = Divider(autoCb, -14)

    local listLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listLabel:SetPoint("TOPLEFT", div1, "BOTTOMLEFT", X, -10)
    listLabel:SetText(L["V2_SYNC_WHAT"])
    listLabel:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    local blCb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
    blCb:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -8)
    blCb:SetChecked(true)
    local blText = blCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    blText:SetPoint("LEFT", blCb, "RIGHT", 3, 0)
    blText:SetText("Blacklist")

    local wlCb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
    wlCb:SetPoint("LEFT", blCb, "RIGHT", 110, 0)
    wlCb:SetChecked(true)
    local wlText = wlCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    wlText:SetPoint("LEFT", wlCb, "RIGHT", 3, 0)
    wlText:SetText("Whitelist")

    local nlCb = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
    nlCb:SetPoint("LEFT", wlCb, "RIGHT", 110, 0)
    nlCb:SetChecked(true)
    local nlText = nlCb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nlText:SetPoint("LEFT", nlCb, "RIGHT", 3, 0)
    nlText:SetText("Notelist")

    local div2 = Divider(blCb, -14)

    local nameLabel = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", div2, "BOTTOMLEFT", X, -10)
    nameLabel:SetText(L["V2_SYNC_NAME"])
    nameLabel:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    local nameInput = CreateFrame("EditBox", "ReputationListV2SyncNameInput", p, "InputBoxTemplate")
    nameInput:SetSize(180, 20)
    nameInput:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", -2, -8)
    nameInput:SetAutoFocus(false)
    p.nameInput = nameInput
    StyleEditBox(nameInput)

    local sendBtn = CreateButton(p, 100, 22, L["V2_SEND"], "primary")
    sendBtn:SetPoint("LEFT", nameInput, "RIGHT", 10, 0)

    local resultText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resultText:SetPoint("TOPLEFT", nameInput, "BOTTOMLEFT", 2, -12)
    resultText:SetWidth(500)
    resultText:SetJustifyH("LEFT")
    p.resultText = resultText

    local div3 = Divider(resultText, -10)

    local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", div3, "BOTTOMLEFT", X, -10)
    hint:SetWidth(500)
    hint:SetJustifyH("LEFT")
    hint:SetText(L["V2_SYNC_HINT"])

    local function DoSend()
        local target = nameInput:GetText()
        if not target or target == "" then
            resultText:SetText("|cFFFF0000" .. L["V2_SYNC_ENTER"] .. "|r")
            return
        end
        if not RL.Sync then
            resultText:SetText("|cFFFF0000" .. L["V2_SYNC_MISSING"] .. "|r")
            return
        end
        local listTypes = {}
        if blCb:GetChecked() then table.insert(listTypes, "blacklist") end
        if wlCb:GetChecked() then table.insert(listTypes, "whitelist") end
        if nlCb:GetChecked() then table.insert(listTypes, "notelist") end
        if #listTypes == 0 then
            resultText:SetText("|cFFFF0000" .. L["V2_SYNC_SELECT"] .. "|r")
            return
        end
        local ok, err, totalParts = RL.Sync:SendListTo(target, listTypes)
        if ok then
            resultText:SetText("|cFF00FF00" .. string.format(L["V2_SYNC_SENT"], target, totalParts or 1) .. "|r")
        else
            resultText:SetText("|cFFFF0000" .. string.format(L["V2_ERROR"], tostring(err)) .. "|r")
        end
    end

    sendBtn:SetScript("OnClick", DoSend)
    nameInput:SetScript("OnEnterPressed", DoSend)

    return p
end

function UI2:RefreshSyncPage()
    local p = CACHE.syncPage
    if not p then return end
    local cfg = ReputationListDB and ReputationListDB.sync
    if cfg then p.autoCb:SetChecked(cfg.autoAccept) end
end

local PROPOSED_LIST_LABEL = { blacklist = "|cFFFF4444Blacklist|r", whitelist = "|cFF44FF44Whitelist|r", notelist = "|cFFFFAA00Notelist|r" }
local PROPOSED_VISIBLE_ROWS = 11
local PROPOSED_ROW_HEIGHT = 22

local function RefreshProposedVisibleRows(p)
    local offset = FauxScrollFrame_GetOffset(p.scroll)
    for i = 1, PROPOSED_VISIBLE_ROWS do
        local row = p.rows[i]
        local item = p.items[offset + i]
        if item then
            row.itemId = item.id
            row.cb:SetChecked(not p.deselected[item.id])
            local notePreview = (item.entry.note and item.entry.note ~= "") and (" — " .. item.entry.note) or ""
            row.fs:SetText(PROPOSED_LIST_LABEL[item.listType] .. " " .. (item.entry.name or item.key) .. notePreview)
            row:Show()
        else
            row.itemId = nil
            row:Hide()
        end
    end
end

local function CreateProposedPage(f)
    local p = CreateContentPage(f)

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 4, -4)
    title:SetText(L["V2_PROPOSED_TITLE"])
    title:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    local infoText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    infoText:SetPoint("TOPLEFT", 0, -28)
    infoText:SetPoint("RIGHT", -4, 0)
    infoText:SetJustifyH("LEFT")
    p.infoText = infoText

    local scroll = CreateFrame("ScrollFrame", "ReputationListV2ProposedScroll", p, "FauxScrollFrameTemplate")
    StyleScrollBar(scroll)
    scroll:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 40)
    p.scroll = scroll
    p.rows, p.items, p.deselected = {}, {}, {}
    for i = 1, PROPOSED_VISIBLE_ROWS do
        local row = CreateFrame("Frame", nil, p)
        row:SetSize(500, PROPOSED_ROW_HEIGHT)
        row:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -10 - (i - 1) * PROPOSED_ROW_HEIGHT)
        row.owner = p
        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("LEFT", 0, 0)
        cb:SetScript("OnClick", function(self)
            local ownerRow = self:GetParent()
            if ownerRow.itemId then
                ownerRow.owner.deselected[ownerRow.itemId] = self:GetChecked() and nil or true
            end
        end)
        row.cb = cb
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        fs:SetWidth(460)
        fs:SetJustifyH("LEFT")
        row.fs = fs
        row:Hide()
        p.rows[i] = row
    end
    local function RefreshScrollRows() RefreshProposedVisibleRows(p) end
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, PROPOSED_ROW_HEIGHT, RefreshScrollRows)
    end)

    local acceptSelectedBtn = CreateButton(p, 150, 22, L["V2_ACCEPT_SELECTED"], "primary")
    acceptSelectedBtn:SetPoint("BOTTOMLEFT", 0, 0)
    acceptSelectedBtn:SetScript("OnClick", function()
        if not (RL.Sync and RL.Sync.pendingQueue) then return end
        local sync = RL.Sync.pendingQueue[STATE.proposedIndex]
        if not sync then return end
        local selections = {}
        for _, item in ipairs(p.items) do
            if not p.deselected[item.id] then
                selections[#selections + 1] = { listType = item.listType, key = item.key, entry = item.entry }
            end
        end
        local ok, stats = RL.Transfer:ImportSelectedEntries(selections, "newest")
        if ok then
            print("|cFF00FF00ReputationList:|r " .. string.format(L["V2_ACCEPT_STATS"],
                stats.added, stats.overwritten, stats.skipped))
        end
        table.remove(RL.Sync.pendingQueue, STATE.proposedIndex)
        UI2:RefreshProposedPage()
        UI2:Refresh()
    end)

    local acceptAllBtn = CreateButton(p, 100, 22, L["V2_ACCEPT_ALL"], "primary")
    acceptAllBtn:SetPoint("LEFT", acceptSelectedBtn, "RIGHT", 8, 0)
    acceptAllBtn:SetScript("OnClick", function()
        if not (RL.Sync and RL.Sync.pendingQueue) then return end
        local sync = RL.Sync.pendingQueue[STATE.proposedIndex]
        if sync then
            local ok, stats = RL.Transfer:ImportPayload(sync.payload, "newest")
            if ok then
                print("|cFF00FF00ReputationList:|r " .. string.format(L["V2_ACCEPT_FROM"],
                    sync.from, stats.added, stats.overwritten, stats.skipped))
            end
            table.remove(RL.Sync.pendingQueue, STATE.proposedIndex)
        end
        UI2:RefreshProposedPage()
        UI2:Refresh()
    end)

    local rejectBtn = CreateButton(p, 100, 22, L["V2_REJECT"], "danger")
    rejectBtn:SetPoint("LEFT", acceptAllBtn, "RIGHT", 8, 0)
    rejectBtn:SetScript("OnClick", function()
        if not (RL.Sync and RL.Sync.pendingQueue) then return end
        local sync = RL.Sync.pendingQueue[STATE.proposedIndex]
        if sync then
            print("|cFFFFAA00ReputationList:|r " .. string.format(L["V2_REJECTED_FROM"], tostring(sync.from)))
            table.remove(RL.Sync.pendingQueue, STATE.proposedIndex)
        end
        UI2:RefreshProposedPage()
        UI2:Refresh()
        sync = nil
        collectgarbage("collect")
    end)

    local skipBtn = CreateButton(p, 100, 22, L["V2_SKIP"])
    skipBtn:SetPoint("LEFT", rejectBtn, "RIGHT", 8, 0)
    skipBtn:SetScript("OnClick", function()
        if not (RL.Sync and RL.Sync.pendingQueue) then return end
        STATE.proposedIndex = (STATE.proposedIndex or 1) + 1
        if STATE.proposedIndex > #RL.Sync.pendingQueue then STATE.proposedIndex = 1 end
        UI2:RefreshProposedPage()
    end)

    p.acceptSelectedBtn, p.acceptAllBtn, p.rejectBtn, p.skipBtn = acceptSelectedBtn, acceptAllBtn, rejectBtn, skipBtn

    return p
end

function UI2:RefreshProposedPage()
    local p = CACHE.proposedPage
    if not p then return end
    local queue = (RL.Sync and RL.Sync.pendingQueue) or {}

    if #queue == 0 then
        p.infoText:SetText(L["V2_NO_SYNC"])
        p.acceptSelectedBtn:Disable()
        p.acceptAllBtn:Disable()
        p.rejectBtn:Disable()
        p.skipBtn:Disable()
        p.currentSync = nil
        for i = 1, #p.items do p.items[i] = nil end
        for key in pairs(p.deselected) do p.deselected[key] = nil end
        FauxScrollFrame_Update(p.scroll, 0, PROPOSED_VISIBLE_ROWS, PROPOSED_ROW_HEIGHT)
        RefreshProposedVisibleRows(p)
        return
    end

    STATE.proposedIndex = STATE.proposedIndex or 1
    if STATE.proposedIndex > #queue then STATE.proposedIndex = 1 end

    local sync = queue[STATE.proposedIndex]
    p.acceptSelectedBtn:Enable()
    p.acceptAllBtn:Enable()
    p.rejectBtn:Enable()
    p.skipBtn:Enable()

    p.infoText:SetText(string.format(
        L["V2_SYNC_INFO"],
        tostring(sync.from), STATE.proposedIndex, #queue, (sync.counts and sync.counts.total) or 0))

    if p.currentSync ~= sync then
        p.currentSync = sync
        for key in pairs(p.deselected) do p.deselected[key] = nil end
        local i = 0
        for listType, entries in pairs(sync.payload.lists or {}) do
            if PROPOSED_LIST_LABEL[listType] then
                for key, entry in pairs(entries) do
                    i = i + 1
                    local item = p.items[i]
                    if not item then item = {}; p.items[i] = item end
                    item.listType, item.key, item.entry = listType, key, entry
                    item.id = listType .. "\031" .. key
                end
            end
        end
        local usedCount = i
        for j = #p.items, usedCount + 1, -1 do p.items[j] = nil end
    end
    FauxScrollFrame_Update(p.scroll, #p.items, PROPOSED_VISIBLE_ROWS, PROPOSED_ROW_HEIGHT)
    RefreshProposedVisibleRows(p)
end

local WHOHERE_LIST_LABEL = { blacklist = "|cFFFF4444Blacklist|r", whitelist = "|cFF44FF44Whitelist|r", notelist = "|cFFFFAA00Notelist|r" }

local function ShowWhoHereContextMenu(mm)
    local menuList = {
        { text = mm.name, isTitle = true, notCheckable = true },
        { text = L["V2_OPEN_CARD"], notCheckable = true,
          func = function()
              if mm.inList then
                  local fresh = FindEntry(mm.name, mm.listType)
                  if fresh then
                      UI2:ShowCard({
                          key = string.lower(mm.name), listType = mm.listType, name = fresh.name or mm.name,
                          class = fresh.class, race = fresh.race, guild = fresh.guild,
                          note = fresh.note, addedDate = fresh.addedDate, data = fresh,
                      })
                  end
              else
                  UI2:ShowCard({
                      key = string.lower(mm.name), listType = "none", name = mm.name,
                      class = mm.class, race = mm.race, guild = mm.guild,
                      note = "", addedDate = "—",
                      data = { level = mm.level, faction = mm.faction, guid = mm.guid, history = {} },
                  })
              end
          end },
        { text = L["V2_ADD_BLACKLIST"], notCheckable = true,
          func = function() RL:AddPlayerDirect(mm.name, "blacklist"); UI2:RefreshWhoHerePage(); UI2:Refresh() end },
        { text = L["V2_ADD_WHITELIST"], notCheckable = true,
          func = function() RL:AddPlayerDirect(mm.name, "whitelist"); UI2:RefreshWhoHerePage(); UI2:Refresh() end },
        { text = L["V2_ADD_NOTELIST"], notCheckable = true,
          func = function() RL:AddPlayerDirect(mm.name, "notelist"); UI2:RefreshWhoHerePage(); UI2:Refresh() end },
    }
    EasyMenu(menuList, CONTEXT_MENU, "cursor", 0, 0, "MENU")
end

local function CreateWhoHerePage(f)
    local p = CreateContentPage(f)

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 4, -4)
    title:SetText(L["V2_WHO_TITLE"])
    title:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    local refreshBtn = CreateButton(p, 100, 22, L["V2_REFRESH"])
    refreshBtn:SetPoint("TOPRIGHT", -4, -2)
    refreshBtn:SetScript("OnClick", function()
        if RL.GroupTracker then RL.GroupTracker:SaveCurrentGroup() end
        UI2:RefreshWhoHerePage()
    end)

    local infoText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", 0, -28)
    infoText:SetPoint("RIGHT", -110, -28)
    infoText:SetJustifyH("LEFT")
    p.infoText = infoText

    local scroll = CreateFrame("ScrollFrame", "ReputationListV2WhoHereScroll", p, "UIPanelScrollFrameTemplate")
    StyleScrollBar(scroll)
    scroll:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 0)
    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(1, 1)
    scroll:SetScrollChild(scrollChild)
    p.scrollChild = scrollChild
    p.rows = {}

    return p
end

function UI2:RefreshWhoHerePage()
    local p = CACHE.whoHerePage
    if not p then return end

    local members = (RL.GroupTracker and RL.GroupTracker:GetAllGroupMembersWithListInfo()) or {}
    local inGroup = RL.GroupTracker and RL.GroupTracker:IsInGroup()
    p.infoText:SetText(string.format(L["V2_WHO_COUNT"], #members,
        inGroup and "" or L["V2_NOT_IN_GROUP"]))

    for _, row in ipairs(p.rows) do row:Hide() end

    local yOff = 0
    for i, m in ipairs(members) do
        local row = p.rows[i]
        if not row then
            row = CreateFrame("Button", nil, p.scrollChild)
            row:SetSize(560, 22)
            local bg = ColorFill(row, {1, 1, 1, 0.04}, "BACKGROUND")
            bg:SetAllPoints()
            row.bg = bg
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", 4, 0)
            fs:SetWidth(540)
            fs:SetJustifyH("LEFT")
            row.fs = fs
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row:SetScript("OnEnter", function(self) self.bg:SetVertexColor(1, 1, 1, 0.09) end)
            row:SetScript("OnLeave", function(self) self.bg:SetVertexColor(1, 1, 1, 0.04) end)
            row:SetScript("OnClick", function(self, button)
                local mm = self.member
                if not mm then return end
                if button == "RightButton" then
                    ShowWhoHereContextMenu(mm)
                    return
                end
                if mm.inList then
                    local fresh = FindEntry(mm.name, mm.listType)
                    if fresh then
                        UI2:ShowCard({
                            key = string.lower(mm.name), listType = mm.listType, name = fresh.name or mm.name,
                            class = fresh.class, race = fresh.race, guild = fresh.guild,
                            note = fresh.note, addedDate = fresh.addedDate, data = fresh,
                        })
                    end
                else

                    UI2:ShowCard({
                        key = string.lower(mm.name), listType = "none", name = mm.name,
                        class = mm.class, race = mm.race, guild = mm.guild,
                        note = "", addedDate = "—",
                        data = { level = mm.level, faction = mm.faction, guid = mm.guid, history = {} },
                    })
                end
            end)
            StubTooltip(row, L["V2_WHO_HINT"])
            p.rows[i] = row
        end
        row:SetPoint("TOPLEFT", 0, -yOff)

        local classColors = RAID_CLASS_COLORS or {}
        local cc = m.class and classColors[m.class]
        local nameColor = cc and string.format("|cFF%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255) or "|cFFFFFFFF"
        local statusStr = m.inList and (WHOHERE_LIST_LABEL[m.listType] or m.listType) or L["V2_NOT_LISTED"]
        row.fs:SetText(string.format(L["V2_WHO_ROW"],
            nameColor, m.name, m.class or "?", m.race or "?", tostring(m.level or "?"),
            (m.guild and m.guild ~= "" and m.guild) or "—", statusStr))

        row.member = m
        row:Show()
        yOff = yOff + 22
    end
    p.scrollChild:SetHeight(math.max(yOff, 1))
end

local HIST_LIST_LABEL = { blacklist = L["V2_HIST_BLACK"], whitelist = L["V2_HIST_WHITE"], notelist = L["V2_HIST_NOTE"] }

local function ParseDateKey(str)
    if not str then return 0 end
    local d, m, y, H, M = str:match("(%d+)%.(%d+)%.(%d+)%s+(%d+):(%d+)")
    if not d then return 0 end
    return tonumber(y) * 100000000 + tonumber(m) * 1000000 + tonumber(d) * 10000
        + tonumber(H) * 100 + tonumber(M)
end

local HISTORY_FEED_POOL = {}
local HISTORY_FEED_OUT = {}
local HISTORY_SEARCH_OUT = {}
local historyFeedRevision = -1

local function CollectHistoryFeed()
    if historyFeedRevision == uiDataRevision then return HISTORY_FEED_OUT end
    local entries = GetEntries()
    for i = #HISTORY_FEED_OUT, 1, -1 do HISTORY_FEED_OUT[i] = nil end
    local n = 0

    local function pushRec(name, listType, date, by, change, isAdd)
        n = n + 1
        local rec = HISTORY_FEED_POOL[n]
        if not rec then
            rec = {}
            HISTORY_FEED_POOL[n] = rec
        end
        rec.name, rec.listType, rec.date = name, listType, date
        rec.nameLower = string.lower(name or "")
        rec.by, rec.change, rec.isAdd = by, change, isAdd
        HISTORY_FEED_OUT[#HISTORY_FEED_OUT + 1] = rec
    end

    for _, e in ipairs(entries) do
        local d = e.data
        pushRec(e.name, e.listType, d.addedDate or "?", d.addedBy or "?", L["V2_HIST_ADDED"], true)
        for _, h in ipairs(d.history or {}) do
            pushRec(e.name, e.listType, h.date or "?", h.by or "?", h.change or "?", false)
        end
    end
    table.sort(HISTORY_FEED_OUT, function(a, b) return ParseDateKey(a.date) > ParseDateKey(b.date) end)
    historyFeedRevision = uiDataRevision
    return HISTORY_FEED_OUT
end

local HISTORY_VISIBLE_ROWS = 8
local HISTORY_ROW_HEIGHT = 34

local function RefreshHistoryVisibleRows(p)
    local feed = p.currentFeed or HISTORY_FEED_OUT
    local offset = FauxScrollFrame_GetOffset(p.scroll)
    for i = 1, HISTORY_VISIBLE_ROWS do
        local row = p.rows[i]
        local rec = feed[offset + i]
        if rec then
            row.dateFS:SetText(rec.date .. "   •   " .. (HIST_LIST_LABEL[rec.listType] or rec.listType) .. "   •   " .. rec.by)
            local color = rec.isAdd and "|cFF66DD66" or "|cFFFFD200"
            row.mainFS:SetText(color .. rec.name .. "|r — " .. rec.change)
            row:Show()
        else
            row:Hide()
        end
    end
end

local function CreateHistoryPage(f)
    local p = CreateContentPage(f)

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 4, -4)
    title:SetText(L["V2_HISTORY_TITLE"])
    title:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    local search = CreateFrame("EditBox", "ReputationListV2HistorySearch", p, "InputBoxTemplate")
    search:SetSize(220, 20)
    search:SetPoint("TOPLEFT", 4, -28)
    search:SetAutoFocus(false)
    StyleEditBox(search)
    search:SetScript("OnTextChanged", function(self)
        STATE.historySearch = self:GetText()
        UI2:RefreshHistoryPage()
    end)
    p.search = search

    local header = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -10)
    p.header = header

    local scroll = CreateFrame("ScrollFrame", "ReputationListV2HistoryScroll", p, "FauxScrollFrameTemplate")
    StyleScrollBar(scroll)
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", -30, 0)
    p.scroll = scroll
    p.rows = {}

    for i = 1, HISTORY_VISIBLE_ROWS do
        local row = CreateFrame("Frame", nil, p)
        row:SetSize(560, 32)
        row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6 - (i - 1) * HISTORY_ROW_HEIGHT)
        local bg = ColorFill(row, {1, 1, 1, 0.04}, "BACKGROUND")
        bg:SetAllPoints()
        row.bg = bg
        local dateFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        dateFS:SetPoint("TOPLEFT", 4, -2)
        row.dateFS = dateFS
        local mainFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        mainFS:SetPoint("TOPLEFT", 4, -16)
        mainFS:SetWidth(540)
        mainFS:SetJustifyH("LEFT")
        row.mainFS = mainFS
        row:Hide()
        p.rows[i] = row
    end
    local function RefreshScrollRows() RefreshHistoryVisibleRows(p) end
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, HISTORY_ROW_HEIGHT, RefreshScrollRows)
    end)

    return p
end

function UI2:RefreshHistoryPage()
    local p = CACHE.historyPage
    if not p then return end

    local feed = CollectHistoryFeed()
    local q = STATE.historySearch
    if q and q ~= "" then
        local ql = string.lower(q)
        for i = #HISTORY_SEARCH_OUT, 1, -1 do HISTORY_SEARCH_OUT[i] = nil end
        for _, rec in ipairs(feed) do
            if string.find(rec.nameLower, ql, 1, true) then
                HISTORY_SEARCH_OUT[#HISTORY_SEARCH_OUT + 1] = rec
            end
        end
        feed = HISTORY_SEARCH_OUT
    end

    p.header:SetText(string.format(L["V2_EVENTS"], #feed))
    p.currentFeed = feed
    FauxScrollFrame_Update(p.scroll, #feed, HISTORY_VISIBLE_ROWS, HISTORY_ROW_HEIGHT)
    RefreshHistoryVisibleRows(p)
end

local function CreateSettingsPage(f)
    local p = CreateContentPage(f)

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 4, -4)
    title:SetText(L["SETTINGS_TITLE"])
    title:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    local scroll = CreateFrame("ScrollFrame", "ReputationListV2SettingsScroll", p, "UIPanelScrollFrameTemplate")
    StyleScrollBar(scroll)
    scroll:SetPoint("TOPLEFT", 0, -28)
    scroll:SetPoint("BOTTOMRIGHT", -30, 0)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(1, 1)
    scroll:SetScrollChild(body)

    local y = 0
    local checks = {}

    local firstHeader = true
    local function AddHeader(text)
        if not firstHeader then

            y = y - 24
            local d = ColorFill(body, { PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.35 }, "ARTWORK")
            d:SetPoint("TOPLEFT", 0, y)
            d:SetPoint("RIGHT", body, "RIGHT", -8, 0)
            d:SetHeight(1)
            y = y - 14
        end
        firstHeader = false
        y = y - 6
        local fs = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 0, y)
        fs:SetText(text)
        fs:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

        y = y - 2
    end

    local function AddHint(text)
        local fs = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 22, y)
        fs:SetPoint("RIGHT", body, "RIGHT", -8, 0)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        fs:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])
        y = y - 18
    end

    local function AddCheckbox(label, key, getter, setter, sameLineX)
        local cb = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        y = y - 24
        cb:SetPoint("TOPLEFT", 4, y)
        local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        fs:SetText(label)
        cb:SetScript("OnClick", function(self) setter(self:GetChecked() and true or false) end)
        checks[key] = { cb = cb, getter = getter }
        return cb
    end

    AddHeader(L["SET_SECTION_NOTIFICATIONS"])
    AddCheckbox(L["SET_AUTO_NOTIFY"], "autoNotify",
        function() return ReputationListDB.autoNotify end,
        function(v) ReputationListDB.autoNotify = v; RL.autoNotify = v end)
    AddCheckbox(L["SET_SELF_NOTIFY"], "selfNotify",
        function() return ReputationListDB.selfNotify end,
        function(v) ReputationListDB.selfNotify = v; RL.selfNotify = v end, 220)
    AddCheckbox(L["SET_SOUND_POPUPS"], "soundNotify",
        function() return ReputationListDB.soundNotify end,
        function(v)
            ReputationListDB.soundNotify = v; RL.soundNotify = v
            ReputationListDB.popupNotify = v; RL.popupNotify = v
            if checks.popupNotify then checks.popupNotify.cb:SetChecked(v) end
        end)
    AddCheckbox(L["SET_FILTER_MESSAGES"], "filterMessages",
        function() return ReputationListDB.filterMessages end,
        function(v) ReputationListDB.filterMessages = v; RL.filterMessages = v end, 220)

    AddHeader(L["SET_SECTION_PROTECTION"])
    AddCheckbox(L["SET_BLOCK_INVITES"], "blockInvites",
        function() return ReputationListDB.blockInvites end,
        function(v) ReputationListDB.blockInvites = v; RL.blockInvites = v end)
    AddCheckbox(L["SET_BLOCK_TRADE"], "blockTrade",
        function() return ReputationListDB.blockTrade end,
        function(v) ReputationListDB.blockTrade = v; RL.blockTrade = v end, 220)
    AddCheckbox(L["SET_COLOR_CHAT"], "colorLFG",
        function() return ReputationListDB.colorLFG end,
        function(v) ReputationListDB.colorLFG = v; RL.colorLFG = v end)

    AddHeader(L["SET_SECTION_NAMEPLATES"])
    AddCheckbox(L["SET_ENABLED"], "npEnabled",
        function() return ReputationListDB.nameplateIcons and ReputationListDB.nameplateIcons.enabled end,
        function(v)
            ReputationListDB.nameplateIcons = ReputationListDB.nameplateIcons or {}
            ReputationListDB.nameplateIcons.enabled = v
            if RL.Nameplates then RL.Nameplates:Toggle(v) end
        end)
    AddCheckbox(L["SET_CUSTOM_ICONS"], "npCustom",
        function() return ReputationListDB.nameplateIcons and ReputationListDB.nameplateIcons.useCustomIcons end,
        function(v)
            ReputationListDB.nameplateIcons = ReputationListDB.nameplateIcons or {}
            ReputationListDB.nameplateIcons.useCustomIcons = v
        end, 220)

    AddHeader(L["SET_SECTION_ONLINE"])
    AddCheckbox(L["SET_ENABLED"], "toastEnabled",
        function() return ReputationListDB.onlineToast and ReputationListDB.onlineToast.enabled end,
        function(v)
            ReputationListDB.onlineToast = ReputationListDB.onlineToast or {}
            ReputationListDB.onlineToast.enabled = v
            if RL.OnlineToast and RL.OnlineToast.SetEnabled then RL.OnlineToast:SetEnabled(v) end
        end)
    AddCheckbox(L["SET_SOUND"], "toastSound",
        function() return ReputationListDB.onlineToast and ReputationListDB.onlineToast.sound end,
        function(v)
            ReputationListDB.onlineToast = ReputationListDB.onlineToast or {}
            ReputationListDB.onlineToast.sound = v
        end, 220)
    AddCheckbox(L["SET_WATCH_BLACKLIST"], "toastBL",
        function() return ReputationListDB.onlineToast and ReputationListDB.onlineToast.watchBlacklist end,
        function(v)
            ReputationListDB.onlineToast = ReputationListDB.onlineToast or {}
            ReputationListDB.onlineToast.watchBlacklist = v
        end)
    AddCheckbox(L["SET_WATCH_WHITELIST"], "toastWL",
        function() return ReputationListDB.onlineToast and ReputationListDB.onlineToast.watchWhitelist end,
        function(v)
            ReputationListDB.onlineToast = ReputationListDB.onlineToast or {}
            ReputationListDB.onlineToast.watchWhitelist = v
        end, 220)
    AddHint(L["SET_ONLINE_HINT"])

    AddHeader(L["SET_SECTION_CHAT_FILTER"])
    AddCheckbox(L["SET_ENABLED"], "wfEnabled",
        function() return ReputationListDB.wordFilter and ReputationListDB.wordFilter.enabled end,
        function(v)
            ReputationListDB.wordFilter = ReputationListDB.wordFilter or {}
            ReputationListDB.wordFilter.enabled = v
        end)
    AddHint(L["SET_CHAT_FILTER_HINT"])

    AddHeader(L["SET_SECTION_SYNC"])
    AddCheckbox(L["SET_DISABLE_SYNC"], "syncDisabled",
        function() return ReputationListDB.sync and ReputationListDB.sync.disabled end,
        function(v)
            ReputationListDB.sync = ReputationListDB.sync or {}
            ReputationListDB.sync.disabled = v
            if RL.Sync and RL.Sync.SetDisabled then RL.Sync:SetDisabled(v) end
        end)
    AddHint(L["SET_DISABLE_SYNC_HINT"])

    AddHeader(L["SET_SECTION_TRANSFER"])
    y = y - 24
    local exportBtn = CreateButton(body, 200, 22, L["SET_OPEN_TRANSFER"])
    exportBtn:SetPoint("TOPLEFT", 4, y)
    exportBtn:SetScript("OnClick", function()
        if RL.Transfer then RL.Transfer:ShowUI() end
    end)
    StubTooltip(exportBtn, L["SET_TRANSFER_HINT"])
    y = y - 30

    body:SetHeight(math.max(-y, 1))
    body:SetWidth(1)

    p.checks = checks
    return p
end

function UI2:RefreshSettingsPage()
    local p = CACHE.settingsPage
    if not p then return end
    for _, entry in pairs(p.checks) do
        entry.cb:SetChecked(entry.getter() and true or false)
    end
end

local CARD_W, CARD_H = 360, 460

local function CreateCardFrame()
    local card = CreateFrame("Frame", "ReputationListV2Card", UIParent)
    card:SetSize(CARD_W, CARD_H)
    card:SetPoint("CENTER", 200, 0)
    FixScale(card)
    card:SetMovable(true)
    card:EnableMouse(true)
    card:RegisterForDrag("LeftButton")
    card:SetScript("OnDragStart", card.StartMoving)
    card:SetScript("OnDragStop", card.StopMovingOrSizing)
    card:SetFrameStrata("DIALOG")
    CreatePanelBackdrop(card)
    tinsert(UISpecialFrames, "ReputationListV2Card")

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", 12, -10)
    icon:SetTexture(Icon("logo_skull.tga"))
    card.icon = icon

    local iconRing = CreateFrame("Frame", nil, card)
    iconRing:SetSize(46, 46)
    iconRing:SetPoint("CENTER", icon)
    iconRing:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    iconRing:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 1)

    local name = card:CreateFontString(nil, "ARTWORK")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    name:SetFont(FONT_HEADER, 16, "")
    name:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])
    card.nameText = name

    local closeBtn = CreateFrame("Button", nil, card, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() card:Hide() end)

    local editBtn = CreateButton(card, 18, 18, "")
    editBtn:SetPoint("TOPRIGHT", -18, -32)
    editBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Note_02")
    editBtn:SetScript("OnClick", function()
        if not card.entry or not card.noteEdit then return end
        card.subTab = "note"
        UI2:RefreshCard()
        card.noteEditMode = not card.noteEditMode
        if card.noteEditMode then
            card.noteEdit:EnableMouse(true)
            card.noteFrame:SetBackdropBorderColor(PAL.gold[1], PAL.gold[2], PAL.gold[3], 1)
            card.noteEdit:SetFocus()
            card.noteEdit:SetCursorPosition(card.noteEdit:GetText():len())
        else
            UI2:SaveCardNote()
        end
    end)
    StubTooltip(editBtn, L["V2_EDIT_NOTE"])

    local forumExportBtn = CreateButton(card, 75, 22, L["V2_FORUM"])
    forumExportBtn:SetPoint("RIGHT", editBtn, "LEFT", -6, 0)
    forumExportBtn:SetScript("OnClick", function()
        if not card.entry then return end
        local entry = card.entry
        local factionLabel = (entry.data and entry.data.faction) or "?"
        local dateLabel = (entry.data and entry.data.addedDate) or "?"
        local noteText = (entry.note and entry.note ~= "" and entry.note) or "—"
        local guidLabel = (entry.data and entry.data.guid) or "—"
        local armoryLabel = (entry.data and entry.data.armoryLink and entry.data.armoryLink ~= "" and entry.data.armoryLink) or "—"

        local b64, err = RL.Transfer:ExportEntry(entry.listType, entry.key)
        local b64Line = b64 or string.format(L["V2_EXPORT_ERROR"], tostring(err))

        local text = string.format(
            L["V2_FORUM_BODY"],
            entry.name, guidLabel, armoryLabel, factionLabel, dateLabel, noteText, b64Line
        )
        ShowCopyableText(string.format(L["V2_FORUM_TITLE"], entry.name), text)
    end)
    StubTooltip(forumExportBtn, L["V2_FORUM_HINT"])

    local snapshotLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    snapshotLabel:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -8)

    snapshotLabel:SetText(L["V2_LAST_DATA"])
    snapshotLabel:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])
    card.snapshotLabel = snapshotLabel

    local infoLeft = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoLeft:SetPoint("TOPLEFT", snapshotLabel, "BOTTOMLEFT", 0, -4)
    infoLeft:SetJustifyH("LEFT")
    infoLeft:SetWidth(200)

    if infoLeft.SetSpacing then infoLeft:SetSpacing(4) end
    card.infoLeft = infoLeft

    local statusBadge = CreateFrame("Frame", nil, card)
    statusBadge:SetSize(104, 20)
    statusBadge:SetPoint("TOPRIGHT", -12, -56)
    statusBadge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    statusBadge:SetBackdropColor(0, 0, 0, 0.9)

    local statusText = statusBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("CENTER", 0, 0)
    card.statusBadge, card.statusText = statusBadge, statusText

    local armoryLabel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    armoryLabel:SetPoint("TOPLEFT", infoLeft, "BOTTOMLEFT", 0, -14)
    armoryLabel:SetText(L["V2_ARMORY"])
    armoryLabel:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])
    card.armoryLabel = armoryLabel

    local armoryEdit = CreateFrame("EditBox", "ReputationListV2CardArmoryEdit", card, "InputBoxTemplate")
    armoryEdit:SetSize(math.floor(CARD_W * 0.7), 20)
    armoryEdit:SetPoint("TOPLEFT", armoryLabel, "BOTTOMLEFT", 0, -4)
    armoryEdit:SetAutoFocus(false)
    StyleEditBox(armoryEdit)
    armoryEdit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    armoryEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    card.armoryEdit = armoryEdit

    local armorySaveBtn = CreateButton(card, 70, 20, L["V2_SAVE"], "primary")
    armorySaveBtn:SetPoint("LEFT", armoryEdit, "RIGHT", 6, 0)
    armorySaveBtn:SetScript("OnClick", function()
        if not card.entry then return end
        local fresh = FindEntry(card.entry.name, card.entry.listType)
        if not fresh then return end
        local newLink = armoryEdit:GetText()
        if fresh.armoryLink ~= newLink and RL.AddHistoryRecord then
            RL.AddHistoryRecord(fresh, L["V2_HIST_ARMORY"])
        end
        fresh.armoryLink = newLink
        if RL.InvalidateCache then RL.InvalidateCache() end
        if RL.SaveSettings then RL:SaveSettings() end
        print("|cFF00FF00ReputationList:|r " .. string.format(L["V2_SAVED_FOR"], card.entry.name))
        armoryEdit:ClearFocus()
    end)
    armoryEdit:SetScript("OnEnterPressed", function(self) armorySaveBtn:Click(); self:ClearFocus() end)

    local subTabs = { { id = "note", label = L["V2_NOTE"] }, { id = "history", label = L["V2_HISTORY"] } }
    card.subTabButtons = {}
    local stx = 12
    for _, subInfo in ipairs(subTabs) do
        local subName, subLabel = subInfo.id, subInfo.label
        local b = CreateFrame("Button", nil, card)
        b:SetSize(100, 20)
        b:SetPoint("TOPLEFT", armoryEdit, "BOTTOMLEFT", stx - 12, -10)
        stx = stx + 100
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("CENTER")
        fs:SetText(subLabel)
        b.fs = fs
        local underline = ColorFill(b, COL.accent, "ARTWORK")
        underline:SetPoint("BOTTOMLEFT", 0, 0); underline:SetPoint("BOTTOMRIGHT", 0, 0)
        underline:SetHeight(2); underline:Hide()
        b.underline = underline
        b:SetScript("OnClick", function() card.subTab = subName; UI2:RefreshCard() end)
        card.subTabButtons[subName] = b
    end
    card.subTab = "note"

    local content = CreateFrame("Frame", nil, card)
    content:SetPoint("TOPLEFT", card.subTabButtons.note, "BOTTOMLEFT", 0, -8)
    content:SetPoint("BOTTOMRIGHT", -12, 100)
    card.content = content

    local noteWidth = math.floor((CARD_W - 24) * 0.55)
    local metaWidth = (CARD_W - 24) - noteWidth - 10

    local noteFrame = CreateFrame("Frame", nil, content)
    noteFrame:SetPoint("TOPLEFT", 0, 0)
    noteFrame:SetPoint("BOTTOMLEFT", 0, 0)
    noteFrame:SetWidth(noteWidth)
    noteFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    noteFrame:SetBackdropColor(0, 0, 0, 0.8)
    noteFrame:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
    card.noteFrame = noteFrame

    local noteBox = CreateFrame("ScrollFrame", "ReputationListV2CardNoteScroll", content, "UIPanelScrollFrameTemplate")
    StyleScrollBar(noteBox)
    local noteScrollBar = _G[noteBox:GetName() and (noteBox:GetName() .. "ScrollBar")]
    if noteScrollBar then noteScrollBar:Hide() end
    noteBox:SetPoint("TOPLEFT", 4, -2)
    noteBox:SetPoint("BOTTOMRIGHT", noteFrame, "BOTTOMRIGHT", -4, 2)

    local noteEdit = CreateFrame("EditBox", nil, noteBox)
    noteEdit:SetMultiLine(true)
    noteEdit:SetFontObject(GameFontHighlightSmall)
    noteEdit:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3])
    noteEdit:SetWidth(noteWidth - 28)
    noteEdit:SetAutoFocus(false)
    noteEdit:EnableMouse(false)
    noteEdit:SetScript("OnEditFocusLost", function()
        if card.noteEditMode then UI2:SaveCardNote() end
    end)
    noteEdit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        card.noteEditMode = false
        card.noteEdit:EnableMouse(false)
        card.noteFrame:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)
        UI2:RefreshCard()
    end)
    noteBox:SetScrollChild(noteEdit)
    card.noteEdit = noteEdit
    card.noteBox = noteBox

    local metaDivider = ColorFill(content, {PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.5}, "ARTWORK")
    metaDivider:SetPoint("TOPLEFT", noteBox, "TOPRIGHT", 8, 28)
    metaDivider:SetPoint("BOTTOMLEFT", noteBox, "BOTTOMRIGHT", 8, 0)
    metaDivider:SetWidth(1)

    local metaText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    metaText:SetPoint("TOPLEFT", metaDivider, "TOPRIGHT", 8, 0)
    metaText:SetJustifyH("LEFT")
    metaText:SetWidth(metaWidth - 8)
    card.metaText = metaText
    card.metaDivider = metaDivider

    local historyBox = CreateFrame("ScrollFrame", "ReputationListV2CardHistoryScroll", content, "UIPanelScrollFrameTemplate")
    StyleScrollBar(historyBox)
    historyBox:SetPoint("TOPLEFT", 0, 0)
    historyBox:SetPoint("BOTTOMRIGHT", -24, 0)
    local historyText = CreateFrame("Frame", nil, historyBox)
    historyText:SetSize(CARD_W - 44, 1)
    historyBox:SetScrollChild(historyText)
    local historyFS = historyText:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    historyFS:SetPoint("TOPLEFT")
    historyFS:SetWidth(CARD_W - 44)
    historyFS:SetJustifyH("LEFT")
    card.historyBox, card.historyText, card.historyFS = historyBox, historyText, historyFS

    local addTagBtn = CreateButton(card, 20, 16, "+")
    card.addTagBtn = addTagBtn
    addTagBtn:SetPoint("TOPLEFT", content, "BOTTOMLEFT", 16, -26)

    local tagsLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tagsLabel:SetPoint("LEFT", addTagBtn, "RIGHT", 6, 0)
    tagsLabel:SetText(L["V2_TAGS_COLON"])
    tagsLabel:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])
    card.tagsAnchor = tagsLabel

    local tagsRow = CreateFrame("Frame", nil, card)
    tagsRow:SetPoint("LEFT", tagsLabel, "RIGHT", 8, 0)
    tagsRow:SetSize(math.floor(CARD_W * 0.85) - 90, 18)
    card.tagsRow = tagsRow

    local MAX_CARD_TAG_CHIPS = 8
    card.tagChips = {}
    for i = 1, MAX_CARD_TAG_CHIPS do
        local chip = CreateFrame("Button", nil, tagsRow)
        chip:SetHeight(14)
        local bg = ColorFill(chip, {0.4, 0.4, 0.4, 1}, "BACKGROUND")
        bg:SetAllPoints()
        local text = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetFont(FONT_BODY, 9, "")
        text:SetPoint("LEFT", 4, 0)
        local xMark = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        xMark:SetFont(FONT_BODY, 9, "")
        xMark:SetPoint("LEFT", text, "RIGHT", 2, 0)
        xMark:SetText("x")
        xMark:SetTextColor(1, 0.4, 0.4)
        chip.bg, chip.text, chip.xMark = bg, text, xMark
        chip:Hide()

        chip:SetScript("OnClick", function(self)
            local tagName = self.tagName
            if not tagName or not card.entry then return end
            local fresh2 = FindEntry(card.entry.name, card.entry.listType)
            if not fresh2 then return end

            local escapedTag = tagName:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
            local newNote = (fresh2.note or ""):gsub("#" .. escapedTag .. "%f[%s%z]", "")

            newNote = newNote:gsub("%s%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            fresh2.note = newNote
            if RL.AddHistoryRecord then RL.AddHistoryRecord(fresh2, string.format(L["V2_HIST_TAG_REMOVED"], tagName)) end
            if RL.InvalidateCache then RL.InvalidateCache() end
            UI2:Refresh(); UI2:RefreshCard()
        end)

        card.tagChips[i] = chip
    end

    addTagBtn:SetScript("OnClick", function()
        if not card.entry then return end
        StaticPopupDialogs["REPLIST_V2_ADD_TAG"] = StaticPopupDialogs["REPLIST_V2_ADD_TAG"] or {
            text = L["V2_TAG_NAME"],
            button1 = L["V2_ADD"], button2 = L["V2_CANCEL"],
            hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
            OnAccept = function(self)
                local tagName = self.editBox:GetText():gsub("^%s+", ""):gsub("%s+$", ""):gsub("^#+", "")
                if tagName == "" or not card.entry then return end
                local fresh = FindEntry(card.entry.name, card.entry.listType)
                local newNote = ((fresh and fresh.note) or card.entry.note or "") .. " #" .. tagName
                if fresh then
                    fresh.note = newNote
                    if RL.AddHistoryRecord then RL.AddHistoryRecord(fresh, string.format(L["V2_HIST_TAG_ADDED"], tagName)) end
                    if RL.InvalidateCache then RL.InvalidateCache() end
                end
                UI2:Refresh(); UI2:RefreshCard()
            end,
            EditBoxOnEnterPressed = function(self)
                self:GetParent().button1:Click()
            end,
        }
        StaticPopup_Show("REPLIST_V2_ADD_TAG")
    end)

    local bottomBar = CreateFrame("Frame", nil, card)
    bottomBar:SetPoint("BOTTOMLEFT", 12, 10)
    bottomBar:SetPoint("BOTTOMRIGHT", -12, 10)
    bottomBar:SetHeight(30)

    local sendBtn = CreateButton(bottomBar, 90, 22, L["V2_SEND"], "primary")
    sendBtn:SetPoint("LEFT", 0, 0)
    sendBtn:SetScript("OnClick", function()
        if not card.entry then return end
        if not (RL.Sync and RL.Sync.SendEntryTo) then
            print("|cFFFF0000ReputationList:|r " .. L["V2_SYNC_MISSING"])
            return
        end
        local entryRef = card.entry
        StaticPopupDialogs["REPLIST_V2_SEND_ENTRY"] = StaticPopupDialogs["REPLIST_V2_SEND_ENTRY"] or {
            text = L["V2_SEND_CARD_TO"],
            button1 = L["V2_SEND"], button2 = L["V2_CANCEL"],
            hasEditBox = true, timeout = 0, whileDead = true, hideOnEscape = true,
            OnAccept = function(self)
                local target = self.editBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
                if target == "" then return end
                local ok, err = RL.Sync:SendEntryTo(target, entryRef.listType, entryRef.key)
                if ok then
                    print("|cFF33CCFFReputationList:|r " .. string.format(L["V2_CARD_SENT"], entryRef.name, target))
                else
                    print("|cFFFF0000ReputationList:|r " .. tostring(err))
                end
            end,
            EditBoxOnEnterPressed = function(self)
                self:GetParent().button1:Click()
            end,
        }
        StaticPopup_Show("REPLIST_V2_SEND_ENTRY", card.entry.name)
    end)
    StubTooltip(sendBtn, L["V2_SEND_CARD_HINT"])

    local exportOneBtn = CreateButton(bottomBar, 135, 22, L["V2_EXPORT_ONE"])
    exportOneBtn:SetPoint("LEFT", sendBtn, "RIGHT", 10, 0)
    exportOneBtn:SetScript("OnClick", function()
        if not card.entry then return end
        if not RL.Transfer then
            print("|cFFFF0000ReputationList:|r " .. L["V2_EXPORT_MODULE_MISSING"])
            return
        end
        local str, err = RL.Transfer:ExportEntry(card.entry.listType, card.entry.key)
        if str then
            ShowCopyableText(string.format(L["V2_EXPORT_TITLE"], card.entry.name), str)
        else
            print("|cFFFF0000ReputationList:|r " .. tostring(err))
        end
    end)

    local deleteBtn2 = CreateButton(bottomBar, 90, 22, L["V2_DELETE"], "danger")
    deleteBtn2:SetPoint("RIGHT", 0, 0)
    deleteBtn2:SetScript("OnClick", function()
        if not card.entry then return end
        RL.UICommon.DeletePlayerDialog(card.entry.name,
            { RefreshList = function() UI2:Refresh() end },
            { currentTab = card.entry.listType }, L)
        card:Hide()
    end)

    card:Hide()
    return card
end

function UI2:ShowCard(entry)
    local card = CACHE.card
    if not card then
        card = CreateCardFrame()
        CACHE.card = card
    end
    card.entry = entry
    card.subTab = "note"
    card:Show()
    self:RefreshCard()
end

function UI2:SaveCardNote()
    local card = CACHE.card
    if not card or not card.entry then return end
    card.noteEditMode = false
    card.noteEdit:EnableMouse(false)
    card.noteEdit:ClearFocus()
    card.noteFrame:SetBackdropBorderColor(PAL.bronze[1], PAL.bronze[2], PAL.bronze[3], 0.9)

    local fresh = FindEntry(card.entry.name, card.entry.listType)
    if not fresh then return end
    local newNote = card.noteEdit:GetText()
    if newNote ~= (fresh.note or "") then
        fresh.note = newNote
        if RL.AddHistoryRecord then RL.AddHistoryRecord(fresh, L["V2_HIST_NOTE_CHANGED"]) end
        card.entry.note = newNote
        if RL.InvalidateCache then RL.InvalidateCache() end
    end
    UI2:Refresh()
    UI2:RefreshCard()
end

function UI2:RefreshCard()
    local card = CACHE.card
    if not card or not card:IsShown() then return end
    local entry = card.entry
    if not entry then return end

    local fresh = FindEntry(entry.name, entry.listType)
    if fresh then entry.note = fresh.note; entry.data = fresh end

    local cardIconTex = CARD_ICON_BY_LIST[entry.listType]
    if cardIconTex then
        card.icon:SetTexture(cardIconTex)
        local tint = STATUS_TINT[entry.listType] or {1, 1, 1}
        card.icon:SetVertexColor(tint[1], tint[2], tint[3])
    end

    card.nameText:SetText(entry.name)
    local classColors = RAID_CLASS_COLORS or {}
    local cc = entry.class and classColors[entry.class]
    if cc then card.nameText:SetTextColor(cc.r, cc.g, cc.b) end

    local realmLabel = (RL.GetCurrentRealmName and RL.GetCurrentRealmName()) or GetRealmName() or "?"
    card.infoLeft:SetText(string.format(
        L["V2_CARD_INFO"],
        entry.class or "?", entry.race or "?",
        (entry.guild and entry.guild ~= "" and entry.guild) or "—",
        entry.data.level or "?", entry.data.faction or "?",
        realmLabel, entry.data.guid or "—"
    ))

    local statusLabel = { blacklist = "BLACKLIST", whitelist = "WHITELIST", notelist = "NOTELIST" }
    local statusColor = { blacklist = PAL.red, whitelist = PAL.green, notelist = {0.35, 0.55, 0.95, 1} }
    local sc = statusColor[entry.listType] or {0.4,0.4,0.4,1}
    card.statusBadge:SetBackdropBorderColor(sc[1], sc[2], sc[3], 1)
    card.statusText:SetTextColor(sc[1], sc[2], sc[3])
    card.statusText:SetText(statusLabel[entry.listType] or entry.listType)

    if not card.armoryEdit:HasFocus() then
        card.armoryEdit:SetText(entry.data.armoryLink or "")
        card.armoryEdit:SetCursorPosition(0)
    end

    local tags = (RL.Tags and RL.Tags:ExtractTags(entry.note)) or {}
    local rowW = card.tagsRow:GetWidth()
    local rowH = 16
    local xCursor, yCursor = 0, 0
    for i, chip in ipairs(card.tagChips) do
        local tagName = tags[i]
        chip.tagName = tagName
        if tagName then
            chip.text:SetText(tagName)

            local w = 5 + chip.text:GetStringWidth() + 3 + chip.xMark:GetStringWidth() + 5
            if xCursor > 0 and xCursor + w > rowW then
                xCursor = 0
                yCursor = yCursor - rowH
            end
            chip:SetWidth(w)
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", card.tagsRow, "TOPLEFT", xCursor, yCursor)
            local color = ColorForTag(tagName)
            chip.bg:SetVertexColor(color[1], color[2], color[3], 1)
            chip:Show()
            xCursor = xCursor + w + 4
        else
            chip:Hide()
        end
    end

    for name, b in pairs(card.subTabButtons) do
        local active = (name == card.subTab)
        b.fs:SetTextColor(active and 1 or 0.65, active and 1 or 0.6, active and 1 or 0.55)
        SetShownCompat(b.underline, active)
    end

    SetShownCompat(card.noteBox, card.subTab == "note")
    SetShownCompat(card.metaText, card.subTab == "note")
    SetShownCompat(card.metaDivider, card.subTab == "note")
    SetShownCompat(card.historyBox, card.subTab == "history")

    if card.subTab == "note" then
        if not card.noteEditMode then
            card.noteEdit:SetText(entry.note or "")
        end

        local snap = entry.data.addedSnapshot
        local snapLines = L["V2_ADDED_DATA_EMPTY"]
        if snap and (snap.class or snap.race or snap.level or snap.guild or snap.faction) then
            snapLines = string.format(
                L["V2_ADDED_DATA"],
                snap.class or "?", snap.race or "?", snap.level or "?",
                (snap.guild and snap.guild ~= "" and snap.guild) or "—", snap.faction or "?"
            )
        end
        card.metaText:SetText(string.format(
            L["V2_META"],
            snapLines,
            entry.data.addedBy or "?", entry.data.addedDate or "?",
            entry.data.lastSeenDate or entry.data.addedDate or "?"
        ))
    elseif card.subTab == "history" then
        local history = entry.data.history
        if history and #history > 0 then
            local lines = {}
            for i = 1, #history do
                local h = history[i]
                table.insert(lines, string.format("%s — %s (%s)", h.date or "?", h.change or "?", h.by or "?"))
            end
            card.historyFS:SetText(table.concat(lines, "\n"))
        else
            card.historyFS:SetText(L["V2_NO_HISTORY"])
        end
    end
end

function UI2:CreateMainFrame()
    if CACHE.frame then return CACHE.frame end

    local f = CreateFrame("Frame", "ReputationListV2Frame", UIParent)
    f:SetSize(C.FRAME_W, C.FRAME_H)
    f:SetPoint("CENTER")
    FixScale(f)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    CreatePanelBackdrop(f)
    tinsert(UISpecialFrames, "ReputationListV2Frame")

    CreateHeader(f)
    CreateTabs(f)
    CreateSidebar(f)
    CreateFilterBar(f)
    f.tableHeader = CreateTableHeader(f)
    CreateListArea(f)
    CreateBottomBar(f)

    f.placeholders = {}
    CACHE.historyPage = CreateHistoryPage(f)
    CACHE.chatFilterPage = CreateChatFilterPage(f)
    CACHE.syncPage = CreateSyncPage(f)
    CACHE.proposedPage = CreateProposedPage(f)
    CACHE.whoHerePage = CreateWhoHerePage(f)
    CACHE.settingsPage = CreateSettingsPage(f)
    f.placeholders.history = CACHE.historyPage
    f.placeholders.chatfilter = CACHE.chatFilterPage
    f.placeholders.sync = CACHE.syncPage
    f.placeholders.proposed = CACHE.proposedPage
    f.placeholders.whohere = CACHE.whoHerePage
    f.placeholders.settings = CACHE.settingsPage

    f:Hide()
    CACHE.frame = f
    UI2.frame = f
    return f
end

function UI2:Refresh()
    local ok, err = pcall(self.RefreshImpl, self)
    if not ok then
        print("|cFFFF0000" .. string.format(L["V2_REFRESH_ERROR"], tostring(err)) .. "|r")
    end
end

function UI2:RefreshImpl()
    local f = CACHE.frame
    if not f then return end

    UpdateTabsVisual(f)

    local isListTab = (STATE.currentTab == "list" or STATE.currentTab == "blacklist" or STATE.currentTab == "whitelist" or STATE.currentTab == "notelist")

    local filtered, counts
    if isListTab then
        filtered, counts = GetFilteredSorted()
    else
        local entries = GetEntries()
        counts = CountByList(entries)
    end

    SetShownCompat(f.filterBar, isListTab)
    SetShownCompat(f.tableHeader, isListTab)
    SetShownCompat(f.scroll, isListTab)
    for i = 1, C.VISIBLE_ROWS do SetShownCompat(f.rows[i], isListTab) end
    for id, p in pairs(f.placeholders) do
        SetShownCompat(p, STATE.currentTab == id)
    end
    if STATE.currentTab == "chatfilter" then self:RefreshChatFilterPage()
    elseif STATE.currentTab == "sync" then self:RefreshSyncPage()
    elseif STATE.currentTab == "proposed" then self:RefreshProposedPage()
    elseif STATE.currentTab == "whohere" then self:RefreshWhoHerePage()
    elseif STATE.currentTab == "settings" then self:RefreshSettingsPage()
    elseif STATE.currentTab == "history" then self:RefreshHistoryPage()
    end

    f.allHeaderText:SetText(string.format(L["V2_ALL_RECORDS"], counts.all or 0))
    UpdateSidebarCounts(f.sidebar, counts)
    UpdateSidebarTags(f.sidebar)

    if not isListTab then
        if f.emptyText then f.emptyText:Hide() end
        return
    end

    FauxScrollFrame_Update(f.scroll, #filtered, C.VISIBLE_ROWS, C.ROW_H)
    local rowError, shownRows = RefreshVisibleRows(f, filtered)

    if rowError then
        f.emptyText:SetText(string.format(L["V2_ROW_ERROR"], rowError))
        f.emptyText:Show()
    elseif #filtered == 0 then
        if (STATE.search and STATE.search ~= "") or STATE.classFilter or STATE.raceFilter then
            f.emptyText:SetText(L["V2_NO_FILTER_RESULTS"])
        else
            f.emptyText:SetText(L["V2_EMPTY_LIST"])
        end
        f.emptyText:Show()
    else
        f.emptyText:Hide()
    end

    f.totalText:SetText(string.format(L["V2_TOTAL"], #filtered, shownRows))
end

function UI2:Toggle()
    local f = self:CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        self:Refresh()
    end
end

SLASH_REPLISTV2_1 = "/rlv2"
SLASH_REPLISTV2_2 = "/replist2"
SlashCmdList["REPLISTV2"] = function()
    local ok, err = pcall(UI2.Toggle, UI2)
    if not ok then
        print("|cFFFF0000" .. string.format(L["V2_UI_ERROR"], tostring(err)) .. "|r")
    end
end
