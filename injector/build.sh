#!/bin/bash

# Navigate to the script's directory (optional)
cd "$(dirname "$0")"

# Run PyInstaller
pyinstaller.exe --onefile --console steamodded_injector.py
