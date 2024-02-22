#!/bin/bash

# Navigate to the script's directory (optional)
cd "$(dirname "$0")"

# Run PyInstaller
nuitka3 --standalone --onefile --include-data-dir=core=../core --include-data-dir=debug=../debug --include-data-dir=loader=../loader steamodded_injector.py 