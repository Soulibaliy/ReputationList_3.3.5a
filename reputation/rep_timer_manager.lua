-- ====================================================================
-- ReputationList Timer Manager for WoW 3.3.5a
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList

RL.TimerManager = {
    elapsed = 0,
    callbacks = {},
    frame = nil
}

local TM = RL.TimerManager

function TM:Register(name, interval, callback)
    if not name or not interval or not callback then
        print("|cFFFF0000[RepList TimerManager]|r Invalid registration: name, interval, and callback required")
        return false
    end
    
    self.callbacks[name] = {
        interval = interval,
        lastRun = 0,
        callback = callback,
        enabled = true
    }
    
    return true
end

function TM:Unregister(name)
    if self.callbacks[name] then
        self.callbacks[name] = nil
        return true
    end
    return false
end

function TM:Enable(name)
    if self.callbacks[name] then
        self.callbacks[name].enabled = true
    end
end

function TM:Disable(name)
    if self.callbacks[name] then
        self.callbacks[name].enabled = false
    end
end

function TM:ForceRun(name)
    if self.callbacks[name] and self.callbacks[name].enabled then
        local success, err = pcall(self.callbacks[name].callback)
        if not success then
            print("|cFFFF0000[RepList TimerManager]|r Error in timer '" .. name .. "': " .. tostring(err))
        end
        self.callbacks[name].lastRun = time()
    end
end

function TM:GetStats()
    local stats = {
        total = 0,
        enabled = 0,
        disabled = 0
    }
    
    for name, data in pairs(self.callbacks) do
        stats.total = stats.total + 1
        if data.enabled then
            stats.enabled = stats.enabled + 1
        else
            stats.disabled = stats.disabled + 1
        end
    end
    
    return stats
end


function TM:Initialize()
    self.frame = CreateFrame("Frame")
    
    self.frame:SetScript("OnUpdate", function(frame, delta)
        TM.elapsed = TM.elapsed + delta
        
        if TM.elapsed >= 1 then
            local currentTime = time()
            
            for name, data in pairs(TM.callbacks) do
                if data.enabled and (currentTime - data.lastRun) >= data.interval then
                    local success, err = pcall(data.callback)
                    if not success then
                        print("|cFFFF0000[RepList TimerManager]|r Error in timer '" .. name .. "': " .. tostring(err))
                    end
                    data.lastRun = currentTime
                end
            end
            
            TM.elapsed = 0
        end
    end)
    
end

TM:Initialize()


SLASH_RLTIMERS1 = "/rltimers"
SlashCmdList["RLTIMERS"] = function()
    local stats = TM:GetStats()
    print("|cFF00FF00[RepList Timer Manager]|r")
    print("Total timers: " .. stats.total)
    print("Enabled: " .. stats.enabled)
    print("Disabled: " .. stats.disabled)
    print("")
    print("Registered timers:")
    
    for name, data in pairs(TM.callbacks) do
        local status = data.enabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
        local lastRun = time() - data.lastRun
        print(string.format("  %s: %s (interval: %ds, last run: %ds ago)", 
            name, status, data.interval, lastRun))
    end
end