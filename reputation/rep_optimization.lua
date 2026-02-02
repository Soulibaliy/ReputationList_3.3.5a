-- ====================================================================
-- ReputationList Optimization Module for WoW 3.3.5a
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList

RL.Optimization = {}
local Opt = RL.Optimization

Opt.guidIndex = {}
Opt.maxGuidIndex = 1000

function Opt:BuildGUIDIndex()
    self.guidIndex = {}
    
    if not RL.GetRealmData then return end
    local realmData = RL:GetRealmData()
    if not realmData then return end
    
    for listType, list in pairs({blacklist = realmData.blacklist, whitelist = realmData.whitelist, notelist = realmData.notelist}) do
        if type(list) == "table" then
            for key, data in pairs(list) do
                if data.guid then
                    local normalizedGuid = RL.NormalizeGUID and RL.NormalizeGUID(data.guid)
                    if normalizedGuid then
                        self.guidIndex[normalizedGuid] = {
                            listType = listType,
                            key = key,
                            timestamp = time()
                        }
                    end
                end
            end
        end
    end
end

function Opt:UpdateGUIDIndex(guid, listType, key)
    if not guid then return end
    local normalizedGuid = RL.NormalizeGUID and RL.NormalizeGUID(guid)
    if normalizedGuid then
        self.guidIndex[normalizedGuid] = {
            listType = listType,
            key = key,
            timestamp = time()
        }
        
        local count = 0; for _ in pairs(self.guidIndex) do count = count + 1 end
        
        if count > self.maxGuidIndex then
            local oldest = nil
            local oldestTime = time()
            for k, v in pairs(self.guidIndex) do
                if v.timestamp < oldestTime then
                    oldest = k
                    oldestTime = v.timestamp
                end
            end
            if oldest then
                self.guidIndex[oldest] = nil
            end
        end
    end
end

function Opt:RemoveFromGUIDIndex(guid)
    if not guid then return end
    local normalizedGuid = RL.NormalizeGUID and RL.NormalizeGUID(guid)
    if normalizedGuid then
        self.guidIndex[normalizedGuid] = nil
    end
end

function Opt:FindByGUID(guid)
    if not guid then return nil, nil end
    local normalizedGuid = RL.NormalizeGUID and RL.NormalizeGUID(guid)
    if not normalizedGuid then return nil, nil end
    
    local indexData = self.guidIndex[normalizedGuid]
    if not indexData then return nil, nil end
    
    if not RL.GetRealmData then return nil, nil end
    local realmData = RL:GetRealmData()
    if not realmData then return nil, nil end
    
    local list = realmData[indexData.listType]
    if not list then return nil, nil end
    
    local data = list[indexData.key]
    if data then
        return data, indexData.key, indexData.listType
    end
    
    return nil, nil
end

function Opt:InvalidateGUIDIndex()
    self.guidIndex = {}
end

function Opt:FastFind(playerName, listType, searchType)
    if not RL.GetRealmData then return nil, nil end
    
    local realmData = RL:GetRealmData()
    local list = realmData[listType]
    if not list then return nil, nil end
    
    local searchKey = string.lower(playerName:match("^[^-]+") or playerName)
    
    if list[searchKey] then
        return list[searchKey], searchKey
    end
    
    return nil, nil
end

Opt.cache = {
    tooltipData = {},
    tooltipTTL = 5,
    maxSize = 25
}

function Opt:GetPlayerStatus(playerName)
    if type(playerName) ~= "string" then
        return nil, nil
    end
    
    if self:FastFind(playerName, "blacklist", "name") then
        return "blacklist", "blacklist"
    elseif self:FastFind(playerName, "whitelist", "name") then
        return "whitelist", "whitelist"
    elseif self:FastFind(playerName, "notelist", "name") then
        return "notelist", "notelist"
    end
    
    return nil, nil
end

function Opt:GetTooltipData(playerName)
    if type(playerName) ~= "string" then
        return nil, nil
    end
    
    local currentTime = time()
    local cacheKey = string.lower(playerName)
    
    local cached = self.cache.tooltipData[cacheKey]
    if cached and (currentTime - cached.timestamp) < self.cache.tooltipTTL then
        cached.lastAccess = currentTime
        return cached.status, cached.note
    end
    
    local status, listType = self:GetPlayerStatus(playerName)
    local note = ""
    
    if status then
        local data = self:FastFind(playerName, listType, "name")
        if data then
            note = data.note or ""
        end
    end
    
    self.cache.tooltipData[cacheKey] = {
        status = status,
        note = note,
        timestamp = currentTime,
        lastAccess = currentTime
    }
    

    local count = 0
    for _ in pairs(self.cache.tooltipData) do
        count = count + 1
    end
    
    if count > self.cache.maxSize then

        local entries = {}
        for k, v in pairs(self.cache.tooltipData) do
            table.insert(entries, {
                key = k,
                lastAccess = v.lastAccess or v.timestamp
            })
        end
        
        table.sort(entries, function(a, b)
            return a.lastAccess < b.lastAccess
        end)
        
        local toRemove = math.ceil(count * 0.3)
        for i = 1, toRemove do
            self.cache.tooltipData[entries[i].key] = nil
        end
    end
    
    return status, note
end

function Opt:InvalidateCache()
    self.cache.tooltipData = {}
end


Opt.throttle = {
    mouseover = {
        lastCheck = 0,
        interval = 0.3
    },
    target = {
        lastCheck = 0,
        interval = 0.2
    }
}

function Opt:CanTriggerEvent(eventType)
    local currentTime = GetTime()
    local throttleData = self.throttle[eventType]
    
    if not throttleData then
        return true
    end
    
    if (currentTime - throttleData.lastCheck) >= throttleData.interval then
        throttleData.lastCheck = currentTime
        return true
    end
    
    return false
end


Opt.memory = {
    cleanupInterval = 600,
    lastCleanup = 0
}

function Opt:CleanupMemory()
    self.cache.tooltipData = {}
    
    collectgarbage("collect")
    
    self.memory.lastCleanup = time()
end

if RL.TimerManager then
    RL.TimerManager:Register("optimization_cleanup", Opt.memory.cleanupInterval, function()
        Opt:CleanupMemory()
    end)
end


RL.FastFind = function(...) 
    return Opt:FastFind(...) 
end

RL.GetPlayerStatus = function(...) 
    return Opt:GetPlayerStatus(...) 
end

RL.GetTooltipData = function(...) 
    return Opt:GetTooltipData(...) 
end

RL.BuildGUIDIndex = function()
    return Opt:BuildGUIDIndex()
end

RL.UpdateGUIDIndex = function(...)
    return Opt:UpdateGUIDIndex(...)
end

RL.RemoveFromGUIDIndex = function(...)
    return Opt:RemoveFromGUIDIndex(...)
end

RL.FindByGUID = function(...)
    return Opt:FindByGUID(...)
end

RL.InvalidateGUIDIndex = function()
    return Opt:InvalidateGUIDIndex()
end

RL.InvalidateIndex = function(...) 
    return Opt:InvalidateGUIDIndex()
end

RL.InvalidateCache = function() 
    Opt:InvalidateCache() 
end

RL.CanTriggerEvent = function(...) 
    return Opt:CanTriggerEvent(...) 
end


