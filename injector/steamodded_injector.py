import subprocess
import os
import sys
import tempfile
import zipfile
import shutil
import requests


def download_file(url, output_path):
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(output_path, "wb") as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        return True
    return False


# def decompile_lua(decompiler_path, lua_path, output_dir):
#     subprocess.run([decompiler_path, lua_path, '--output', output_dir])


def merge_directory_contents(directory_path):
    directory_content = ""
    if os.path.exists(directory_path):
        print(f"Processing directory: {directory_path}")
        for file_name in os.listdir(directory_path):
            if file_name.endswith(".lua"):
                file_path = os.path.join(directory_path, file_name)
                try:
                    with open(file_path, "r", encoding="utf-8") as file:
                        file_content = file.read()
                        directory_content += "\n" + file_content
                        print(f"Appended {file_name} to the directory content")
                except IOError as e:
                    print(f"Error reading {file_path}: {e}")
    else:
        print(f"Directory not found: {directory_path}")
    return directory_content


def modify_main_lua(main_lua_path, base_dir, directories):
    print(f"Modifying {main_lua_path} with files from {directories} in {base_dir}")

    try:
        with open(main_lua_path, "r", encoding="utf-8") as file:
            main_lua_content = file.read()
    except IOError as e:
        print(f"Error reading {main_lua_path}: {e}")
        return

    for directory in directories:
        directory_path = os.path.join(base_dir, directory)
        print(f"Looking for directory: {directory_path}")  # Debug print
        directory_content = merge_directory_contents(directory_path)
        main_lua_content += "\n" + directory_content

    try:
        with open(main_lua_path, "w", encoding="utf-8") as file:
            file.write(main_lua_content)
    except IOError as e:
        print(f"Error writing to {main_lua_path}: {e}")


def modify_game_lua(game_lua_path):
    try:
        with open(game_lua_path, "r", encoding="utf-8") as file:
            lines = file.readlines()

        target_line = "    self.SPEEDFACTOR = 1\n"
        insert_line = "    initSteamodded()\n"  # Ensure proper indentation
        target_index = None

        for i, line in enumerate(lines):
            if target_line in line:
                target_index = i
                break  # Find the first occurrence and stop

        if target_index is not None:
            print("Target line found. Inserting new line.")
            lines.insert(target_index + 1, insert_line)
            with open(game_lua_path, "w", encoding="utf-8") as file:
                file.writelines(lines)
            print("Successfully modified game.lua.")
        else:
            print("Target line not found in game.lua.")

    except IOError as e:
        print(f"Error modifying game.lua: {e}")


print("Starting the process...")

# URL to download the LuaJIT decompiler
# luajit_decompiler_url = ""

# Temporary directory for operations
with tempfile.TemporaryDirectory() as decompiler_dir:
    # This part was used to download the LuaJit decompiler
    # luajit_decompiler_path = os.path.join(decompiler_dir, 'luajit-decompiler-v2.exe')

    # # Download LuaJIT decompiler
    # if not download_file(luajit_decompiler_url, luajit_decompiler_path):
    #     print("Failed to download LuaJIT decompiler.")
    #     sys.exit(1)

    # print("LuaJIT Decompiler downloaded.")

    # URL to download the 7-Zip suite
    seven_zip_url = (
        "https://github.com/Steamopollys/Steamodded/raw/main/7-zip/7z-repack.zip"
    )

    # Temporary directory for 7-Zip suite
seven_zip_dir = tempfile.TemporaryDirectory()
print(seven_zip_dir.name)
print("Downloading and extracting 7-Zip suite...")
download_file(seven_zip_url, os.path.join(seven_zip_dir.name, "7z2401x64-repack.zip"))
with zipfile.ZipFile(
    os.path.join(seven_zip_dir.name, "7z2401x64-repack.zip"), "r"
) as zip_ref:
    zip_ref.extractall(seven_zip_dir.name)

# Check the operating system
#if os.name() == 'Linux':
#    seven_zip_path = ['wine', os.path.join(seven_zip_dir.name, "7z.exe")]
#elif os.name == 'nt':
#    seven_zip_path = os.path.join(seven_zip_dir.name, "7z.exe")
#else:
#    # Handle other operating systems or raise an error
#    raise NotImplementedError("This script only supports Windows and Linux.")

# Determine the operating system and prepare the 7-Zip command accordingly
if os.name == 'posix':
    # Check if Wine is installed
    wine_path = shutil.which('wine')
    if not wine_path:
        raise EnvironmentError("Wine is not installed. Please install Wine to run Windows executables on Linux.")
    # Prepare the command to run 7z.exe with Wine
    seven_zip_path = os.path.join(seven_zip_dir.name, "7z.exe")
    command = "/bin/7z"
else:
    # Directly use the 7z command on other operating systems
    seven_zip_path = os.path.join(seven_zip_dir.name, "7z.exe")
    command = [seven_zip_path]

#command = seven_zip_dir + ["x", "-o" + temp_dir.name, sfx_archive_path]

# seven_zip_path = os.path.join(seven_zip_dir.name, "7z.exe")

# Check if the SFX archive path is provided
if len(sys.argv) < 2:
    print("Please drag and drop the SFX archive onto this executable.")
    seven_zip_dir.name.cleanup()
    sys.exit(1)

sfx_archive_path = sys.argv[1]
print(f"SFX Archive received: {sfx_archive_path}")

# Temporary directory for extraction and modification
temp_dir = tempfile.TemporaryDirectory()
print(temp_dir.name)
# Extract the SFX archive
#subprocess.run([command, "x", "-o" + temp_dir.name, sfx_archive_path])
subprocess.run([command, "x", f"-o{temp_dir.name}", sfx_archive_path], check=True)
print("Extraction complete.")

# Path to main.lua and game.lua within the extracted files
main_lua_path = os.path.join(temp_dir.name, "main.lua")
game_lua_path = os.path.join(temp_dir.name, "game.lua")
decompile_output_path = os.path.join(temp_dir.name, "output")
os.makedirs(decompile_output_path, exist_ok=True)  # Create the output directory


# This part was used to decompile to game data
# No longer needed
# decompile_lua(luajit_decompiler_path, main_lua_path, decompile_output_path)
# print("Decompilation of main.lua complete.")

main_lua_output_path = os.path.join(temp_dir.name, "main.lua")

# Determine the base directory (where the .exe is located)
if getattr(sys, "frozen", False):
    # Running in a PyInstaller or Nuitka bundle
    base_dir = os.path.dirname(sys.executable)
else:
    # Running in a normal Python environment
    base_dir = os.path.dirname(os.path.abspath(__file__))

# Modify main.lua
directories = ["core", "debug", "loader"]
modify_main_lua(main_lua_output_path, base_dir, directories)
print("Modification of main.lua complete.")

# Modify main.lua
modify_game_lua(game_lua_path)
print("Modification of game.lua complete.")

# Update the SFX archive with the modified main.lua
#subprocess.run([command, "a", sfx_archive_path, main_lua_output_path])
subprocess.run([command, "a", sfx_archive_path, main_lua_output_path], check=True)
# Update the SFX archive with the modified game.lua
#subprocess.run([command, "a", sfx_archive_path, game_lua_path])
subprocess.run([command, "a", sfx_archive_path, game_lua_path], check=True)
print("SFX Archive updated.")

seven_zip_dir.cleanup()
temp_dir.cleanup()

print("Process completed successfully.")
print("Press any key to exit...")
input()
