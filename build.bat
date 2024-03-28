@echo off
python -m nuitka --standalone --onefile --include-data-dir=core=./core --include-data-dir=debug=./debug --include-data-dir=loader=./loader steamodded_injector.py
pause

