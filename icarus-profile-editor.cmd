@echo off
set "profile_dir=%localappdata%\Icarus\Saved\PlayerData"

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
set "timestamp=%timestamp::=-%"
set "timestamp=%timestamp:/=-%"
set "timestamp=%timestamp:\=-%"
set "timestamp=%timestamp: =%"
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

:input
setlocal enabledelayedexpansion
set /p number=Please enter a number: 

rem Check if the input is an integer and greater than or equal to zero
for /f "delims=0123456789" %%a in ("!number!") do (
    echo Please enter an integer with a value greater than or equal to zero.
    goto input
)

if !number! lss 0 (
    echo Please enter an integer with a value greater than or equal to zero.
    goto input
)

echo You entered: !number!
exit /b 0
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
    echo Removing jq to ensure latest...
    echo   Executing: winget remove jqlang.jq
    winget remove jqlang.jq
    echo jq is not installed. Installing jq...
    echo   Executing: winget install jqlang.jq
    winget install jqlang.jq
    for /f "delims=" %%i in ('where jq 2^>nul') do set "jq_path=%%i"
    if not defined jq_path (
        echo jq installation failed. Please install it manually.
        exit /b 1
    ) else (
        echo jq installed successfully.
    )
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
endlocal & set "player_name=%cleaned_name%"

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
set "currencies=Credits Exotic1 Exotic_Red Refund Biomass Licence"

@REM Loop through each currency type
for %%c in (%currencies%) do (
    for /f "tokens=*" %%a in ('jq -r ".MetaResources[] | select(.MetaRow==\"%%c\") | .Count" "%profile_json%"') do (
        set "current_%%c=%%a"
        echo %%a > current_%%c.txt
    )
)

@REM Display current values with proper labels
set "label_Credits=Current Credits:     "
set "label_Exotic1=Current Exotics:     "
set "label_Exotic_Red=Current Red Exotics: "
set "label_Refund=Current Refund:      "
set "label_Biomass=Current Biomass:     "
set "label_Licence=Current Licences:    "

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
set "currencies=Credits Exotic1 Exotic_Red Refund Biomass Licence"

for %%c in (%currencies%) do (
    set "current_currency=%%c"
    set "current_var=current_%%c"
    set "new_var=new_%%c"
    set "new_var=!new_var:~0,1!!new_var:~1!"
    set "current_value="
    
    @REM Read current value from the corresponding file
    if exist "current_%%c.txt" (
        for /f "delims=" %%a in (current_%%c.txt) do set "current_value=%%a"
        set "current_value=!current_value: =!"
    )

    set "new_value="

    if !max_currencies! neq 0 (
        set "new_value=!max_currencies!"
    ) else (
        :prompt_value
        set /p "new_value=Enter new value for !current_currency! [!current_value!]: "
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
set "currencies=Credits Exotic1 Exotic_Red Refund Biomass Licence"

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
set "currencies=Credits Exotic1 Exotic_Red Refund Biomass Licence"
set "temp_counter=1"

@REM Create initial backup and first temp file
move "%profile_json%" "%backup_file%" >nul
set "input_file=%backup_file%"

@REM Loop through each currency and apply jq updates
for %%c in (%currencies%) do (
    set "output_file=temp!temp_counter!.json"
    jq "if (.MetaResources ^| any(.MetaRow == \"%%c\")) then (.MetaResources[] ^| select(.MetaRow == \"%%c\") ^| .Count) ^|= !new_%%c! else .MetaResources += [{\"MetaRow\": \"%%c\", \"Count\": !new_%%c!}] end" "!input_file!" > "!output_file!"
    
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
jq ".MetaResources" "%profile_json%"

endlocal
exit /b 0
@REM ########## End of Function: set_meta_resources ##########


:start_editing
@REM Make sure jq is installed
call :check_jq || if not "%ERRORLEVEL%"=="0" exit /b %ERRORLEVEL%

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
timeout /t 120