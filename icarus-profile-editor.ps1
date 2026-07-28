# Icarus Profile Editor - PowerShell Version
# This script provides a more reliable way to edit Icarus profile files

param(
    [string]$ProfileDir = "$env:LOCALAPPDATA\Icarus\Saved\PlayerData"
)

# Function to get timestamp for backup files
function Get-Timestamp {
    return Get-Date -Format "yyyyMMdd_HHmmss"
}

# Function to check if Icarus process is running
function Test-IcarusProcess {
    $process = Get-Process -Name "Icarus" -ErrorAction SilentlyContinue
    return $null -ne $process
}

# Function to get available profiles (SteamID64s)
function Get-Profiles {
    if (!(Test-Path $ProfileDir)) {
        Write-Error "Profile directory not found: $ProfileDir"
        return @()
    }
    
    $profiles = Get-ChildItem $ProfileDir -Directory | ForEach-Object { $_.Name }
    return $profiles
}

# Function to display profile selection menu
function Show-ProfileSelection {
    param([array]$Profiles)
    
    Write-Host "The following profiles are available for editing:"
    for ($i = 0; $i -lt $Profiles.Count; $i++) {
        Write-Host "  [$($i + 1)]: $($Profiles[$i])"
    }
    Write-Host ""
    
    do {
        Write-Host -NoNewline "Enter the profile number you would like to edit: [1] "
        $input = Read-Host
        if ($input -eq "") { $input = "1" }
        
        if ($input -match '^\d+$' -and $input -ge 1 -and $input -le $Profiles.Count) {
            return $Profiles[$input - 1]
        } else {
            Write-Host "Invalid input. Please enter a number between 1 and $($Profiles.Count)"
        }
    } while ($true)
}

# Function to get current MetaResources from profile
function Get-MetaResources {
    param([string]$ProfilePath)
    
    $profileContent = Get-Content $ProfilePath -Raw | ConvertFrom-Json
    return $profileContent.MetaResources
}

# Function to display currency values
function Show-CurrencyValues {
    param([array]$MetaResources)
    
    Write-Host "Current Values:"
    $currencies = @(
        @{Name="Credits"; FriendlyName="Ren"},
        @{Name="Exotic1"; FriendlyName="Exotics"},
        @{Name="Exotic_Red"; FriendlyName="Stabilized Exotic"},
        @{Name="Exotic_Uranium"; FriendlyName="Uranium Rod"},
        @{Name="Refund"; FriendlyName="Refund"},
        @{Name="Biomass"; FriendlyName="Legendary Biomass"},
        @{Name="Licence"; FriendlyName="Legendary Licence"}
    )
    
    foreach ($currency in $currencies) {
        $value = ($MetaResources | Where-Object { $_.MetaRow -eq $currency.Name } | Select-Object -ExpandProperty Count)
        Write-Host ("  {0,-22}" -f ($currency.FriendlyName + ":")) -ForegroundColor Cyan -NoNewline
        Write-Host " $value" -ForegroundColor Yellow
    }
}

# Function to prompt for new values
function Prompt-NewValues {
    param([array]$MetaResources)
    
    $currencies = @(
        @{Name="Credits"; FriendlyName="Ren"},
        @{Name="Exotic1"; FriendlyName="Exotics"},
        @{Name="Exotic_Red"; FriendlyName="Stabilized Exotic"},
        @{Name="Exotic_Uranium"; FriendlyName="Uranium Rod"},
        @{Name="Refund"; FriendlyName="Refund"},
        @{Name="Biomass"; FriendlyName="Legendary Biomass"},
        @{Name="Licence"; FriendlyName="Legendary Licence"}
    )
    
    $newValues = @{}
    
    foreach ($currency in $currencies) {
        $currentValue = ($MetaResources | Where-Object { $_.MetaRow -eq $currency.Name } | Select-Object -ExpandProperty Count)
        Write-Host ""
        $newValue = Read-Host "Enter new value for $($currency.FriendlyName) [$currentValue]"
        
        if ($newValue -match '^\d+$') {
            $newValues[$currency.Name] = [int]$newValue
        } else {
            $newValues[$currency.Name] = $currentValue
        }
    }
    
    return $newValues
}

# Function to update MetaResources in profile JSON
function Update-MetaResources {
    param(
        [string]$ProfilePath,
        [hashtable]$NewValues
    )
    
    # Read the existing profile
    $profileContent = Get-Content $ProfilePath -Raw | ConvertFrom-Json
    
    # Create a backup
    $timestamp = Get-Timestamp
    $backupFile = "$ProfilePath.$timestamp"
    Copy-Item $ProfilePath $backupFile
    
    # Update MetaResources
    foreach ($currency in $NewValues.Keys) {
        $existingResource = $profileContent.MetaResources | Where-Object { $_.MetaRow -eq $currency }
        
        if ($null -ne $existingResource) {
            # Update existing resource
            $existingResource.Count = $NewValues[$currency]
        } else {
            # Add new resource
            $newResource = @{
                MetaRow = $currency
                Count = $NewValues[$currency]
            }
            $profileContent.MetaResources += [PSCustomObject]$newResource
        }
    }
    
    # Write back to profile
    $profileContent | ConvertTo-Json -Depth 10 | Set-Content $ProfilePath
    
    Write-Host ""
    Write-Host "These are now the updated values in your selected profile:"
    # Display updated values with proper alignment
    $currencies = @(
        @{Name="Credits"; FriendlyName="Ren"},
        @{Name="Exotic1"; FriendlyName="Exotics"},
        @{Name="Exotic_Red"; FriendlyName="Stabilized Exotic"},
        @{Name="Exotic_Uranium"; FriendlyName="Uranium Rod"},
        @{Name="Refund"; FriendlyName="Refund"},
        @{Name="Biomass"; FriendlyName="Legendary Biomass"},
        @{Name="Licence"; FriendlyName="Legendary Licence"}
    )
    
    foreach ($currency in $currencies) {
        $value = ($profileContent.MetaResources | Where-Object { $_.MetaRow -eq $currency.Name } | Select-Object -ExpandProperty Count)
        Write-Host ("  {0,-22}" -f ($currency.FriendlyName + ":")) -ForegroundColor Cyan -NoNewline
        Write-Host " $value" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return $backupFile
}

# Function to prompt about unlocking blueprints
function Prompt-UnlockAll {
    do {
        Write-Host -NoNewline "Would you like to unlock all mission-gated blueprints and map pathways? (y/n): "
        $answer = Read-Host
        
        if ($answer -eq "y" -or $answer -eq "Y") {
            return $true
        } elseif ($answer -eq "n" -or $answer -eq "N") {
            return $false
        } else {
            Write-Host "Please answer 'y' for yes or 'n' for no."
        }
    } while ($true)
}

# Function to unlock all blueprints and pathways
function Unlock-AllBlueprints {
    param([string]$ProfilePath)
    
    # Read the existing profile
    $profileContent = Get-Content $ProfilePath -Raw | ConvertFrom-Json
    
    # Create a backup
    $timestamp = Get-Timestamp
    $backupFile = "$ProfilePath.$timestamp"
    Copy-Item $ProfilePath $backupFile
    
    # Define the UnlockedFlags array (as specified in the original request)
    $unlockedFlags = @(
        1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 35, 36, 37,
        38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53,
        54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
        70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85,
        86, 87, 88, 89, 90, 91, 93, 94, 95, 96, 97, 98, 99
    )
    
    # Update or add the UnlockedFlags array
    if ($profileContent.UnlockedFlags) {
        $profileContent.UnlockedFlags = $unlockedFlags
    } else {
        $profileContent | Add-Member -Name "UnlockedFlags" -Value $unlockedFlags -MemberType NoteProperty
    }
    
    # Write back to profile
    $profileContent | ConvertTo-Json -Depth 10 | Set-Content $ProfilePath
    
    Write-Host ""
    Write-Host "Successfully updated UnlockedFlags in your selected profile."
    Write-Host ""
}

# Main execution starts here

# Check if Icarus process is running
if (!(Test-IcarusProcess)) {
    Write-Host "Icarus game client is not running. Please start it before editing profiles."
    exit 1
}

# Get available profiles
$profiles = Get-Profiles
if ($profiles.Count -eq 0) {
    Write-Error "No profiles found in $ProfileDir"
    exit 1
}

# Select profile
$selectedProfile = Show-ProfileSelection -Profiles $profiles

# Construct profile path
$profilePath = "$ProfileDir\$selectedProfile\Profile.json"

# Validate profile exists
if (!(Test-Path $profilePath)) {
    Write-Error "Profile file does not exist: $profilePath"
    exit 1
}

Write-Host ""
Write-Host "Editing profile file: $profilePath"

# Display current currency amounts
$metaResources = Get-MetaResources -ProfilePath $profilePath
Show-CurrencyValues -MetaResources $metaResources

# Prompt for new values
$newValues = Prompt-NewValues -MetaResources $metaResources

# Update MetaResources in the profile
$backupFile = Update-MetaResources -ProfilePath $profilePath -NewValues $newValues

# Ask user if they want to unlock all mission-gated blueprints and map pathways
if (Prompt-UnlockAll) {
    Unlock-AllBlueprints -ProfilePath $profilePath
}

Write-Host ""
Write-Host "You have successfully updated the currency values in your selected profile."
Write-Host "You may now exit the Icarus game client, or select a character and start"
Write-Host "playing."
Write-Host ""
Write-Host "When you exit the Icarus game client, the changes will be synced to Steam"
Write-Host "Cloud if you have that feature enabled in your Steam client."
Write-Host ""
Write-Host "A backup of your profile JSON file has been created with a timestamp here:"
Write-Host "$backupFile"
Write-Host ""
Write-Host "Press any key to exit..."
[Console]::ReadKey($true) | Out-Null
