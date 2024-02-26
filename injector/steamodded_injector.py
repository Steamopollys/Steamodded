import os
import platform
import subprocess
import sys
import tempfile
import zipfile
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
        for file_name in sorted(os.listdir(directory_path)):
            if file_name.endswith(".lua"):
                file_path = os.path.join(directory_path, file_name)
                try:
                    with open(file_path, "r", encoding="utf-8") as file:
                        file_content = file.read()
                        directory_content += "\n" + file_content
                        print(f"Appended {file_name} to the directory content")
                except IOError as e:
                    print(f"Error reading {file_path}: {e}")
                    raise RuntimeError()
    else:
        print(f"Directory not found: {directory_path}")
        raise RuntimeError()
    return directory_content


def modify_main_lua(main_lua_path, base_dir, directories):
    print(f"Modifying {main_lua_path} with files from {directories} in {base_dir}")

    try:
        with open(main_lua_path, "r", encoding="utf-8") as file:
            main_lua_content = file.read()
    except IOError as e:
        print(f"Error reading {main_lua_path}: {e}")
        raise RuntimeError()

    if "----MOD CORE----" in main_lua_content:
        print(f"Mod loader already present in {main_lua_path}, aborting")
        raise RuntimeError()

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
        raise RuntimeError()


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
            raise RuntimeError()

    except IOError as e:
        print(f"Error modifying game.lua: {e}")
        raise RuntimeError()


def modify_game_sources(source_dir, base_dir):
    """
    Modify the source files of the game, found in [source_dir], using our own files from [base_dir].

    Returns the list of modified paths.
    """
    # Path to main.lua and game.lua within the extracted files
    main_lua_path = os.path.join(source_dir, "main.lua")
    game_lua_path = os.path.join(source_dir, "game.lua")

    # Modify main.lua
    directories = ["core", "debug", "loader"]
    modify_main_lua(main_lua_path, base_dir, directories)
    print("Modification of main.lua complete.")

    # Modify main.lua
    modify_game_lua(game_lua_path)
    print("Modification of game.lua complete.")

    return [main_lua_path, game_lua_path]


def download_seven_zip():
    """"
    Fetch and extract 7zip, returns (command_path, command_dir) as a tuple
    """
    # URL to download the 7-Zip suite
    seven_zip_url = "https://github.com/Steamopollys/Steamodded/raw/main/7-zip/7z-repack.zip"

    # Temporary directory for 7-Zip suite
    seven_zip_dir = tempfile.TemporaryDirectory()
    print(seven_zip_dir.name)
    print("Downloading and extracting 7-Zip suite...")
    download_file(seven_zip_url, os.path.join(seven_zip_dir.name, "7z-repack.zip"))
    with zipfile.ZipFile(
            os.path.join(seven_zip_dir.name, "7z-repack.zip"), "r"
    ) as zip_ref:
        zip_ref.extractall(seven_zip_dir.name)

    # Check the operating system
    # if os.name() == 'Linux':
    #     seven_zip_path = ['wine', os.path.join(seven_zip_dir.name, "7z.exe")]
    # elif os.name == 'nt':
    #     seven_zip_path = os.path.join(seven_zip_dir.name, "7z.exe")
    # else:
    #     # Handle other operating systems or raise an error
    #     raise NotImplementedError("This script only supports Windows and Linux.")

    # Determine the operating system and prepare the 7-Zip command accordingly
    if os.name == 'posix':
        if platform.system() == 'Darwin':
            # This is macOS
            seven_zip_command = "7zz"  # Update this path as necessary for macOS
        else:
            # This is Linux or another POSIX-compliant OS
            seven_zip_command = "7zz"
    else:
        # This is for Windows
        seven_zip_command = f"{seven_zip_dir.name}/7z.exe"

    return seven_zip_command, seven_zip_dir


def main():
    print("Starting the process...")

    # URL to download the LuaJIT decompiler
    # luajit_decompiler_url = ""

    # Temporary directory for operations
    with tempfile.TemporaryDirectory() as decompiler_dir:
        pass
        # This part was used to download the LuaJit decompiler
        # luajit_decompiler_path = os.path.join(decompiler_dir, 'luajit-decompiler-v2.exe')

        # # Download LuaJIT decompiler
        # if not download_file(luajit_decompiler_url, luajit_decompiler_path):
        #     print("Failed to download LuaJIT decompiler.")
        #     sys.exit(1)

        # print("LuaJIT Decompiler downloaded.")

    seven_zip_command, seven_zip_dir = download_seven_zip()

    # Check if the SFX archive path is provided
    if len(sys.argv) < 2:
        print("Please drag and drop the SFX archive onto this executable.")
        seven_zip_dir.cleanup()
        sys.exit(1)

    sfx_archive_path = sys.argv[1]
    print(f"SFX Archive received: {sfx_archive_path}")

    # Temporary directory for extraction and modification
    temp_dir = tempfile.TemporaryDirectory()
    print(temp_dir.name)
    # Extract the SFX archive
    subprocess.run([seven_zip_command, "x", f"-o{temp_dir.name}", sfx_archive_path], check=True)
    print("Extraction complete.")

    # Determine the base directory (where the .exe is located)
    if getattr(sys, "frozen", False):
        # Running in a PyInstaller or Nuitka bundle
        base_dir = os.path.dirname(sys.executable)
    else:
        # Running in a normal Python environment
        base_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

    # decompile_output_path = os.path.join(temp_dir.name, "output")
    # os.makedirs(decompile_output_path, exist_ok=True)  # Create the output directory
    # This part was used to decompile to game data
    # No longer needed
    # decompile_lua(luajit_decompiler_path, main_lua_path, decompile_output_path)
    # print("Decompilation of main.lua complete.")

    modified_files = modify_game_sources(temp_dir.name, base_dir)

    # Update the SFX archive with the modified source files
    subprocess.run([seven_zip_command, "u", sfx_archive_path, *modified_files], check=True)
    print("SFX Archive updated.")

    seven_zip_dir.cleanup()
    temp_dir.cleanup()

    print("Process completed successfully.")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        print("Process failed, see above for errors")

    print("Press enter to exit...")
    input()
