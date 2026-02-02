-- ====================================================================
-- ReputationList Save Fix v2.0 for WoW 3.3.5a
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList


RL.SaveConfig = {
    pendingSave = false,
    batchMode = false,
    lastSave = 0,
    saveInterval = 5,
    hooked = false
}


local function ActualSave()
    if not ReputationListDB then return end
    
    ReputationListDB.autoNotify = RL.autoNotify
    ReputationListDB.selfNotify = RL.selfNotify
    ReputationListDB.colorLFG = RL.colorLFG
    ReputationListDB.soundNotify = RL.soundNotify
    ReputationListDB.popupNotify = RL.popupNotify
    ReputationListDB.filterMessages = RL.filterMessages
    ReputationListDB.blockInvites = RL.blockInvites
    ReputationListDB.blockTrade = RL.blockTrade
    
    if not ReputationListDB.uiMode then
        ReputationListDB.uiMode = "full"
    end
    
    RL.SaveConfig.pendingSave = false
    RL.SaveConfig.lastSave = GetTime()
end


local function PatchedSaveSettings()
    RL.SaveConfig.pendingSave = true
end


function RL:BeginBatchSave()
    self.SaveConfig.batchMode = true
    self.SaveConfig.pendingSave = false
end

function RL:EndBatchSave()
    self.SaveConfig.batchMode = false
    if self.SaveConfig.pendingSave then
        ActualSave()
    end
end

function RL:ForceSave()
    ActualSave()
end

RL.ActualSave = ActualSave


if RL.TimerManager then
    RL.TimerManager:Register("save", RL.SaveConfig.saveInterval, function()
        if not RL.SaveConfig.batchMode and RL.SaveConfig.pendingSave then
            ActualSave()
        end
    end)
    
    RL.TimerManager:Register("gc", 60, function()
        collectgarbage("step", 300)
    end)
end

local saveFrame = CreateFrame("Frame")


saveFrame:RegisterEvent("ADDON_LOADED")
saveFrame:RegisterEvent("PLAYER_LOGOUT")

saveFrame:SetScript("OnEvent", function(self, event, addon)
    if event == "PLAYER_LOGOUT" then
        ActualSave()
        
    elseif event == "ADDON_LOADED" then
        if addon == "reputation" and not RL.SaveConfig.hooked then
            
            if RL.SaveSettings then
                RL.OriginalSaveSettings = RL.SaveSettings
                
                RL.SaveSettings = PatchedSaveSettings
                
                RL.SaveConfig.hooked = true
                
            else
                print("|cFFFF0000[RepList]|r WARNING: SaveSettings not found!")
            end
        end
    end
end)


SLASH_RLSAVE1 = "/rlsave"
SlashCmdList["RLSAVE"] = function()
    ActualSave()
    print("|cFF00FF00[RepList]|r Данные сохранены принудительно")
end

SLASH_RLSAVESTATUS1 = "/rlstatus"
SlashCmdList["RLSAVESTATUS"] = function()
    print("|cFF00FF00[RepList Save Status]|r")
    print("Hooked: " .. tostring(RL.SaveConfig.hooked))
    print("Pending save: " .. tostring(RL.SaveConfig.pendingSave))
    print("Batch mode: " .. tostring(RL.SaveConfig.batchMode))
    print("Last save: " .. string.format("%.1f sec ago", GetTime() - RL.SaveConfig.lastSave))
    
    collectgarbage("collect")
    UpdateAddOnMemoryUsage()
    local addonMem = GetAddOnMemoryUsage("reputation")
    local luaMem = collectgarbage("count")
    
    print(string.format("Addon memory: %.2f KB (%.2f MB)", addonMem, addonMem / 1024))
    print(string.format("Total Lua memory: %.2f KB (%.2f MB)", luaMem, luaMem / 1024))
end


SLASH_RLMEMTEST1 = "/rlmemtest"
local _memTestFrame
SlashCmdList["RLMEMTEST"] = function(msg)
    local count = tonumber(msg) or 10
    
    print("|cFF00FF00[RepList Memory Test]|r Adding " .. count .. " test players...")
    
    collectgarbage("collect")
    UpdateAddOnMemoryUsage()
    local memBefore = GetAddOnMemoryUsage("reputation")
    
    for i = 1, count do
        RL:AddPlayerDirect("MemTest" .. i, "blacklist", "Test player " .. i)
    end
    
    print("Waiting 6 seconds for auto-save...")
    
    if not _memTestFrame then
        _memTestFrame = CreateFrame("Frame")
    end
    local elapsed = 0
    _memTestFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        
        if elapsed >= 6 then
            self:SetScript("OnUpdate", nil)
            
            collectgarbage("collect")
            UpdateAddOnMemoryUsage()
            local memAfter = GetAddOnMemoryUsage("reputation")
            
            local growth = memAfter - memBefore
            
            print("─────────────────────────────────────")
            print(string.format("Before: %.2f KB", memBefore))
            print(string.format("After: %.2f KB", memAfter))
            print(string.format("Growth: %.2f KB", growth))
            print(string.format("Per player: %.2f KB", growth / count))
            print("─────────────────────────────────────")
            
            if growth > count * 50 then
                print("|cFFFF0000WARNING:|r Memory growth too high!")
                print("Expected: ~" .. (count * 2) .. " KB")
                print("Actual: " .. string.format("%.2f KB", growth))
            else
                print("|cFF00FF00OK:|r Memory growth is normal")
            end
        end
    end)
end
