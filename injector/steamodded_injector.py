import requests
import subprocess
import os
import sys
import tempfile
import zipfile

def download_file(url, output_path):
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(output_path, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192): 
                file.write(chunk)
        return True
    return False

def decompile_lua(decompiler_path, lua_path, output_dir):
    subprocess.run([decompiler_path, lua_path, '--output', output_dir])

def modify_main_lua(main_lua_path, base_dir, directories):
    print(f"Modifying {main_lua_path} with files from {directories} in {base_dir}")

    try:
        with open(main_lua_path, 'r', encoding='utf-8') as file:
            main_lua_content = file.read()
    except IOError as e:
        print(f"Error reading {main_lua_path}: {e}")
        return

    for directory in directories:
        directory_path = os.path.join(base_dir, directory)
        if os.path.exists(directory_path):
            print(f"Processing directory: {directory_path}")
            for file_name in os.listdir(directory_path):
                if file_name.endswith('.lua'):
                    file_path = os.path.join(directory_path, file_name)
                    try:
                        with open(file_path, 'r', encoding='utf-8') as file:
                            file_content = file.read()
                            main_lua_content += '\n' + file_content
                            print(f"Appended {file_name} to main.lua")
                    except IOError as e:
                        print(f"Error reading {file_path}: {e}")
        else:
            print(f"Directory not found: {directory_path}")

    try:
        with open(main_lua_path, 'w', encoding='utf-8') as file:
            file.write(main_lua_content)
    except IOError as e:
        print(f"Error writing to {main_lua_path}: {e}")




print("Starting the process...")

# URL to download the LuaJIT decompiler
luajit_decompiler_url = "https://github.com/marsinator358/luajit-decompiler-v2/releases/download/Nov_25_2023/luajit-decompiler-v2.exe"

# Temporary directory for LuaJIT decompiler
with tempfile.TemporaryDirectory() as decompiler_dir:
    luajit_decompiler_path = os.path.join(decompiler_dir, 'luajit-decompiler-v2.exe')

    # Download LuaJIT decompiler
    if not download_file(luajit_decompiler_url, luajit_decompiler_path):
        print("Failed to download LuaJIT decompiler.")
        sys.exit(1)

    print("LuaJIT Decompiler downloaded.")

    # URL to download the 7-Zip suite
    seven_zip_url = "https://cdn.discordapp.com/attachments/485484159603572757/1181530870029504514/7-Zip.zip?ex=6581655f&is=656ef05f&hm=3dfd3e5a4936b0a50d7a5b3f2dd36c30032940b6fb6715e2399602d3be68ce0e"

    # Temporary directory for 7-Zip suite
    with tempfile.TemporaryDirectory() as seven_zip_dir:
        print("Downloading and extracting 7-Zip suite...")
        download_file(seven_zip_url, os.path.join(seven_zip_dir, "7-Zip.zip"))
        with zipfile.ZipFile(os.path.join(seven_zip_dir, "7-Zip.zip"), 'r') as zip_ref:
            zip_ref.extractall(seven_zip_dir)
        seven_zip_path = os.path.join(seven_zip_dir, '7z.exe')

        # Check if the SFX archive path is provided
        if len(sys.argv) < 2:
            print("Please drag and drop the SFX archive onto this executable.")
            sys.exit(1)

        sfx_archive_path = sys.argv[1]
        print(f"SFX Archive received: {sfx_archive_path}")

        # Temporary directory for extraction and modification
        with tempfile.TemporaryDirectory() as tempdir:
            # Extract the SFX archive
            subprocess.run([seven_zip_path, 'x', '-o' + tempdir, sfx_archive_path])
            print("Extraction complete.")

            # Path to main.lua within the extracted files
            main_lua_path = os.path.join(tempdir, 'main.lua')
            decompile_output_path = os.path.join(tempdir, 'output')
            os.makedirs(decompile_output_path, exist_ok=True)  # Create the output directory

            # Decompile main.lua
            decompile_lua(luajit_decompiler_path, main_lua_path, decompile_output_path)
            print("Decompilation of main.lua complete.")

            main_lua_output_path = os.path.join(decompile_output_path, 'main.lua')

            # Determine the base directory (where the .exe is located)
            if getattr(sys, 'frozen', False):
                base_dir = os.path.dirname(sys.executable)
            else:
                base_dir = os.path.dirname(os.path.abspath(__file__))

            # Modify main.lua
            directories = ['core', 'debug', 'loader']
            modify_main_lua(main_lua_output_path, base_dir, directories)
            print("Modification of main.lua complete.")

            # Update the SFX archive with the modified main.lua
            subprocess.run([seven_zip_path, 'a', sfx_archive_path, main_lua_output_path])
            print("SFX Archive updated.")

print("Process completed successfully.")

