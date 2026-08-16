# Reputation - Player Lists Manager for WoW 3.3.5a

A comprehensive addon for managing blacklists, whitelists, and player notes with advanced tracking, filtering, synchronization, and notification capabilities.

![Version](https://img.shields.io/badge/version-2.1-blue)
![WoW](https://img.shields.io/badge/WoW-3.3.5a-orange)
![License](https://img.shields.io/badge/license-MIT-green)

[Русская версия](README_RU.md)

## Features

### Player Cards

Display comprehensive player information:

- GUID (unique identifier)
- Name, race, class, level, faction, and realm
- Guild affiliation
- Custom notes and tags
- Armory/profile link
- Entry date and author
- Player data change history
- Export of an individual player entry

### GUID Tracking

Track players even after name, race, or faction changes. Checks occur:

- In groups and raids
- On target selection or mouseover
- During trade initiation
- While inspecting the current group through the **Who's Here?** tab

GUID conflicts are detected and handled without silently overwriting an existing player entry.

### Redesigned Interface 2.0

- Unified standalone interface for the default UI and ElvUI
- Integrated player lists and settings in the Social frame
- Dedicated Blacklist, Whitelist, and Notelist tabs
- Search and sorting by player name or date
- Filters by class, race, tag, and ignore status
- Player counters and quick filters
- **Who's Here?**, History, Sync, Incoming, Chat Filter, and Settings tabs
- Russian and English localization

### Tags and Search

Add tags directly to player notes, for example:

```text
#ninja #goodtank #afk
```

Tags are detected automatically and can be used for quick filtering and player search.

### Group and Raid Inspection

The **Who's Here?** tab displays members of the current or most recently tracked group/raid and shows whether they already exist in Blacklist, Whitelist, or Notelist.

Players can be opened, inspected, or added to a list directly from this tab.

### Synchronization

- Send all lists or selected list types to another Reputation List user
- Send an individual player card
- Review incoming data before importing it
- Accept all entries or only selected players
- Skip or reject incoming suggestions
- Prefer newer data when merging conflicting entries

### Export and Import

- Export all lists or individual list types
- Export individual player entries
- Text and Base64 formats
- Merge imported data with the existing database
- Import legacy Reputation List data

### Import from Other Addons

Supports importing from:

- BlackList
- ElitistGroup
- IgnoreMore

The source addon must be installed and enabled during import.

### Chat Phrase Filter

- Add custom phrases directly from the interface
- Hide messages containing selected phrases
- Or show only messages containing selected phrases
- Configure filtering separately for Say, Yell, channels, whispers, party, raid, guild, and emotes

### Nameplate and Online Notifications

- Display reputation icons on player nameplates
- Use standard or custom icons
- Receive notifications when tracked players come online
- Configure Blacklist and Whitelist monitoring separately
- Optional notification sounds

### Easy Player Management

- Right-click menu integration
- Add players directly from chat
- Add players from group and raid inspection
- Move players between list types while preserving known data
- Account-wide data with realm separation (x1, x4, x100)

## List Types

- **Blacklist** — Problematic or unwanted players
- **Whitelist** — Reliable players such as tanks, healers, friends, and raid leaders
- **Notelist** — Neutral notes, for example "often AFK"

## Tracking and Notifications

- Auto-notification when players join a group or raid
- Alerts for whispers and trade requests
- Real-time party member checking
- Online player notifications
- Pop-up player cards
- Tooltip integration
- Sound notifications
- Color highlighting in chat and LFG channels
- Interactive markers in Guild and Raid tabs
- Reputation markers in mail and other supported Blizzard UI elements

## Built-in Ignore List Integration

- Direct addition to the in-game ignore list
- Ignore status display
- Quick unignore
- Occupied slots counter

## Blacklist Protection

Optionally block blacklisted players from:

- Group invitations
- Trade requests
- Private messages and configured chat channels
- Quick **Add to Blacklist & Kick** action for group or raid leaders

## History

- Dedicated global History tab with player search
- History section inside each player card
- Tracks the date and author of player addition
- Records the data the player was added with
- Shows the last known encounter information
- Maintains a history of character data changes
- Records name changes and GUID linking

## Performance and Memory

Version 2.0 includes extensive optimizations for large databases:

- Virtualized player, history, and incoming synchronization lists
- Reusable visible UI rows instead of creating one frame per entry
- Bounded caches for filtering, counters, and tags
- Reduced temporary table and string allocations
- Optimized scrolling and tab switching
- Improved support for databases containing hundreds or thousands of players
- No periodic forced full garbage collection

## Data Management

### Method 1: In-Addon Export and Import (Recommended)

Use the built-in export/import interface to transfer or merge lists using text or Base64 data.

### Method 2: Merge Tool

Use the merge tool to combine lists across multiple accounts.

### Method 3: Manual Backup

Copy the SavedVariables file while the WoW client is closed:

```text
/WTF/Account/Account_Name/SavedVariables/reputation.lua
```

## Installation

1. Download the latest release.
2. Extract the `reputation` folder to your WoW addons directory:

   ```text
   World of Warcraft/Interface/AddOns/
   ```

3. Verify the resulting path:

   ```text
   World of Warcraft/Interface/AddOns/reputation/reputation.toc
   ```

4. Restart WoW and enable the addon if necessary.
5. Use `/rlistui`, `/rlui`, or the minimap button to open the interface.

## Useful Commands

```text
/rlistui  - Open the main interface
/rlui     - Open the main interface
/rlexport - Open export tools
/rlimport - Open import tools
/rlsync   - Open synchronization tools
/rlfilter - Configure the chat phrase filter
/rlplates - Configure nameplate icons
/rltoast  - Configure online notifications
```

Most features and settings are also available directly from the main interface.

## Merge Tool Usage

**What it does:**

- Checks for `SavedVariables\reputation.lua` in all accounts
- Merges lists into one unified database
- Keeps the most recent entry when duplicates are found
- Writes the merged data back to all accounts

**How to use:**

1. **Close the WoW client** — this is important.
2. Run the merge tool.
3. Specify the path to the `\WTF\Account` folder.
4. Click **Merge Data**.

## Screenshots

Screenshots of the redesigned 2.0 interface will be added here.

## Changelog

### Version 2.0

- Completely redesigned unified interface
- Added tags and advanced filtering
- Added list and individual player synchronization
- Added incoming suggestion review
- Added chat phrase filtering
- Added nameplate icons and online notifications
- Expanded player cards and history
- Added unified settings to the main and Social interfaces
- Added full Russian and English UI localization
- Improved memory usage, scrolling, and large-list performance
- Removed obsolete separate Classic and ElvUI interface files

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

## Contributing

Contributions are welcome. Feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

This addon is designed for World of Warcraft 3.3.5a (WotLK). Use it at your own risk on private servers, as server implementations may differ.

## Support

If you encounter an issue or have a suggestion:

- Open an [Issue](../../issues)
- Check existing issues before creating a new one

---

**Remember the players worth keeping — and those worth avoiding.**
