# Steamodded - A Balatro ModLoader

## Introduction

Steamodded is a mod loader and injector for the game Balatro. It is developed using Lua for the injected code and Python for additional tools. Currently, Steamodded focuses on basic mod loading and injection functionalities and does not include a modding API.

## Features

- **Mod Loader:** Loads mods into the game.

It will load every mods located at the path `C:\Users\<USER>\AppData\Roaming\Balatro` (or `%appdata%\Balatro\Mods`) into the game.
If it's for now very simple, it will seach for an header at the top of the file that looks like this:

```text
--- STEAMODDED HEADER
--- MOD_NAME: Your Mod Name
--- MOD_ID: YourModID
--- MOD_AUTHOR: [You, AnotherDev, AnotherOtherDev]
--- MOD_DESCRIPTION: The Description of your Mod
```

This header is mandatory and the mod loader will not load the mod without it.

The `MOD_ID` must be unique and without spaces. The `MOD_AUTHOR` must be an array. Every part of the Header must be present.

Additionally, the following segments may be present below your header in any order:

```text
--- PRIORITY: -1000
--- DISPLAY_NAME: ShortName
--- BADGE_COLOUR: 123456
```

The priority value must be an integer and defaults to 0 if absent. A lower value will cause your mod to be loaded earlier.

If a display name is present, it will replace your mod name on badges that identify your mod on custom game objects. Make sure to keep it short and recognizable. 

If no badge colour is specified, a default colour of #666666 will be used for these badges. The colour must be a valid hex code.

After the Header validation, the lua code of your mod will be loaded.

- **Core Management:** Handles the overall management of mods.

This is the hearth of the project, every parts depend on it.

For now it's not doing much outside of displaying basic informations and offering a basic GUI for Steamodded. In the future it will be the most important part of the project.

- **Debug Socket:** Provides a way to output debug data.

The debug Socket is used to send debug informtions from the Game and the Mods outside of the Game. Since we can't launch Balatro linked with a console interface, it's the most efficient way to provide debug data.

- **Injector:** Injects Steamodded into Balatro.

The injector is coded in Python. It's used to inject every other parts of Steamodded into the base game.

It use 2 external tools: [7zip](https://www.7-zip.org/) for is extreme capability in term of SFX ZIP, permiting Steamodded to modify the executable without breaking it, and [luajit-decompiler-v2](https://github.com/marsinator358/luajit-decompiler-v2) that is used for decompiling the code before reinjection. Big thanks to them, they made this project way easier to do.

The code is NOT recompiled after injection. It might change in the future but it will stay like that for now.

Another Injector is provided using Powershell. It can be used compiled or not compiled. This one also rely on 7zip but will let you handle in someway the installation.

## Installation

### How to Install Steamodded

Please refer to the [Installation Instructions](https://github.com/Steamopollys/Steamodded/wiki/01.-Getting-started) in the Steamodded guide. While it is possible to use the injector for versions 0.9.8 and below, this method is no longer recommended and is deprecated starting in version 1.0, which is current in Alpha.

### How to install the Alpha

To use the 1.0.0 pre-release version, install Steamodded [using Git](https://github.com/Steamopollys/Steamodded/wiki/01.-Getting-started#using-the-command-line-requires-git) and check out the main branch. Alternatively, [download](https://github.com/Steamopollys/Steamodded/archive/refs/heads/main.zip) the source code directly instead of the release and proceed with steps 3-6 of the manual [Installation Instructions](https://github.com/Steamopollys/Steamodded/wiki/01.-Getting-started)

## How to Install a Mod

- Navigate to your Mods directory as it was specified in the installation instructions.
- Put the mod into the directory (only the Mod File if there is only one file provided or all the files in a subdirectory)
- Launch the game and enjoy!


## Contributing

This project is open for contribution. Please, feel free to open a pull request to do so. If you are adding new features, providing documentation is highly appreciated.

## License

This project is licensed under the GNU General Public License. This ensures that the software is free to use, modify, and distribute. For more details, click [here](https://github.com/Steamopollys/Steamodded/actions?tab=GPL-3.0-1-ov-file)
