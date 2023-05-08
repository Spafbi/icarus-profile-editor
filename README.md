# Icarus Credits, Exotics, and Talent Refund Points modification utility
This utility updates Icarus profiles in the current Windows profile with new values for credits, exotics, and talent refund points.

This utility was created on Windows 11 using Python 3.11.3. It works for me, but your mileage may vary.

The script does log actions taken, so you will be able to review the changes. See *Running with options*, below, to see how to enable more verbose logging.
# Short Version -or- I don't want to read more stuff
To set credits and exotics to 9999, and talent refund points to 30, download and run [icarus-credits-modifier.exe](https://github.com/spafbi/icarus-credits-modifier/releases/latest/download/icarus-credits-modifier.exe)

NOTE: To help prevent potential complications, Icarus is required to be running and should be at the title screen when this utilty is used.

-Enjoy!
# Download types
## Python script
Just clone this reposity, or [download a zip](https://github.com/Spafbi/icarus-credits-modifier/archive/refs/heads/main.zip) of it, and execute the script using Python. Python 3.11.3 was used to create this script, and that's what the Pipfile expects. To set up the environment, navigate on your command-line to the directory where the script was copied/cloned, execute
```cmd
pipenv install
```
and this will install the required modules.

NOTE: Be sure to be using either PowerShell or a Command prompt when executing the Python version of this script; it will almost certainly fail with WSL.
## Windows executable
Download [icarus-credits-modifier.exe](https://github.com/spafbi/icarus-credits-modifier/releases/latest/download/icarus-credits-modifier.exe)

# Usage
NOTE: To help prevent potential complications, Icarus is required to be running and should be at the title screen when this utilty is used.

## Running with defaults
Defaults for values are set to:
 * Credits: 9999
 * Exotics: 9999
 * Talent refund points: 30

If that sounds good to you, just use one of the following execution methods:
### EXE file
Just download and execute the `icarus-credits-modifier.exe` file (link above) and you should be good to go!
### Python script
After setting up the environment (see *Python script* in the *Download types* section above)
```cmd
pipenv run python .\icarus-credits-modifier.py
```
## Running with options!
You may also run the script with options! Here's the output from running with `-h` to show all available options:
```txt
usage: icarus-credits-modifier.py [-h] [-c CREDITS] [-e EXOTICS] [-r REFUND] [-s STEAM] [-v]

icarus-credits-modifier.py sets credits and exotics to 9999, and talent refund points to 30, for
all Steam accounts located in %LOCALAPPDATA%\Icarus\Saved\PlayerData.

options:
  -h, --help            show this help message and exit
  -c CREDITS, --credits CREDITS
                        The amount of credits you want to have in game
  -e EXOTICS, --exotics EXOTICS
                        The amount of exotics you want to have in game
  -r REFUND, --refund REFUND
                        The number of talent refund credits you want to have
  -s STEAM, --steam STEAM
                        This option may be specified to alter a single account, identified by its
                        SteamID64, for which you wish to set values. Omitting this option defaults
                        to all SteamID64 accounts in %LOCALAPPDATA%\Icarus\Saved\PlayerData
  -v, --verbose         Verbose logging
```
Of course, the directory/folder paths will appear different on your system.