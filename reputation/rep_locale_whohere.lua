-- ============================================================================
-- Reputation List - Additional Localization for "Who's Here?" feature
-- Дополнительная локализация для функции "Кто здесь?"
-- ============================================================================

local RL = ReputationList
if not RL or not RL.L then return end

local L = RL.L

L["UI_WHO_HERE"] = "Кто здесь?"
L["UI_WHO_HERE_TT"] = "Показать игроков в текущей группе/рейде.\nИгроки из списков будут выделены соответствующим цветом."
L["UI_NOT_IN_GROUP"] = "Вы не находитесь в группе или рейде!"
L["UI_ADDED_FROM_GROUP"] = "Добавлен из группы"

if GetLocale() == "enUS" or GetLocale() == "enGB" then
    L["UI_WHO_HERE"] = "Who's Here?"
    L["UI_WHO_HERE_TT"] = "Show players in current group/raid.\nPlayers from lists will be highlighted with corresponding color."
    L["UI_NOT_IN_GROUP"] = "You are not in a group or raid!"
    L["UI_ADDED_FROM_GROUP"] = "Added from group"
end

print("|cFF00FF00ReputationList:|r Additional localization for 'Who's Here?' loaded")
