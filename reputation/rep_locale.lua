-- ============================================================================
-- Reputation List - Localization Module
-- Система локализации для WoW 3.3.5a
-- Поддерживаемые языки: Русский (ruRU), Английский (enUS, enGB)
-- ============================================================================

local RL = ReputationList
if not RL then return end

RL.L = {}
local L = RL.L

local locale = GetLocale()

local function NormalizeLocale(loc)
    if not loc then return "enUS" end
    
    local lowerLoc = loc:lower()
    
    if lowerLoc == "ruru" then
        return "ruRU"
    end
    
    if lowerLoc:find("en") or lowerLoc == "enus" or lowerLoc == "engb" then
        return "enUS"
    end

    return "enUS"

end

local normalizedLocale = NormalizeLocale(locale)


local Translations = {
    ["ruRU"] = {
        ["ADDON_LOADED"] = "загружен на реалме",
        ["USE_HELP"] = "Используйте",
        ["FOR_HELP"] = "для справки",
        ["CURRENT_REALM"] = "Текущий realm:",
        ["UNKNOWN_COMMAND"] = "Неизвестная команда. Используйте /rlist help",
        
        ["ADDON_NOT_FOUND"] = "Аддон %s не найден или не загружен",
        ["ADDON_NO_DATA"] = "Аддон %s не найден или не содержит данных",
        ["IMPORTED_PLAYERS"] = "Импортировано %d игроков из %s",
        ["IMPORTED_FROM"] = "Импортировано из",
        ["IMPORT_USAGE"] = "Использование: /rlist import [blacklist|elitist|ignoremore]",
        
        ["OLD_DATA_DETECTED"] = "Обнаружены данные старой версии, выполняется миграция...",
        ["MIGRATION_COMPLETE"] = "Миграция завершена! Данные перенесены на realm:",
        
        ["ADD_USAGE"] = "Использование: /rlist add [black/white/note] [Имя] [заметка]",
        ["INVALID_NAME"] = "Некорректное имя игрока",
        ["INVALID_LIST_TYPE"] = "Неверный тип списка",
        ["PLAYER_ADDED"] = "Игрок %s добавлен в %s",
        ["NO_PLAYER_NAME"] = "Не указано имя игрока",
        ["PLAYERS_ADDED"] = "Добавлено %d игроков в %s",
        
        ["REMOVE_USAGE"] = "Использование: /rlist remove [black/white/note] [Имя]",
        ["PLAYER_REMOVED"] = "Игрок %s удален из %s",
        ["PLAYER_NOT_FOUND"] = "Игрок %s не найден в %s",
        
        ["CHECK_USAGE"] = "Использование: /rlist check [Имя]",
        
        ["LIST_USAGE"] = "Использование: /rlist list [black/white/note]",
        ["LIST_EMPTY"] = "Список пуст",
        ["TOTAL_ENTRIES"] = "Всего записей:",
        
        ["AUTO_NOTIFY_ON"] = "Автооповещение в чат группы включено",
        ["AUTO_NOTIFY_OFF"] = "Автооповещение в чат группы выключено",
        ["SELF_NOTIFY_ON"] = "Оповещение себе в ЛС включено",
        ["SELF_NOTIFY_OFF"] = "Оповещение себе в ЛС выключено",
        ["COLOR_LFG_ON"] = "Окрашивание LFG включено",
        ["COLOR_LFG_OFF"] = "Окрашивание LFG выключено",
        ["SOUND_NOTIFY_ON"] = "Звук и всплывающие окна включены",
        ["SOUND_NOTIFY_OFF"] = "Звук и всплывающие окна выключены",
        
        ["NICK_CHANGE_DETECTED"] = "Обнаружена смена ника:",
        ["CLASS_CHANGED"] = "%s сменил класс:",
        ["RACE_CHANGED"] = "%s сменил расу:",
        ["FACTION_CHANGED"] = "%s сменил фракцию:",
        
        ["NOT_LEADER"] = "Вы не являетесь лидером группы/рейда",
        ["CANNOT_KICK_COMBAT"] = "Невозможно исключить игрока во время боя",
        ["TRYING_TO_KICK_RAID"] = "Попытка исключить %s из рейда (индекс: %d)",
        ["TRYING_TO_KICK_PARTY"] = "Попытка исключить %s из группы",
        
        ["BLOCKED_INVITE"] = "Заблокирован инвайт от игрока из ЧС:",
        ["BLOCKED_TRADE"] = "Заблокирован трейд от игрока из ЧС:",
        ["BLACKLIST_WHISPER"] = "пишет вам!",
        
        ["ERROR_TARGET_NOT_EXIST"] = "Ошибка: цель не существует",
        ["ERROR_NOT_PLAYER"] = "Ошибка: '%s' не является игроком!",
        ["UI_MODULE_NOT_FOUND"] = "UI модуль не найден.",
        ["UI_NOT_READY"] = "UI не готов.",
        
        ["MINIMAP_RESTORED"] = "иконка миникарты восстановлена.",
        ["MINIMAP_NOT_FOUND"] = "иконка ещё не найдена.",
        ["MINIMAP_SHOWN_WRONG_POS"] = "иконка показана, но позиция может быть неверной.",
        ["MINIMAP_USE_RMB"] = "Используйте ПКМ для перемещения или /reload для сброса.",
        ["MINIMAP_NOT_CREATED"] = "иконка миникарты ещё не создана.",
        ["SETTINGS_SAVED"] = "Настройки сохранены. Выполните /reload или перезайдите.",
        
        ["HELP_HEADER"] = "=== ReputationList Справка ===",
        ["HELP_ADD"] = "/rlist add [black/white/note] [Имя] [заметка] - Добавить игрока",
        ["HELP_REMOVE"] = "/rlist remove [black/white/note] [Имя] - Удалить игрока",
        ["HELP_CHECK"] = "/rlist check [Имя] - Проверить игрока",
        ["HELP_NOTIFY"] = "/rlist notify - Проверить группу вручную",
        ["HELP_AUTO"] = "/rlist auto - Вкл/выкл автооповещение в чат",
        ["HELP_SELF"] = "/rlist self - Вкл/выкл оповещение себе в ЛС",
        ["HELP_COLOR"] = "/rlist color - Вкл/выкл окрашивание в LFG",
        ["HELP_SOUND"] = "/rlist sound - Вкл/выкл звук и всплывающие окна",
        ["HELP_LIST"] = "/rlist list [black/white/note] - Показать список",
        ["HELP_REALM"] = "/rlist realm - Показать текущий realm",
        ["HELP_RMAP"] = "/rmap или /rlmap - Восстановить отображение иконки на мини-карте",
        ["HELP_IMPORT_BL"] = "/rlist import blacklist - Импорт из аддона Blacklist",
        ["HELP_IMPORT_EL"] = "/rlist import elitist - Импорт из аддона Elitist",
        ["HELP_IMPORT_IM"] = "/rlist import ignoremore - Импорт из аддона IgnoreMore",
        ["HELP_RMB"] = "ПКМ по игроку - Добавить через меню",
        ["HELP_COMMANDS"] = "Команды: /rlist ui, /rlist map, /rlist add [имя]",
        
        ["BLACKLIST"] = "Чёрный список",
        ["WHITELIST"] = "Белый список",
        ["NOTELIST"] = "Заметки",
        
        ["UI_TITLE_BLACKLIST"] = "Reputation List - Чёрный список",
        ["UI_TITLE_WHITELIST"] = "Reputation List - Белый список",
        ["UI_TITLE_NOTELIST"] = "Reputation List - Заметки",
        ["UI_SEARCH"] = "Поиск...",
        ["UI_ADD"] = "Добавить",
        ["UI_REMOVE"] = "Удалить",
        ["UI_CLEAR_ALL"] = "Очистить всё",
        ["UI_EXPORT"] = "Экспорт",
        ["UI_IMPORT"] = "Импорт",
        ["UI_SETTINGS"] = "Настройки",
        ["UI_CLOSE"] = "Закрыть",
        ["UI_SAVE"] = "Сохранить",
        ["UI_CANCEL"] = "Отмена",
        ["UI_YES"] = "Да",
        ["UI_NO"] = "Нет",
        ["UI_PLAYER_NAME"] = "Имя игрока",
        ["UI_NOTE"] = "Заметка",
        ["UI_DATE_ADDED"] = "Дата добавления",
        ["UI_ADDED_BY"] = "Добавил",
        ["UI_CLASS"] = "Класс",
        ["UI_LEVEL"] = "Уровень",
        ["UI_GUILD"] = "Гильдия",
        ["UI_KICK_FROM_GROUP"] = "Кикнуть из группы",
        ["UI_COPY_NAME"] = "Скопировать имя",
        ["UI_EDIT_NOTE"] = "Редактировать заметку",
        ["UI_MOVE_TO"] = "Переместить в",
        ["UI_DELETE"] = "Удалить",
		["UI_IG"] = "игнор",
		["UI_UNLOCK"] = "разбл.",
		["UI_GT"] = "Исключить игрока",
		["UI_GTline"] = "Добавить в Blacklist и исключить из группы/рейда",
		["UI_TGTPL"] = "Выберите игрока в таргет",
		["UI_CHECK"] = "Проверить и оповестить",
		["UI_CHKGR"] = "ПРОВЕРИТЬ игроков в группе или рейде",
		["UI_ACTION"] = "Действия",
		["UI_EDITT"] = "Редактировать",
		["UI_IG_F"] = "Игнорировать",
		["UI_UNL_F"] = "Разблокировать",
		["UI_INF"] = "Информация",
		["UI_NM"] = "Имя",
		["UI_NM_INPT"] = "Введите имя игрока",
		["UI_PLR"] = "Игрок ",
		["UI_DLPL"] = " удален",
		["UI_NT_UP"] = "Заметка обновлена",
		["UI_DAL"] = "Добавить %s в Blacklist и исключить из группы",
		["UI_BAD_P"] = "Нежелательный игрок",
		["UI_OUT_R"] = " исключен из рейда",
		["UI_OUT_G"] = " исключен из группы",
		["UI_RM_IG"] = " убран из игнор-листа",
		["UI_BLIZ_F"] = "Игнор-лист переполнен (максимум 50)",
		["UI_BLACK"] = " добавлен в игнор-лист",
		["UI_LBL_NM"] = "|cFFFFFF00Имя:|r",
		["UI_LBL_CL"] = "|cFFFFFF00Класс:|r",
		["UI_LBL_RC"] = "|cFFFFFF00Раса:|r",
		["UI_LBL_GLD"] = "|cFFFFFF00Гильдия:|r",
		["UI_LBL_NT"] = "|cFFFF0000ЗАМЕТКА:|r",
		["UI_F_UN"] = "Неизвестно",
		["UI_F_UNO"] = "Неизвестен",
		["UI_F_UN2"] = "Неизвестна",
		["UI_F_V"] = "Не записан",
		["UI_F_N"] = "Без заметки",
		["UI_POP1"] = "ВНИМАНИЕ ",
		["UI_POP2"] = "ДОВЕРЕННЫЙ ",
		["UI_POP3"] = "ЗАМЕТКА ",
		["UI_UVD"] = "Уведомления",
		["UI_DEF"] = "Блокировать от BL",
		["UI_CB1"] = "Авто-оповещение",
		["UI_CB2"] = "Настройка изменена.",
		["UI_CB3"] = "Приглашения",
		["UI_CB4"] = "Уведомлять в ЛС",
		["UI_CB5"] = "Обмен",
		["UI_CB6"] = "Подсвечивать чат",
		["UI_CB7"] = "Сообщения",
		["UI_CB8"] = "Всплывающие окна",
		["UI_CB9"] = "Экспорт списков",
		["UI_CB10"] = "Импорт списков",
		["UI_CB11"] = "|cFFFF0000Экспорт уже выполняется!|r",
		["UI_CB12"] = "Начинается экспорт...",
		["UI_CB13"] = "Подготовка: %d / %d (%.0f%%)",
		["UI_CB14"] = "Экспорт: %d / %d (%.0f%%)",
		["UI_CB15"] = "|cFF00FF00Экспорт данных|r",
		["UI_CB16"] = "|cFFFFFFFFИгра не зависла, идёт обработка...|r",
		["UI_CB17"] = "Неизвестный формат данных",
		["UI_CB18"] = "Пустые данные",
		["UI_CB19"] = "Импорт из BlackList",
		["UI_CB20"] = "Импорт из ElitistGroup",
		["UI_CB21"] = "Выделить всё",
		["UI_CB22"] = "|cFFFF0000Нет данных для импорта|r",
		["UI_CB23"] = "|cFFFF0000Ошибка: ",
		["UI_CB24"] = "|cFF00FF00Формат:|r ",
		["UI_CB25"] = "|cFFFF0000Ошибка: неверный формат|r",
		["UI_CB26"] = "|cFFFF0000Ошибка выполнения|r",
		["UI_CB27"] = "|cFF00FF00Импорт завершён! Добавлено: ",
		["UI_CB28"] = "|cFFFF0000Нет новых данных|r",
		["UI_CB29"] = "|cFFFF0000Ошибка открытия окна экспорта|r",
		["UI_CB30"] = "Подготовка данных...\n\nПодождите, идёт подсчёт игроков...",
		["UI_CB31"] = "|cFF00FF00ReputationList:|r Начинается экспорт...",
		["UI_CB32"] = "|cFF00FF00ReputationList:|r Экспорт завершен! Записей: %d",
		["UI_CB33"] = "|cFFFF0000Ошибка открытия окна импорта|r",
		["UI_CB34"] = "|cFF00FF00ReputationList:|r Новый UI загружен! Команда: /rlnew",
		["UI_CB35"] = "|cFF00FF00ReputationList:|r ElvUI обнаружен. Классический UI не загружается.",
		["UI_CB36"] = "|cFF00FF00ReputationList:|r Загрузите файл rep_ui_elvui.lua для стиля ElvUI",
		["UI_CB37"] = "Оповестить",
		["UI_CB38"] = "Исключить",
		["UI_CB39"] = "Игрок:",
		["UI_CB40"] = "Заметка:",
		["UI_CB41"] = " из списка?",
		["UI_CB42"] = "Удалить ",
		["UI_CB43"] = "Редактировать заметку для ",
		["UI_CB44"] = "Сохранить",
		["UI_CB45"] = "|cFFFFFF00Уровень:|r",
		["UI_CB46"] = "Подготовка...",
		["UI_CB47"] = "Импортировать",
		["UI_CB48"] = "|cFF00FF00ReputationList:|r ElvUI стиль загружен! Команды: |cFF00FFFF/rlelvui|r или |cFF00FFFF/rlnew|r",
		["UI_CB49"] = "|cFF00FF00ReputationList:|r ElvUI стиль активирован!",
		["UI_CB50"] = "|cFFFF0000ReputationList:|r ElvUI не обнаружен. ElvUI UI не загружается.",
		["UI_CB51"] = "Информация о ",
		["UI_CB52"] = "Нажмите, чтобы открыть ReputationList",
		["UI_CB53"] = "|cFFFF0000ReputationList:|r FriendsFrame не найден",
		["UI_CB54"] = "|cFFFF8800ReputationList:|r Аддон не загружен",
		["UI_CB55"] = "|cFFFF8800ReputationList:|r UI не инициализирован. Попробуйте /rlnew",
		["UI_CB56"] = "|cFFFF0000ReputationList:|r Команда интерфейса не найдена.",
		["UI_CB57"] = "ЛКМ - открыть интерфейс",
		["UI_CB58"] = "ПКМ (удерживая) - переместить",
		["UI_CB59"] = "СКМ - скрыть",
		["UI_CB60"] = " загружен на реалме |cFFFFAA00",
		["UI_CB61"] = "Используйте |cFFFFFF00/rlist help|r для справки",
		["UI_CB62"] = "|cFF00FF00=== ReputationList Справка ===|r",
		["UI_CB63"] = "|cFFFFFF00/rlist add [black/white/note] [Имя] [заметка]|r - Добавить игрока",
		["UI_CB64"] = "|cFFFFFF00/rlist remove [black/white/note] [Имя]|r - Удалить игрока",
		["UI_CB65"] = "|cFFFFFF00/rlist check [Имя]|r - Проверить игрока",
		["UI_CB66"] = "|cFFFFFF00/rlist notify|r - Проверить группу вручную",
		["UI_CB67"] = "|cFFFFFF00/rlist auto|r - Вкл/выкл автооповещение в чат",
		["UI_CB68"] = "|cFFFFFF00/rlist self|r - Вкл/выкл оповещение себе в ЛС",
		["UI_CB69"] = "|cFFFFFF00/rlist color|r - Вкл/выкл окрашивание в LFG",
		["UI_CB70"] = "|cFFFFFF00/rlist sound|r - Вкл/выкл звук и всплывающие окна",
		["UI_CB71"] = "|cFFFFFF00/rlist list [black/white/note]|r - Показать список",
		["UI_CB72"] = "|cFFFFFF00/rlist realm|r - Показать текущий realm",
		["UI_CB73"] = "|cFFFFFF00/rmap или /rlmap|r - Восстановить отображение иконки на мини-карте",
		["UI_CB74"] = "|cFFFFFF00/rlist import blacklist|r - Импорт из аддона Blacklist",
		["UI_CB75"] = "|cFFFFFF00/rlist import elitist|r - Импорт из аддона Elitist",
		["UI_CB76"] = "|cFFFFFF00/rlist import ignoremore|r - Импорт из аддона IgnoreMore",
		["UI_CB77"] = "|cFFFFFF00ПКМ по игроку|r - Добавить через меню",
		["UI_CB78"] = "Добавить в Blacklist",
		["UI_CB79"] = "Добавить в Whitelist",
		["UI_CB80"] = "Добавить в Notelist",
		["UI_CB81"] = "Добавить %s в список.\nВведите заметку:",
		["UI_CB82"] = "|cFF00FF00Reputation List:|r иконка миникарты восстановлена.",
		["UI_CB83"] = "|cFFFF0000Reputation List:|r иконка ещё не найдена.",
		["UI_CB84"] = "|cFFFFFF00Уровень:|r",
        
        ["SETTINGS_TITLE"] = "Настройки Reputation List",
        ["SETTINGS_AUTO_NOTIFY"] = "Автооповещение в чат группы",
        ["SETTINGS_SELF_NOTIFY"] = "Оповещение себе в ЛС",
        ["SETTINGS_COLOR_LFG"] = "Окрашивание имён в LFG",
        ["SETTINGS_SOUND_NOTIFY"] = "Звуковые уведомления",
        ["SETTINGS_POPUP_NOTIFY"] = "Всплывающие окна",
        ["SETTINGS_BLOCK_INVITES"] = "Блокировать инвайты от ЧС",
        ["SETTINGS_BLOCK_TRADE"] = "Блокировать трейд от ЧС",
        ["SETTINGS_FILTER_MESSAGES"] = "Фильтровать сообщения от ЧС",
        ["SETTINGS_MINIMAP"] = "Показывать иконку на миникарте",
        
        ["CONFIRM_CLEAR_ALL"] = "Вы уверены, что хотите очистить весь список?",
        ["CONFIRM_DELETE"] = "Удалить игрока %s из списка?",
        ["YES"] = "Да",
        ["NO"] = "Нет",
        ["CANCEL"] = "Отмена",
        ["OK"] = "ОК",
        
        ["RATING"] = "Рейтинг:",
        
        ["MEMORY_STATS"] = "[RepList Memory Stats]",
        ["NOTIFIED_PLAYERS"] = "Notified Players:",
        ["SHOWN_CARDS"] = "Shown Cards:",
        ["ALERT_COOLDOWNS"] = "Alert Cooldowns:",
        ["ALERT_QUEUE"] = "Alert Queue:",
    },
    
    ["enUS"] = {
        ["ADDON_LOADED"] = "loaded on realm",
        ["USE_HELP"] = "Use",
        ["FOR_HELP"] = "for help",
        ["CURRENT_REALM"] = "Current realm:",
        ["UNKNOWN_COMMAND"] = "Unknown command. Use /rlist help",
        
        ["ADDON_NOT_FOUND"] = "Addon %s not found or not loaded",
        ["ADDON_NO_DATA"] = "Addon %s not found or contains no data",
        ["IMPORTED_PLAYERS"] = "Imported %d players from %s",
        ["IMPORTED_FROM"] = "Imported from",
        ["IMPORT_USAGE"] = "Usage: /rlist import [blacklist|elitist|ignoremore]",
        
        ["OLD_DATA_DETECTED"] = "Old version data detected, migrating...",
        ["MIGRATION_COMPLETE"] = "Migration complete! Data transferred to realm:",
        
        ["ADD_USAGE"] = "Usage: /rlist add [black/white/note] [Name] [note]",
        ["INVALID_NAME"] = "Invalid player name",
        ["INVALID_LIST_TYPE"] = "Invalid list type",
        ["PLAYER_ADDED"] = "Player %s added to %s",
        ["NO_PLAYER_NAME"] = "No player name specified",
        ["PLAYERS_ADDED"] = "Added %d players to %s",
        
        ["REMOVE_USAGE"] = "Usage: /rlist remove [black/white/note] [Name]",
        ["PLAYER_REMOVED"] = "Player %s removed from %s",
        ["PLAYER_NOT_FOUND"] = "Player %s not found in %s",
        
        ["CHECK_USAGE"] = "Usage: /rlist check [Name]",
        
        ["LIST_USAGE"] = "Usage: /rlist list [black/white/note]",
        ["LIST_EMPTY"] = "List is empty",
        ["TOTAL_ENTRIES"] = "Total entries:",
        
        ["AUTO_NOTIFY_ON"] = "Auto-notify to group chat enabled",
        ["AUTO_NOTIFY_OFF"] = "Auto-notify to group chat disabled",
        ["SELF_NOTIFY_ON"] = "Self whisper notifications enabled",
        ["SELF_NOTIFY_OFF"] = "Self whisper notifications disabled",
        ["COLOR_LFG_ON"] = "LFG coloring enabled",
        ["COLOR_LFG_OFF"] = "LFG coloring disabled",
        ["SOUND_NOTIFY_ON"] = "Sound and popup notifications enabled",
        ["SOUND_NOTIFY_OFF"] = "Sound and popup notifications disabled",
        
        ["NICK_CHANGE_DETECTED"] = "Nickname change detected:",
        ["CLASS_CHANGED"] = "%s changed class:",
        ["RACE_CHANGED"] = "%s changed race:",
        ["FACTION_CHANGED"] = "%s changed faction:",
        
        ["NOT_LEADER"] = "You are not the group/raid leader",
        ["CANNOT_KICK_COMBAT"] = "Cannot kick player during combat",
        ["TRYING_TO_KICK_RAID"] = "Attempting to kick %s from raid (index: %d)",
        ["TRYING_TO_KICK_PARTY"] = "Attempting to kick %s from party",
        
        ["BLOCKED_INVITE"] = "Blocked invite from blacklisted player:",
        ["BLOCKED_TRADE"] = "Blocked trade from blacklisted player:",
        ["BLACKLIST_WHISPER"] = "is whispering you!",
        
        ["ERROR_TARGET_NOT_EXIST"] = "Error: target does not exist",
        ["ERROR_NOT_PLAYER"] = "Error: '%s' is not a player!",
        ["UI_MODULE_NOT_FOUND"] = "UI module not found.",
        ["UI_NOT_READY"] = "UI not ready.",
        
        ["MINIMAP_RESTORED"] = "minimap icon restored.",
        ["MINIMAP_NOT_FOUND"] = "icon not found yet.",
        ["MINIMAP_SHOWN_WRONG_POS"] = "icon shown, but position may be incorrect.",
        ["MINIMAP_USE_RMB"] = "Use RMB to move or /reload to reset.",
        ["MINIMAP_NOT_CREATED"] = "minimap icon not created yet.",
        ["SETTINGS_SAVED"] = "Settings saved. Execute /reload or relog.",
        
        ["HELP_HEADER"] = "=== ReputationList Help ===",
        ["HELP_ADD"] = "/rlist add [black/white/note] [Name] [note] - Add player",
        ["HELP_REMOVE"] = "/rlist remove [black/white/note] [Name] - Remove player",
        ["HELP_CHECK"] = "/rlist check [Name] - Check player",
        ["HELP_NOTIFY"] = "/rlist notify - Check group manually",
        ["HELP_AUTO"] = "/rlist auto - Toggle auto-notify to chat",
        ["HELP_SELF"] = "/rlist self - Toggle self whisper notifications",
        ["HELP_COLOR"] = "/rlist color - Toggle LFG coloring",
        ["HELP_SOUND"] = "/rlist sound - Toggle sound and popups",
        ["HELP_LIST"] = "/rlist list [black/white/note] - Show list",
        ["HELP_REALM"] = "/rlist realm - Show current realm",
        ["HELP_RMAP"] = "/rmap or /rlmap - Restore minimap icon display",
        ["HELP_IMPORT_BL"] = "/rlist import blacklist - Import from Blacklist addon",
        ["HELP_IMPORT_EL"] = "/rlist import elitist - Import from Elitist addon",
        ["HELP_IMPORT_IM"] = "/rlist import ignoremore - Import from IgnoreMore addon",
        ["HELP_RMB"] = "RMB on player - Add via menu",
        ["HELP_COMMANDS"] = "Commands: /rlist ui, /rlist map, /rlist add [name]",
        
        ["BLACKLIST"] = "Blacklist",
        ["WHITELIST"] = "Whitelist",
        ["NOTELIST"] = "Notes",
        
        ["UI_TITLE_BLACKLIST"] = "Reputation List - Blacklist",
        ["UI_TITLE_WHITELIST"] = "Reputation List - Whitelist",
        ["UI_TITLE_NOTELIST"] = "Reputation List - Notes",
        ["UI_SEARCH"] = "Search...",
        ["UI_ADD"] = "Add",
        ["UI_REMOVE"] = "Remove",
        ["UI_CLEAR_ALL"] = "Clear All",
        ["UI_EXPORT"] = "Export",
        ["UI_IMPORT"] = "Import",
        ["UI_SETTINGS"] = "Settings",
        ["UI_CLOSE"] = "Close",
        ["UI_SAVE"] = "Save",
        ["UI_CANCEL"] = "Cancel",
        ["UI_YES"] = "Yes",
        ["UI_NO"] = "No",
        ["UI_PLAYER_NAME"] = "Player Name",
        ["UI_NOTE"] = "Note",
        ["UI_DATE_ADDED"] = "Date Added",
        ["UI_ADDED_BY"] = "Added By",
        ["UI_CLASS"] = "Class",
        ["UI_LEVEL"] = "Level",
        ["UI_GUILD"] = "Guild",
        ["UI_KICK_FROM_GROUP"] = "Kick from Group",
        ["UI_COPY_NAME"] = "Copy Name",
        ["UI_EDIT_NOTE"] = "Edit Note",
        ["UI_MOVE_TO"] = "Move to",
        ["UI_DELETE"] = "Delete",
		["UI_IG"] = "ignor",
		["UI_UNLOCK"] = "unlock",
		["UI_GT"] = "Kick player",
		["UI_GTline"] = "Add to Blacklist and kick from party/raid",
		["UI_TGTPL"] = "Select a player as target",
		["UI_CHECK"] = "Check and notify",
		["UI_CHKGR"] = "CHECK players in party or raid",
		["UI_ACTION"] = "Actions",
		["UI_EDITT"] = "Edit",
		["UI_IG_F"] = "Ignore",
		["UI_UNL_F"] = "Unblock",
		["UI_INF"] = "Info",
		["UI_NM"] = "Name",
		["UI_NM_INPT"] = "Enter player name",
		["UI_PLR"] = "Player ",
		["UI_DLPL"] = " removed",
		["UI_NT_UP"] = "Note updated",
		["UI_DAL"] = "Add %s to Blacklist and kick from party",
		["UI_BAD_P"] = "Blacklisted player",
		["UI_OUT_R"] = " kicked from raid",
		["UI_OUT_G"] = " kicked from party",
		["UI_RM_IG"] = " removed from ignore list",
		["UI_BLIZ_F"] = "Ignore list is full (maximum 50)",
		["UI_BLACK"] = " added to ignore list",
		["UI_LBL_NM"] = "|cFFFFFF00Name:|r",
		["UI_LBL_CL"] = "|cFFFFFF00Class:|r",
		["UI_LBL_RC"] = "|cFFFFFF00Race:|r",
		["UI_LBL_GLD"] = "|cFFFFFF00Guild:|r",
		["UI_LBL_NT"] = "|cFFFF0000NOTE:|r",
		["UI_F_UN"] = "Unknown",
		["UI_F_UNO"] = "Unknown",
		["UI_F_UN2"] = "Unknown",
		["UI_F_V"] = "Not recorded",
		["UI_F_N"] = "No note",
		["UI_POP1"] = "WARNING ",
		["UI_POP2"] = "TRUSTED ",
		["UI_POP3"] = "NOTE ",
		["UI_UVD"] = "Notifications",
		["UI_DEF"] = "Block BL",
		["UI_CB1"] = "Auto-notification",
		["UI_CB2"] = "Setting changed.",
		["UI_CB3"] = "Invitations",
		["UI_CB4"] = "Notify in whisper",
		["UI_CB5"] = "Trading",
		["UI_CB6"] = "Highlight chat",
		["UI_CB7"] = "Messages",
		["UI_CB8"] = "Popups",
		["UI_CB9"] = "Export lists",
		["UI_CB10"] = "Import lists",
		["UI_CB11"] = "|cFFFF0000Export already in progress!|r",
		["UI_CB12"] = "Export starting...",
		["UI_CB13"] = "Preparing: %d / %d (%.0f%%)",
		["UI_CB14"] = "Exporting: %d / %d (%.0f%%)",
		["UI_CB15"] = "|cFF00FF00Data Export|r",
		["UI_CB16"] = "|cFFFFFFFFGame is not frozen, processing...|r",
		["UI_CB17"] = "Unknown data format",
		["UI_CB18"] = "Empty data",
		["UI_CB19"] = "Import from Blacklist",
		["UI_CB20"] = "Import from ElitistGroup",
		["UI_CB21"] = "Select all",
		["UI_CB22"] = "|cFFFF0000No data to import|r",
		["UI_CB23"] = "|cFFFF0000Error: ",
		["UI_CB24"] = "|cFF00FF00Format:|r ",
		["UI_CB25"] = "|cFFFF0000Error: invalid format|r",
		["UI_CB26"] = "|cFFFF0000Execution error|r",
		["UI_CB27"] = "|cFF00FF00Import completed! Added: ",
		["UI_CB28"] = "|cFFFF0000No new data|r",
		["UI_CB29"] = "|cFFFF0000Error opening export window|r",
		["UI_CB30"] = "Preparing data...\n\nPlease wait, counting players...",
		["UI_CB31"] = "|cFF00FF00ReputationList:|r Export starting...",
		["UI_CB32"] = "|cFF00FF00ReputationList:|r Export completed! Records: %d",
		["UI_CB33"] = "|cFFFF0000Error opening import window|r",
		["UI_CB34"] = "|cFF00FF00ReputationList:|r New UI loaded! Command: /rlnew",
		["UI_CB35"] = "|cFF00FF00ReputationList:|r ElvUI detected. Classic UI not loading.",
		["UI_CB36"] = "|cFF00FF00ReputationList:|r Load rep_ui_elvui.lua file for ElvUI style",
		["UI_CB37"] = "Notify",
		["UI_CB38"] = "Kick",
		["UI_CB39"] = "Player:",
		["UI_CB40"] = "Note:",
		["UI_CB41"] = " from list?",
		["UI_CB42"] = "Delete ",
		["UI_CB43"] = "Edit note for ",
		["UI_CB44"] = "Save",
		["UI_CB45"] = "|cFFFFFF00Level:|r",
		["UI_CB46"] = "Preparing...",
		["UI_CB47"] = "Import",
		["UI_CB48"] = "|cFF00FF00ReputationList:|r ElvUI style loaded! Commands: |cFF00FFFF/rlelvui|r or |cFF00FFFF/rlnew|r",
		["UI_CB49"] = "|cFF00FF00ReputationList:|r ElvUI style activated!",
		["UI_CB50"] = "|cFFFF0000ReputationList:|r ElvUI not detected. ElvUI UI not loading.",
		["UI_CB51"] = "Info about ",
		["UI_CB52"] = "Click to open ReputationList",
		["UI_CB53"] = "|cFFFF0000ReputationList:|r FriendsFrame not found",
		["UI_CB54"] = "|cFFFF8800ReputationList:|r Addon not loaded",
		["UI_CB55"] = "|cFFFF8800ReputationList:|r UI not initialized. Try /rlnew",
		["UI_CB56"] = "|cFFFF0000ReputationList:|r Interface command not found.",
		["UI_CB57"] = "Left-click - open interface",
		["UI_CB58"] = "Right-click (hold) - move",
		["UI_CB59"] = "Middle-click - hide",
		["UI_CB60"] = " loaded on realm |cFFFFAA00",
		["UI_CB61"] = "Use |cFFFFFF00/rlist help|r for help",
		["UI_CB62"] = "|cFF00FF00=== ReputationList Help ===|r",
		["UI_CB63"] = "|cFFFFFF00/rlist add [black/white/note] [Name] [note]|r - Add player",
		["UI_CB64"] = "|cFFFFFF00/rlist remove [black/white/note] [Name]|r - Remove player",
		["UI_CB65"] = "|cFFFFFF00/rlist check [Name]|r - Check player",
		["UI_CB66"] = "|cFFFFFF00/rlist notify|r - Check group manually",
		["UI_CB67"] = "|cFFFFFF00/rlist auto|r - Toggle auto-notification in chat",
		["UI_CB68"] = "|cFFFFFF00/rlist self|r - Toggle self-notification via whisper",
		["UI_CB69"] = "|cFFFFFF00/rlist color|r - Toggle LFG chat coloring",
		["UI_CB70"] = "|cFFFFFF00/rlist sound|r - Toggle sound and popup alerts",
		["UI_CB71"] = "|cFFFFFF00/rlist list [black/white/note]|r - Show list",
		["UI_CB72"] = "|cFFFFFF00/rlist realm|r - Show current realm",
		["UI_CB73"] = "|cFFFFFF00/rmap or /rlmap|r - Restore minimap icon display",
		["UI_CB74"] = "|cFFFFFF00/rlist import blacklist|r - Import from Blacklist addon",
		["UI_CB75"] = "|cFFFFFF00/rlist import elitist|r - Import from Elitist addon",
		["UI_CB76"] = "|cFFFFFF00/rlist import ignoremore|r - Import from IgnoreMore addon",
		["UI_CB77"] = "|cFFFFFF00Right-click on player|r - Add via context menu",
		["UI_CB78"] = "Add to Blacklist",
		["UI_CB79"] = "Add to Whitelist",
		["UI_CB80"] = "Add to Notelist",
		["UI_CB81"] = "Add %s to list.\nEnter note:",
		["UI_CB82"] = "|cFF00FF00Reputation List:|r Minimap icon restored.",
		["UI_CB83"] = "|cFFFF0000Reputation List:|r Icon not found yet.",
		["UI_CB84"] = "|cFFFFFF00Level:|r",
        
        ["SETTINGS_TITLE"] = "Reputation List Settings",
        ["SETTINGS_AUTO_NOTIFY"] = "Auto-notify to group chat",
        ["SETTINGS_SELF_NOTIFY"] = "Self whisper notifications",
        ["SETTINGS_COLOR_LFG"] = "Color names in LFG",
        ["SETTINGS_SOUND_NOTIFY"] = "Sound notifications",
        ["SETTINGS_POPUP_NOTIFY"] = "Popup notifications",
        ["SETTINGS_BLOCK_INVITES"] = "Block invites from blacklist",
        ["SETTINGS_BLOCK_TRADE"] = "Block trade from blacklist",
        ["SETTINGS_FILTER_MESSAGES"] = "Filter messages from blacklist",
        ["SETTINGS_MINIMAP"] = "Show minimap icon",
        
        ["CONFIRM_CLEAR_ALL"] = "Are you sure you want to clear the entire list?",
        ["CONFIRM_DELETE"] = "Delete player %s from list?",
        ["YES"] = "Yes",
        ["NO"] = "No",
        ["CANCEL"] = "Cancel",
        ["OK"] = "OK",
        
        ["RATING"] = "Rating:",
        
        ["MEMORY_STATS"] = "[RepList Memory Stats]",
        ["NOTIFIED_PLAYERS"] = "Notified Players:",
        ["SHOWN_CARDS"] = "Shown Cards:",
        ["ALERT_COOLDOWNS"] = "Alert Cooldowns:",
        ["ALERT_QUEUE"] = "Alert Queue:",
    }
}

Translations["enGB"] = Translations["enUS"]

local currentTranslations = Translations[normalizedLocale] or Translations["enUS"]

setmetatable(L, {
    __index = function(t, key)
        local translation = currentTranslations[key]
        if translation then
            return translation
        else
            print("|cFFFF0000ReputationList:|r Missing translation: " .. tostring(key))
            return key
        end
    end
})


function RL:GetLocalizedListName(listType)
    if listType == "blacklist" or listType == "black" then
        return L["BLACKLIST"]
    elseif listType == "whitelist" or listType == "white" then
        return L["WHITELIST"]
    elseif listType == "notelist" or listType == "note" then
        return L["NOTELIST"]
    end
    return listType
end

function RL:GetLocalizedUITitle(listType)
    if listType == "blacklist" then
        return L["UI_TITLE_BLACKLIST"]
    elseif listType == "whitelist" then
        return L["UI_TITLE_WHITELIST"]
    elseif listType == "notelist" then
        return L["UI_TITLE_NOTELIST"]
    end
    return "Reputation List"
end

function RL:GetCurrentLocale()
    return normalizedLocale
end

function RL:IsRussianLocale()
    return normalizedLocale == "ruRU"
end


ReputationListLocale = L