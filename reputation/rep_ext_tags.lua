ReputationList = ReputationList or {}
local RL = ReputationList

if not RL.GetRealmData then
    return
end

RL.Tags = RL.Tags or {}
local TAGS = RL.Tags

local LIST_TYPES = { "blacklist", "whitelist", "notelist" }

function TAGS:ExtractTags(note)
    local tags = {}
    if not note or note == "" then return tags end
    for tag in note:gmatch("#([^%s#]+)") do
        table.insert(tags, tag)
    end
    return tags
end

function TAGS:GetFirstTag(note)
    if not note or note == "" then return "" end
    return note:match("#([^%s#]+)") or ""
end

function TAGS:HasTag(note, tagName)
    if not tagName or tagName == "" then return false end
    local folded = RL.FoldCaseRU and RL.FoldCaseRU(tagName) or tagName:lower()
    if not note or note == "" then return false end
    for t in note:gmatch("#([^%s#]+)") do
        local tFolded = RL.FoldCaseRU and RL.FoldCaseRU(t) or t:lower()
        if tFolded == folded then return true end
    end
    return false
end

local ALL_TAGS_CACHE = {}

function TAGS:GetAllTags()
    for k in pairs(ALL_TAGS_CACHE) do ALL_TAGS_CACHE[k] = nil end
    local realmData = RL:GetRealmData()
    if not realmData then return ALL_TAGS_CACHE end

    for _, listType in ipairs(LIST_TYPES) do
        local list = realmData[listType]
        if list then
            for _, entry in pairs(list) do
                if entry.note and entry.note ~= "" then
                    for tag in entry.note:gmatch("#([^%s#]+)") do
                        ALL_TAGS_CACHE[tag] = (ALL_TAGS_CACHE[tag] or 0) + 1
                    end
                end
            end
        end
    end
    return ALL_TAGS_CACHE
end

function TAGS:GetSortedTagNames()
    local all = self:GetAllTags()
    local names = {}
    for tag in pairs(all) do table.insert(names, tag) end
    table.sort(names, function(a, b)
        local fa = RL.FoldCaseRU and RL.FoldCaseRU(a) or a:lower()
        local fb = RL.FoldCaseRU and RL.FoldCaseRU(b) or b:lower()
        return fa < fb
    end)
    return names, all
end
