@echo off
nuitka --standalone --onefile --include-data-file=7-zip/7z.zip=./7-zip/7z.zip --include-data-dir=core=./core --include-data-dir=debug=./debug --include-data-dir=loader=./loader steamodded_injector.py
pause

