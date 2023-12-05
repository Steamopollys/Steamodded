# Steamodded - A Balatro ModLoader

## Introduction

Steamodded is a mod loader and injector for the game Balatro. It is developed using Lua for the injected code and Python for additional tools. Currently, Steamodded focuses on basic mod loading and injection functionalities and does not include a modding API.


## Features

- **Mod Loader:** Loads mods into the game.

It will load every mods located at the path `C:\Users\USER\AppData\Roaming\Balatro\Mods` (or `%appdata%\Balatro\Mods`) into the game.
If it's for now very simple, it will seach for an header at the top of the file that looks like this:
```
--- STEAMODDED HEADER
--- MOD_NAME: Your Mod Name
--- MOD_ID: YourModID
--- MOD_AUTHOR: [You, AnotherDev, AnotherOtherDev]
--- MOD_DESCRIPTION: The Description of your Mod
```
    
This header is mandatory and the mod loader will not load the mod without it.

The `MOD_ID` must be unique and without spaces. The `MOD_AUTHOR` mus be an array. Every part of the Header must be present.

After the Header validation, the lua code of your mod will be loaded.

  
- **Core Management:** Handles the overall management of mods.

This is the hearth of the project, every parts depend on it.

For now it's not doing much outside of displaying basic informations and offering a basic GUI for Steamodded. In the future it will be the most important part of the project.


- **Debug Socket:** Provides a way to output debug data.

The debug Socket is used to send debug informtions from the Game and the Mods outside of the Game. Since we can't launch Balatro linked with a console interface, it's the most efficient way to provide debug data.

- **Injector:** Injects Steamodded into Balatro.

The injector is coded in Python. It's used to inject every other parts of Steamodded into the base game.

It use 2 external tools: [7zip](https://www.7-zip.org/) for is extreme capability in term of SFX ZIP, permiting Steamodded to modify the executable without breaking it, and [luajit-decompiler-v2](https://github.com/marsinator358/luajit-decompiler-v2) that is used for decompiling the code before reinjection.

The code is NOT recompiled after injection. It might change in the future but it will stay like that for now.


## Installation
[Provide detailed steps on how to install the mod loader.]

## Usage
[Explain how to use the mod loader, including any commands or configurations.]

## Dependencies
[List any dependencies required to run the mod loader.]

## Contributing
[Guidelines for contributing to the project, if applicable.]

## License
[Information about the project's license.]

## Acknowledgments
[Credits or acknowledgments for any third-party resources or contributors.]
