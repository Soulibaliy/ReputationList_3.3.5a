-- ====================================================================
-- ReputationList Public API for 3rd-party addons
-- Version: 1.0.0
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList

RL.API = {}
local API = RL.API

-- API Version for backwards compatibility
API.VERSION = "1.0.0"

-- ============================================================================
-- PLAYER STATUS CHECKS
-- ============================================================================

--- Get player status in lists (blacklist/whitelist/notelist)
-- @param playerName string - Player name to check
-- @return status string|nil - "blacklist", "whitelist", "notelist" or nil
-- @return listType string|nil - Same as status (for compatibility)
function API:GetPlayerStatus(playerName)
    if not playerName then return nil, nil end
    return RL.GetPlayerStatus(playerName)
end

--- Get player data by GUID
-- @param guid string - Player GUID
-- @return data table|nil - Player data from list
-- @return key string|nil - Key in list
-- @return listType string|nil - List type (blacklist/whitelist/notelist)
function API:GetPlayerByGUID(guid)
    if not guid then return nil, nil, nil end
    return RL.FindByGUID(guid)
end

--- Fast find player in specific list
-- @param playerName string - Player name
-- @param listType string - "blacklist", "whitelist", or "notelist"
-- @return data table|nil - Player data
-- @return key string|nil - Key in list
function API:FindPlayer(playerName, listType)
    return RL.FastFind(playerName, listType, "name")
end

-- ============================================================================
-- GROUP/RAID MANAGEMENT
-- ============================================================================

--- Get all group/raid members with their reputation status
-- @return members table - Array of member data
function API:GetGroupMembers()
    local members = {}
    local isRaid = IsInRaid()
    local numMembers = isRaid and GetNumRaidMembers() or GetNumPartyMembers()
    
    if numMembers == 0 then
        return members
    end
    
    for i = 1, numMembers do
        local unit = isRaid and ("raid" .. i) or ("party" .. i)
        local name = UnitName(unit)
        local guid = UnitGUID(unit)
        
        if name then
            local status, listType = self:GetPlayerStatus(name)
            local data = nil
            
            if status then
                data = self:FindPlayer(name, listType)
            end
            
            table.insert(members, {
                name = name,
                guid = guid,
                status = status,
                listType = listType,
                unit = unit,
                data = data,
            })
        end
    end
    
    return members
end

--- Check if any blacklisted players in group
-- @return hasBlacklisted boolean
-- @return playerName string|nil - Name of blacklisted player
function API:HasBlacklistedInGroup()
    local members = self:GetGroupMembers()
    
    for _, member in ipairs(members) do
        if member.listType == "blacklist" then
            return true, member.name
        end
    end
    
    return false, nil
end

--- Get current raid leader name
-- @return name string|nil - Raid leader name
function API:GetRaidLeader()
    if not IsInRaid() then
        return nil
    end
    
    for i = 1, GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if rank == 2 then  -- 2 = leader
            return name
        end
    end
    
    return nil
end

-- ============================================================================
-- LIST MANAGEMENT
-- ============================================================================

--- Add player to list
-- @param playerName string - Player name
-- @param listType string - "blacklist", "whitelist", or "notelist"
-- @param note string - Note about player
-- @param source string - Source of addition (default: "API")
-- @return success boolean
function API:AddPlayer(playerName, listType, note, source)
    if not RL.AddPlayer then return false end
    return RL:AddPlayer(playerName, listType, note, source or "API")
end

--- Remove player from list
-- @param playerName string - Player name
-- @param listType string - "blacklist", "whitelist", or "notelist"
-- @return success boolean
function API:RemovePlayer(playerName, listType)
    if not RL.RemovePlayer then return false end
    return RL:RemovePlayer(playerName, listType)
end

-- ============================================================================
-- CACHING
-- ============================================================================

--- Get data from Reputation's tooltip cache
-- @param playerName string - Player name
-- @return status string|nil - Player status
-- @return note string|nil - Player note
function API:GetFromCache(playerName)
    return RL.GetTooltipData(playerName)
end

--- Invalidate cache
function API:InvalidateCache()
    if RL.InvalidateCache then
        RL.InvalidateCache()
    end
end

-- ============================================================================
-- PERFORMANCE UTILITIES
-- ============================================================================

--- Check if event can be triggered (throttling)
-- @param eventType string - Event type identifier
-- @return canTrigger boolean
function API:CanTriggerEvent(eventType)
    return RL.CanTriggerEvent and RL.CanTriggerEvent(eventType) or true
end

--- Get memory statistics
-- @return stats table - Memory usage stats
function API:GetMemoryStats()
    return RL.GetMemoryStats and RL.GetMemoryStats() or {}
end

-- ============================================================================
-- EVENT SYSTEM
-- ============================================================================

local eventCallbacks = {}

--- Register callback for Reputation events
-- @param event string - Event name
-- @param callback function - Callback function
function API:RegisterCallback(event, callback)
    if not eventCallbacks[event] then
        eventCallbacks[event] = {}
    end
    table.insert(eventCallbacks[event], callback)
end

--- Trigger event (internal use)
-- @param event string - Event name
-- @param ... any - Event arguments
function API:TriggerEvent(event, ...)
    if eventCallbacks[event] then
        for _, callback in ipairs(eventCallbacks[event]) do
            local success, err = pcall(callback, ...)
            if not success then
                print("|cFFFF0000[RepList API]|r Error in callback: " .. tostring(err))
            end
        end
    end
end

--- Unregister callback
-- @param event string - Event name
-- @param callback function - Callback to remove
function API:UnregisterCallback(event, callback)
    if not eventCallbacks[event] then return end
    
    for i = #eventCallbacks[event], 1, -1 do
        if eventCallbacks[event][i] == callback then
            table.remove(eventCallbacks[event], i)
        end
    end
end

-- Events that Reputation will trigger:
-- "PLAYER_ADDED" - (playerName, listType, note)
-- "PLAYER_REMOVED" - (playerName, listType)
-- "GROUP_UPDATED" - ()
-- "LIST_CHANGED" - (listType)

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--- Normalize player name (remove server, trim spaces)
-- @param name string - Player name
-- @return normalized string - Normalized name
function API:NormalizeName(name)
    return RL.NormalizeName and RL.NormalizeName(name) or name
end

--- Get realm data
-- @return realmData table|nil - Current realm data
function API:GetRealmData()
    return RL.GetRealmData and RL.GetRealmData() or nil
end

-- ============================================================================
-- UI INTEGRATION
-- ============================================================================

--- Open Reputation UI
function API:OpenUI()
    if RL.UI then
        if RL.UI.Classic and RL.UI.Classic.Toggle then
            RL.UI.Classic:Toggle()
        elseif RL.UI.ElvUI and RL.UI.ElvUI.Toggle then
            RL.UI.ElvUI:Toggle()
        end
    end
end

--- Check if Reputation is loaded and available
-- @return available boolean
function API:IsAvailable()
    return RL and RL.version and true or false
end

--- Get Reputation version
-- @return version string
function API:GetVersion()
    return RL.version or "Unknown"
end

--- Get minimum required Reputation version for compatibility
-- @return minVersion string
function API:GetMinimumRequiredVersion()
    return "1.65b"
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Export global shortcut
_G.ReputationAPI = API

-- Print API ready message (debug)
if RL.DEBUG then
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        print("|cFF00FF00[RepList API]|r Version " .. API.VERSION .. " ready")
    end)
end
