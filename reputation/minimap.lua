local addonName, ns = ...
ReputationTrackerDB = ReputationTrackerDB or {}

local function GetDB()
    return ReputationTrackerDB
end

local DB = ReputationTrackerDB
local radius = 80
local parent = Minimap

local L = ReputationList.L or ReputationListLocale

if ElvUI and MinimapHolder then
    parent = MinimapHolder
end

local icon = CreateFrame("Button", "ReputationTrackerMinimapIcon", parent)
icon:SetFrameStrata("HIGH")
icon:SetSize(32, 32)
icon:EnableMouse(true)
icon:RegisterForClicks("LeftButtonUp", "MiddleButtonUp")
icon:Show()
icon:SetAlpha(1)
icon:SetNormalTexture(nil)
icon:SetPushedTexture(nil)
icon:SetHighlightTexture(nil)

local border = icon:CreateTexture(nil, "BACKGROUND")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetPoint("CENTER", icon, "CENTER", 10, -10)
border:SetSize(48, 48)

local highlight = icon:CreateTexture(nil, "HIGHLIGHT")
highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
highlight:SetPoint("CENTER", icon, "CENTER", 0, 0)
highlight:SetSize(44, 44)
highlight:SetBlendMode("ADD")

local text = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER", icon, "CENTER", 2, 0)
text:SetText("BL")
text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

local function SetPosition(angle)
    ReputationTrackerDB.minimapAngle = angle
    local rad = math.rad(angle)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", parent, "CENTER", x, y)
end

local function UpdateDrag()
    local mx, my = parent:GetCenter()
    local px, py = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local dx = px / scale - mx
    local dy = py / scale - my
    local angle = math.deg(math.atan2(dy, dx))
    SetPosition(angle)
end


local function OpenAddonUI()
    local RL = ReputationList
    if not RL then
        print(L["UI_CB54"])
        return
    end
    
    if RL.UI then
        -- Используем новый метод Toggle если доступен
        if RL.UI.ElvUI and RL.UI.ElvUI.Toggle then
            RL.UI.ElvUI:Toggle()
            return
        end
        
        if RL.UI.Classic and RL.UI.Classic.Toggle then
            RL.UI.Classic:Toggle()
            return
        end

        -- Поддержка старого метода через mainFrame
        if RL.UI.ElvUI and RL.UI.ElvUI.mainFrame then
            local frame = RL.UI.ElvUI.mainFrame
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
                if RL.UI.ElvUI.RefreshList then
                    RL.UI.ElvUI:RefreshList()
                end
            end
            return
        end
        
        if RL.UI.Classic and RL.UI.Classic.mainFrame then
            local frame = RL.UI.Classic.mainFrame
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
                if RL.UI.Classic.RefreshList then
                    RL.UI.Classic:RefreshList()
                end
            end
            return
        end
    end
    
    -- Поддержка команд
    if SlashCmdList["REPLISTNEW"] then
        SlashCmdList["REPLISTNEW"]("")
        return
    end
    
    print(L["UI_CB55"])
end
icon:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            -- Social UI (если есть)
            if RL.SocialUI and RL.SocialUI.Toggle then
                RL.SocialUI:Toggle()
            end
        else
            -- Открываем основной UI
            OpenAddonUI()
        end
	 elseif button == "MiddleButton" then
        icon:Hide()
        ReputationTrackerDB.hidden = true
    end
end)

icon:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        icon:SetScript("OnUpdate", UpdateDrag)
    end
end)

icon:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        icon:SetScript("OnUpdate", nil)
    end
end)

icon:SetScript("OnEnter", function()
    GameTooltip:SetOwner(icon, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cffffff00Reputation List|r")
    GameTooltip:AddLine(L["UI_CB57"])
    GameTooltip:AddLine(L["UI_CB58"])
    GameTooltip:AddLine(L["UI_CB59"])
    GameTooltip:Show()
end)

icon:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")

local minimapReady = false
local addonLoaded = false

loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "reputation" or arg1 == "ReputationList" then
            addonLoaded = true
        end
    elseif event == "PLAYER_LOGIN" then
        minimapReady = true
    end
    
    if minimapReady and addonLoaded then
        local db = ReputationTrackerDB
        if db.hidden then
            icon:Hide()
            return
        end
        if not db.minimapAngle then
            db.minimapAngle = 180
        end
        SetPosition(db.minimapAngle)
        icon:Show()
        
        self:UnregisterEvent("ADDON_LOADED")
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)