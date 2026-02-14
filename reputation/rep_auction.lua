local RL = ReputationList
if not RL then return end

local AuctionUI = {}
RL.AuctionUI = AuctionUI

local CACHE = {
    pendingBid = nil,
    confirmDialog = nil,
    originalPlaceAuctionBid = nil,
}

local useElvUI = false
if ElvUI then
    local E, _, _, _, _ = unpack(ElvUI)
    if E then
        useElvUI = true
    end
end

local L = ReputationList.L or ReputationListLocale

local function CheckSellerInBlacklist(seller)
    if not seller or not RL then return false end
    
    local normalizedName = RL.NormalizeName(seller):lower()
    local realmData = RL:GetRealmData()
    if not realmData then return false end
    
    if realmData.blacklist and realmData.blacklist[normalizedName] then
        return true, realmData.blacklist[normalizedName].note or ""
    end
    
    return false
end

local function CreateConfirmDialog()
    if CACHE.confirmDialog then
        return CACHE.confirmDialog
    end
    
    local dialog = CreateFrame("Frame", "ReputationListAuctionWarning", UIParent)
    dialog:SetSize(350, 150)
    dialog:SetPoint("CENTER", 0, 0)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(100)
    dialog:Hide()
    dialog:EnableMouse(true)
    
    if useElvUI then
        dialog:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        dialog:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        dialog:SetBackdropBorderColor(0, 0, 0, 1)
        
        local titleBg = dialog:CreateTexture(nil, "BORDER")
        titleBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        titleBg:SetPoint("TOPLEFT", 2, -2)
        titleBg:SetPoint("TOPRIGHT", -2, -2)
        titleBg:SetHeight(25)
        titleBg:SetVertexColor(0.1, 0.1, 0.1, 1)
        
        local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -8)
        title:SetText("ReputationList Warning")
        dialog.title = title
        
        local icon = dialog:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
        icon:SetSize(32, 32)
        icon:SetPoint("TOPLEFT", 12, -35)
        dialog.icon = icon
        
        local text = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 50, -35)
        text:SetPoint("TOPRIGHT", -12, -35)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        dialog.text = text
        
        local acceptBtn = CreateFrame("Button", nil, dialog)
        acceptBtn:SetSize(120, 22)
        acceptBtn:SetPoint("BOTTOM", -65, 20)
        acceptBtn:SetText(L["AUC03"])
        acceptBtn:SetNormalFontObject("GameFontNormal")
        acceptBtn:SetHighlightFontObject("GameFontHighlight")
        acceptBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        acceptBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        acceptBtn:SetBackdropBorderColor(0, 0, 0, 1)
        acceptBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.25, 0.25, 1)
            self:SetBackdropBorderColor(0.3, 0.8, 1, 1)
        end)
        acceptBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 1)
            self:SetBackdropBorderColor(0, 0, 0, 1)
        end)
        acceptBtn:SetScript("OnClick", function(self)
            dialog:Hide()
            if CACHE.pendingBid and CACHE.originalPlaceAuctionBid then
                local listType, index, bid = CACHE.pendingBid.listType, CACHE.pendingBid.index, CACHE.pendingBid.bid
                CACHE.pendingBid = nil
                CACHE.originalPlaceAuctionBid(listType, index, bid)
            end
        end)
        dialog.acceptBtn = acceptBtn
        
        local cancelBtn = CreateFrame("Button", nil, dialog)
        cancelBtn:SetSize(120, 22)
        cancelBtn:SetPoint("BOTTOM", 65, 20)
        cancelBtn:SetText(L["CANCEL"])
        cancelBtn:SetNormalFontObject("GameFontNormal")
        cancelBtn:SetHighlightFontObject("GameFontHighlight")
        cancelBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        cancelBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        cancelBtn:SetBackdropBorderColor(0, 0, 0, 1)
        cancelBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.25, 0.25, 0.25, 1)
            self:SetBackdropBorderColor(0.3, 0.8, 1, 1)
        end)
        cancelBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.15, 1)
            self:SetBackdropBorderColor(0, 0, 0, 1)
        end)
        cancelBtn:SetScript("OnClick", function(self)
            dialog:Hide()
            CACHE.pendingBid = nil
        end)
        dialog.cancelBtn = cancelBtn
    else
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = {left = 11, right = 12, top = 12, bottom = 11}
        })
        dialog:SetBackdropColor(0, 0, 0, 1)
        
        local header = dialog:CreateTexture(nil, "ARTWORK")
        header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
        header:SetWidth(256)
        header:SetHeight(64)
        header:SetPoint("TOP", 0, 12)
        
        local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", header, "TOP", 0, -14)
        title:SetText("ReputationList Warning")
        dialog.title = title
        
        local icon = dialog:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT", 24, 10)
        dialog.icon = icon
        
        local text = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 64, -32)
        text:SetPoint("TOPRIGHT", -24, -32)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        dialog.text = text
        
        local acceptBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        acceptBtn:SetSize(120, 22)
        acceptBtn:SetPoint("BOTTOM", -65, 20)
        acceptBtn:SetText(L["AUC03"])
        acceptBtn:SetScript("OnClick", function(self)
            dialog:Hide()
            if CACHE.pendingBid and CACHE.originalPlaceAuctionBid then
                local listType, index, bid = CACHE.pendingBid.listType, CACHE.pendingBid.index, CACHE.pendingBid.bid
                CACHE.pendingBid = nil
                CACHE.originalPlaceAuctionBid(listType, index, bid)
            end
        end)
        dialog.acceptBtn = acceptBtn
        
        local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        cancelBtn:SetSize(120, 22)
        cancelBtn:SetPoint("BOTTOM", 65, 20)
        cancelBtn:SetText(L["CANCEL"])
        cancelBtn:SetScript("OnClick", function(self)
            dialog:Hide()
            CACHE.pendingBid = nil
        end)
        dialog.cancelBtn = cancelBtn
    end
    
    dialog:SetScript("OnShow", function(self)
        PlaySound("igQuestFailed")
    end)
    
    dialog:SetScript("OnHide", function(self)
    end)
    
    CACHE.confirmDialog = dialog
    return dialog
end

function AuctionUI:HookPlaceAuctionBid()
    if CACHE.originalPlaceAuctionBid then
        return
    end
    
    CACHE.originalPlaceAuctionBid = PlaceAuctionBid
    
    PlaceAuctionBid = function(listType, index, bid)
        if not listType or not index then
            if CACHE.originalPlaceAuctionBid then
                return CACHE.originalPlaceAuctionBid(listType, index, bid)
            end
            return
        end
        
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo(listType, index)
        
        if owner then
            local isBlacklisted, note = CheckSellerInBlacklist(owner)
            
            if isBlacklisted then
                CACHE.pendingBid = {
                    listType = listType,
                    index = index,
                    bid = bid
                }
                
                local dialog = CreateConfirmDialog()
                
                local warningText = string.format(
                    L["AUC01"],
                    owner
                )
                
                if note ~= "" then
                    warningText = warningText .. string.format(L["AUC02"], note)
                end
                
                dialog.text:SetText(warningText)
                dialog:Show()
                return
            end
        end
        
        if CACHE.originalPlaceAuctionBid then
            return CACHE.originalPlaceAuctionBid(listType, index, bid)
        end
    end
end

function AuctionUI:Initialize()
    self:HookPlaceAuctionBid()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self.elapsed = 0
    self:SetScript("OnUpdate", function(frame, elapsed)
        frame.elapsed = frame.elapsed + elapsed
        if frame.elapsed >= 2 then
            frame:SetScript("OnUpdate", nil)
            if RL and RL.AuctionUI then
                RL.AuctionUI:Initialize()
            end
        end
    end)
end)