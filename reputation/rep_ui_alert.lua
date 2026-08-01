ReputationList = ReputationList or {}
local RL = ReputationList

RL.UIAlert = RL.UIAlert or {}
local Alert = RL.UIAlert

local ADDON_FOLDER = "reputation"
local function Icon(name)
    return "Interface\\AddOns\\" .. ADDON_FOLDER .. "\\textures\\" .. name
end

local PAL = {
    bronze  = {0.482, 0.353, 0.169, 1},
    gold    = {0.827, 0.651, 0.227, 1},
    red     = {0.710, 0.086, 0.086, 1},
    green   = {0.235, 0.616, 0.224, 1},
    blue    = {0.35,  0.55,  0.95,  1},
    text    = {0.941, 0.847, 0.627, 1},
    textDim = {0.682, 0.635, 0.549, 1},
}

local FONT_BODY = "Fonts\\FRIZQT__.TTF"
local FONT_HEADER = "Fonts\\MORPHEUS.TTF"

local function CreatePanelBackdrop(f)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 32, edgeSize = 18,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetBackdropColor(1, 1, 1, 0.95)
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

local function CreateDivider(parent, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 24, y)
    line:SetPoint("TOPRIGHT", -24, y)
    line:SetTexture(PAL.gold[1], PAL.gold[2], PAL.gold[3], 0.35)
    return line
end

local function CreateCloseButton(parent)
    local b = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    b:SetPoint("TOPRIGHT", -4, -4)
    return b
end

local ROW_ICON_SIZE = 20

local function CreateInfoRow(parent, y)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 200, y)
    row:SetPoint("RIGHT", -20, 0)
    row:SetHeight(18)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_ICON_SIZE, ROW_ICON_SIZE)
    row.icon:SetPoint("LEFT", 0, 0)

    row.bullet = row:CreateFontString(nil, "OVERLAY")
    row.bullet:SetFont(FONT_BODY, 12, "")
    row.bullet:SetPoint("LEFT", 0, 0)
    row.bullet:SetText("|cFFD3A63A\226\151\134|r") -- золотой ромб-маркер

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(FONT_BODY, 12, "")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    row.value = row:CreateFontString(nil, "OVERLAY")
    row.value:SetFont(FONT_BODY, 12, "")
    row.value:SetPoint("LEFT", row.label, "RIGHT", 4, 0)
    row.value:SetPoint("RIGHT", 0, 0)
    row.value:SetJustifyH("LEFT")
    row.value:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3])

    function row:SetTextureIcon(path, texCoord)
        if path == false then
            row.icon:Hide()
            row.bullet:Hide()
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        elseif path then
            row.icon:SetTexture(path)
            if texCoord then row.icon:SetTexCoord(unpack(texCoord)) end
            row.icon:Show()
            row.bullet:Hide()
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        else
            row.icon:Hide()
            row.bullet:Show()
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row.bullet, "RIGHT", 6, 0)
        end
    end

    return row
end


local STATUS_INFO = {
    blacklist = { subKey = "UI_ALERT_SUB_BLACKLIST", color = PAL.red,   badge = "skull_icon.tga"     },
    whitelist = { subKey = "UI_ALERT_SUB_WHITELIST", color = PAL.green, badge = "hands_icon.tga"     },
    notelist  = { subKey = "UI_ALERT_SUB_NOTELIST",  color = PAL.blue,  badge = "notelist_icon.tga"  },
}

local function TryOpenFullCard(playerName, listTypeHint)
    if not (RL.UI2 and RL.UI2.ShowCard and RL.GetRealmData) then
        return false
    end

    local key = string.lower(playerName or "")
    if key == "" then return false end

    local realmData = RL:GetRealmData()
    if not realmData then return false end

    local listType, record = listTypeHint, nil
    if listType and realmData[listType] then
        record = realmData[listType][key]
    end

    if not record then
        for _, lt in ipairs({ "blacklist", "whitelist", "notelist" }) do
            if realmData[lt] and realmData[lt][key] then
                listType, record = lt, realmData[lt][key]
                break
            end
        end
    end

    if not record then return false end

    RL.UI2:ShowCard({
        key = key,
        listType = listType,
        name = record.name or playerName,
        class = record.class,
        race = record.race,
        guild = record.guild,
        note = record.note,
        addedDate = record.addedDate,
        data = record,
    })

    return true
end

function Alert:CreateFrame()
    local L = RL.L or ReputationListLocale or {}

    local f = CreateFrame("Frame", "RepListPlayerCard", UIParent)
    f:SetSize(400, 330)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)

    if ReputationListDB and ReputationListDB.cardPositions and ReputationListDB.cardPositions.x then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ReputationListDB.cardPositions.x, ReputationListDB.cardPositions.y)
    else
        f:SetPoint("CENTER")
    end

    CreatePanelBackdrop(f)

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        self.rlDragging = true
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetLeft(), self:GetTop()
        ReputationListDB.cardPositions = ReputationListDB.cardPositions or {}
        ReputationListDB.cardPositions.x = x
        ReputationListDB.cardPositions.y = y
 
    end)

 
    f:SetScript("OnMouseUp", function(self, button)
        if self.rlDragging then
            self.rlDragging = false
            return
        end
        if button == "LeftButton" and self.currentPlayer then
            TryOpenFullCard(self.currentPlayer, self.currentListType)
        end
    end)


    f.emblem = f:CreateTexture(nil, "ARTWORK")
    f.emblem:SetTexture(Icon("warning_emblem.tga"))
    f.emblem:SetTexCoord(0, 340 / 512, 0, 107 / 128)
    f.emblem:SetSize(300, 94)
    f.emblem:SetPoint("TOP", 0, -14)


    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFont(FONT_HEADER, 20, "")
    f.title:SetPoint("TOP", f.emblem, "BOTTOM", 0, -6)
    f.title:SetTextColor(PAL.red[1], PAL.red[2], PAL.red[3])
    f.title:SetShadowColor(0, 0, 0, 0.9)
    f.title:SetShadowOffset(1, -1)
    f.title:SetText(L["UI_ALERT_TITLE"] or "WARNING")

    f.divider1 = CreateDivider(f, -136)

    f.nameValue = f:CreateFontString(nil, "OVERLAY")
    f.nameValue:SetFont(FONT_HEADER, 20, "")
    f.nameValue:SetPoint("TOPLEFT", 45, -165)
    f.nameValue:SetPoint("RIGHT", f, "LEFT", 190, 0)
    f.nameValue:SetJustifyH("LEFT")
    f.nameValue:SetJustifyV("TOP")
    f.nameValue:SetTextColor(PAL.gold[1], PAL.gold[2], PAL.gold[3])

    f.classRow = CreateInfoRow(f, -152)
    f.classRow.label:SetText(L["UI_LBL_CL"] or "Class:")
    f.classRow:SetTextureIcon(false)

    f.factionRow = CreateInfoRow(f, -174)
    f.factionRow.label:SetText(L["UI_LBL_FAC"] or "Faction:")
    f.factionRow:SetTextureIcon(false)

    f.guildRow = CreateInfoRow(f, -196)
    f.guildRow.label:SetText(L["UI_LBL_GLD"] or "Guild:")
    f.guildRow:SetTextureIcon(false)

    f.divider2 = CreateDivider(f, -224)

    f.noteLabel = f:CreateFontString(nil, "OVERLAY")
    f.noteLabel:SetFont(FONT_BODY, 12, "")
    f.noteLabel:SetPoint("TOPLEFT", 24, -236)
    f.noteLabel:SetText(L["UI_LBL_NT"] or "NOTE:")

    f.noteText = f:CreateFontString(nil, "OVERLAY")
    f.noteText:SetFont(FONT_BODY, 12, "")
    f.noteText:SetPoint("TOPLEFT", 24, -254)

    f.noteText:SetPoint("BOTTOMRIGHT", -24, 44)
    f.noteText:SetJustifyH("LEFT")
    f.noteText:SetJustifyV("TOP")
    f.noteText:SetTextColor(PAL.text[1], PAL.text[2], PAL.text[3])
    if f.noteText.SetSpacing then f.noteText:SetSpacing(2) end

    f.subtitle = f:CreateFontString(nil, "OVERLAY")
    f.subtitle:SetFont(FONT_BODY, 12, "")
    f.subtitle:SetPoint("BOTTOM", 0, 26)
    f.subtitle:SetJustifyH("CENTER")
    f.subtitle:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])

    f.closeBtn = CreateCloseButton(f)
    f.closeBtn:SetScript("OnClick", function()
        f:Hide()
        if f.currentPlayer then
            RL.shownCards[f.currentPlayer] = nil
        end
    end)

    f.hint = f:CreateFontString(nil, "OVERLAY")
    f.hint:SetFont(FONT_BODY, 10, "")
    f.hint:SetPoint("BOTTOM", 0, 10)
    f.hint:SetTextColor(PAL.textDim[1], PAL.textDim[2], PAL.textDim[3])
    f.hint:SetText(L["UI_ALERT_HINT"] or "")
    f.hint:Hide()

    f.infoElements = {
        f.nameValue, f.classRow, f.factionRow, f.guildRow,
        f.noteLabel, f.noteText,
    }

    RL.playerCardFrame = f
    f:Hide()
    return f
end

function Alert:Update(playerName, playerData)
    local L = RL.L or ReputationListLocale or {}
    local f = RL.playerCardFrame
    if not f then return end

    if not playerData then
        playerData = { name = playerName, note = L["UI_F_N"] }
    end

    if not playerData.faction and playerData.race and RL.GetFactionByRace then
        playerData.faction = RL.GetFactionByRace(playerData.race)
    end

    local classColors = RAID_CLASS_COLORS or {}
    local classColor = classColors[playerData.class] or { r = PAL.gold[1], g = PAL.gold[2], b = PAL.gold[3] }

    f.nameValue:SetText(playerData.name or L["UI_F_UN"] or "?")
    f.nameValue:SetTextColor(classColor.r, classColor.g, classColor.b)

    f.classRow.value:SetText(playerData.class or L["UI_F_UNO"] or "?")
    f.factionRow.value:SetText(playerData.faction or L["UI_F_UN"] or "?")
    f.guildRow.value:SetText((playerData.guild and playerData.guild ~= "" and playerData.guild) or L["NO"] or "-")

    f.noteText:SetText(playerData.note or L["UI_F_N"] or "")

    local listType = nil
    local realmData = RL:GetRealmData()
    local key = string.lower(playerName or "")

    if realmData.blacklist[key] then
        listType = "blacklist"
    elseif realmData.whitelist[key] then
        listType = "whitelist"
    elseif realmData.notelist[key] then
        listType = "notelist"
    end

    local status = STATUS_INFO[listType] or STATUS_INFO.blacklist
    f.subtitle:SetText(L[status.subKey] or "")
    f.title:SetTextColor(status.color[1], status.color[2], status.color[3])
    f:SetBackdropBorderColor(status.color[1], status.color[2], status.color[3], 1)

    f.currentPlayer = key
    f.currentListType = listType

    if RL.UI2 and RL.UI2.ShowCard and listType then
        f.hint:Show()
    else
        f.hint:Hide()
    end
end
