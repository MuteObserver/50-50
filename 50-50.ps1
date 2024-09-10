# Function to show progress
function Show-Progress {
    param ([string]$Activity)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Activity" -ForegroundColor Cyan
}

# Function to get all mods
function Get-AllMods {
    param ([string]$Directory)
    return Get-ChildItem -Path $Directory -Recurse -File | ForEach-Object {
        @{
            FullName = $_.FullName
            IsEnabled = -not $_.Name.EndsWith('.disabled')
            InProblemSet = $true
        }
    }
}

# Function to toggle mod state
function Toggle-ModState {
    param ([hashtable]$Mod)
    if ($Mod.IsEnabled) {
        Rename-Item -Path $Mod.FullName -NewName "$($Mod.FullName).disabled"
        $Mod.IsEnabled = $false
    } else {
        Rename-Item -Path $Mod.FullName -NewName ($Mod.FullName -replace '\.disabled$', '')
        $Mod.IsEnabled = $true
    }
}

# Function to display current status
function Show-Status {
    param ([array]$Mods)
    $enabledCount = ($Mods | Where-Object { $_.IsEnabled }).Count
    $problemSetCount = ($Mods | Where-Object { $_.InProblemSet }).Count
    Write-Host "Status: $enabledCount enabled, $($Mods.Count - $enabledCount) disabled. Problem set size: $problemSetCount"
}

# Main script
$directory = Read-Host "Enter the full path to your Sims 4 mods directory"
$mods = Get-AllMods -Directory $directory
Show-Progress "Found $($mods.Count) mods in total."

Show-Status -Mods $mods
$initialState = Read-Host "Does the current state have the issue? (Y/N)"

if ($initialState -eq 'N') {
    $mods | ForEach-Object { $_.InProblemSet = $_.IsEnabled }
}

$iteration = 0
$continue = $true

while ($continue) {
    $iteration++
    Show-Progress "Iteration $iteration"
    Show-Status -Mods $mods

    $problemSet = $mods | Where-Object { $_.InProblemSet }
    $halfCount = [math]::Ceiling($problemSet.Count / 2)
    $firstHalf = $problemSet | Select-Object -First $halfCount

    Show-Progress "Toggling state of $halfCount mods..."
    $firstHalf | ForEach-Object { Toggle-ModState $_ }

    Show-Status -Mods $mods
    $response = Read-Host "Is the issue present? (Y: Yes, N: No, U: Undo last action, Q: Quit)"

    switch ($response.ToUpper()) {
        "Y" {
            Show-Progress "Issue is present. Keeping the first half in the problem set."
            $mods | ForEach-Object { $_.InProblemSet = $firstHalf -contains $_ }
        }
        "N" {
            Show-Progress "Issue is not present. Second half is the problem set."
            $mods | ForEach-Object { $_.InProblemSet = $firstHalf -notcontains $_ }
            $firstHalf | ForEach-Object { Toggle-ModState $_ } # Re-enable the first half
        }
        "U" {
            Show-Progress "Undoing last action..."
            $firstHalf | ForEach-Object { Toggle-ModState $_ }
            $iteration--
        }
        "Q" {
            $continue = $false
        }
    }

    if (($mods | Where-Object { $_.InProblemSet }).Count -le 1) {
        Show-Progress "Problem mod(s) isolated."
        $continue = $false
    }
}

$problemMods = $mods | Where-Object { $_.InProblemSet }
Show-Progress "Process completed. Probable problem mods:"
$problemMods | ForEach-Object { Write-Host "- $($_.FullName)" }

$restoreAll = Read-Host "Do you want to restore all mods to enabled state? (Y/N)"
if ($restoreAll -eq 'Y') {
    $mods | Where-Object { -not $_.IsEnabled } | ForEach-Object { Toggle-ModState $_ }
    Show-Progress "All mods have been enabled."
}

Show-Progress "Script execution completed."
