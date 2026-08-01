ReputationList = ReputationList or {}
local RL = ReputationList

if not RL.GetRealmData then
    return
end

RL.Nameplates = RL.Nameplates or {}
local NP = RL.Nameplates

ReputationListDB = ReputationListDB or {}

local function EnsureDefaults()
    ReputationListDB = ReputationListDB or {}
    ReputationListDB.nameplateIcons = ReputationListDB.nameplateIcons or {
        enabled = true,
        useCustomIcons = true,
    }
    return ReputationListDB.nameplateIcons
end

local CFG = EnsureDefaults()
if RL.Initialize then
    hooksecurefunc(RL, "Initialize", function()
        CFG = EnsureDefaults()
    end)
end

local CUSTOM_ICON_PATH = "Interface\\AddOns\\reputation\\textures\\"
local CUSTOM_ICONS = {
    blacklist = CUSTOM_ICON_PATH .. "skull_icon.tga",
    whitelist = CUSTOM_ICON_PATH .. "hands_icon.tga",
    notelist  = CUSTOM_ICON_PATH .. "notelist_icon.tga",
}
local FALLBACK_ICONS = {
    blacklist = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
    whitelist = "Interface\\FriendsFrame\\StatusIcon-Online",
    notelist  = "Interface\\Common\\Indicator-Yellow",
}

local function GetIconTexture(listType)
    return CFG.useCustomIcons and CUSTOM_ICONS[listType] or FALLBACK_ICONS[listType]
end

local cachedRealmData = nil

local function RefreshRealmDataCache()
    local ok, realmData = pcall(function() return RL:GetRealmData() end)
    cachedRealmData = ok and realmData or nil
end

local function GetListTypeForName(name)
    if not name or name == "" then return nil end
    if not cachedRealmData then return nil end
    local normName = RL.NormalizeName and RL.NormalizeName(name) or name
    local key = string.lower(normName)
    if cachedRealmData.blacklist and cachedRealmData.blacklist[key] then return "blacklist" end
    if cachedRealmData.whitelist and cachedRealmData.whitelist[key] then return "whitelist" end
    if cachedRealmData.notelist and cachedRealmData.notelist[key] then return "notelist" end
    return nil
end

RefreshRealmDataCache()
if RL.TimerManager then
    RL.TimerManager:Register("RL_NameplateRealmCache", 2, RefreshRealmDataCache)
end

local function StripIcon(text)
    if not text then return text end
    return (text:gsub("^|T.-|t%s*", ""))
end

local function PackInto(buf, ...)
    local n = select("#", ...)
    for i = 1, n do
        buf[i] = select(i, ...)
    end
    for i = n + 1, #buf do
        buf[i] = nil
    end
    return n
end

local hbScratch = {}
local function FindHealthBar(frame)
    local child = frame:GetChildren()
    if child and child.GetObjectType and child:GetObjectType() == "StatusBar" then
        return child
    end
    local n = PackInto(hbScratch, frame:GetChildren())
    for i = 1, n do
        local c = hbScratch[i]
        if c and c.GetObjectType and c:GetObjectType() == "StatusBar" then
            return c
        end
    end
    return nil
end

local regionScratch = {}
local function FindNameFontString(frame)
    local n = PackInto(regionScratch, frame:GetRegions())
    for i = 1, n do
        local region = regionScratch[i]
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and text ~= "" then
                return region
            end
        end
    end
    return nil
end

local notPlateCache = setmetatable({}, { __mode = "k" })
local lastCacheReset = GetTime()
local CACHE_RESET_INTERVAL = 60

local function IsNamePlate(frame)
    if not frame or not frame.GetObjectType then return false end
    if notPlateCache[frame] then return false end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    local objType = frame:GetObjectType()
    if objType ~= "Button" and objType ~= "Frame" then
        notPlateCache[frame] = true
        return false
    end
    if frame:GetName() then
        notPlateCache[frame] = true
        return false
    end
    if FindHealthBar(frame) then
        return true
    end
    notPlateCache[frame] = true
    return false
end

local function ApplyIcon(fontString)
    local rawText = StripIcon(fontString:GetText())
    if fontString:GetText() ~= rawText then fontString:SetText(rawText) end
    local listType = GetListTypeForName(rawText)
    local icon = fontString.__ReputationListIcon
    if not listType then
        if icon then icon:Hide() end
        return
    end

    if not icon then
        local parent = fontString:GetParent()
        if not parent or not parent.CreateTexture then return end
        icon = parent:CreateTexture(nil, "OVERLAY")
        icon:SetSize(14, 14)
        icon:SetPoint("RIGHT", fontString, "LEFT", -2, 0)
        fontString.__ReputationListIcon = icon
    end
    icon:SetTexture(GetIconTexture(listType))
    icon:Show()
end

local ElvNP = nil
local function DetectElvUI()
    local ok, elvE = pcall(function() return _G.ElvUI and unpack(_G.ElvUI) end)
    if ok and elvE and elvE.GetModule then
        local ok2, mod = pcall(function() return elvE:GetModule("NamePlates", true) end)
        if ok2 and mod and mod.Update_Name then
            return mod
        end
    end
    return nil
end
ElvNP = DetectElvUI()

local SCANNING_DISABLED_DUE_TO_ELVUI = false

local function InstallElvHook()
    hooksecurefunc(ElvNP, "Update_Name", function(self, frame)
        if not CFG.enabled then return end
        if not frame or not frame.Name or not frame.UnitName or frame.UnitName == "" then return end
        local listType = GetListTypeForName(frame.UnitName)
        local current = frame.Name:GetText() or ""
        local stripped = StripIcon(current)
        if current ~= stripped then frame.Name:SetText(stripped) end
        ApplyIcon(frame.Name)
    end)
    SCANNING_DISABLED_DUE_TO_ELVUI = true
end

if ElvNP then
    InstallElvHook()
else
  
    local retryElapsed, retryCount = 0, 0
    local retryDriver = CreateFrame("Frame")
    retryDriver:SetScript("OnUpdate", function(self, delta)
        retryElapsed = retryElapsed + delta
        if retryElapsed < 1 then return end
        retryElapsed = 0
        retryCount = retryCount + 1
        ElvNP = DetectElvUI()
        if ElvNP then
            InstallElvHook()
            self:SetScript("OnUpdate", nil)
        elseif retryCount >= 5 then
            self:SetScript("OnUpdate", nil)
        end
    end)
end


local trackedList = {}
local worldChildrenScratch = {}

local debugMode = false
local lastScanFound = 0
local lastScanCandidates = 0

function NP:ScanPlates()
    if SCANNING_DISABLED_DUE_TO_ELVUI then return end
    if not CFG.enabled and not debugMode then
        trackedList = {}
        return
    end

    RefreshRealmDataCache()

    local now = GetTime()
    if now - lastCacheReset >= CACHE_RESET_INTERVAL then
        lastCacheReset = now
        for k in pairs(notPlateCache) do
            notPlateCache[k] = nil
        end
    end

    local n = PackInto(worldChildrenScratch, WorldFrame:GetChildren())
    local found = 0
    local candidates = 0
    local newTracked = {}

    for i = 1, n do
        local frame = worldChildrenScratch[i]
        if IsNamePlate(frame) then
            candidates = candidates + 1
            local fs = FindNameFontString(frame)
            if fs then
                found = found + 1
                if CFG.enabled then
                    ApplyIcon(fs)
                    newTracked[#newTracked + 1] = fs
                end
            end
        end
    end

    trackedList = newTracked

    lastScanFound = found
    lastScanCandidates = candidates
end


local tightElapsed = 0
local TIGHT_INTERVAL = 0.1
local tightDriver = CreateFrame("Frame")
tightDriver:SetScript("OnUpdate", function(self, delta)
    if SCANNING_DISABLED_DUE_TO_ELVUI then return end
    tightElapsed = tightElapsed + delta
    if tightElapsed < TIGHT_INTERVAL then return end
    tightElapsed = 0

    if not CFG.enabled then return end
    for i = 1, #trackedList do
        local fs = trackedList[i]
        if fs and fs.GetText then
            ApplyIcon(fs)
        end
    end
end)

local scanElapsed = 0
local SCAN_INTERVAL = 0.3
local scanDriver = CreateFrame("Frame")
scanDriver:SetScript("OnUpdate", function(self, delta)
    if SCANNING_DISABLED_DUE_TO_ELVUI then return end
    scanElapsed = scanElapsed + delta
    if scanElapsed >= SCAN_INTERVAL then
        scanElapsed = 0
        NP:ScanPlates()
    end
end)

function NP:Toggle(state)
    if state == nil then
        CFG.enabled = not CFG.enabled
    else
        CFG.enabled = state
    end

    if not CFG.enabled then
        for i = 1, #trackedList do
            local fs = trackedList[i]
            if fs and fs.__ReputationListIcon then fs.__ReputationListIcon:Hide() end
            if fs and fs.GetText then
                local stripped = StripIcon(fs:GetText())
                if fs:GetText() ~= stripped then fs:SetText(stripped) end
            end
        end
        trackedList = {}
    end

    print("|cFF00FF00[ReputationList]|r Иконки на неймплейтах: " .. (CFG.enabled and "|cFF00FF00включены|r" or "|cFFFF0000выключены|r"))
end

-- ---------------------------------------------------------------------------
-- Слэш-команды
-- ---------------------------------------------------------------------------

SLASH_RLPLATES1 = "/rlplates"
SlashCmdList["RLPLATES"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if msg == "on" then
        NP:Toggle(true)
    elseif msg == "off" then
        NP:Toggle(false)
    elseif msg == "custom" then
        CFG.useCustomIcons = true
        print("|cFF00FF00[ReputationList]|r Использование собственных иконок включено (файлы должны лежать в reputation\\icons\\).")
    elseif msg == "builtin" then
        CFG.useCustomIcons = false
        print("|cFF00FF00[ReputationList]|r Использование стандартных иконок WoW.")
    elseif msg == "mem" then
        UpdateAddOnMemoryUsage()
        local kb, foundName = nil, nil
        for i = 1, GetNumAddOns() do
            local name = GetAddOnInfo(i)
            if name and name:lower():find("reputation") then
                kb = GetAddOnMemoryUsage(i)
                foundName = name
                break
            end
        end
        local cacheCount = 0
        for _ in pairs(notPlateCache) do cacheCount = cacheCount + 1 end
        local scanStatus = SCANNING_DISABLED_DUE_TO_ELVUI and "выключено (используется хук ElvUI)" or "активно (фолбэк-скан WorldFrame)"
        if kb then
            print(string.format(
                "|cFF00FF00[ReputationList]|r Память ВСЕГО аддона \"%s\" (все файлы): %.1f KB. Сканирование неймплейтов: %s. Размер буфера детей WorldFrame - %d, закэшировано \"не неймплейт\" - %d, сейчас отслеживается совпадений - %d.",
                foundName, kb, scanStatus, #worldChildrenScratch, cacheCount, #trackedList))
        else
            print("|cFFFF0000[ReputationList]|r Не удалось найти аддон по имени \"reputation\" в списке загруженных - проверьте название папки в Interface/AddOns.")
        end
        print("|cFFFFAA00[ReputationList]|r Если это число растёт значительно и без остановки при большом онлайне/списке - пришлите его до и после, чтобы локализовать точнее.")
    elseif msg == "debug" then
        if SCANNING_DISABLED_DUE_TO_ELVUI then
            print("|cFF00FF00[ReputationList]|r Обнаружен модуль неймплейтов ElvUI - сканирование WorldFrame отключено намеренно, иконки ставятся напрямую через хук ElvNP.Update_Name. Счётчики скана (кандидаты/найдено) в этом режиме не используются.")
        else
            debugMode = not debugMode
            NP:ScanPlates()
            print(string.format(
                "|cFF00FF00[ReputationList]|r Debug %s. За последний скан: кандидатов на неймплейт - %d, из них с именем - %d, отслеживается сейчас - %d.",
                debugMode and "включён" or "выключен", lastScanCandidates, lastScanFound, #trackedList))
            if lastScanCandidates == 0 then
                print("|cFFFFAA00[ReputationList]|r Ни одного кандидата не найдено вообще - похоже, у вас нестандартные неймплейты (аддон-замена вроде TidyPlates/Aloft), эвристика их не видит.")
            elseif lastScanFound == 0 then
                print("|cFFFFAA00[ReputationList]|r Кандидаты есть, но текст имени не найден - возможно, в игре выключен показ имён на неймплейтах (CVar unitnameplatesshownames).")
            end
        end
    else
        print("|cFF00FF00[ReputationList]|r Иконки на неймплейтах: " .. (CFG.enabled and "включены" or "выключены"))
        print("  /rlplates on|off - включить/выключить")
        print("  /rlplates custom|builtin - использовать свои иконки или стандартные WoW")
        print("  /rlplates debug - диагностика, если иконки не появляются")
        print("  /rlplates mem - показать текущую память аддона и внутренние счётчики")
    end
end
