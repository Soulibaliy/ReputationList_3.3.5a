-- ============================================================================
-- Reputation List - Group/Raid Tracker Module (FIXED v2)
-- Отслеживание игроков с сохранением истории до входа в новую группу
-- ============================================================================
local RL = ReputationList
if not RL then return end
local GroupTracker = {}
RL.GroupTracker = GroupTracker
local currentGroupPlayers = {}
local lastGroupUpdate = 0
local UPDATE_INTERVAL = 2
local wasInGroupPreviously = false

local function GetGroupMemberInfo(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        return nil
    end
    local name = UnitName(unit)
    if not name then return nil end
    local baseInfo = nil
    if RL.GetPlayerInfo then
        baseInfo = RL.GetPlayerInfo(unit)
    end
    local info = {
        name = RL.NormalizeName(name),
        guid = baseInfo and baseInfo.guid or (UnitGUID(unit) and RL.NormalizeGUID(UnitGUID(unit))),
        class = baseInfo and baseInfo.class or select(2, UnitClass(unit)),
        race = baseInfo and baseInfo.race or select(2, UnitRace(unit)),
        level = baseInfo and baseInfo.level or UnitLevel(unit),
        guild = baseInfo and baseInfo.guild or GetGuildInfo(unit),
        faction = baseInfo and baseInfo.faction or UnitFactionGroup(unit),
    }
    return info
end

local function GetGroupStatusSnapshot()
    return {
        numParty = GetNumPartyMembers(),
        numRaid = GetNumRaidMembers()
    }
end

local function IsNewGroup(currentSnapshot)
    local nowInGroup = (currentSnapshot.numParty > 0 or currentSnapshot.numRaid > 0)
    local isNew = (not wasInGroupPreviously) and nowInGroup
    
    wasInGroupPreviously = nowInGroup
    
    return isNew
end

function GroupTracker:IsInGroup()
    return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
end

function GroupTracker:GetCurrentGroupMembers()
    local now = time()
    if (now - lastGroupUpdate) < UPDATE_INTERVAL then
        return currentGroupPlayers
    end
    wipe(currentGroupPlayers)
    lastGroupUpdate = now
    if not self:IsInGroup() then
        return currentGroupPlayers
    end
    local numMembers = GetNumRaidMembers()
    local isRaid = numMembers > 0
    if not isRaid then
        numMembers = GetNumPartyMembers()
    end
    local playerInfo = GetGroupMemberInfo("player")
    if playerInfo then
        currentGroupPlayers[playerInfo.name] = playerInfo
    end
    for i = 1, numMembers do
        local unit = isRaid and ("raid" .. i) or ("party" .. i)
        local info = GetGroupMemberInfo(unit)
        if info then
            currentGroupPlayers[info.name] = info
        end
    end
    return currentGroupPlayers
end

function GroupTracker:ForceUpdate()
    lastGroupUpdate = 0
end

function GroupTracker:GetGroupMemberExtendedInfo(playerName)
    local members = self:GetCurrentGroupMembers()
    local memberInfo = members[playerName]
    if not memberInfo then
        return nil
    end
    local listType, listKey, listData = RL:FindPlayerInAllLists(playerName)
    local extendedInfo = {
        name = memberInfo.name,
        guid = memberInfo.guid,
        class = memberInfo.class,
        race = memberInfo.race,
        level = memberInfo.level,
        guild = memberInfo.guild,
        faction = memberInfo.faction,
        inList = listType ~= nil,
        listType = listType,
        listData = listData,
        note = listData and listData.note or nil,
    }
    return extendedInfo
end

function GroupTracker:GetAllGroupMembersWithListInfo()
    local members = {}
    local result = {}
    if ReputationGroupTrackerDB and ReputationGroupTrackerDB.whoHereCache then
        members = ReputationGroupTrackerDB.whoHereCache
    end
    for name, info in pairs(members) do
        local listType, listKey, listData = RL:FindPlayerInAllLists(info.name)
        local extendedInfo = {
            name = info.name,
            guid = info.guid,
            class = info.class,
            race = info.race,
            level = info.level,
            guild = info.guild,
            faction = info.faction,
            inList = listType ~= nil,
            listType = listType,
            listData = listData,
            note = listData and listData.note or nil,
            lastSeen = info.lastSeen,
        }
        table.insert(result, extendedInfo)
    end
    table.sort(result, function(a, b)
        return a.name < b.name
    end)
    return result
end

function GroupTracker:SaveCurrentGroup()
    if not ReputationGroupTrackerDB then
        ReputationGroupTrackerDB = {}
    end

    local members = self:GetCurrentGroupMembers()
    local currentSnapshot = GetGroupStatusSnapshot()
    local isNewGroup = IsNewGroup(currentSnapshot)

    if isNewGroup then
        ReputationGroupTrackerDB.whoHereCache = {}
        ReputationGroupTrackerDB.currentGroup = nil
    end

    if next(members) then
        local snapshot = {
            timestamp = time(),
            date = date("%d.%m.%Y %H:%M"),
            members = {},
            isNew = isNewGroup
        }
        for name, info in pairs(members) do
            snapshot.members[name] = {
                name = info.name,
                guid = info.guid,
                class = info.class,
                race = info.race,
                level = info.level,
                guild = info.guild,
                faction = info.faction
            }
        end
        ReputationGroupTrackerDB.currentGroup = snapshot
    end

    if not ReputationGroupTrackerDB.whoHereCache then
        ReputationGroupTrackerDB.whoHereCache = {}
    end
    for name, info in pairs(members) do
        local key = string.lower(RL.NormalizeName(name))
        if not ReputationGroupTrackerDB.whoHereCache[key] then
            ReputationGroupTrackerDB.whoHereCache[key] = {
                name = info.name,
                guid = info.guid,
                class = info.class,
                race = info.race,
                level = info.level,
                guild = info.guild,
                faction = info.faction,
                firstSeen = time(),
                lastSeen = time()
            }
        else
            ReputationGroupTrackerDB.whoHereCache[key].lastSeen = time()
            ReputationGroupTrackerDB.whoHereCache[key].guild = info.guild
            ReputationGroupTrackerDB.whoHereCache[key].level = info.level
        end
    end
end

function GroupTracker:GetSavedGroup()
    if not ReputationGroupTrackerDB or not ReputationGroupTrackerDB.currentGroup then
        return nil
    end
    return ReputationGroupTrackerDB.currentGroup
end

function GroupTracker:GetCachedPlayerInfo(playerName)
    if not ReputationGroupTrackerDB or not ReputationGroupTrackerDB.whoHereCache then
        return nil
    end
    local key = string.lower(RL.NormalizeName(playerName))
    return ReputationGroupTrackerDB.whoHereCache[key]
end

function GroupTracker:ClearWhoHereCache()
    if not ReputationGroupTrackerDB then
        ReputationGroupTrackerDB = {}
    end
    ReputationGroupTrackerDB.whoHereCache = {}
    ReputationGroupTrackerDB.currentGroup = nil
    wasInGroupPreviously = false
    
    if RL.UI and RL.UI.Classic and RL.UI.Classic.OnGroupUpdate then
        RL.UI.Classic:OnGroupUpdate()
    end
    if RL.UI and RL.UI.ElvUI and RL.UI.ElvUI.OnGroupUpdate then
        RL.UI.ElvUI:OnGroupUpdate()
    end
end

function GroupTracker:OnGroupRosterUpdate()
    self:GetCurrentGroupMembers()
    
    self:SaveCurrentGroup()
    
    if RL.UI and RL.UI.Classic and RL.UI.Classic.OnGroupUpdate then
        RL.UI.Classic:OnGroupUpdate()
    end
    if RL.UI and RL.UI.ElvUI and RL.UI.ElvUI.OnGroupUpdate then
        RL.UI.ElvUI:OnGroupUpdate()
    end
end

function GroupTracker:Initialize()
    if not ReputationGroupTrackerDB then
        ReputationGroupTrackerDB = {
            currentGroup = nil,
            whoHereCache = {}
        }
    end
    
    local snapshot = GetGroupStatusSnapshot()
    wasInGroupPreviously = (snapshot.numParty > 0 or snapshot.numRaid > 0)
    
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    frame:SetScript("OnEvent", function(self, event)
        GroupTracker:OnGroupRosterUpdate()
    end)
    self.frame = frame
end

GroupTracker:Initialize()

if ReputationTrackerDB then
    if not ReputationGroupTrackerDB then
        ReputationGroupTrackerDB = {}
    end
    if ReputationTrackerDB.currentGroup and not ReputationGroupTrackerDB.currentGroup then
        ReputationGroupTrackerDB.currentGroup = ReputationTrackerDB.currentGroup
        ReputationTrackerDB.currentGroup = nil
    end
    if ReputationTrackerDB.whoHereCache and not ReputationGroupTrackerDB.whoHereCache then
        ReputationGroupTrackerDB.whoHereCache = ReputationTrackerDB.whoHereCache
        ReputationTrackerDB.whoHereCache = nil
    end
end