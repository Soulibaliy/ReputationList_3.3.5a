-- ====================================================================
-- ReputationList Anti-Spam Module for WoW 3.3.5a
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList

RL.AntiSpam = {}
local AS = RL.AntiSpam


AS.cooldowns = {
    mouseoverCooldown = 10,
    targetCooldown = 5,
    popupCooldown = 30,
    soundCooldown = 15,
    chatCooldown = 5,
    whisperCooldown = 60
}


AS.priority = {
    whisper = 100,
    trade = 90,
    invite = 85,
    group = 70,
    target = 50,
    mouseover = 30,
    
    maxNotificationsPerMinute = 10,
    maxPopupsPerMinute = 3
}


AS.counters = {
    total = {},
    popups = {}
}


function AS:CheckNotificationCooldown(playerKey, notificationType)
    local currentTime = time()
    local cooldownKey = playerKey .. "_" .. notificationType
    
    if not RL.alertCooldowns then
        RL.alertCooldowns = {}
    end
    
    if not RL.alertCooldowns[cooldownKey] then
        RL.alertCooldowns[cooldownKey] = currentTime
        return true
    end
    
    local lastNotification = RL.alertCooldowns[cooldownKey]
    local cooldownDuration = self.cooldowns[notificationType .. "Cooldown"] or 10
    
    if (currentTime - lastNotification) >= cooldownDuration then
        RL.alertCooldowns[cooldownKey] = currentTime
        return true
    end
    
    return false
end


function AS:CanShowNotification(notificationType, priority)
    local currentTime = time()
    
    local newTotal = {}
    for _, notif in ipairs(self.counters.total) do
        if (currentTime - notif.timestamp) < 60 then
            table.insert(newTotal, notif)
        end
    end
    self.counters.total = newTotal
    
    if #self.counters.total >= self.priority.maxNotificationsPerMinute then
		local minPriority = priority
		local minIndex = nil
    
		for i, notif in ipairs(self.counters.total) do
			if notif.priority < minPriority then
				minPriority = notif.priority
				minIndex = i
			end
		end
    
		if minIndex then
			table.remove(self.counters.total, minIndex)
		else
			return false
		end
	end
    
    table.insert(self.counters.total, {
        timestamp = currentTime,
        type = notificationType,
        priority = priority
    })
    
    return true
end

function AS:CanShowPopup(playerKey)
    local currentTime = time()
    
    local newPopups = {}
    for _, popup in ipairs(self.counters.popups) do
        if (currentTime - popup.timestamp) < 60 then
            table.insert(newPopups, popup)
        end
    end
    self.counters.popups = newPopups
    
    if #self.counters.popups >= self.priority.maxPopupsPerMinute then
        return false
    end
    
    table.insert(self.counters.popups, {
        timestamp = currentTime,
        playerKey = playerKey
    })
    
    return true
end


AS.popupCardCooldowns = {}
AS.popupCardCooldown = 30
AS.maxPopupCardCooldowns = 200

function AS:CanShowPopupCard(playerName)
    local currentTime = time()
    local key = string.lower(playerName)
    
    if self.popupCardCooldowns[key] then
        if (currentTime - self.popupCardCooldowns[key]) < self.popupCardCooldown then
            return false
        end
    end
    
    if not self:CanShowPopup(key) then
        return false
    end
    
    self.popupCardCooldowns[key] = currentTime
    
    -- LRU очистка при превышении лимита
    local count = 0
    for _ in pairs(self.popupCardCooldowns) do
        count = count + 1
    end
    
    if count > self.maxPopupCardCooldowns then
        local oldestKey = nil
        local oldestTime = currentTime
        
        for k, timestamp in pairs(self.popupCardCooldowns) do
            if timestamp < oldestTime then
                oldestKey = k
                oldestTime = timestamp
            end
        end
        
        if oldestKey then
            self.popupCardCooldowns[oldestKey] = nil
        end
    end
    
    return true
end


AS.adaptive = {
    baseCD = {
        mouseover = 10,
        target = 5,
        popup = 30
    },
    
    spamThreshold = 5,
    spamMultiplier = 2,
    
    playerStats = {},
    maxPlayerStats = 200
}

function AS:GetAdaptiveCooldown(playerKey, notificationType)
    local currentTime = time()
    local baseCooldown = self.adaptive.baseCD[notificationType] or 10
    
    if not self.adaptive.playerStats[playerKey] then
        self.adaptive.playerStats[playerKey] = {
            count = 0,
            firstSeen = currentTime,
            lastSeen = currentTime
        }
    end
    
    local stats = self.adaptive.playerStats[playerKey]
    
    stats.count = stats.count + 1
    stats.lastSeen = currentTime
    
    if (currentTime - stats.firstSeen) > 60 then
        stats.count = 1
        stats.firstSeen = currentTime
    end
    
    local cooldown = baseCooldown
    
    if stats.count > self.adaptive.spamThreshold then
        local spamLevel = math.floor(stats.count / self.adaptive.spamThreshold)
        cooldown = baseCooldown * (self.adaptive.spamMultiplier ^ spamLevel)
        
        cooldown = math.min(cooldown, 300)
        
        if stats.count == self.adaptive.spamThreshold + 1 then
            print(string.format("|cFFFFAA00[RepList]|r Частые уведомления от %s. Кулдаун увеличен до %d сек.", 
                playerKey, cooldown))
        end
    end
    local count = 0
    for _ in pairs(self.adaptive.playerStats) do
        count = count + 1
    end
    
    if count > self.adaptive.maxPlayerStats then
        local oldestKey = nil
        local oldestTime = currentTime
        
        for key, stats in pairs(self.adaptive.playerStats) do
            if stats.lastSeen < oldestTime then
                oldestKey = key
                oldestTime = stats.lastSeen
            end
        end
        
        if oldestKey then
            self.adaptive.playerStats[oldestKey] = nil
        end
    end
    return cooldown
end


function AS:Cleanup()
    local currentTime = time()
    
    -- Очистка adaptive.playerStats (старше 10 минут)
    for playerKey, stats in pairs(self.adaptive.playerStats) do
        if (currentTime - stats.lastSeen) > 600 then  -- 10 минут
            self.adaptive.playerStats[playerKey] = nil
        end
    end
    
    -- Очистка popupCardCooldowns (старше 5 минут)
    for playerKey, timestamp in pairs(self.popupCardCooldowns) do
        if (currentTime - timestamp) > 300 then  -- 5 минут
            self.popupCardCooldowns[playerKey] = nil
        end
    end
    
    -- Очистка counters.total (старше 1 минуты)
    local newTotal = {}
    for _, notif in ipairs(self.counters.total) do
        if (currentTime - notif.timestamp) < 60 then
            table.insert(newTotal, notif)
        end
    end
    self.counters.total = newTotal
    
    -- Очистка counters.popups (старше 1 минуты)
    local newPopups = {}
    for _, popup in ipairs(self.counters.popups) do
        if (currentTime - popup.timestamp) < 60 then
            table.insert(newPopups, popup)
        end
    end
    self.counters.popups = newPopups
end

if RL.TimerManager then
    RL.TimerManager:Register("antispam_cleanup", 300, function()
        AS:Cleanup()
    end)
end


RL.CheckNotificationCooldown = function(...) 
    return AS:CheckNotificationCooldown(...) 
end

RL.CanShowNotification = function(...) 
    return AS:CanShowNotification(...) 
end

RL.CanShowPopup = function(...) 
    return AS:CanShowPopup(...) 
end

RL.CanShowPopupCard = function(...)
    return AS:CanShowPopupCard(...)
end

RL.GetAdaptiveCooldown = function(...)
    return AS:GetAdaptiveCooldown(...)
end

RL.GetAntiSpamStats = function()
    return {
        activeNotifications = #AS.counters.total,
        activePopups = #AS.counters.popups,
        trackedPlayers = (function()
            local count = 0
            for _ in pairs(AS.adaptive.playerStats) do count = count + 1 end
            return count
        end)()
    }
end
