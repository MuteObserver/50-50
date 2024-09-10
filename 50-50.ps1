function Show-Progress {
    param ([string]$Activity)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Activity" -ForegroundColor Cyan
}

function Get-AllMods {
    param ([string]$Directory)
    return Get-ChildItem -Path $Directory -Recurse -File | ForEach-Object {
        @{
            FullName = $_.FullName
            IsEnabled = -not $_.Name.EndsWith('.disabled')
            WasInitiallyDisabled = $_.Name.EndsWith('.disabled')
            LastWriteTime = $_.LastWriteTime
            InProblemSet = $true
        }
    } | Sort-Object { $_.LastWriteTime }
}

function Toggle-ModState {
    param ([hashtable]$Mod)
    $newName = if ($Mod.IsEnabled) {
        "$($Mod.FullName).disabled"
    } else {
        $Mod.FullName -replace '\.disabled$', ''
    }
    Rename-Item -LiteralPath $Mod.FullName -NewName $newName -ErrorAction SilentlyContinue
    if ($?) {
        $Mod.FullName = $newName
        $Mod.IsEnabled = -not $Mod.IsEnabled
    }
}

function Show-Status {
    param ([array]$Mods)
    $enabledCount = ($Mods | Where-Object { $_.IsEnabled }).Count
    $problemSetCount = ($Mods | Where-Object { $_.InProblemSet }).Count
    Write-Host "Status: $enabledCount enabled, $($Mods.Count - $enabledCount) disabled. Problem set size: $problemSetCount"
}

# Main script
$directory = Read-Host "Enter the full path to your Sims 4 mods directory"
$directory = $directory.Trim('"') # Remove quotes if user included them

if (-not (Test-Path -LiteralPath $directory)) {
    Write-Host "Directory not found. Please check the path and try again."
    exit
}

Show-Progress "Scanning for mods..."
$mods = Get-AllMods -Directory $directory
Show-Progress "Found $($mods.Count) mods in total."

# Re-enable initially disabled mods
$initiallyDisabledMods = $mods | Where-Object { $_.WasInitiallyDisabled }
if ($initiallyDisabledMods.Count -gt 0) {
    Show-Progress "Re-enabling $($initiallyDisabledMods.Count) initially disabled mods..."
    $initiallyDisabledMods | ForEach-Object { Toggle-ModState $_ }
}

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

    $problemSet = $mods | Where-Object { $_.InProblemSet -and $_.IsEnabled }
    $halfCount = [math]::Ceiling($problemSet.Count / 2)
    $firstHalf = $problemSet | Select-Object -First $halfCount

    Show-Progress "Disabling $halfCount mods..."
    $firstHalf | ForEach-Object { Toggle-ModState $_ }

    Show-Status -Mods $mods
    $response = Read-Host "Is the issue present? (Y: Yes, N: No, U: Undo last action, Q: Quit)"

    switch ($response.ToUpper()) {
        "Y" {
            Show-Progress "Issue is present. Keeping the disabled mods in the problem set."
            $mods | ForEach-Object { $_.InProblemSet = ($firstHalf -contains $_) -or (-not $_.IsEnabled) }
        }
        "N" {
            Show-Progress "Issue is not present. Enabled mods are the problem set."
            $mods | ForEach-Object { $_.InProblemSet = $_.IsEnabled }
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

$restoreAll = Read-Host "Do you want to restore all mods to their original state? (Y/N)"
if ($restoreAll -eq 'Y') {
    Show-Progress "Restoring mods to original state..."
    $mods | ForEach-Object {
        if ($_.IsEnabled -ne -not $_.WasInitiallyDisabled) {
            Toggle-ModState $_
        }
    }
    Show-Progress "All mods have been restored to their original state."
}

Show-Progress "Script execution completed."
