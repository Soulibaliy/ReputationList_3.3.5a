-- ====================================================================
-- ReputationList Memory Management Module for WoW 3.3.5a
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList

RL.Memory = {}
local Memory = RL.Memory

local function tableLen(tbl)
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end


Memory.config = {
    maxNotified = 500,
    maxCards = 100,
    maxCooldowns = 200,
    maxQueue = 50,
    
    notifiedTTL = 1800,
    cardTTL = 1200,
    cooldownTTL = 300,
    queueTTL = 60,
    
    cleanupInterval = 100
}

Memory.cleanupTimer = 0


function Memory:CleanupTable(tbl, maxSize, ttl, currentTime)
    if not tbl then return end
    
    for key, timestamp in pairs(tbl) do
        if type(timestamp) == "number" then
            if (currentTime - timestamp) > ttl then
                tbl[key] = nil
            end
        else
            tbl[key] = nil
        end
    end
    
    local count = tableLen(tbl)
    
    if count > maxSize then
        local sorted = {}
        for key, timestamp in pairs(tbl) do
            table.insert(sorted, {
                key = key, 
                time = type(timestamp) == "number" and timestamp or 0
            })
        end
        
        table.sort(sorted, function(a, b) 
            return a.time < b.time 
        end)
        
        local toRemove = count - maxSize
        for i = 1, toRemove do
            tbl[sorted[i].key] = nil
        end
    end
end

function Memory:PerformCleanup()
    local currentTime = time()
    local cleaned = {
        notified = 0,
        cards = 0,
        cooldowns = 0,
        queue = 0
    }
    
    if not RL.notifiedPlayers then RL.notifiedPlayers = {} end
    if not RL.shownCards then RL.shownCards = {} end
    if not RL.alertCooldowns then RL.alertCooldowns = {} end
    if not RL.alertQueue then RL.alertQueue = {} end
    
    local beforeNotified = 0
    beforeNotified = tableLen(RL.notifiedPlayers)
    
    local beforeCards = 0
    beforeCards = tableLen(RL.shownCards)
    
    local beforeCooldowns = 0
    beforeCooldowns = tableLen(RL.alertCooldowns)
    
    local beforeQueue = #RL.alertQueue
    
    self:CleanupTable(
        RL.notifiedPlayers, 
        self.config.maxNotified, 
        self.config.notifiedTTL, 
        currentTime
    )
    
    self:CleanupTable(
        RL.shownCards, 
        self.config.maxCards, 
        self.config.cardTTL, 
        currentTime
    )
    
    self:CleanupTable(
        RL.alertCooldowns, 
        self.config.maxCooldowns, 
        self.config.cooldownTTL, 
        currentTime
    )
    
    local newQueue = {}
    for _, alert in ipairs(RL.alertQueue) do
        if alert.timestamp and (currentTime - alert.timestamp) < self.config.queueTTL then
            table.insert(newQueue, alert)
        end
    end
    RL.alertQueue = newQueue
    
    local afterNotified = 0
    afterNotified = tableLen(RL.notifiedPlayers)
    cleaned.notified = beforeNotified - afterNotified
    
    local afterCards = 0
    afterCards = tableLen(RL.shownCards)
    cleaned.cards = beforeCards - afterCards
    
    local afterCooldowns = 0
    afterCooldowns = tableLen(RL.alertCooldowns)
    cleaned.cooldowns = beforeCooldowns - afterCooldowns
    
    cleaned.queue = beforeQueue - #RL.alertQueue
    
    local totalCleaned = cleaned.notified + cleaned.cards + cleaned.cooldowns + cleaned.queue
    if totalCleaned > 0 then
 
    end
	
	if not self.lastFullCleanup then
        self.lastFullCleanup = currentTime
    end
    
    if (currentTime - self.lastFullCleanup) > 1800 then
        if RL.BuildGUIDIndex then
            RL.BuildGUIDIndex()
        end
        self.lastFullCleanup = currentTime
    end
	
end


function Memory:Initialize()
    if RL.TimerManager then
        RL.TimerManager:Register("memory_cleanup", Memory.config.cleanupInterval, function()
            Memory:PerformCleanup()
        end)
    else
        print("|cFFFF0000[RepList Memory]|r ERROR: TimerManager not found!")
    end       
end


RL.CleanupMemory = function()
    Memory:PerformCleanup()
end

RL.GetMemoryStats = function()
    local stats = {
        notifiedPlayers = 0,
        shownCards = 0,
        alertCooldowns = 0,
        alertQueue = 0
    }
    
    if RL.notifiedPlayers then
        stats.notifiedPlayers = tableLen(RL.notifiedPlayers)
    end
    
    if RL.shownCards then
        stats.shownCards = tableLen(RL.shownCards)
    end
    
    if RL.alertCooldowns then
        stats.alertCooldowns = tableLen(RL.alertCooldowns)
    end
    
    if RL.alertQueue then
        stats.alertQueue = #RL.alertQueue
    end
    
    return stats
end


Memory:Initialize()
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" then
        Memory:PerformCleanup()
    end
end)