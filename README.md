# Reputation - Player Lists Manager for WoW 3.3.5a

A comprehensive addon for managing blacklists, whitelists, and player notes with advanced tracking capabilities.

![Version](https://img.shields.io/badge/version-1.70-blue)
![WoW](https://img.shields.io/badge/WoW-3.3.5a-orange)
![License](https://img.shields.io/badge/license-MIT-green)

[Русская версия](README_RU.md)

## Features

### Player Cards
Display comprehensive player information:
- GUID (unique identifier)
- Name, Race, Class, Level
- Guild affiliation
- Custom notes
- Entry date and author

### GUID Tracking
Track players even after name/race/faction changes. Checks occur:
- In groups and raids
- On target selection / mouseover
- During trade initiation

### Interface
- **Localization**: Russian and English
- **Two UI styles**: Classic and ElvUI
- **Dual interface**: Standalone window + integrated into Social frame

### Import from Other Addons
Supports importing from:
- BlackList
- ElitistGroup
- IgnoreMore

### Easy Player Management
- Right-click menu integration
- Add players directly from chat
- Account-wide data with realm separation (x1, x4, x100)

## List Types

- **Blacklist** — Problematic players
- **Whitelist** — Reliable players (tanks, healers, friends, raid leaders)
- **Notelist** — Neutral notes (e.g., "often AFK")

## Tracking & Notifications

- Auto-notification when players join group/raid
- Alerts for whispers and trade requests
- Real-time party member checking
- Pop-up player cards
- Tooltip integration
- Sound notifications
- Color highlighting in LFG channels
- Interactive markers in Guild/Raid tabs

## Built-in Ignore List Integration

- Direct addition to in-game ignore
- Status display
- Quick unignore
- Occupied slots counter

## Blacklist Protection

Block blacklisted players from:
- Group invitations
- Trade requests
- Private messages
- Quick "Add to BL & Kick" button (for group/raid leaders)

## Data Management

### Method 1: Merge Tool (Recommended)
Use the included merge tool to combine lists across multiple accounts.

### Method 2: Manual Export/Import
Copy the file manually:
```
/WTF/Account/Account_Name/SavedVariables/reputation.lua
```

## Installation addon

1. Download the latest release
2. Extract the `Reputation` folder to your WoW addons directory:
```
   World of Warcraft/Interface/AddOns/
```
3. Restart WoW
4. Use `/rlnew`, `/rlelvui` or button on minimap to open the interface

## Merge Tool Usage

**What it does:**
- Checks for `SavedVariables\reputation.lua` in all accounts
- Merges lists into one unified database
- Keeps the most recent entry when duplicates are found
- Writes the merged data back to all accounts

**How to use:**
1. **Close WoW client** (important!)
2. Run the merge tool
3. Specify path to `\WTF\Account` folder
4. Click "Merge Data"


## Screenshots



##  Changelog

### Version 1.65b
- Current stable release

See(CHANGELOG.md) for full version history.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is licensed under the MIT License - see the(LICENSE) file for details.

## Disclaimer

This addon is designed for World of Warcraft 3.3.5a (WotLK). Use at your own risk on private servers.

## Support

If you encounter any issues or have suggestions:
- Open an [Issue](../../issues)
- Check existing issues before creating a new one

---

**Enjoy managing your player lists!**
