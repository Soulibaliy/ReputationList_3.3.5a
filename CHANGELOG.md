# Changelog

All notable changes to the Reputation List addon will be documented in this file.

## [2.1] - 2026-08-16

### Fixed:

- Card sync: tags, history, and Armory link are now transferred
- Fixed a bug where sending a new player's card would repeat the previous send
- Long tags in the list no longer overflow their colored badge - they're now truncated with an ellipsis
- Fixed text-format export/import bug
- Character card: the background under the "History" tab now adjusts to the text width, matching the "Note" tab
- Added English translation for history entries (Armory link updated, note changed, tag removed, moved between lists, guild/race/class changed, added from group, no note)
- The Blacklist and Whitelist export/import buttons in the transfer window now work only with their respective list instead of all lists

### Added:

- Context menu item (right-click on a player) - move to another list: Blacklist / Whitelist / Notelist
- The add-player form now defaults to the NL (Notelist) list
- Settings: interface language toggle, with the choice saved (requires a relog)
- Settings: interface design toggle (Classic / ElvUI), with the choice saved (requires a relog)
- The addon now defaults to English if the game client's language isn't Russian
- Main addon window resizing via the bottom-right corner, with all content scaling to fit and the chosen scale saved

## [2.0] - 2026-08-01

### Added

- Completely redesigned unified interface for the default Blizzard UI and ElvUI.
- Dedicated Blacklist, Whitelist, and Notelist tabs.
- Advanced search, sorting, and filtering by class, race, tag, and ignore status.
- Player tag system with quick tag filters.
- **Who's Here?** tab for inspecting current and recently tracked group or raid members.
- Global History tab with player search.
- Synchronization of complete lists, selected list types, and individual player cards.
- Incoming Suggestions tab for reviewing synchronized data before importing it.
- Selective acceptance, skipping, and rejection of incoming entries.
- Text and Base64 export/import formats.
- Custom chat phrase filter with per-channel configuration and hide/show-only modes.
- Reputation icons on player nameplates.
- Online notifications for tracked Blacklist and Whitelist players.
- Unified settings in the main addon window and the Social frame.
- Armory/profile links, tags, individual export, synchronization, and forum export in player cards.
- Full Russian and English localization for the new interface.

### Changed

- Replaced the separate Classic and ElvUI interfaces with one adaptive interface.
- Expanded player cards and character history.
- Improved integration with chat, guild, raid, mail, tooltips, and the Blizzard ignore list.
- Improved export/import workflow and legacy data compatibility.
- Improved support for databases containing hundreds or thousands of players.
- Moved the primary addon settings into the redesigned interface.

### Performance

- Virtualized the main player list, History tab, and incoming synchronization list.
- Reused visible interface rows instead of creating one frame per entry.
- Added bounded caches for filters, counters, tags, and collected player entries.
- Reduced temporary table, closure, tag-parsing, and string allocations.
- Optimized rapid scrolling and tab switching.
- Removed periodic forced full garbage collection while preserving diagnostic memory commands.

### Fixed

- Fixed uncontrolled memory growth during active list scrolling.
- Fixed excessive temporary memory growth while rapidly switching tabs.
- Fixed scrolling in the Social-frame settings panel.
- Fixed chat-filter phrases extending beyond the addon window.
- Fixed History and Incoming Suggestions rows extending beyond the bottom of the main window.
- Fixed multiple interface layout and visual issues.
- Fixed several data refresh, cache invalidation, and localization issues.

## [1.80] - 2026-07-19

### Added

- Added a History tab to the character card.
- Added tracking of the date and author of player additions.
- Added storage of the player data available at the time of addition.
- Added display of the last encounter date with a player.
- Added character data change history, limited to the five most recent entries.

### Fixed and improved

- Multiple graphical fixes.
- Stability and functionality improvements.
- Expanded and improved English localization.

## [1.65b] - 2026-02-02

### Added
- Initial public release on GitHub

### Features
- Player card system with GUID tracking
- Blacklist, Whitelist, and Notelist management
- Import from BlackList, ElitistGroup, IgnoreMore
- Classic and ElvUI interface styles
- Russian and English localization
- Merge tool for multi-account data management
- Real-time party/raid member checking
- Integration with in-game ignore list
- Protection features for blacklisted players

---

## [Unreleased]

### Planned
