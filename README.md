# Icarus Profile Editor
A handy utility that finds and modifies your Icarus game profiles to boost your in-game currencies and talent refund points. Right now it handles currencies and talent points, and also unlocks mission-gated blueprints and map pathways.

Built with Windows 11 and PowerShell scripting. This tool uses native PowerShell JSON handling.

Got multiple Steam accounts? No worries - the script will show you a list of available profiles and let you pick which one to modify.

# Instructions
**Important:** Start Icarus and get to the main title screen before running the script. If you don't, here be dragons (meaning it may not work as expected...or at all).

1) Download [icarus-profile-editor-launcher.cmd](https://github.com/spafbi/icarus-profile-editor/releases/latest/download/icarus-profile-editor-launcher.cmd) - it'll probably land in your Downloads folder.
2) Press WIN+R to open the Run dialog and paste this command:
   ```cmd
   %USERPROFILE%\Downloads\icarus-profile-editor-launcher.cmd
   ```
3) Hit *Enter*
4) Select which Steam profile you want to edit from the list
5) The script will show your current currency values with friendly names:
   - Ren (Credits)
   - Exotics
   - Stabilized Exotic
   - Uranium Rod
   - Refund
   - Legendary Biomass
   - Legendary Licence
6) Enter the amounts you want (or just press Enter to keep current values)
7) You'll then be asked if you want to unlock all mission-gated blueprints and map pathways
8) Bob's your uncle!

## Automatic Backups - We've Got You Covered!
Every time the script modifies your profile, it automatically creates a backup copy of your `profile.json` file in the same folder (`%LOCALAPPDATA%\Icarus\Saved\PlayerData\<steamID64>\`). 

The backup files are timestamped, so they'll look something like this:
```
Profile.json.Sun09-02-2025_08-20PM
Profile.json.Fri07-18-2025_02-04PM
```

Feel free to delete these backup files once you've confirmed everything is working perfectly. They're just there for peace of mind!
