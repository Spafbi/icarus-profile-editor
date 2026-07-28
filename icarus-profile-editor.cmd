@echo off
set "profile_dir=%localappdata%\Icarus\Saved\PlayerData"
set "currencies=Credits Exotic1 Exotic_Red Exotic_Uranium Refund Biomass Licence"

:GETARGS
@REM Set default values
set "max_currencies=0"
set "unlock_all=0"

if "%~1" equ "--max-currencies" (
  set "max_currencies=999999"
  shift
) else if "%~1" equ "--unlock-all" (
  @REM This option is for future use, currently not implemented
  set "unlock_all=1"
  shift
) else if not "%~1" equ "" (
    echo Unknown argument: %1
    shift
)

if not "%~1" equ "" goto GETARGS

goto :start_editing

:get_timestamp
@REM for /f "tokens=*" %%i in ('curl -s "http://worldtimeapi.org/api/timezone/Etc/UTC" ^| jq -r ".unixtime"') do set "timestamp=%%i"
for /f "tokens=*" %%i in ('date /t') do set "this_date=%%i"
set "this_date=%this_date:/=-%"
for /f "tokens=*" %%i in ('time /t') do set "this_time=%%i"
set "this_time=%this_time::=-%"
set "this_time=%this_time: =%"
set "timestamp=%this_date%_%this_time%"
exit /b 0
@REM ########## End of Function: get_timestamp ##########

:check_icarus_process
@REM Function: check_icarus_process
@REM Description: This function checks if the 'icarus' process is running on the system.
@REM It ensures that the 'icarus' process is active before proceeding with further operations in the script.
tasklist /FI "IMAGENAME eq Icarus-Win64-Shipping.exe" 2>NUL | find /I /N "Icarus-Win64-Shipping.exe">NUL
if not "%ERRORLEVEL%"=="0" (
    echo Icarus does not appear to be running.
    echo Please make sure Icarus is running and sitting at the title screen.
    echo Exiting...
    exit /b 1
)
exit /b 0
@REM ########## End of Function: check_icarus_process ##########

@REM ########## End of Function: input ##########

:check_jq
@REM Function: check_jq
@REM Description: This function checks if the 'jq' command-line JSON processor is installed on the system.
@REM It ensures that 'jq' is available for parsing JSON data within the script.
set "jq_path="
for /f "delims=" %%i in ('where jq 2^>nul') do set "jq_path=%%i"
if not defined jq_path (
    echo This script requires the 'jq' command-line JSON processor to be installed.
    echo jq was not found in your PATH
    echo Installing jq...
    echo   Executing: winget install jqlang.jq
    winget install jqlang.jq --accept-source-agreements --accept-package-agreements
    echo.
    echo The 'jq' installation is complete. Please close this window and re-run the script.
    echo The script will now exit.
    echo.
    pause >nul
    exit /b 1
) else (
    set "JQ_EXE=jq"
)
exit /b 0
@REM ########## End of Function: check_jq ##########

:get_profiles
@REM Function: get_profiles
@REM Description: This function retrieves the list of SteamID64 directories within the profile directory.
@REM It ensures that the profile directory exists and then collects all SteamID64s into a list.
if not exist "%profile_dir%" (
    echo Profile directory does not exist: %profile_dir%
    exit /b 1
)
setlocal enabledelayedexpansion
set "steamid64_list="

for /d %%d in ("%profile_dir%\*") do (
    set "steamid64=%%~nxd"
    set "steamid64_list=!steamid64_list! !steamid64!"
)

if "!steamid64_list:~0,1!"==" " set "steamid64_list=!steamid64_list:~1!"
if "!steamid64_list:~-1!"==" " set "steamid64_list=!steamid64_list:~0,-1!"
echo !steamid64_list!
endlocal
exit /b 0
@REM ########## End of Function: get_profiles ##########


:get_steam_name
@REM Function: get_steam_name
@REM Description: This function retrieves the player profile name for a given SteamID64.
@REM It fetches the player name from the <title> block from https://steamcommunity.com/profiles/%steamid64%

set "steamid64=%~1"
set "profile_url=https://steamcommunity.com/profiles/%steamid64%"

@REM Fetch the profile page and extract the player name from the <title> block
for /f "tokens=*" %%a in ('curl -s -L "%profile_url%" ^| findstr /i "<title>"') do (
    set "title_line=%%a"
)

@REM Extract the player name from the title line
for /f "tokens=1,* delims=<>" %%a in ("%title_line%") do (
    if "%%a"=="title" (
        set "player_name=%%b"
    )
)

@REM Remove "Steam Community :: " prefix and "</title>" suffix from the player name
set "player_name=%player_name:Steam Community :: =%"
set "player_name=%player_name:</title>=%"

@REM Remove any special characters except spaces
setlocal enabledelayedexpansion
set "cleaned_name="
for /l %%i in (0,1,31) do (
    set "char=!player_name:~%%i,1!"
    if "!char!"==" " (
        set "cleaned_name=!cleaned_name!!char!"
    ) else (
        for %%j in (a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9) do (
            if "!char!"=="%%j" set "cleaned_name=!cleaned_name!!char!"
        )
    )
)
@REM Write cleaned name to temp file so it persists outside the setlocal block
echo !cleaned_name! > temp_steam_name.txt
endlocal & set "player_name="

@REM Read the name from the temp file
if exist temp_steam_name.txt (
    for /f "delims=" %%a in (temp_steam_name.txt) do set "player_name=%%a"
    del temp_steam_name.txt
)

echo %player_name%
exit /b 0
@REM ########## End of Function: get_steam_name ##########

:prompt_profile_selection
@REM Function: prompt_profile_selection
@REM Description: This function presents a numbered list of profiles and prompts the user to select one.
@REM It writes to temp_selected_profile.txt the selected profile (SteamID64) for editing.

setlocal enabledelayedexpansion
set "profiles=%*"
set "index=1"

echo The following profiles are available for editing:
for %%i in (%profiles%) do (
    call :get_steam_name %%i > temp_name.txt
    set "steam_name=Unknown"
    if exist temp_name.txt (
        for /f "delims=" %%a in (temp_name.txt) do set "steam_name=%%a"
    )
    del temp_name.txt
    echo   [!index!]: %%i ^(!steam_name!^)
    set "profile_!index!=%%i"
    set /a index+=1
)
set /a index-=1

:prompt_again
set /p "selection=Enter the profile number you would like to edit: [1] "
if "%selection%"=="" set "selection=1"

for /l %%i in (1,1,%index%) do (
    if "!selection!"=="%%i" (
        set "selected_profile=!profile_%%i!"
        echo !selected_profile! > temp_selected_profile.txt
        endlocal
        exit /b 0
    )
)

echo Invalid selection. Please try again.
goto :prompt_again

:get_meta_resources
@REM Function: get_meta_resources
@REM Description: This function uses jq to get the MetaResources list from the file identified in profile_json.
@REM It extracts the currency types and their current values and assigns them to variables.

setlocal enabledelayedexpansion
set "currencies=Credits Exotic1 Exotic_Red Exotic_Uranium Refund Biomass Licence"

@REM Loop through each currency type
    for %%c in (%currencies%) do (
        for /f "tokens=*" %%a in ('%JQ_EXE% -r ".MetaResources[] | select(.MetaRow==\"%%c\") | .Count" "%profile_json%"') do (
            set "current_%%c=%%a"
            echo %%a > current_%%c.txt
        )
    )

@REM Display current values with proper labels
set "label_Credits=Current Ren:               "
set "label_Exotic1=Current Exotics:           "
set "label_Exotic_Red=Current Stabilized Exotic: "
set "label_Exotic_Uranium=Current Uranium Rod:       "
set "label_Refund=Current Refund:            "
set "label_Biomass=Current Legendary Biomass: "
set "label_Licence=Current Legendary Licence: "

for %%c in (%currencies%) do (
    echo !label_%%c! !current_%%c!
)

endlocal & (
    set "current_Credits=%current_Credits%"
    set "current_Exotic1=%current_Exotic1%"
    set "current_Exotic_Red=%current_Exotic_Red%"
    set "current_Refund=%current_Refund%"
    set "current_Biomass=%current_Biomass%"
    set "current_Licence=%current_Licence%"
)
exit /b 0
@REM ########## End of Function: get_meta_resources ##########


:prompt_new_values
@REM Function: prompt_new_values
@REM Description: This function prompts the user to enter new values for each currency.
@REM It validates the input to ensure it is a positive integer or empty, and assigns the values to new variables.

setlocal enabledelayedexpansion
set "currencies=Credits Exotic1 Exotic_Red Exotic_Uranium Refund Biomass Licence"

for %%c in (%currencies%) do (
    set "current_currency=%%c"
    set "current_var=current_%%c"
    set "new_var=new_%%c"
    set "current_value="
    
    @REM Read current value from the corresponding file
    if exist "current_%%c.txt" (
        for /f "delims=" %%a in (current_%%c.txt) do set "current_value=%%a"
        set "current_value=!current_value: =!"
    )

    set "new_value="

    @REM Set friendly names for display purposes
    if "%%c"=="Credits" set "friendly_name=Ren"
    if "%%c"=="Exotic1" set "friendly_name=Exotics"
    if "%%c"=="Exotic_Red" set "friendly_name=Stabilized Exotic"
    if "%%c"=="Exotic_Uranium" set "friendly_name=Uranium Rod"
    if "%%c"=="Refund" set "friendly_name=Refund"
    if "%%c"=="Biomass" set "friendly_name=Legendary Biomass"
    if "%%c"=="Licence" set "friendly_name=Legendary Licence"

    if !max_currencies! neq 0 (
        set "new_value=!max_currencies!"
    ) else (
        :prompt_value
        set /p "new_value=Enter new value for !friendly_name! [!current_value!]: "
        if "!new_value!"=="" set "new_value=!current_value!"
        for /f "delims=0123456789" %%a in ("!new_value!") do (
            echo Please enter an integer with a value greater than or equal to zero.
            goto prompt_value
        )
    )

    if !new_value! lss 0 (
        echo Please enter an integer with a value greater than or equal to zero.
        goto prompt_value
    )   
    set "!new_var!=!new_value!"
    echo !new_value! > !new_var!.txt
)
endlocal
exit /b 0
@REM ########## End of Function: prompt_new_values ##########

:load_new_values
setlocal enabledelayedexpansion
set "currencies=Credits Exotic1 Exotic_Red Exotic_Uranium Refund Biomass Licence"

@REM Load new values from files
for %%c in (%currencies%) do (
    set "new_%%c=0"
    if exist "new_%%c.txt" (
        for /f "delims=" %%a in (new_%%c.txt) do set "new_%%c=%%a"
    )
)

@REM Clean up temporary files
for %%c in (%currencies%) do (
    if exist "current_%%c.txt" del "current_%%c.txt"
    if exist "new_%%c.txt" del "new_%%c.txt"
)

@REM Export variables to parent scope
endlocal & (
    set "new_Credits=%new_Credits%"
    set "new_Exotic1=%new_Exotic1%"
    set "new_Exotic_Red=%new_Exotic_Red%"
    set "new_Exotic_Uranium=%new_Exotic_Uranium%"
    set "new_Refund=%new_Refund%"
    set "new_Biomass=%new_Biomass%"
    set "new_Licence=%new_Licence%"
)
exit /b 0
@REM ########## End of Function: load_new_values ##########


:set_meta_resources
@REM Function: set_meta_resources
@REM Description: This function updates the MetaResources values in the profile JSON file with new values.

@REM Copy the profile JSON file to a backup with a timestamp
call :get_timestamp
set "backup_file=%profile_json%.%timestamp%"

setlocal enabledelayedexpansion
set "currencies=Credits Exotic1 Exotic_Red Exotic_Uranium Refund Biomass Licence"
set "temp_counter=1"

@REM Create initial backup and first temp file
move "%profile_json%" "%backup_file%" >nul
set "input_file=%backup_file%"

@REM Loop through each currency and apply jq updates
    for %%c in (%currencies%) do (
        set "output_file=temp!temp_counter!.json"
        %JQ_EXE% "if (.MetaResources ^| any(.MetaRow == \"%%c\")) then (.MetaResources[] ^| select(.MetaRow == \"%%c\") ^| .Count) ^|= !new_%%c! else .MetaResources += [{\"MetaRow\": \"%%c\", \"Count\": !new_%%c!}] end" "!input_file!" > "!output_file!"
    
    @REM Check if jq command succeeded
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to update currency %%c with value !new_%%c!
        echo The profile file may be corrupted.
        exit /b 1
    )
    
    @REM Clean up previous temp file (except backup)
    if "!input_file!" neq "%backup_file%" del "!input_file!" >nul
    
    set "input_file=!output_file!"
    set /a temp_counter+=1
)

@REM Move final result to original location
move "!input_file!" "%profile_json%" >nul

@REM Output the MetaResources block
echo.
echo "These are now the updated values in your selected profile:"
%JQ_EXE% ".MetaResources" "%profile_json%"
echo.

endlocal
exit /b 0
@REM ########## End of Function: set_meta_resources ##########


:start_editing
@REM Make sure jq is installed
call :check_jq || exit /b 1

@REM Make sure Icarus is running
call :check_icarus_process || exit /b %ERRORLEVEL%

@REM Get the list of profiles (SteamID64s)
call :get_profiles > temp_profiles.txt || if not "%ERRORLEVEL%"=="0" exit /b %ERRORLEVEL%
set /p profiles=<temp_profiles.txt
del temp_profiles.txt

@REM Present a list of profiles for editing and ask the user to select one
call :prompt_profile_selection %profiles%

@REM Read the selected profile from temp_selected_profile.txt to create the profile JSON path.
set /p this_profile=<temp_selected_profile.txt
del temp_selected_profile.txt
for /f "tokens=* delims=" %%a in ("%this_profile%") do set "this_profile=%%a"
set "this_profile=%this_profile: =%"
set "profile_json=%profile_dir%\%this_profile%\Profile.json"

@REM Validate that the profile JSON file exists before editing
if not exist "%profile_json%" (
    echo Profile file does not exist: %profile_json%
    echo Exiting...
    exit /b 1
)

echo. & echo Editing profile file: %profile_json%

@REM Display current currency amounts
echo. & call :get_meta_resources

@REM Prompt the user to enter new values for each currency
echo. & call :prompt_new_values

@REM Load the new values from the temporary files
echo. & call :load_new_values

@REM Update the MetaResources values in the profile JSON file
echo. & call :set_meta_resources

echo.
echo You have successfully updated the currency values in your selected profile.
echo You may now exit the Icarus game client, or select a character and start
echo playing.
echo.
echo When you exit the Icarus game client, the changes will be synced to Steam
echo Cloud if you have that feature enabled in your Steam client.
echo.
echo A backup of your profile JSON file has been created with a timestamp here:
echo %backup_file%
echo.

:display_new_currency_names
@REM Display updated currency names by reading from the profile JSON
setlocal enabledelayedexpansion
set "currencies=Credits Exotic1 Exotic_Red Exotic_Uranium Refund Biomass Licence"
for %%c in (%currencies%) do (
    set "current_value=0"
    @REM Read directly from the profile JSON file using jq
    for /f "tokens=*" %%a in ('%JQ_EXE% -r ".MetaResources[] | select(.MetaRow==\"%%c\") | .Count" "%profile_json%"') do (
        set "current_value=%%a"
    )
    
    @REM Set friendly names for display purposes
    if "%%c"=="Credits" set "friendly_name=Ren:              "
    if "%%c"=="Exotic1" set "friendly_name=Exotics:          "
    if "%%c"=="Exotic_Red" set "friendly_name=Stabilized Exotic:"
    if "%%c"=="Exotic_Uranium" set "friendly_name=Uranium Rod:      "
    if "%%c"=="Refund" set "friendly_name=Refund:           "
    if "%%c"=="Biomass" set "friendly_name=Legendary Biomass:"
    if "%%c"=="Licence" set "friendly_name=Legendary Licence:"
    
    echo !friendly_name! !current_value!
)
endlocal
echo.
echo Press any key to exit, or wait 30 seconds...
timeout /t 30 > nul
