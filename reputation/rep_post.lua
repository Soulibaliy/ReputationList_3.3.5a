local RL = ReputationList
if not RL then return end

local PostUI = {}
RL.PostUI = PostUI

local CACHE = {
    markedMails = {},
}

local function GetListMarkup(listType)
    if listType == "blacklist" then
        return "[Blacklist]", {1, 0.3, 0.3}
    elseif listType == "whitelist" then
        return "[Whitelist]", {0.3, 1, 0.3}
    elseif listType == "notelist" then
        return "[Notelist]", {1, 0.8, 0.3}
    end
    return nil, nil
end

local function CheckSenderInLists(sender)
    if not sender or not RL then return nil end
    
    local normalizedName = RL.NormalizeName(sender):lower()
    local realmData = RL:GetRealmData()
    if not realmData then return nil end
    
    if realmData.blacklist and realmData.blacklist[normalizedName] then
        return "blacklist"
    end
    
    if realmData.whitelist and realmData.whitelist[normalizedName] then
        return "whitelist"
    end
    
    if realmData.notelist and realmData.notelist[normalizedName] then
        return "notelist"
    end
    
    return nil
end

local function CreateMarkIndicator(mailItemFrame, senderFS, listType)
    if not mailItemFrame.repMarkup then
        mailItemFrame.repMarkup = mailItemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        mailItemFrame.repMarkup:SetPoint("LEFT", senderFS, "RIGHT", -40, 0)
    end
    
    local markup, color = GetListMarkup(listType)
    if markup and color then
        mailItemFrame.repMarkup:SetText(markup)
        mailItemFrame.repMarkup:SetTextColor(color[1], color[2], color[3])
        mailItemFrame.repMarkup:Show()
    else
        mailItemFrame.repMarkup:Hide()
    end
end

local function UpdateMailIndicators()
    if not InboxFrame or not InboxFrame:IsShown() then
        return
    end
    
    local numItems = GetInboxNumItems()
    if not numItems or numItems == 0 then
        return
    end
    
    local offset = InboxFrame.pageNum and ((InboxFrame.pageNum - 1) * 7) or 0
    
    for i = 1, 7 do
        local mailIndex = offset + i
        local mailItem = _G["MailItem"..i]
        
        if mailItem and mailIndex <= numItems then
            local _, _, sender = GetInboxHeaderInfo(mailIndex)
            
            if sender then
                local senderFS = _G["MailItem"..i.."Sender"]
                
                if senderFS then
                    local listType = CheckSenderInLists(sender)
                    
                    if listType then
                        CreateMarkIndicator(mailItem, senderFS, listType)
                        CACHE.markedMails[mailIndex] = true
                    elseif mailItem.repMarkup then
                        mailItem.repMarkup:Hide()
                        CACHE.markedMails[mailIndex] = nil
                    end
                end
            end
        elseif mailItem and mailItem.repMarkup then
            mailItem.repMarkup:Hide()
        end
    end
end

local function CleanupMailMarkers()
    for i = 1, 7 do
        local mailItem = _G["MailItem"..i]
        if mailItem and mailItem.repMarkup then
            mailItem.repMarkup:Hide()
        end
    end
    CACHE.markedMails = {}
end

function PostUI:Initialize()
    if not InboxFrame then
        return
    end
    
    local mailFrame = CreateFrame("Frame")
    mailFrame:RegisterEvent("MAIL_SHOW")
    mailFrame:RegisterEvent("MAIL_CLOSED")
    
    mailFrame:SetScript("OnEvent", function(self, event)
        if event == "MAIL_SHOW" then
            UpdateMailIndicators()
        elseif event == "MAIL_CLOSED" then
            CleanupMailMarkers()
        end
    end)
    
    hooksecurefunc("InboxFrame_Update", function()
        if InboxFrame and InboxFrame:IsShown() then
            UpdateMailIndicators()
        end
    end)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self.elapsed = 0
    self:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed >= 1.5 then
            frame:SetScript("OnUpdate", nil)
            if RL and RL.PostUI then
                RL.PostUI:Initialize()
            end
        end
    end)
end)