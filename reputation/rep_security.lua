-- ====================================================================
-- ReputationList Security Module for WoW 3.3.5a
-- ====================================================================

ReputationList = ReputationList or {}
local RL = ReputationList

RL.Security = {}
local Security = RL.Security

function Security:SanitizeString(str, maxLength)
    if not str or type(str) ~= "string" or str == "" then 
        return ""
    end
    
    maxLength = maxLength or 200
    if #str > maxLength then
        str = str:sub(1, maxLength)
    end
    
    str = str:gsub("[%z\1-\8\11-\31\127]", "")
    
    str = str:gsub("\\", "\\\\")
    str = str:gsub('"', '\\"')
    str = str:gsub("'", "\\'")
    str = str:gsub("\n", "\\n")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\t", "\\t")
    
    str = str:gsub("[%[%]%-]+", function(s)
		if s == "[[" or s == "]]" or s == "--" then
			return ""
		end
		return s
	end)
    
    return str
end

function Security:ValidatePlayerName(name)
    if not name or type(name) ~= "string" then
        return nil, "Имя должно быть строкой"
    end
    
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    
    local charCount = 0
    for char in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        charCount = charCount + 1
    end
    
    if charCount < 2 then
        return nil, "Имя слишком короткое (минимум 2 символа)"
    end
    
    if charCount > 12 then
        return nil, "Имя слишком длинное (максимум 12 символов)"
    end
    
    local firstChar = name:sub(1,1)
    if firstChar:match("%l") then
        name = firstChar:upper() .. name:sub(2)
    end
    
    return name, nil
end

function Security:NormalizeName(name)
    if not name then return nil end
    local short = name:match("^[^-]+") or name
    short = short:gsub("^%s+", ""):gsub("%s+$", "")
    return short
end

function Security:IsInBlizzardIgnore(name)
    if not name then return false end
    name = self:NormalizeName(name)
    if not name then return false end
    
    local lowerName = name:lower()
    for i = 1, GetNumIgnores() do
        local ignoredName = GetIgnoreName(i)
        if ignoredName then
            local normalizedIgnored = self:NormalizeName(ignoredName)
            if normalizedIgnored and normalizedIgnored:lower() == lowerName then
                return true, ignoredName
            end
        end
    end
    return false, nil
end

function Security:ValidateGUID(guid)
    if not guid then 
        return false 
    end
    
    local guidType = type(guid)
    
    if guidType == "string" then
        if guid:match("^0x%x+$") and #guid >= 10 and #guid <= 18 then
            return true
        end
        
        if guid:match("^Player%-%d+%-%d+%-%d+$") then
            return true
        end
        
        return false
    end
    
    if guidType == "number" then
        if guid > 0 and guid < 2^63 then
            return true
        end
    end
    
    return false
end

function Security:NormalizeGUID(guid)
    if not self:ValidateGUID(guid) then
        return nil
    end
    
    if type(guid) == "string" and guid:match("^0x%x+$") then
        return guid:lower()
    end
    
    if type(guid) == "number" then
        return string.format("0x%016x", guid):lower()
    end
    
    if type(guid) == "string" and guid:match("^Player%-") then
        return guid
    end
    
    return nil
end

function Security:CompareGUIDs(guid1, guid2)
    local norm1 = self:NormalizeGUID(guid1)
    local norm2 = self:NormalizeGUID(guid2)
    
    if not norm1 or not norm2 then
        return false
    end
    
    return norm1 == norm2
end


Security.suspiciousActivity = {
    invalidGUIDs = {},
    invalidNames = {},
    maxAttempts = 10,
    banDuration = 300
}

function Security:CheckGUIDSecurity(guid, source)
    if not self:ValidateGUID(guid) then
        local currentTime = time()
        source = source or "unknown"
        
        if not self.suspiciousActivity.invalidGUIDs[source] then
            self.suspiciousActivity.invalidGUIDs[source] = {
                count = 0,
                firstSeen = currentTime,
                lastSeen = currentTime
            }
        end
        
        local attempts = self.suspiciousActivity.invalidGUIDs[source]
        attempts.count = attempts.count + 1
        attempts.lastSeen = currentTime
        
        if attempts.count > self.maxAttempts then
            if (currentTime - attempts.firstSeen) < self.banDuration then
                print("|cFFFF0000[RepList Security]|r Обнаружена подозрительная активность. Функции временно ограничены.")
                return false, "SECURITY_BLOCK"
            else
                attempts.count = 0
                attempts.firstSeen = currentTime
            end
        end
        
        return false, "INVALID_GUID"
    end
    
    return true, self:NormalizeGUID(guid)
end

function Security:CleanupSuspiciousActivity()
    local currentTime = time()
    
    for source, data in pairs(self.suspiciousActivity.invalidGUIDs) do
        if (currentTime - data.lastSeen) > 3600 then
            self.suspiciousActivity.invalidGUIDs[source] = nil
        end
    end
    
    for source, data in pairs(self.suspiciousActivity.invalidNames) do
        if (currentTime - data.lastSeen) > 3600 then
            self.suspiciousActivity.invalidNames[source] = nil
        end
    end
end

if RL.TimerManager then
    RL.TimerManager:Register("security_cleanup", 600, function()
        Security:CleanupSuspiciousActivity()
    end)
end


RL.SanitizeString = function(str, maxLen) 
    return Security:SanitizeString(str, maxLen) 
end

RL.ValidatePlayerName = function(name) 
    return Security:ValidatePlayerName(name) 
end

RL.NormalizeName = function(name)
    return Security:NormalizeName(name)
end

RL.IsInBlizzardIgnore = function(name)
    return Security:IsInBlizzardIgnore(name)
end

RL.ValidateGUID = function(guid) 
    return Security:ValidateGUID(guid) 
end

RL.NormalizeGUID = function(guid) 
    return Security:NormalizeGUID(guid) 
end

RL.CompareGUIDs = function(g1, g2) 
    return Security:CompareGUIDs(g1, g2) 
end

RL.CheckGUIDSecurity = function(guid, source)
    return Security:CheckGUIDSecurity(guid, source)
end
