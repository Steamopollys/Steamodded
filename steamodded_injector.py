from pathlib import Path
import subprocess
import os
import sys
from tempfile import TemporaryDirectory
from typing import Literal
import zipfile
import shutil
import platform
from contextlib import contextmanager
import requests


def download_file(url, output_path):
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(output_path, "wb") as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        return True
    return False


def merge_directory_contents(directory_path):
    directory_content = ""
    core_file_name = "core.lua"
    
    if os.path.exists(directory_path):
        print(f"Processing directory: {directory_path}")
        
        # Process core.lua first if it exists
        core_file_path = os.path.join(directory_path, core_file_name)
        if os.path.isfile(core_file_path):
            try:
                with open(core_file_path, "r", encoding="utf-8") as file:
                    directory_content += file.read() + "\n"  # Append the core file content first
                    print(f"Appended {core_file_name} to the directory content")
            except IOError as e:
                print(f"Error reading {core_file_path}: {e}")
        
        # Process the rest of the .lua files
        for file_name in os.listdir(directory_path):
            if file_name.endswith(".lua") and file_name != core_file_name:  # Skip the core.lua file
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


def download_7zip():
    """Download 7-Zip suite to a temporary directory"""
    # URL to download the 7-Zip suite
    seven_zip_url = "https://github.com/Steamopollys/Steamodded/raw/main/7-zip/7z.zip"
    seven_zip_dir = TemporaryDirectory()
    print(seven_zip_dir.name)
    print("Downloading and extracting 7-Zip suite...")
    download_file(seven_zip_url, os.path.join(seven_zip_dir.name, "7z.zip"))
    with zipfile.ZipFile(os.path.join(seven_zip_dir.name, "7z.zip"), "r") as zip_ref:
        zip_ref.extractall(seven_zip_dir.name)
    return seven_zip_dir


OSType = Literal["windows", "macOS", "linux"]

def get_os_type() -> OSType:
    """Determine whether the OS is Windows, Linux, or macOS"""
    if os.name == "nt":
        return "windows"
    elif os.name == "posix":
        if platform.system() == "Darwin":
            return "macOS"
        else:
            # This is Linux or another POSIX-compliant OS
            return "linux"
    else:
        raise RuntimeError(f"Unsupported OS runtime: {os.name}")


@contextmanager
def get_7zip_command(os_type: OSType):
    """Prepare the 7-Zip command according to the operating system"""
    seven_zip_dir = download_7zip()
    try:
        if os_type in ["linux", "macOS"]:
            command = "7zz"
            # Check that 7zz is installed and warn the user if not
            assert shutil.which(
                command
            ), "7zz is not installed! Install 7-zip and try again."
        elif os_type == "windows":
            command = f"{seven_zip_dir.name}/7z.exe"
        yield command
    finally:
        # Make sure we always clean up the temporary 7z dir
        seven_zip_dir.cleanup()


def get_mods_dir(os_type: OSType):
    """Get the mods dir for Balatro and create it if it doesn't already exist"""
    if os_type == "windows":
        mods_dir = os.path.expandvars(r"%appdata%\Balatro\Mods")
    elif os_type == "macOS":
        mods_dir = os.path.expanduser("~/Library/Application Support/Balatro/Mods")
    elif os_type == "linux":
        mods_dir = os.path.expanduser( "~/.local/share/Steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods")

    mods_dir = Path(mods_dir)

    if mods_dir.exists() and mods_dir.is_file():
        mods_dir.unlink()
    if not mods_dir.exists():
        mods_dir.mkdir()

    return mods_dir


def main():
    print("Starting the process...")

    # Check if the SFX archive path is provided
    if len(sys.argv) < 2:
        print("Please drag and drop the SFX archive onto this executable.")
        sys.exit(1)

    sfx_archive_path = sys.argv[1]
    print(f"SFX Archive received: {sfx_archive_path}")
    os_type = get_os_type()

    with get_7zip_command(os_type) as command, TemporaryDirectory() as temp_dir:
        # Temporary directory for extraction and modification
        print(temp_dir)
        # Extract the SFX archive
        subprocess.run([command, "x", f"-o{temp_dir}", sfx_archive_path], check=True)
        print("Extraction complete.")

        # Path to main.lua and game.lua within the extracted files
        game_lua_path = os.path.join(temp_dir, "game.lua")
        decompile_output_path = os.path.join(temp_dir, "output")
        os.makedirs(decompile_output_path, exist_ok=True)  # Create the output directory

        main_lua_output_path = os.path.join(temp_dir, "main.lua")

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
        subprocess.run( [command, "a", sfx_archive_path, main_lua_output_path], check=True)
        # Update the SFX archive with the modified game.lua
        subprocess.run([command, "a", sfx_archive_path, game_lua_path], check=True)
        print("SFX Archive updated.")

    mods_dir = get_mods_dir(os_type)
    print("Process completed successfully.")
    print(f"Place your mods in {mods_dir}")
    print("Press any key to exit...")
    input()


if __name__ == "__main__":
    main()
