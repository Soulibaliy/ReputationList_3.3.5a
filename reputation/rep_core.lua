ReputationList = ReputationList or {}
local RL = ReputationList
RL.version = "1.70"
if not RL.SanitizeString then
    error("Security module not loaded! Check .toc file order.")
end
if not RL.FastFind then
    error("Optimization module not loaded! Check .toc file order.")
end
RL.notifiedPlayers = {}
RL.lastRaidRoster = {}
RL.alertQueue = {}
RL.alertCooldowns = {}
RL.shownCards = {}
RL.nameCache = {}
RL.nameCacheAccess = {}
RL.maxNameCache = 50

function RL.NormalizeName(name)
    if not name or name == "" then return "" end
    
    if RL.nameCache[name] then
        RL.nameCacheAccess[name] = time()
        return RL.nameCache[name]
    end
    
    local result = name:match("^[^-]+") or name
    result = result:gsub("^%s+", ""):gsub("%s+$", "")

    RL.nameCache[name] = result
    RL.nameCacheAccess[name] = time()
    
    local count = 0
    for _ in pairs(RL.nameCache) do
        count = count + 1
    end
    
    if count > RL.maxNameCache then
        local entries = {}
        for k, v in pairs(RL.nameCacheAccess) do
            table.insert(entries, {key = k, time = v})
        end
        
        table.sort(entries, function(a, b)
            return a.time < b.time
        end)
        
        local toRemove = math.ceil(count * 0.3)
        for i = 1, toRemove do
            RL.nameCache[entries[i].key] = nil
            RL.nameCacheAccess[entries[i].key] = nil
        end
    end
    
    return result
end

local L = ReputationList.L or ReputationListLocale

function RL:SyncSettings()
    RL.autoNotify = ReputationListDB.autoNotify
    RL.selfNotify = ReputationListDB.selfNotify
    RL.colorLFG = ReputationListDB.colorLFG
    RL.soundNotify = ReputationListDB.soundNotify
    RL.popupNotify = ReputationListDB.popupNotify
	RL.blockInvites = ReputationListDB.blockInvites
	RL.blockTrade = ReputationListDB.blockTrade
	RL.filterMessages = ReputationListDB.filterMessages
end

function RL:GetUIMode()
    if not ReputationListDB.uiMode then
        ReputationListDB.uiMode = "full"
    end
    return ReputationListDB.uiMode
end

function RL:SetUIMode(mode)
    ReputationListDB.uiMode = mode
end

function RL:ToggleUIMode()
    local newMode = (self:GetUIMode() == "full") and "mini" or "full"
    self:SetUIMode(newMode)

    if self.UI and self.UI.Classic then
        self.UI.Classic:ApplyUIMode()
    end
end

local translit = {
    ["А"]="a", ["а"]="a", ["Б"]="b", ["б"]="b", ["В"]="v", ["в"]="v",
    ["Г"]="g", ["г"]="g", ["Д"]="d", ["д"]="d", ["Е"]="e", ["е"]="e",
    ["Ё"]="yo",["ё"]="yo",["Ж"]="zh",["ж"]="zh",["З"]="z", ["з"]="z",
    ["И"]="i", ["и"]="i", ["Й"]="y", ["й"]="y", ["К"]="k", ["к"]="k",
    ["Л"]="l", ["л"]="l", ["М"]="m", ["м"]="m", ["Н"]="n", ["н"]="n",
    ["О"]="o", ["о"]="o", ["П"]="p", ["п"]="p", ["Р"]="r", ["р"]="r",
    ["С"]="s", ["с"]="s", ["Т"]="t", ["т"]="t", ["У"]="u", ["у"]="u",
    ["Ф"]="f", ["ф"]="f", ["Х"]="h", ["х"]="h", ["Ц"]="c", ["ц"]="c",
    ["Ч"]="ch",["ч"]="ch",["Ш"]="sh",["ш"]="sh",["Щ"]="sch",["щ"]="sch",
    ["Ы"]="y", ["ы"]="y", ["Э"]="e", ["э"]="e", ["Ю"]="yu", ["ю"]="yu",
    ["Я"]="ya", ["я"]="ya",
}

local function NormalizeKey(name)
    if not name then return "" end
    local out = {}
    for uchar in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local t = translit[uchar]
        if t then
            out[#out+1] = t
        else
            out[#out+1] = uchar:lower()
        end
    end
    return table.concat(out)
end

local function NormalizeRealm(realm)
    if not realm then return "Unknown" end
    realm = realm:gsub("^%s+", ""):gsub("%s+$", "")
    realm = realm:gsub("%s*%[.-%]%s*$", "")
    realm = realm:gsub("%s*%(.-%)%s*$", "")
    return realm
end

RL.NormalizeRealm = NormalizeRealm

local function GetCurrentRealm()
    local realm = GetRealmName()
    return NormalizeRealm(realm)
end

local function FindEntryByGUID(list, guid)
    if not list or not guid then return nil end
    
    local normalizedGuid = RL.NormalizeGUID(guid)
    if not normalizedGuid then return nil end
    
    for stored, data in pairs(list) do
        if data.guid then
            local storedGuid = RL.NormalizeGUID(data.guid)
            if storedGuid and storedGuid == normalizedGuid then
                return stored, data
            end
        end
    end
    return nil
end

local function CheckGUIDConflict(playerName, guid, listName, realmData, note)
    if not guid then return nil, nil, nil end
    
    local key = string.lower(playerName)
    
    for listType, list in pairs({blacklist = realmData.blacklist, whitelist = realmData.whitelist, notelist = realmData.notelist}) do
        local foundKey, foundData = FindEntryByGUID(list, guid)
        if foundKey and foundData then
            if foundKey ~= key then
                print("|cFFFFAA00ReputationList:|r " .. L["NICK_CHANGE_DETECTED"] .. (foundData.name or foundKey) .. " -> " .. playerName)
                return listType, foundKey, foundData, true
            else
                return listType, foundKey, foundData, false
            end
        end
    end
    
    return nil, nil, nil, false
end

local function ApplyNameChange(guidListType, guidKey, guidData, playerName, key, listType, targetList, listName, realmData, currentInfo, note, batchMode)
    local targetListType = listType
    if listType == "black" or listType == "bl" then
        targetListType = "blacklist"
    elseif listType == "white" or listType == "wl" then
        targetListType = "whitelist"
    elseif listType == "note" or listType == "nl" then
        targetListType = "notelist"
    end

    print(L["INFO_R05"])

    local oldList = realmData[guidListType]
    oldList[guidKey] = nil
    oldList[key] = guidData

    guidData.name = playerName
    guidData.key = NormalizeKey(playerName)
    guidData.note = note

    if currentInfo then
        if currentInfo.class   then guidData.class   = currentInfo.class   end
        if currentInfo.race    then guidData.race    = currentInfo.race    end
        if currentInfo.level   then guidData.level   = currentInfo.level   end
        if currentInfo.guild   then guidData.guild   = currentInfo.guild   end
        if currentInfo.faction then guidData.faction = currentInfo.faction end
    end

    if guidListType ~= targetListType then
        local oldListName = guidListType:gsub("^%l", string.upper)
        print(L["WH_D08"] .. oldListName .. L["WH_D09"] .. listName .. "|r")
        targetList[key] = guidData
        oldList[key] = nil
    end

    if not batchMode then
        RL.InvalidateCache()
        RL:SaveSettings()
        print(L["WH_D11"] .. playerName .. L["WH_D10"] .. listName)
    end
    return true
end

function RL.GetPlayerInfo(unit)
    local info = {}
    
    local rawGUID = UnitGUID(unit)
    if rawGUID and RL.ValidateGUID(rawGUID) then
        info.guid = RL.NormalizeGUID(rawGUID)
    else
        info.guid = nil
    end
    
    info.class = select(2, UnitClass(unit))
    info.race = select(2, UnitRace(unit))
    info.level = UnitLevel(unit)
    info.guild = GetGuildInfo(unit) or nil
    info.faction = UnitFactionGroup(unit)
    return info
end


local function GetPlayerInfo(unit)
    return RL.GetPlayerInfo(unit)
end

local function GetFactionByRace(race)
    if not race then return nil end
    
    local allianceRaces = {
        ["Human"] = true,
        ["Dwarf"] = true,
        ["NightElf"] = true,
        ["Gnome"] = true,
        ["Draenei"] = true
    }
    
    local hordeRaces = {
        ["Orc"] = true,
        ["Undead"] = true,
        ["Tauren"] = true,
        ["Scourge"] = true,
        ["Troll"] = true,
        ["BloodElf"] = true
    }
    
    if allianceRaces[race] then
        return "Alliance"
    elseif hordeRaces[race] then
        return "Horde"
    end
    
    return nil
end

function RL.FindPlayerInGroup(playerName)
    if not playerName then return nil end
    
    local normName = RL.NormalizeName(playerName)
    local searchKey = NormalizeKey(normName)
    
    if UnitName("player") and RL.NormalizeName(UnitName("player")) == normName then
        return "player"
    end
    
    local numMembers = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    if numMembers > 0 then
        local isRaid = GetNumRaidMembers() > 0
        for i = 1, (isRaid and numMembers or numMembers) do
            local unit
            if isRaid then
                unit = "raid" .. i
            else
                unit = "party" .. i
            end
            
            if UnitExists(unit) and UnitIsPlayer(unit) then
                local name = UnitName(unit)
                if name then
                    local normUnitName = RL.NormalizeName(name)
                    if normUnitName == normName or NormalizeKey(normUnitName) == searchKey then
                        return unit
                    end
                end
            end
        end
    end
    
    return nil
end

local function FindPlayerInGroup(playerName)
    return RL.FindPlayerInGroup(playerName)
end

function RL:ImportFromBlacklist()
    if not BlackListedPlayers then
        print(L["WH_W01"])
        return
    end
    
    local realmData = RL:GetRealmData()
    local imported = 0
    
    for realm, players in pairs(BlackListedPlayers) do
        for _, playerData in ipairs(players) do
            if playerData.name and playerData.name ~= "" then
                local name = RL.NormalizeName(playerData.name)
                local key = string.lower(name)
                
                if not realmData.blacklist[key] then
                    local note = playerData.reason or "Импортировано из Blacklist"
                    if note == "" then note = "Импортировано из Blacklist" end
                    
                    realmData.blacklist[key] = {
                        name = name,
                        note = note,
                        addedDate = date("%d.%m.%Y %H:%M"),
                        addedBy = "Import (Blacklist)",
                        guid = nil,
                        class = playerData.class or nil,
                        race = playerData.race or nil,
                        level = playerData.level or nil,
                        guild = nil,
                        faction = nil,
                        key = NormalizeKey(name)
                    }
                    imported = imported + 1
                end
            end
        end
    end
    
    RL:SaveSettings()
    
    if RL.BuildGUIDIndex then
        RL.BuildGUIDIndex()
    end
    
    print("|cFF00FF00ReputationList:|r Импортировано " .. imported .. " игроков из Blacklist")
end

local function ParseElitistData(dataStr)
    if not dataStr or dataStr == "" then return nil end
    
    dataStr = dataStr:gsub("^%s*{", ""):gsub("}%s*$", "")
    
    local result = {}
    
    local notesStr = dataStr:match("notes=({.-});")
    if notesStr then
        for playerKey, noteData in notesStr:gmatch("%[\"(.-)\".-=%s*{(.-)}") do
            local comment = noteData:match("comment=\"(.-)\";")
            local rating = noteData:match("rating=(%d+);")
            
            if comment or rating then
                result.note = comment or ("Рейтинг: " .. (rating or "?"))
                result.rater = RL.NormalizeName(playerKey:match("^[^-]+") or playerKey)
            end
        end
    end
    
    result.class = dataStr:match("classToken=\"(.-)\";")
    result.level = tonumber(dataStr:match("level=(%d+);"))
    result.name = dataStr:match("name=\"(.-)\";")
    
    return result
end

function RL:ImportFromElitist()
    if not ElitistGroupDB or not ElitistGroupDB.faction then
        print(L["WH_W02"])
        return
    end
    
    local realmData = RL:GetRealmData()
    local imported = 0
    
    for faction, factionData in pairs(ElitistGroupDB.faction) do
        if factionData.users then
            for playerKey, userData in pairs(factionData.users) do
                local parsedData = ParseElitistData(userData)
                
                if parsedData and parsedData.note then
                    local name = RL.NormalizeName(playerKey:match("^[^-]+") or playerKey)
                    local key = string.lower(name)
                    
                    if not realmData.blacklist[key] then
                        local noteText = parsedData.note or "Импортировано из Elitist"
                        if parsedData.rater then
                            noteText = noteText .. " (от " .. parsedData.rater .. ")"
                        end
                        
                        realmData.blacklist[key] = {
                            name = name,
                            note = noteText,
                            addedDate = date("%d.%m.%Y %H:%M"),
                            addedBy = "Import (Elitist)",
                            guid = nil,
                            class = parsedData.class or nil,
                            race = nil,
                            level = parsedData.level or nil,
                            guild = nil,
                            faction = faction,
                            key = NormalizeKey(name)
                        }
                        imported = imported + 1
                    end
                end
            end
        end
    end
    
    RL:SaveSettings()
    
    if RL.BuildGUIDIndex then
        RL.BuildGUIDIndex()
    end
    
    print("|cFF00FF00ReputationList:|r Импортировано " .. imported .. " игроков из Elitist")
end

function RL:ImportFromIgnoreMore()
    if not IgM_SV or not IgM_SV.list then
        print(L["WH_W03"])
        return
    end

    local realmData = RL:GetRealmData()
    local imported = 0

    for realmKey, players in pairs(IgM_SV.list) do
        if type(players) == "table" then
            for playerName, playerData in pairs(players) do
                if type(playerName) == "string" and playerName ~= "" then
                    local name = RL.NormalizeName(playerName)
                    local key = string.lower(name)

                    if not realmData.blacklist[key] then
                        realmData.blacklist[key] = {
                            name = name,
                            note = "Импортировано из IgnoreMore",
                            addedDate = date("%d.%m.%Y %H:%M"),
                            addedBy = "Import (IgnoreMore)",
                            guid = nil,
                            class = nil,
                            race = nil,
                            level = nil,
                            guild = nil,
                            faction = nil,
                            key = NormalizeKey(name)
                        }
                        imported = imported + 1
                    end
                end
            end
        end
    end

    RL:SaveSettings()
    
    if RL.BuildGUIDIndex then
        RL.BuildGUIDIndex()
    end
    
    print("|cFF00FF00ReputationList:|r Импортировано " .. imported .. " игроков из IgnoreMore")
end

local function MigrateOldData()
    if not ReputationListDB then return end
    
    if ReputationListDB.blacklist or ReputationListDB.whitelist or ReputationListDB.notelist then
        print("|cFFFFAA00ReputationList:|r Обнаружены данные старой версии, выполняется миграция...")
        
        local currentRealm = GetCurrentRealm()
        
        local newDB = {
            realms = {},
            autoNotify = ReputationListDB.autoNotify,
            selfNotify = ReputationListDB.selfNotify,
            colorLFG = true,
            soundNotify = true,
            popupNotify = true,
            cardPositions = {}
        }
        
        newDB.realms[currentRealm] = {
            blacklist = ReputationListDB.blacklist or {},
            whitelist = ReputationListDB.whitelist or {},
            notelist = ReputationListDB.notelist or {}
        }
        
        ReputationListDB = newDB
        
        print(L["WH_W04"] .. currentRealm)
    end
end

function RL:Initialize()
	ReputationListDB = ReputationListDB or {}
    if not ReputationListDB.realms then
        local currentRealm = GetCurrentRealm()
        ReputationListDB = {
            realms = {
                [currentRealm] = {
                    blacklist = {},
                    whitelist = {},
                    notelist = {}
                }
            },
            autoNotify = true,
            selfNotify = true,
            colorLFG = true,
            soundNotify = true,
            popupNotify = true,
			blockInvites = false,
			blockTrade = false,
			filterMessages = false,
            cardPositions = {},
            initialized = true
        }
    else
        MigrateOldData()
        
        local currentRealm = GetCurrentRealm()
        ReputationListDB.realms = ReputationListDB.realms or {}
        
        if not ReputationListDB.realms[currentRealm] then
            ReputationListDB.realms[currentRealm] = {
                blacklist = {},
                whitelist = {},
                notelist = {}
            }
        end
        
        if not ReputationListDB.initialized then
            ReputationListDB.autoNotify = true
            ReputationListDB.selfNotify = true
            ReputationListDB.colorLFG = true
            ReputationListDB.soundNotify = true
            ReputationListDB.popupNotify = true
            ReputationListDB.blockInvites = false
            ReputationListDB.blockTrade = false
            ReputationListDB.filterMessages = false
            ReputationListDB.initialized = true
        end
        
		if not ReputationListDB.uiMode then
		ReputationListDB.uiMode = "full"
		end
        ReputationListDB.cardPositions = ReputationListDB.cardPositions or {}
    end
    
    RL.autoNotify = ReputationListDB.autoNotify
    RL.selfNotify = ReputationListDB.selfNotify
    RL.colorLFG = ReputationListDB.colorLFG
    RL.soundNotify = ReputationListDB.soundNotify
    RL.popupNotify = ReputationListDB.popupNotify
	RL.blockInvites = ReputationListDB.blockInvites
	RL.blockTrade = ReputationListDB.blockTrade
	RL.filterMessages = ReputationListDB.filterMessages
    
    local currentRealm = GetCurrentRealm()
    local realmData = ReputationListDB.realms[currentRealm]
    
    for stored, data in pairs(realmData.blacklist) do
        if data and not data.key then
            data.key = NormalizeKey(stored)
        end
    end
    for stored, data in pairs(realmData.whitelist) do
        if data and not data.key then
            data.key = NormalizeKey(stored)
        end
    end
    for stored, data in pairs(realmData.notelist) do
        if data and not data.key then
            data.key = NormalizeKey(stored)
        end
    end
    
    print("|cFF00FF00ReputationList|r v" .. RL.version .. L["UI_CB60"] .. currentRealm .. "|r")
    print(L["UI_CB61"])
end

function RL:SaveSettings()
    if ReputationListDB then
        ReputationListDB.autoNotify = RL.autoNotify
        ReputationListDB.selfNotify = RL.selfNotify
        ReputationListDB.colorLFG = RL.colorLFG
        ReputationListDB.soundNotify = RL.soundNotify
        ReputationListDB.popupNotify = RL.popupNotify
		ReputationListDB.blockInvites = RL.blockInvites
		ReputationListDB.blockTrade = RL.blockTrade
		ReputationListDB.filterMessages = RL.filterMessages
		if not ReputationListDB.uiMode then
            ReputationListDB.uiMode = "full"
        end
    end
end

function RL:GetRealmData(listType)
    local currentRealm = GetCurrentRealm()
    if not ReputationListDB.realms[currentRealm] then
        ReputationListDB.realms[currentRealm] = {
            blacklist = {},
            whitelist = {},
            notelist = {}
        }
    end
    
    if listType then
        return ReputationListDB.realms[currentRealm][listType]
    else
        return ReputationListDB.realms[currentRealm]
    end
end

SLASH_RLIST1 = "/rlist"
SLASH_RLIST2 = "/репутация"
SlashCmdList["RLIST"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local cmd = args[1] and string.lower(args[1]) or ""
    
    if cmd == "help" or cmd == "" then
        RL:ShowHelp()
    elseif cmd == "add" then
        RL:AddPlayer(args)
    elseif cmd == "remove" or cmd == "del" then
        RL:RemovePlayer(args[2], args[3])
    elseif cmd == "check" then
        RL:CheckPlayer(args[2])
    elseif cmd == "kick" then
        RL:KickPlayer(args[2])
    elseif cmd == "notify" then
        RL:ManualNotify()
    elseif cmd == "auto" then
        RL:ToggleAuto()
    elseif cmd == "self" then
        RL:ToggleSelfNotify()
    elseif cmd == "color" then
        RL:ToggleColorLFG()
    elseif cmd == "sound" then
        RL:ToggleSoundNotify()
    elseif cmd == "list" then
        RL:ShowList(args[2])
    elseif cmd == "realm" then
        print("|cFF00FF00ReputationList:|r Текущий realm: |cFFFFAA00" .. GetRealmName() .. "|r")
 elseif cmd == "import" then
        if args[2] == "blacklist" or args[2] == "bl" then
            RL:ImportFromBlacklist()
        elseif args[2] == "elitist" or args[2] == "eg" then
            RL:ImportFromElitist()
        elseif args[2] == "ignoremore" or args[2] == "im" then
            RL:ImportFromIgnoreMore()
        else
            print("|cFFFF0000ReputationList:|r Использование: /rlist import [blacklist|elitist|ignoremore]")
        end
    elseif cmd == "map" then
        if ReputationTrackerMinimapIcon then
            ReputationTrackerDB.hidden = false
            ReputationTrackerMinimapIcon:Show()
            if not ReputationTrackerDB.minimapAngle then
                ReputationTrackerDB.minimapAngle = 180
            end
            print(L["UI_CB82"])
        else
            print(L["UI_CB83"])
        end
    elseif cmd == "ui" then
        local ui = (RL.UI and RL.UI.ElvUI) or (RL.UI and RL.UI.Classic)
        if ui then
            if ui.Toggle then
                ui:Toggle()
            elseif ui.frame then
                if ui.frame:IsShown() then ui.frame:Hide() else ui.frame:Show() end
                if ui.UpdateList and ui.frame:IsShown() then pcall(function() ui:UpdateList() end) end
            end
        else
            print(L["WH_W05"])
        end
    else
        print(L["WH_W06"])
    end
end

function RL:ShowHelp()
	print(L["UI_CB62"])
	print(L["UI_CB63"])
	print(L["UI_CB64"])
	print(L["UI_CB65"])
	print(L["UI_CB66"])
	print(L["UI_CB66_1"])
	print(L["UI_CB67"])
	print(L["UI_CB68"])
	print(L["UI_CB69"])
	print(L["UI_CB70"])
	print(L["UI_CB71"])
	print(L["UI_CB72"])
	print(L["UI_CB73"])
	print(L["UI_CB74"])
	print(L["UI_CB75"])
	print(L["UI_CB76"])
	print(L["UI_CB77"])
	print(L["UI_CB85"])
end

function RL:FindPlayerInAllLists(playerName)
    if not playerName then return nil, nil, nil end
    
    local realmData = RL:GetRealmData()
    local key = string.lower(playerName)
    
    if realmData.blacklist[key] then
        return "blacklist", key, realmData.blacklist[key]
    end
    
    if realmData.whitelist[key] then
        return "whitelist", key, realmData.whitelist[key]
    end
    
    if realmData.notelist[key] then
        return "notelist", key, realmData.notelist[key]
    end
    
    return nil, nil, nil
end

function RL:AddPlayer(args)
    if #args < 3 then
        print("|cFFFF0000ReputationList:|r Использование: /rlist add [black/white/note] [Имя] [заметка]")
        return
    end
    
    local listType = string.lower(args[2])
    local playerName = args[3]
    
    local validName, err = RL.ValidatePlayerName(playerName)
    if not validName then
        print("|cFFFF0000ReputationList:|r " .. (err or L["INVALID_NAME"]))
        return
    end
    playerName = validName
    
    local note = table.concat({unpack(args,4)}, " ")
    
    note = RL.SanitizeString(note, 200)
    if note == "" then note = "Без заметки" end
    local targetList, listName
    local realmData = RL:GetRealmData()
    
    if listType == "black" or listType == "bl" then
        targetList = realmData.blacklist
        listName = "Blacklist"
    elseif listType == "white" or listType == "wl" then
        targetList = realmData.whitelist
        listName = "Whitelist"
    elseif listType == "note" or listType == "nl" then
        targetList = realmData.notelist
        listName = "Notelist"
    else
        print("|cFFFF0000ReputationList:|r " .. L["INVALID_LIST_TYPE"])
        return
    end
    
    local key = string.lower(playerName)
    
    local unit = nil
    if UnitExists("target") and UnitIsPlayer("target") then
        local targetName = UnitName("target")
        if targetName then
            targetName = RL.NormalizeName(targetName)
            if targetName == playerName then
                unit = "target"
            end
        end
    end
    
    if not unit then
        unit = FindPlayerInGroup(playerName)
    end
    
    local currentInfo = nil
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        currentInfo = GetPlayerInfo(unit)
    end
    
    local guidListType, guidKey, guidData, isNameChange = nil, nil, nil, false
    if currentInfo and currentInfo.guid then
        guidListType, guidKey, guidData, isNameChange = CheckGUIDConflict(playerName, currentInfo.guid, listName, realmData, note)
    end
    
    if isNameChange and guidData then
        if ApplyNameChange(guidListType, guidKey, guidData, playerName, key, listType, targetList, listName, realmData, currentInfo, note, false) then
            return
        end
    end
    
    local existingListType, existingKey, existingData = RL:FindPlayerInAllLists(playerName)
    
    local playerData = {
        name = playerName,
        note = note,
        addedDate = date("%d.%m.%Y %H:%M"),
        addedBy = UnitName("player"),
        guid = nil,
        class = nil,
        race = nil,
        level = nil,
        guild = nil,
        faction = nil,
        armoryLink = nil,
        key = key:gsub("[^%w]", ""):lower()
    }
    
    if existingData then
        local canCopyData = true
        
        if currentInfo and currentInfo.guid and existingData.guid then
            if currentInfo.guid ~= existingData.guid then
                canCopyData = false
                
                print(L["WH_W07"] .. playerName .. "'!")
                print(L["WH_W08"] .. existingData.guid .. "|r")
                print(L["WH_W09"] .. currentInfo.guid .. "|r")
                
                local oldKey = string.lower(playerName)
                local guidSuffix = existingData.guid:sub(-8)
                local unknownName = "Unknown-" .. guidSuffix
                local unknownKey = string.lower(unknownName)
                
                if existingListType then
                    local oldList = realmData[existingListType]
                    if oldList and oldList[oldKey] then
                        existingData.name = unknownName
                        existingData.key = NormalizeKey(unknownName)
                        
                        oldList[unknownKey] = existingData
                        oldList[oldKey] = nil
                        
                        print(L["WH_W10"] .. unknownName .. "|r")
                        print(L["WH_W11"])
                        print(L["WH_W12"] .. playerName .. L["WH_W13"])
                        
                        RL.InvalidateCache()
                        RL:SaveSettings()
                    end
                end
            end
        end
        
        if canCopyData then
            playerData.guid = existingData.guid
            playerData.class = existingData.class
            playerData.race = existingData.race
            playerData.level = existingData.level
            playerData.guild = existingData.guild
            playerData.faction = existingData.faction
            playerData.armoryLink = existingData.armoryLink
            
            if existingListType and existingListType ~= listType then
                local oldList = realmData[existingListType]
                if oldList then
                    oldList[existingKey] = nil
                end
            end
        end
    end
    
    if currentInfo then
        if currentInfo.guid and not playerData.guid then
            playerData.guid = currentInfo.guid
        end
        if currentInfo.class then playerData.class = currentInfo.class end
        if currentInfo.race then playerData.race = currentInfo.race end
        if currentInfo.level then playerData.level = currentInfo.level end
        if currentInfo.guild then playerData.guild = currentInfo.guild end
        if currentInfo.faction then playerData.faction = currentInfo.faction end
    end
    
    targetList[key] = playerData
    
    if not self.batchMode then
        RL.InvalidateCache()
        RL:SaveSettings()
        print(L["WH_W14"] .. playerName .. L["WH_W15"] .. listName)
    end
end

function RL:AddPlayerDirect(playerName, listType, note, unit, cachedPlayerData)
    if not playerName or playerName == "" then
        print("|cFFFF0000ReputationList:|r " .. L["NO_PLAYER_NAME"])
        return
    end
    
    local validName, err = RL.ValidatePlayerName(playerName)
    if not validName then
        print("|cFFFF0000ReputationList:|r " .. (err or L["INVALID_NAME"]))
        return
    end
    playerName = validName
    
    note = RL.SanitizeString(note or L["UI_F_N"], 200)
    
    local targetList, listName
    local realmData = RL:GetRealmData()
    
    if listType == "blacklist" then
        targetList = realmData.blacklist
        listName = "Blacklist"
    elseif listType == "whitelist" then
        targetList = realmData.whitelist
        listName = "Whitelist"
    elseif listType == "notelist" then
        targetList = realmData.notelist
        listName = "Notelist"
    else
        print("|cFFFF0000ReputationList:|r " .. L["INVALID_LIST_TYPE"])
        return
    end
    
    local key = string.lower(playerName)
    
    if not unit or not UnitExists(unit) then
        unit = FindPlayerInGroup(playerName)
    end
    
    local currentInfo = nil
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        currentInfo = GetPlayerInfo(unit)
    end
    
    local guidListType, guidKey, guidData, isNameChange = nil, nil, nil, false
    if currentInfo and currentInfo.guid then
        guidListType, guidKey, guidData, isNameChange = CheckGUIDConflict(playerName, currentInfo.guid, listName, realmData, note)
    end
    
    if isNameChange and guidData then
        if ApplyNameChange(guidListType, guidKey, guidData, playerName, key, listType, targetList, listName, realmData, currentInfo, note, self.batchMode) then
            return
        end
    end
    
    local existingListType, existingKey, existingData = RL:FindPlayerInAllLists(playerName)
    
    local playerData = {
        name = playerName,
        note = note,
        addedDate = date("%d.%m.%Y %H:%M"),
        addedBy = UnitName("player"),
        guid = nil,
        class = nil,
        race = nil,
        level = nil,
        guild = nil,
        faction = nil,
        armoryLink = nil,
        key = key:gsub("[^%w]", ""):lower()
    }
    
    if existingData then
        local canCopyData = true
        
        if currentInfo and currentInfo.guid and existingData.guid then
            if currentInfo.guid ~= existingData.guid then
                canCopyData = false
                print(L["WEM01"] .. playerName .. "'")
                print(L["WEM02"] .. existingListType .. L["WEM03"] .. listName .. "|r")
            end
        end
        
        if canCopyData then
            playerData.guid = existingData.guid
            playerData.class = existingData.class
            playerData.race = existingData.race
            playerData.level = existingData.level
            playerData.guild = existingData.guild
            playerData.faction = existingData.faction
            
            playerData.armoryLink = existingData.armoryLink
            if existingListType and existingListType ~= listType then
                local oldList = realmData[existingListType]
                if oldList then
                    oldList[existingKey] = nil
                end
            end
        end
    end
    
    if currentInfo then
        if currentInfo.guid then playerData.guid = currentInfo.guid end
        if currentInfo.class then playerData.class = currentInfo.class end
        if currentInfo.race then playerData.race = currentInfo.race end
        if currentInfo.level then playerData.level = currentInfo.level end
        if currentInfo.guild then playerData.guild = currentInfo.guild end
        if currentInfo.faction then playerData.faction = currentInfo.faction end
    elseif cachedPlayerData then
        if cachedPlayerData.guid then playerData.guid = cachedPlayerData.guid end
        if cachedPlayerData.class then playerData.class = cachedPlayerData.class end
        if cachedPlayerData.race then playerData.race = cachedPlayerData.race end
        if cachedPlayerData.level then playerData.level = cachedPlayerData.level end
        if cachedPlayerData.guild then playerData.guild = cachedPlayerData.guild end
        if cachedPlayerData.faction then playerData.faction = cachedPlayerData.faction end
    end
    
    targetList[key] = playerData
    
    if playerData.guid and RL.UpdateGUIDIndex then
        RL.UpdateGUIDIndex(playerData.guid, listType, key)
    end
    
    if not self.batchMode then
        RL.InvalidateCache()
        RL:SaveSettings()
        print(L["WH_D11"] .. playerName .. L["WH_W15"] .. listName)
    end
end

function RL:AddPlayersBatch(players, listType)
    if not players or type(players) ~= "table" then
        return false
    end
    
    listType = listType or "blacklist"
    
    self.batchMode = true
    
    local added = 0
    for _, playerData in ipairs(players) do
        local name = playerData.name or playerData
        local note = playerData.note or L["UI_F_N"]
        local guid = playerData.guid
        
        if self:AddPlayerDirect(name, listType, note) then
            added = added + 1
        end
    end
    
    self.batchMode = false
    
    if RL.BuildGUIDIndex then
        RL.BuildGUIDIndex()
    end
    if self.InvalidateCache then
        self.InvalidateCache()
    end
    
    if self.SaveSettings then
        self:SaveSettings()
    end
    
    
    print(string.format("|cFF00FF00[RepList]|r " .. L["PLAYERS_ADDED"], added, listType))
    return true
end

function RL:RemovePlayer(listType, playerName)
    if not listType or not playerName then
        print("|cFFFF0000ReputationList:|r " .. L["REMOVE_USAGE"])
        return
    end
    
    listType = string.lower(listType)
    playerName = RL.NormalizeName(playerName)
    local searchKey = string.lower(playerName)
    
    local targetList, listName
    local realmData = RL:GetRealmData()
    
    if listType == "black" or listType == "bl" then
        targetList = realmData.blacklist
        listName = "Blacklist"
    elseif listType == "white" or listType == "wl" then
        targetList = realmData.whitelist
        listName = "Whitelist"
    elseif listType == "note" or listType == "nl" then
        targetList = realmData.notelist
        listName = "Notelist"
    else
        print("|cFFFF0000ReputationList:|r " .. L["INVALID_LIST_TYPE"])
        return
    end
    
    if targetList[searchKey] then
        local playerData = targetList[searchKey]
        
        if playerData.guid and RL.RemoveFromGUIDIndex then
            RL.RemoveFromGUIDIndex(playerData.guid)
        end
        
        targetList[searchKey] = nil
        
        
        RL.InvalidateCache()
        
        print(L["WH_D11"] .. playerName .. L["WEM04"] .. listName)
    else
        print(L["WH_D11"] .. playerName .. L["WEM05"] .. listName)
    end
end

function RL:KickPlayer(target)
    local playerName
    
    if target and target ~= "" then
        if target:lower() == "target" then
            playerName = UnitName("target")
            if not playerName or not UnitIsPlayer("target") then
                print(L["WEM06"])
                return
            end
        else
            playerName = target
        end
    else
        playerName = UnitName("target")
        if not playerName or not UnitIsPlayer("target") then
            print(L["WEM07"])
            return
        end
    end
    
    playerName = RL.NormalizeName(playerName)
    
    local foundInGroup = false
    if UnitInRaid("player") then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name and RL.NormalizeName(name):lower() == playerName:lower() then
                foundInGroup = true
                break
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name and RL.NormalizeName(name):lower() == playerName:lower() then
                foundInGroup = true
                break
            end
        end
    end
    
    if not foundInGroup then
        print("|cFFFF0000ReputationList:|r " .. playerName .. L["WEM08"])
        return
    end
    
    RL:AddPlayerDirect(playerName, "blacklist", L["WEM09"], "target")
    
    local chatType = "SAY"
    if UnitInRaid("player") then
        chatType = "RAID"
    elseif GetNumPartyMembers() > 0 then
        chatType = "PARTY"
    end
    SendChatMessage(playerName .. L["BLACKLIST_DAL"], chatType)
    
    if UnitInRaid("player") then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name and RL.NormalizeName(name):lower() == playerName:lower() then
                UninviteUnit(name)
                print("|cFFFF0000ReputationList:|r " .. playerName .. L["WEM10"])
                return
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name and RL.NormalizeName(name):lower() == playerName:lower() then
                UninviteUnit(name)
                print("|cFFFF0000ReputationList:|r " .. playerName .. L["WEM10"])
                return
            end
        end
    end
end

function RL:CheckPlayer(playerName)
    if not playerName then
        print(L["WEM11"])
        return
    end
    
    playerName = RL.NormalizeName(playerName)
    local found = false
    
    local data, key = RL.FastFind(playerName, "blacklist", "name")
    if data then
        print("|cFFFF0000Blacklist:|r " .. playerName .. " - " .. (data.note or ""))
        found = true
    end
    
    data, key = RL.FastFind(playerName, "whitelist", "name")
    if data then
        print("|cFF00FF00Whitelist:|r " .. playerName .. " - " .. (data.note or ""))
        found = true
    end
    
    data, key = RL.FastFind(playerName, "notelist", "name")
    if data then
        print("|cFFFFAA00Notelist:|r " .. playerName .. " - " .. (data.note or ""))
        found = true
    end
    
    if not found then
        print(L["WH_W14"] .. playerName .. L["WEM12"])
    end
end

function RL:GetPlayerTooltipInfo(playerName)
    if not playerName then return nil, nil end
    
    playerName = RL.NormalizeName(playerName)
    
    local data = RL.FastFind(playerName, "blacklist", "name")
    if data then
        return "blacklist", data.note or ""
    end
    
    data = RL.FastFind(playerName, "whitelist", "name")
    if data then
        return "whitelist", data.note or ""
    end
    
    data = RL.FastFind(playerName, "notelist", "name")
    if data then
        return "notelist", data.note or ""
    end
    
    return nil, nil
end

function RL:ShowList(listType)
    if not listType then
        print(L["WEM13"])
        return
    end
    
    listType = string.lower(listType)
    local realmData = RL:GetRealmData()
    local targetList, listName, color
    
    if listType == "black" or listType == "bl" then
        targetList = realmData.blacklist
        listName = "Blacklist"
        color = "|cFFFF0000"
    elseif listType == "white" or listType == "wl" then
        targetList = realmData.whitelist
        listName = "Whitelist"
        color = "|cFF00FF00"
    elseif listType == "note" or listType == "nl" then
        targetList = realmData.notelist
        listName = "Notelist"
        color = "|cFFFFAA00"
    else
        print("|cFFFF0000ReputationList:|r " .. L["INVALID_LIST_TYPE"])
        return
    end
    
    print(color .. "=== " .. listName .. " ===|r")
    local count = 0
    for name, data in pairs(targetList) do
        count = count + 1
        print(color .. name .. "|r - " .. (data and data.note or ""))
    end
    
    if count == 0 then
        print(L["WEM15"])
    else
        print(L["WEM14"] .. count .. "|r")
    end
end

function RL:ToggleAuto()
    RL.autoNotify = not RL.autoNotify
    ReputationListDB.autoNotify = RL.autoNotify
    if RL.autoNotify then
        print(L["WEM16"])
    else
        print(L["WEM17"])
    end
end

function RL:ToggleSelfNotify()
    RL.selfNotify = not RL.selfNotify
    ReputationListDB.selfNotify = RL.selfNotify
    if RL.selfNotify then
        print(L["WEM18"])
    else
        print(L["WEM19"])
    end
end

function RL:ToggleColorLFG()
    RL.colorLFG = not RL.colorLFG
    ReputationListDB.colorLFG = RL.colorLFG
    if RL.colorLFG then
        print(L["WEM20"])
    else
        print(L["WEM21"])
    end
end

function RL:ToggleSoundNotify()
    RL.soundNotify = not RL.soundNotify
    RL.popupNotify = RL.soundNotify
    ReputationListDB.soundNotify = RL.soundNotify
    ReputationListDB.popupNotify = RL.popupNotify
    
    if RL.soundNotify then
        print(L["WEM22"])
    else
        print(L["WEM23"])
    end
end

function RL:CheckAndUpdatePlayer(name, guid, unit)
    if not name or not guid then return end
    
    local normName = RL.NormalizeName(name)
    local searchKey = string.lower(normName)
    local realmData = RL:GetRealmData()
    
    local updated = false
    
    for listType, list in pairs({blacklist = realmData.blacklist, whitelist = realmData.whitelist, notelist = realmData.notelist}) do
        
        local foundKey, foundData = FindEntryByGUID(list, guid)
        
        if foundKey and foundData then

            if foundKey ~= searchKey then

                print("|cFFFFAA00ReputationList:|r" .. L["NICK_CHANGE_DETECTED"] .. (foundData.name or foundKey) .. " -> " .. normName)
                
                list[searchKey] = foundData
                list[foundKey] = nil
                
                foundData.name = normName
                foundData.key = NormalizeKey(normName)
                updated = true
            end
            
            if unit and UnitExists(unit) and UnitIsPlayer(unit) then
                local info = GetPlayerInfo(unit)

                if info.class and info.class ~= foundData.class then 
                    print("|cFFFFAA00ReputationList:|r " .. normName .. L["CLASS_CHANGED"] .. (foundData.class or "?") .. " -> " .. info.class)
                    foundData.class = info.class
                    updated = true 
                end
                if info.race and info.race ~= foundData.race then 
                    print("|cFFFFAA00ReputationList:|r " .. normName .. L["RACE_CHANGED"] .. (foundData.race or "?") .. " -> " .. info.race)
                    foundData.race = info.race
                    updated = true 
                end
                if info.level and info.level ~= foundData.level then foundData.level = info.level; updated = true end
                if info.guild and info.guild ~= foundData.guild then foundData.guild = info.guild; updated = true end
                if info.faction and info.faction ~= foundData.faction then 
                    print("|cFFFFAA00ReputationList:|r " .. normName .. L["FACTION_CHANGED"] .. (foundData.faction or "?") .. " -> " .. info.faction)
                    foundData.faction = info.faction
                    updated = true 
                end
            end
            
            if updated then
                RL.InvalidateCache()
                RL:SaveSettings()
                if UI and UI.RefreshList then
                    UI:RefreshList()
                end
            end
            
            return true
        end
        
        local data = list[searchKey]
        if data then
            if data.name ~= normName then
                data.name = normName
                updated = true
            end
            
            if not data.guid and guid then
                data.guid = guid
                updated = true
            end
            
            if unit and UnitExists(unit) and UnitIsPlayer(unit) then
                local info = GetPlayerInfo(unit)
                
                if data.guid and info.guid and info.guid ~= data.guid then

                    print(L["INFO_R01"] .. normName .. "'!")
                    print(L["INFO_R02"] .. data.guid .. "|r")
                    print(L["INFO_R03"] .. info.guid .. "|r")
                    print(L["INFO_R04"])
                    

                    return false
                end
                
                if info.class and info.class ~= data.class then data.class = info.class; updated = true end
                if info.race and info.race ~= data.race then data.race = info.race; updated = true end
                if info.level and info.level ~= data.level then data.level = info.level; updated = true end
                if info.guild and info.guild ~= data.guild then data.guild = info.guild; updated = true end
                if info.faction and info.faction ~= data.faction then data.faction = info.faction; updated = true end
            end
            
            if updated then
                RL.InvalidateCache()
                RL:SaveSettings()
                if UI and UI.RefreshList then
                    UI:RefreshList()
                end
            end
            
            return true
        end
    end
    
    return false
end

function RL:ManualNotify()
    RL.notifiedPlayers = {}
    RL.lastRaidRoster = {}
    RL:CheckGroupMembers()
end

function RL:CheckGroupMembers()
    local numMembers = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    if numMembers == 0 then
        RL.notifiedPlayers = {}
        RL.lastRaidRoster = {}
        return
    end
    
    local realmData = RL:GetRealmData()
    local isRaid = GetNumRaidMembers() > 0
    
    local currentRoster = {}
	for i = 1, (isRaid and numMembers or numMembers + 1) do
		local unit
		if isRaid then
			unit = "raid" .. i
		else
			unit = (i == 1) and "player" or ("party" .. (i-1))
		end
    
		local guid = UnitGUID(unit)
		if guid then
			guid = RL.NormalizeGUID(guid)
			if guid then
				currentRoster[guid] = true
			end
		end
    
		local name = UnitName(unit)
		if name then
			local normName = RL.NormalizeName(name)
			local searchKey = string.lower(normName)
			currentRoster[searchKey] = true
		end
	end
    
local newPlayers = {}
for key in pairs(currentRoster) do
    if not RL.lastRaidRoster[key] then
        newPlayers[key] = true
    end
end
    
    RL.lastRaidRoster = currentRoster
    
    for i = 1, (isRaid and numMembers or numMembers + 1) do
        local name, unit
        if isRaid then
            name = select(1, GetRaidRosterInfo(i))
            unit = "raid" .. i
        else
            if i == 1 then
                name = UnitName("player")
                unit = "player"
            else
                name = UnitName("party" .. (i-1))
                unit = "party" .. (i-1)
            end
        end
        
        if name then
            local normName = RL.NormalizeName(name)
            local searchKey = string.lower(normName)
            local guid = UnitGUID(unit)
            
            if guid then
                guid = RL.NormalizeGUID(guid)
            end
            
            if guid then
                RL:CheckAndUpdatePlayer(normName, guid, unit)
            end
            
            local isNewPlayer = (guid and newPlayers[guid]) or newPlayers[searchKey]
			local alreadyNotified = (guid and RL.notifiedPlayers[guid]) or RL.notifiedPlayers[searchKey]

			if isNewPlayer and not alreadyNotified then
				if guid then
					RL.notifiedPlayers[guid] = true
				end
				RL.notifiedPlayers[searchKey] = true
    
				local data = nil
				if guid then
					local foundKey, foundData = FindEntryByGUID(realmData.blacklist, guid)
					if foundKey and foundData then
						data = foundData
					end
				end
    
				if not data then
					data = realmData.blacklist[searchKey]
				end
                
                if data then
                    local message = "Blacklist: " .. normName .. " - " .. data.note
                    if RL.selfNotify then
                        SendChatMessage(message, "WHISPER", nil, UnitName("player"))
                    end
                    if RL.autoNotify then
                        SendChatMessage(message, isRaid and "RAID" or "PARTY")
                    end
                    
                    if RL.popupNotify and not UnitAffectingCombat("player") then
                        local cardData = data
                        if unit and UnitExists(unit) and UnitIsPlayer(unit) then
                            local info = GetPlayerInfo(unit)
                            cardData = {
                                name = data.name or normName,
                                note = data.note,
                                guid = info.guid or data.guid,
                                class = info.class or data.class,
                                race = info.race or data.race,
                                level = info.level or data.level,
                                guild = info.guild or data.guild,
                                faction = info.faction or data.faction
                            }
                        end
                        if RL.ShowPlayerCard and RL.CanShowPopupCard(normName) then
                            RL:ShowPlayerCard(normName, cardData)
                        end
                    end
                end
                      
                local isIgnored, exactName = RL.IsInBlizzardIgnore(normName)
                if isIgnored then
                    local message = "Blacklist: " .. (exactName or normName) .. L["BLACKLIST_BL2"]
                    if RL.selfNotify then
                        SendChatMessage(message, "WHISPER", nil, UnitName("player"))
                    end
                    if RL.autoNotify then
                        SendChatMessage(message, isRaid and "RAID" or "PARTY")
                    end
                end
            end
        end
    end
end

function RL:KickFromGroup(playerName, note)
    if not playerName then return end
    
    local normName = RL.NormalizeName(playerName)
    if not normName then return end
    
    local isLeader = false
    if GetNumRaidMembers() > 0 then
        isLeader = (UnitIsRaidOfficer("player") or IsRaidLeader())
    elseif GetNumPartyMembers() > 0 then
        isLeader = IsPartyLeader()
    end
    
    if not isLeader then
        print("|cFFFF0000ReputationList:|r " .. L["NOT_LEADER"])
        return
    end
    
    if InCombatLockdown() then
        print("|cFFFF0000ReputationList:|r " .. L["CANNOT_KICK_COMBAT"])
        return
    end
    
    if not note or note == "" then note = L["BLACKLIST_DAL"] end
    
    local unit = FindPlayerInGroup(normName)
    RL:AddPlayerDirect(normName, "blacklist", note, unit)
    
    local chatType = GetNumRaidMembers() > 0 and "RAID" or "PARTY"
    local message = "Blacklist: " .. normName .. ", " .. L["BLACKLIST_DAL"]
    SendChatMessage(message, chatType)
    
    UIErrorsFrame:AddMessage(normName .. " - " .. L["BLACKLIST_DAL"], 1.0, 0.0, 0.0, 1.0, 5)
    
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name = select(1, GetRaidRosterInfo(i))
            if name then
                local checkName = RL.NormalizeName(name)
                if checkName == normName then
                    SetRaidRosterSelection(i)
                    UninviteUnit("raid" .. i)
                    print(L["WEM24"] .. name .. L["WEM26"] .. i .. ")")
                    break
                end
            end
        end
    else
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                local checkName = RL.NormalizeName(name)
                if checkName == normName then
                    UninviteUnit("party" .. i)
                    print(L["WEM24"] .. name .. L["WEM25"])
                    break
                end
            end
        end
    end
end

local function BlockInvites(name)
    if not name then return false end
    
    if not ReputationListDB.blockInvites then
        return false
    end
    
    local normName = RL.NormalizeName(name)
    local realmData = RL:GetRealmData()
    if not realmData then return false end
    
    local key = string.lower(normName)
    
    if realmData.blacklist[key] then
        DeclineGroup()
        StaticPopupSpecial_Hide(StaticPopup1)
        
        print("|cFFFF0000[ReputationList]|r" .. L["BLOCKED_INVITE"] .. normName)
        
        return true
    end
    
    return false
end

function RL:CreatePlayerCardFrame()
    local f = CreateFrame("Frame", "RepListPlayerCard", UIParent)
    f:SetSize(400, 350)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)

    if ReputationListDB.cardPositions and ReputationListDB.cardPositions.x then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ReputationListDB.cardPositions.x, ReputationListDB.cardPositions.y)
    else
        f:SetPoint("CENTER")
    end

    local useElvUI = IsAddOnLoaded("ElvUI")
    local E, S
    if useElvUI then
        if _G["ElvUI"] then
            E = _G["ElvUI"][1]
            if E then
                S = E:GetModule('Skins')
            end
        end
        if not E or not S then
            useElvUI = false
        end
    end

    if useElvUI then
        f:SetTemplate("Transparent")
        f:CreateShadow()
    else
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        f:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    end

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetLeft(), self:GetTop()
        ReputationListDB.cardPositions = ReputationListDB.cardPositions or {}
        ReputationListDB.cardPositions.x = x
        ReputationListDB.cardPositions.y = y
    end)

    f.title = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.title:FontTemplate(nil, 16, "OUTLINE")
    else
        f.title:SetFontObject("GameFontNormalLarge")
    end
    f.title:SetPoint("TOP", 0, -15)
    f.title:SetTextColor(1, 0, 0)
    f.title:SetText(L["UI_POP1"] .. "BLACKLIST")

    f.factionLogo = f:CreateTexture(nil, "ARTWORK")
    f.factionLogo:SetSize(80, 80)
    f.factionLogo:SetPoint("TOPLEFT", 20, -50)

    local startY = -50
    local leftX = 110

    f.nameLabel = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.nameLabel:FontTemplate()
    else
        f.nameLabel:SetFontObject("GameFontHighlight")
    end
    f.nameLabel:SetPoint("TOPLEFT", leftX, startY)
    f.nameLabel:SetText(L["UI_LBL_NM"])

    f.nameValue = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.nameValue:FontTemplate()
    else
        f.nameValue:SetFontObject("GameFontNormal")
    end
    f.nameValue:SetPoint("LEFT", f.nameLabel, "RIGHT", 5, 0)
    f.nameValue:SetWidth(200)
    f.nameValue:SetJustifyH("LEFT")

    f.classLabel = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.classLabel:FontTemplate()
    else
        f.classLabel:SetFontObject("GameFontHighlight")
    end
    f.classLabel:SetPoint("TOPLEFT", leftX, startY - 25)
    f.classLabel:SetText(L["UI_LBL_CL"])

    f.classValue = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.classValue:FontTemplate()
    else
        f.classValue:SetFontObject("GameFontNormal")
    end
    f.classValue:SetPoint("LEFT", f.classLabel, "RIGHT", 5, 0)

    f.raceLabel = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.raceLabel:FontTemplate()
    else
        f.raceLabel:SetFontObject("GameFontHighlight")
    end
    f.raceLabel:SetPoint("TOPLEFT", leftX, startY - 45)
    f.raceLabel:SetText(L["UI_LBL_RC"])

    f.raceValue = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.raceValue:FontTemplate()
    else
        f.raceValue:SetFontObject("GameFontNormal")
    end
    f.raceValue:SetPoint("LEFT", f.raceLabel, "RIGHT", 5, 0)

    f.levelLabel = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.levelLabel:FontTemplate()
    else
        f.levelLabel:SetFontObject("GameFontHighlight")
    end
    f.levelLabel:SetPoint("TOPLEFT", leftX, startY - 65)
    f.levelLabel:SetText(L["UI_CB84"])

    f.levelValue = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.levelValue:FontTemplate()
    else
        f.levelValue:SetFontObject("GameFontNormal")
    end
    f.levelValue:SetPoint("LEFT", f.levelLabel, "RIGHT", 5, 0)

    f.guildLabel = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.guildLabel:FontTemplate()
    else
        f.guildLabel:SetFontObject("GameFontHighlight")
    end
    f.guildLabel:SetPoint("TOPLEFT", leftX, startY - 85)
    f.guildLabel:SetText(L["UI_LBL_GLD"])

    f.guildValue = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.guildValue:FontTemplate()
    else
        f.guildValue:SetFontObject("GameFontNormal")
    end
    f.guildValue:SetPoint("LEFT", f.guildLabel, "RIGHT", 5, 0)
    f.guildValue:SetWidth(200)
    f.guildValue:SetJustifyH("LEFT")

    f.guidLabel = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.guidLabel:FontTemplate(nil, 11)
    else
        f.guidLabel:SetFontObject("GameFontHighlightSmall")
    end
    f.guidLabel:SetPoint("TOPLEFT", 20, startY - 110)
    f.guidLabel:SetText("|cFFFFFF00GUID:|r")

    f.guidValue = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.guidValue:FontTemplate(nil, 11)
    else
        f.guidValue:SetFontObject("GameFontNormalSmall")
    end
    f.guidValue:SetPoint("LEFT", f.guidLabel, "RIGHT", 5, 0)
    f.guidValue:SetWidth(300)
    f.guidValue:SetJustifyH("LEFT")

    f.noteLabel = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.noteLabel:FontTemplate()
    else
        f.noteLabel:SetFontObject("GameFontHighlight")
    end
    f.noteLabel:SetPoint("TOPLEFT", 20, -175)
    f.noteLabel:SetText(L["UI_LBL_NT"])

    f.noteText = f:CreateFontString(nil, "OVERLAY")
    if useElvUI then
        f.noteText:FontTemplate()
    else
        f.noteText:SetFontObject("GameFontNormal")
    end
    f.noteText:SetPoint("TOPLEFT", 20, -195)
    f.noteText:SetPoint("BOTTOMRIGHT", -20, 40)
    f.noteText:SetJustifyH("LEFT")
    f.noteText:SetJustifyV("TOP")
    f.noteText:SetTextColor(1, 1, 0.5)

    local closeBtn = CreateFrame("Button", nil, f, useElvUI and nil or "GameMenuButtonTemplate")
    closeBtn:SetSize(100, 25)
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetText(L["UI_CLOSE"])
    if useElvUI and S then
        S:HandleButton(closeBtn)
    end
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        if f.currentPlayer then
            RL.shownCards[f.currentPlayer] = nil
        end
    end)

    RL.playerCardFrame = f
    f:Hide()
end

function RL:UpdatePlayerCard(playerName, playerData)
    local f = RL.playerCardFrame
    if not f then return end

    if not playerData then
        playerData = {
            name = playerName,
            note = "Нет данных",
            guid = nil,
            class = nil,
            race = nil,
            level = nil,
            guild = nil,
            faction = nil
        }
    end

    if not playerData.faction and playerData.race then
        playerData.faction = GetFactionByRace(playerData.race)
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
    if playerData.class and classColors[playerData.class] then
        classColor = classColors[playerData.class]
    end

    if playerData.faction == "Alliance" then
        f.factionLogo:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
    elseif playerData.faction == "Horde" then
        f.factionLogo:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
    else
        f.factionLogo:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    f.nameValue:SetText(playerData.name or L["UI_F_UN"])
    f.nameValue:SetTextColor(classColor.r, classColor.g, classColor.b)
    f.classValue:SetText(playerData.class or L["UI_F_UNO"])
    f.raceValue:SetText(playerData.race or L["UI_F_UN2"])
    f.levelValue:SetText(tostring(playerData.level or "?"))
    f.guildValue:SetText(playerData.guild or L["NO"])
    f.guidValue:SetText(playerData.guid or L["UI_F_V"])

    local noteText = playerData.note or L["UI_F_N"]
    f.noteText:SetText(noteText)
	
local listType = nil
local realmData = RL:GetRealmData()
local key = string.lower(playerName or "")

if realmData.blacklist[key] then
    listType = "blacklist"
    f.title:SetText(L["UI_POP1"] .. "BLACKLIST")
    f.title:SetTextColor(1, 0, 0)
    if not useElvUI then
        f:SetBackdropBorderColor(0.8, 0.1, 0.1, 1)
    end
elseif realmData.whitelist[key] then
    listType = "whitelist"
    f.title:SetText(L["UI_POP2"] .. "WHITELIST")
    f.title:SetTextColor(0, 1, 0)
    if not useElvUI then
        f:SetBackdropBorderColor(0.1, 0.8, 0.1, 1)
    end
elseif realmData.notelist[key] then
    listType = "notelist"
    f.title:SetText(L["UI_POP3"] .. "NOTELIST")
    f.title:SetTextColor(1, 0.84, 0)
    if not useElvUI then
        f:SetBackdropBorderColor(1, 0.84, 0, 1)
    end
end

    f.currentPlayer = string.lower(playerName or "")
end

function RL:ShowPlayerCard(playerName, playerData, forceShow)
    if not forceShow and not RL.popupNotify then
        return
    end
    
    if UnitAffectingCombat("player") then
        table.insert(RL.alertQueue, {name = playerName, data = playerData})
        return
    end
    
    local now = GetTime()
    local key = string.lower(playerName or "")
    
    if not forceShow then
        if RL.shownCards[key] then
            return
        end
        
        if RL.alertCooldowns[key] and (now - RL.alertCooldowns[key]) < 5 then
            return
        end
    end
    
    RL.alertCooldowns[key] = now
    RL.shownCards[key] = true
    
    if not RL.playerCardFrame then
        RL:CreatePlayerCardFrame()
    end
    
    RL:UpdatePlayerCard(playerName, playerData)
    
    if RL.soundNotify then
        PlaySound("TellMessage")
    end
    
    RL.playerCardFrame:Show()
end

function RL:ProcessAlertQueue()
    if #RL.alertQueue > 0 and not UnitAffectingCombat("player") then
        local alert = table.remove(RL.alertQueue, 1)
        if alert then
            RL:ShowPlayerCard(alert.name, alert.data)
        end
    end
end

function RL:CheckTargetUnit()
    if UnitIsPlayer("target") and UnitExists("target") then
        local name = UnitName("target")
        local guid = UnitGUID("target")
        if name and guid then
            guid = RL.NormalizeGUID(guid)
            if guid then
                local normName = RL.NormalizeName(name)
                RL:CheckAndUpdatePlayer(normName, guid, "target")
                RL:ShowTooltipInfo(normName)
            end
        end
    end
end

function RL:ShowTooltipInfo(playerName)
    local realmData = RL:GetRealmData()
    local key = string.lower(playerName)
    local data = realmData.blacklist[key]
              or realmData.whitelist[key]
              or realmData.notelist[key]
    
    if data then
        if realmData.blacklist[key] then
            GameTooltip:AddLine("|cFFFF0000Blacklist:|r " .. data.note, 1, 1, 1)
        elseif realmData.whitelist[key] then
            GameTooltip:AddLine("|cFF00FF00Whitelist:|r " .. data.note, 1, 1, 1)
        elseif realmData.notelist[key] then
            GameTooltip:AddLine("|cFFFFAA00Notelist:|r " .. data.note, 1, 1, 1)
        end
        GameTooltip:Show()
    else
        local isIgnored = RL.IsInBlizzardIgnore(playerName)
        if isIgnored then
            GameTooltip:AddLine(L["WEM27"], 1, 1, 1)
            GameTooltip:Show()
        end
    end
end

hooksecurefunc("UnitPopup_ShowMenu", function(dropdownMenu, which, unit, name, userData)
    if UIDROPDOWNMENU_MENU_LEVEL ~= 1 then return end
    
    local isPlayer = false
    local playerName = nil
    local isChatContext = false
    
  
    if unit and UnitExists(unit) then
        local _, unitClass = UnitClass(unit)
        local _, unitRace = UnitRace(unit)
        
        if unitClass and unitRace then
            isPlayer = true
            playerName = UnitName(unit)
        end
    elseif name and name ~= "" and not name:match("^%d") then
        isPlayer = true
        playerName = name
        isChatContext = true
    end
    
    if not isPlayer or not playerName then return end
    
    local normalizedName = RL.NormalizeName(playerName)
    
    local info = UIDropDownMenu_CreateInfo()
    info.text = ""
    info.notCheckable = true
    info.isNotRadio = true
    info.disabled = true
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
    
    info = UIDropDownMenu_CreateInfo()
    info.text = "ReputationList"
    info.isTitle = true
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
    
    info = UIDropDownMenu_CreateInfo()
    info.text = L["UI_CB78"]
    info.notCheckable = true
    info.func = function()
        if isChatContext then
            StaticPopup_Show("REPUTATION_ADD_PROMPT_CHAT", normalizedName, nil, {name = normalizedName, listType = "blacklist"})
        else
            StaticPopup_Show("REPUTATION_ADD_PROMPT", normalizedName, nil, {unit = unit, listType = "blacklist"})
        end
    end
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
    
    info = UIDropDownMenu_CreateInfo()
    info.text = L["UI_CB79"]
    info.notCheckable = true
    info.func = function()
        if isChatContext then
            StaticPopup_Show("REPUTATION_ADD_PROMPT_CHAT", normalizedName, nil, {name = normalizedName, listType = "whitelist"})
        else
            StaticPopup_Show("REPUTATION_ADD_PROMPT", normalizedName, nil, {unit = unit, listType = "whitelist"})
        end
    end
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
    
    info = UIDropDownMenu_CreateInfo()
    info.text = L["UI_CB80"]
    info.notCheckable = true
    info.func = function()
        if isChatContext then
            StaticPopup_Show("REPUTATION_ADD_PROMPT_CHAT", normalizedName, nil, {name = normalizedName, listType = "notelist"})
        else
            StaticPopup_Show("REPUTATION_ADD_PROMPT", normalizedName, nil, {unit = unit, listType = "notelist"})
        end
    end
    UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end)

StaticPopupDialogs["REPUTATION_ADD_PROMPT"] = {
    text = L["UI_CB81"],
    button1 = L["UI_ADD"],
    button2 = L["CANCEL"],
    hasEditBox = true,
    maxLetters = 255,
    editBoxWidth = 350,
    OnAccept = function(self, data)
        if not data.unit or not UnitExists(data.unit) then
            print("|cFFFF0000ReputationList:|r Ошибка: цель не существует")
            return
        end
        
        local _, unitClass = UnitClass(data.unit)
        local _, unitRace = UnitRace(data.unit)
        if not unitClass or not unitRace then
            print("|cFFFF0000ReputationList:|r Ошибка: '" .. (UnitName(data.unit) or "?") .. "' не является игроком!")
            return
        end
        
        local note = self.editBox:GetText()
        if not note or note == "" then note = L["UI_F_N"] end
        local name = UnitName(data.unit)
        RL:AddPlayerDirect(name, data.listType, note, data.unit)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

StaticPopupDialogs["REPUTATION_ADD_PROMPT_CHAT"] = {
    text = L["UI_CB81"],
    button1 = L["UI_ADD"],
    button2 = L["CANCEL"],
    hasEditBox = true,
    maxLetters = 255,
    editBoxWidth = 350,
    OnAccept = function(self, data)
        local note = self.editBox:GetText()
        if not note or note == "" then note = L["UI_F_N"] end
        local unit = FindPlayerInGroup(data.name)
        RL:AddPlayerDirect(data.name, data.listType, note, unit)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

StaticPopupDialogs["REPUTATION_KICK_PROMPT"] = {
    text = L["UI_DAL"],
    button1 = L["UI_CB38"],
    button2 = L["CANCEL"],
    hasEditBox = true,
    maxLetters = 255,
    editBoxWidth = 350,
    OnShow = function(self)
        self.editBox:SetText(L["BLACKLIST_DAL"])
    end,
    OnAccept = function(self, data)
        local note = self.editBox:GetText()
        RL:KickFromGroup(data.name, note)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}


local function EnhancedChatFilter(self, event, msg, sender, ...)
    if not sender then return end
    
    local normSender = RL.NormalizeName(sender)
    if not normSender then return end
    
    local searchKey = string.lower(normSender)
    local realmData = RL:GetRealmData()
    
    if ReputationListDB.filterMessages and realmData.blacklist[searchKey] then
        if event == "CHAT_MSG_WHISPER" or 
			event == "CHAT_MSG_CHANNEL" or 
			event == "CHAT_MSG_YELL" or
			event == "CHAT_MSG_SAY" or
			event == "CHAT_MSG_PARTY" or
			event == "CHAT_MSG_PARTY_LEADER" or
			event == "CHAT_MSG_RAID" or
			event == "CHAT_MSG_RAID_LEADER" then
            return true
        end
    end
    
    if RL.colorLFG then
        if realmData.blacklist[searchKey] then
            return false, "|cFFFF0000[ЧС] " .. msg .. "|r", sender, ...
        elseif realmData.whitelist[searchKey] then
            return false, "|cFF00FF00[WL] " .. msg .. "|r", sender, ...
        elseif realmData.notelist[searchKey] then
            return false, "|cFFFFAA00[NL] " .. msg .. "|r", sender, ...
        end
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", EnhancedChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", EnhancedChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", EnhancedChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", EnhancedChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", EnhancedChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", EnhancedChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", EnhancedChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", EnhancedChatFilter)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("TRADE_REQUEST")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "reputation" or addonName == "ReputationList" then
            RL:Initialize()
        end
        
    elseif event == "PLAYER_LOGIN" then
        if not ReputationListDB then RL:Initialize() end

        if RL.BuildGUIDIndex then
            RL.BuildGUIDIndex()
        end
        
        if not SlashCmdList["REPLISTUI"] then
            SLASH_REPLISTUI1 = "/rlistui"
            SLASH_REPLISTUI2 = "/rlui"
            SlashCmdList["REPLISTUI"] = function()
                local ui = (RL.UI and RL.UI.ElvUI) or (RL.UI and RL.UI.Classic)
                if ui and ui.Toggle then ui:Toggle() else print(L["WEM42"]) end
            end
        end
        
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        if RL.CheckGroupMembers then RL:CheckGroupMembers() end
        
    elseif event == "UPDATE_MOUSEOVER_UNIT" then

        if RL.CanTriggerEvent and RL.CanTriggerEvent("mouseover") then
            if RL.CheckMouseoverUnit then 
                RL:CheckMouseoverUnit() 
            end
        end
        
        elseif event == "PLAYER_TARGET_CHANGED" then
        if RL.CanTriggerEvent("target") then
            if RL.CheckTargetUnit then 
                RL:CheckTargetUnit() 
            end
        end
        
    elseif event == "PLAYER_LOGOUT" then
        if RL.SaveSettings then RL:SaveSettings() end
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        if RL.ProcessAlertQueue then RL:ProcessAlertQueue() end
		
    elseif event == "PARTY_INVITE_REQUEST" then
        local inviterName = ...
        if inviterName then
            BlockInvites(inviterName)
        end
        
        
    elseif event == "TRADE_SHOW" then
    local traderName = UnitName("npc")
    if traderName then
        local normName = RL.NormalizeName(traderName)
        local searchKey = string.lower(normName)
        local realmData = RL:GetRealmData()
        
        local guid = UnitGUID("npc")
        if guid then
            guid = RL.NormalizeGUID(guid)
        end
        if guid and RL.CheckAndUpdatePlayer then
            RL:CheckAndUpdatePlayer(normName, guid, "npc")
        end
        
        local shouldBlock = false
        local foundData = nil
        
        if guid and RL.FindByGUID then
            foundData, foundKey, foundListType = RL.FindByGUID(guid)
            if foundData and foundListType == "blacklist" then
                shouldBlock = true
            end
        end
        
        if not shouldBlock and realmData.blacklist[searchKey] then
            local dataByName = realmData.blacklist[searchKey]
            
            if dataByName.guid and guid then
                if dataByName.guid == guid then

                    shouldBlock = true
                    foundData = dataByName
                else

                    print(L["WEM40"] .. normName .. L["WEM41"])
                    shouldBlock = false
                end
            elseif not dataByName.guid then

                shouldBlock = true
                foundData = dataByName
                
                if guid then
                    dataByName.guid = guid
                    RL:SaveSettings()
                end
            end
        end
        
        if shouldBlock and foundData then
            if ReputationListDB.blockTrade then
                CancelTrade()
                print(L["WEM38"] .. normName)
            else
                print(L["WEM39"] .. normName)
            end
            
            if RL.ShowPlayerCard and RL.popupNotify and RL.CanShowPopupCard(normName) then
                if foundData then
                    local unit = "npc"
                    local cardData = foundData
                    
                    if UnitExists(unit) and UnitIsPlayer(unit) then
                        local info = GetPlayerInfo(unit)
                        cardData = {
                            name = foundData.name or normName,
                            note = foundData.note,
                            guid = info.guid or foundData.guid,
                            class = info.class or foundData.class,
                            race = info.race or foundData.race,
                            level = info.level or foundData.level,
                            guild = info.guild or foundData.guild,
                            faction = info.faction or foundData.faction
                        }
                    end
                    
                    RL:ShowPlayerCard(normName, cardData)
                end
            end
            
            if ReputationListDB.blockTrade then
                return
            end
        end
    end
        
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        local normSender = RL.NormalizeName(sender)
        
        local unit
        if normSender == RL.NormalizeName(UnitName("player")) then
            unit = "player"
        else
            unit = FindPlayerInGroup(normSender)
        end

        if sender then
            local normName = RL.NormalizeName(sender)
            local searchKey = string.lower(normName)
            
            local guid = nil
            if unit and UnitExists(unit) then
                guid = UnitGUID(unit)
                if guid then
                    guid = RL.NormalizeGUID(guid)
                end
                if guid and RL.CheckAndUpdatePlayer then
                    RL:CheckAndUpdatePlayer(normName, guid, unit)
                end
            end
            
            local realmData = RL:GetRealmData()
            local data = realmData.blacklist[searchKey]

            if data then
                if RL.selfNotify then
                    local noteText = (data.note and data.note ~= "") and (" (" .. data.note .. ")") or ""
                    print("|cFFFFFF00[RepList]|r |cFFFF0000Blacklist:|r |cFF00CCCC" .. normName .. L["WEM37"] .. noteText)
                    
                    local selfMsg = L["WEM35"] .. normName .. L["WEM36"] .. msg
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. selfMsg .. "|r")
                end
                
                local cardData = data
                
                if unit and UnitExists(unit) and UnitIsPlayer(unit) then
                    local info = GetPlayerInfo(unit)
                    cardData = {
                        name = data.name or normName,
                        note = data.note,
                        guid = info.guid or data.guid,
                        class = info.class or data.class,
                        race = info.race or data.race,
                        level = info.level or data.level,
                        guild = info.guild or data.guild,
                        faction = info.faction or data.faction
                    }
                end
                
                if RL.ShowPlayerCard and RL.CanShowPopupCard(normName) then
                    RL:ShowPlayerCard(normName, cardData)
                end
            end
        end
    
    end
end)

SLASH_RLMAP1 = "/rlmap"
SLASH_RLMAP2 = "/rmap"
SlashCmdList["RLMAP"] = function()
    if not ReputationTrackerDB then
        ReputationTrackerDB = {}
    end
    
    ReputationTrackerDB.hidden = false
    
    if not ReputationTrackerDB.minimapAngle then
        ReputationTrackerDB.minimapAngle = 180
    end
    
    if ReputationTrackerMinimapIcon then
        ReputationTrackerMinimapIcon:Show()
        ReputationTrackerMinimapIcon:SetAlpha(1)
        
        local success = pcall(function()
            local parent = Minimap
            if ElvUI and MinimapHolder then
                parent = MinimapHolder
            end
            
            local radius = 80
            local angle = ReputationTrackerDB.minimapAngle or 180
            local rad = math.rad(angle)
            local x = math.cos(rad) * radius
            local y = math.sin(rad) * radius
            
            ReputationTrackerMinimapIcon:ClearAllPoints()
            ReputationTrackerMinimapIcon:SetPoint("CENTER", parent, "CENTER", x, y)
        end)
        
        if success then
            print(L["WEM30"])
        else
            print(L["WEM31"])
            print(L["WEM32"])
        end
    else
        print(L["WEM33"])
        print(L["WEM34"])
    end
end


RL.mouseoverCache = {
    lastGUID = nil,
    lastCheck = 0
}

function RL:CheckMouseoverUnit()
    if not UnitExists("mouseover") or not UnitIsPlayer("mouseover") then
        return
    end
    
    local guid = UnitGUID("mouseover")
    if not guid then return end
    
    guid = RL.NormalizeGUID(guid)
    if not guid then return end
    
    local playerName = UnitName("mouseover")
    if not playerName then return end
    
    local normName = RL.NormalizeName(playerName)
    
    local currentTime = GetTime()

    if self.mouseoverCache.lastGUID == guid and 
       (currentTime - self.mouseoverCache.lastCheck) < 5 then
        return
    end
    
    self.mouseoverCache.lastGUID = guid
    self.mouseoverCache.lastCheck = currentTime
    
    local foundData, foundKey, foundListType
    
    if RL.FindByGUID then
        foundData, foundKey, foundListType = RL.FindByGUID(guid)
    end
    
    if foundData then
        local info = GetPlayerInfo("mouseover")
        local updated = false
        
        local searchKey = string.lower(normName)
        if foundKey ~= searchKey then
            print("|cFFFFAA00ReputationList:|r" .. L["NICK_CHANGE_DETECTED"] .. (foundData.name or foundKey) .. " -> " .. normName)
            
            local realmData = self:GetRealmData()
            local list = realmData[foundListType]
            list[searchKey] = foundData
            list[foundKey] = nil
            
            foundData.name = normName
            foundData.key = NormalizeKey(normName)
            updated = true
            
            if RL.UpdateGUIDIndex and guid then
                RL.UpdateGUIDIndex(guid, foundListType, searchKey)
            end
        end
        
        if info.class and info.class ~= foundData.class then 
            print("|cFFFFAA00ReputationList:|r " .. normName .. " сменил класс: " .. (foundData.class or "?") .. " -> " .. info.class)
            foundData.class = info.class
            updated = true 
        end
        if info.race and info.race ~= foundData.race then 
            print("|cFFFFAA00ReputationList:|r " .. normName .. " сменил расу: " .. (foundData.race or "?") .. " -> " .. info.race)
            foundData.race = info.race
            updated = true 
        end
        if info.level and info.level ~= foundData.level then foundData.level = info.level; updated = true end
        if info.guild and info.guild ~= foundData.guild then foundData.guild = info.guild; updated = true end
        if info.faction and info.faction ~= foundData.faction then 
            print("|cFFFFAA00ReputationList:|r " .. normName .. " сменил фракцию: " .. (foundData.faction or "?") .. " -> " .. info.faction)
            foundData.faction = info.faction
            updated = true 
        end
        
        if updated then
            RL.InvalidateCache()
            self:SaveSettings()
            if UI and UI.RefreshList then
                UI:RefreshList()
            end
        end
    else

        local status, listType = RL.GetPlayerStatus(normName)
        
        if status then
            local data = RL.FastFind(normName, listType, "name")
            
            if data then
                local info = GetPlayerInfo("mouseover")
                local updated = false
                
                if data.guid and info.guid and info.guid ~= data.guid then

                    print(L["WEM28"] .. normName .. L["WEM29"])
                    print(L["INFO_R02"] .. data.guid .. "|r")
                    print(L["INFO_R03"] .. info.guid .. "|r")
                    
                    local realmData = self:GetRealmData()
                    local list = realmData[listType]
                    local oldKey = string.lower(normName)
                    
                    local guidSuffix = data.guid:sub(-8)
                    local unknownName = "Unknown-" .. guidSuffix
                    local unknownKey = string.lower(unknownName)
                    
                    data.name = unknownName
                    data.key = NormalizeKey(unknownName)
                    
                    list[unknownKey] = data
                    list[oldKey] = nil
                    
                    print(L["WH_W10"] .. unknownName .. "|r")
                    
                    RL.InvalidateCache()
                    self:SaveSettings()
                    return
                end
                
                if not data.guid and info.guid then 
                    data.guid = info.guid
                    updated = true 
                end
                
                if info.class and info.class ~= data.class then data.class = info.class; updated = true end
                if info.race and info.race ~= data.race then data.race = info.race; updated = true end
                if info.level and info.level ~= data.level then data.level = info.level; updated = true end
                if info.guild and info.guild ~= data.guild then data.guild = info.guild; updated = true end
                if info.faction and info.faction ~= data.faction then data.faction = info.faction; updated = true end
                
                if updated then
                    RL.InvalidateCache()
                    self:SaveSettings()
                    if UI and UI.RefreshList then
                        UI:RefreshList()
                    end
                end
            end
        end
    end
end

local tooltipFrame = CreateFrame("Frame")
tooltipFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
tooltipFrame:SetScript("OnEvent", function(self, event)
    if GameTooltip:IsShown() then
        local name, unit = GameTooltip:GetUnit()
        if name and unit and UnitIsPlayer(unit) then
            local playerName = UnitName(unit)
            if playerName then
                local normName = RL.NormalizeName(playerName)
                
                local guid = UnitGUID(unit)
                if guid then
                    guid = RL.NormalizeGUID(guid)
                end
                
                local status, note = nil, nil
                local foundData = nil
                
                if guid and RL.FindByGUID then
                    foundData, foundKey, status = RL.FindByGUID(guid)
                    if foundData then
                        note = foundData.note or ""
                    end
                end
                
                if not foundData and RL.GetTooltipData then
                    local tempStatus, tempNote = RL.GetTooltipData(normName)
                    
                    if tempStatus then
                        local realmData = RL:GetRealmData()
                        local searchKey = string.lower(normName)
                        local list = realmData[tempStatus]
                        
                        if list and list[searchKey] then
                            local dataByName = list[searchKey]
                            
                            if dataByName.guid and guid then
                                if dataByName.guid == guid then

                                    status = tempStatus
                                    note = tempNote
                                    foundData = dataByName
                                else

                                    status = nil
                                    note = nil
                                end
                            elseif not dataByName.guid then

                                status = tempStatus
                                note = tempNote
                                foundData = dataByName
                                
                                if guid then
                                    dataByName.guid = guid
                                    RL:SaveSettings()
                                end
                            end
                        end
                    end
                end
                
                if status then
                    GameTooltip:AddLine(" ")
                    
                    local displayNote = (note and note ~= "") and note or L["UI_F_N"]

					if status == "blacklist" then
						GameTooltip:AddLine("|cFFFF0000Blacklist:|r " .. displayNote, 1, 1, 1)
					elseif status == "whitelist" then
						GameTooltip:AddLine("|cFF00FF00Whitelist:|r " .. displayNote, 1, 1, 1)
					elseif status == "notelist" then
						GameTooltip:AddLine("|cFFFFAA00Notelist:|r " .. displayNote, 1, 1, 1)
					end
                    
                    GameTooltip:Show()
                end
            end
        end
    end
end)

SLASH_RLMEM1 = "/rlmem"
SlashCmdList["RLMEM"] = function()
    local stats = RL.GetMemoryStats()
    print("|cFF00FF00[RepList Memory Stats]|r")
    print("Notified Players: " .. stats.notifiedPlayers)
    print("Shown Cards: " .. stats.shownCards)
    print("Alert Cooldowns: " .. stats.alertCooldowns)
    print("Alert Queue: " .. stats.alertQueue)
end

SLASH_RLAS1 = "/rlas"
SlashCmdList["RLAS"] = function()
    local stats = RL.GetAntiSpamStats()
    print("|cFF00FF00[RepList Anti-Spam Stats]|r")
    print("Active Notifications: " .. stats.activeNotifications)
    print("Active Popups: " .. stats.activePopups)
    print("Tracked Players: " .. stats.trackedPlayers)
end

SLASH_RLCLEAN1 = "/rlclean"
SlashCmdList["RLCLEAN"] = function()
    RL.CleanupMemory()
    print("|cFF00FF00[RepList]|r Память очищена вручную")
end

SLASH_RLCLEARWHO1 = "/rlclearwho"
SLASH_RLCLEARWHO2 = "/rlочистить"
SlashCmdList["RLCLEARWHO"] = function()
    if RL.GroupTracker and RL.GroupTracker.ClearWhoHereCache then
        RL.GroupTracker:ClearWhoHereCache()
        print("|cFF00FF00[RepList]|r Список 'Кто здесь?' очищен")
    else
        print("|cFFFF0000[RepList]|r Ошибка: GroupTracker не найден")
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("TRADE_SHOW")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")