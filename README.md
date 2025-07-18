# Icarus Profile Editor
A handy utility that finds and modifies your Icarus game profiles to boost your in-game currencies and talent refund points. Right now it handles currencies and talent points, but future versions will expand to unlock missions and blueprints too.

Built with Windows 11 and good old-fashioned CMD scripting. If needed, this tool automatically downloads and installs [jq](https://jqlang.org/) (a JSON processor) via [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/) to handle all the profile file editing behind the scenes.

Got multiple Steam accounts? No worries - the script will show you a list of available profiles and let you pick which one to modify.

# Quick Start - Just Want Max Credits?
Want to set all currencies and talent refund points to 999999 each? Here's the fastest way:

1) Download [icarus-profile-editor.cmd](https://github.com/spafbi/icarus-profile-editor/releases/latest/download/icarus-profile-editor.cmd) - it'll probably land in your Downloads folder.
1) **Important:** Start Icarus and get to the main title screen before running the script. If you don't, here be dragons (meaning it may not work as expected...or at all).
1) Press WIN+R to open the Run dialog and paste this command:
   ```cmd
   %USERPROFILE%\Downloads\icarus-profile-editor.cmd --max-currencies
   ```
1) Hit *Enter*
1) You'll be prompted to select which profile you want to edit, and Bob's your uncle!

Enjoy your newfound riches! 💰
# Detailed Instructions
Want more control over your currency values? This works just like the Quick Start, but lets you see your current values and enter custom amounts instead of maxing everything out.

**Important:** Start Icarus and get to the main title screen before running the script. If you don't, here be dragons (meaning it may not work as expected...or at all).

1) Download [icarus-profile-editor.cmd](https://github.com/spafbi/icarus-profile-editor/releases/latest/download/icarus-profile-editor.cmd) - it'll probably land in your Downloads folder.
2) Press WIN+R to open the Run dialog and paste this command:
   ```cmd
   %USERPROFILE%\Downloads\icarus-profile-editor.cmd
   ```
3) Hit *Enter*
4) Select which Steam profile you want to edit from the list
5) The script will show your current currency values and prompt you to enter new ones
6) Enter the amounts you want (or just press Enter to keep current values)
7) Bob's your uncle!

## Command Line Options
Want to skip some of the prompts? You can run the script with these options:

```txt
usage: icarus-profile-editor.cmd [--max-currencies] [--unlock-all]

options:
  --max-currencies
      Sets all currencies to 999999 without prompting for new values
  --unlock-all
      Unlocks all missions and blueprints (coming soon - not implemented yet)
```
## Automatic Backups - We've Got You Covered!
Every time the script modifies your profile, it automatically creates a backup copy of your `profile.json` file in the same folder (`%LOCALAPPDATA%\Icarus\Saved\PlayerData\<steamID64>\`). 

The backup files are timestamped, so they'll look something like this:
```
Profile.json.Sun09-02-2025_08-20PM
Profile.json.Fri07-18-2025_02-04PM
```

Feel free to delete these backup files once you've confirmed everything is working perfectly. They're just there for peace of mind!