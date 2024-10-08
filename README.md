# 50-50: Sims 4 Mod Detective
A quick and dirty tool for saving time when troubleshooting Sims 4 mods.

## What is this?
A powerShell script implements the 50/50 method for isolating problematic mods for The Sims 4. 
Holds your hand, streamlines the process of finding which mod(s) are causing issues in your game.

## How it works
1. Disables half of your mods
2. You test the game
3. If the problem persists, the issue is in the enabled half. If not, it's in the disabled half.
4. Repeat the process with the problematic half until you isolate the issue

This script automates this process, handling the enabling/disabling of mods and guiding you through the steps.

## Installation
1. Clone this repository or download the `50-50.ps1` file
2. Ensure you have PowerShell installed (comes pre-installed on Windows 10 and later)

## Usage
1. Open PowerShell
2. Navigate to the directory containing the script
3. Run the script
4. Follow the on-screen prompts
5. Profit

## Features
- Automatically handles enabling/disabling of mods
- Keeps track of the current "problem set" of mods
- Allows undoing actions
- Provides a final list of probable problematic mods
- Option to restore all mods to enabled state at the end

## Limitations
- Requires manual testing of the game between iterations, the tool simply holds your hand
- Will take multiple iterations for large mod collections

## Contributing
Feel free to fork, modify, and submit pull requests. All contributions, very welcome.
