# Define the URL of the GitHub repository ZIP
$repoUrl = "https://codeload.github.com/Steamopollys/Steamodded/zip/refs/tags/0.8.0" # Update this URL
$directories = @("core", "debug", "loader")

function Find-7Zip {
    $possiblePaths = @(
        "${env:ProgramFiles}\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
        "${env:ProgramW6432}\7-Zip\7z.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    $pathFromEnv = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($pathFromEnv) {
        return $pathFromEnv.Source
    }

    # If 7-Zip not found, offer to download and install
    $userResponse = Read-Host "7-Zip not found. Would you like to download and install it now? (Y/N)"
    if ($userResponse -eq 'Y' -or $userResponse -eq 'y') {
        $installerPath = "${env:TEMP}\7zInstaller.exe"
        $installerUrl = "https://www.7-zip.org/a/7z1900-x64.exe" # Update URL to the latest version
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -Args "/S" -Wait

        # Recheck for 7-Zip installation
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                return $path
            }
        }
    }

    throw "7-Zip installation was not found or completed. Please install 7-Zip manually."
}

# Function to download and extract specific directories from GitHub repo ZIP
function Download-And-Extract-Repo {
    # Download the ZIP file
    $downloadPath = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName() + ".zip")
    Invoke-WebRequest -Uri $repoUrl -OutFile $downloadPath

    $extractPath = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName())
    # Extract the ZIP file
    Expand-Archive -LiteralPath $downloadPath -DestinationPath $extractPath

    $unknownSubDir = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    Write-Host "Found subdirectory: $($unknownSubDir.FullName)"

    $mergedFilePath = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName())

    # Merge contents of specific directories into main.lua
    $mergedContent = ""
    foreach ($dir in $directories) {
        $dirPath = Join-Path -Path $unknownSubDir.FullName -ChildPath $dir
        # Filter for .lua files only
        $files = Get-ChildItem -Path $dirPath -File -Filter "*.lua"
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw
            $mergedContent += $content + "`n" # New line between files
        }
    }    

    # Save the merged content to main.lua
    $mergedContent | Out-File -FilePath $mergedFilePath
    return ($mergedContent)
}

function Find-GameExe {
    $steamInstallPath = Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Valve\Steam" | Select-Object -ExpandProperty InstallPath

    # Check if the Steam installation path exists
    if (-not(Test-Path $steamInstallPath))
    {
        return ""
    }
    Write-Host "Found steam installation path: $steamInstallPath"
    
    # Construct the path to the vdf file that contains the game library information
    $vdfPath = Join-Path $steamInstallPath 'steamapps\libraryfolders.vdf'
    
    # Read the vdf file and convert it to a hashtable
    $vdfContent = Get-Content $vdfPath -Raw
    $paths = [Regex]::Matches($vdfContent, '"path"\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value -replace '\\\\', '\' }
    
    # Construct the full game path for each library folder and check if it exists
    $gameFolder = 'steamapps\common\Balatro'
    foreach ($path in $paths) {
        $gamePath = Join-Path $path $gameFolder
        $exePath = Join-Path $gamePath "Balatro.exe"
        if (Test-Path $exePath) {
            return $exePath
        }
    }
    return ""
}

function Find-Or-Prompt-GameExe {
    $foundPath = Find-GameExe
    if ($foundPath) {
        return $foundPath
    }

    # If not found, prompt the user
    $userInputPath = Read-Host "Unable to locate $gameName automatically. Please enter the full path to $gameName.exe"
    if (Test-Path $userInputPath) {
        return $userInputPath
    } else {
        Write-Host "The path entered does not exist. Exiting script."
        exit
    }
}

$7ZipPath = Find-7Zip

$mergedContent = Download-And-Extract-Repo -url $repoUrl -downloadPath $downloadPath -extractPath $extractPath -mergedContent $mergedContent -directories $directories

$balatroExePath = Find-Or-Prompt-GameExe

$tempDirForExtraction = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName())
Write-Host "Temporary directory for extraction: $tempDirForExtraction"
& $7ZipPath x "$balatroExePath" -o"$tempDirForExtraction" "*main.lua*" -r

# Determine the path to the extracted main.lua
$extractedMainLua = Get-ChildItem -Path $tempDirForExtraction
Write-Host $extractedMainLua
$extractedMainLuaPath = $extractedMainLua.FullName

Write-Host "Extracted main.lua path: $extractedMainLuaPath"

# $mergedContent = Get-Content -Path $mergedFilePath -Raw
Add-Content -Path $extractedMainLuaPath -Value $mergedContent -Encoding UTF8

Push-Location -Path $tempDirForExtraction
& $7ZipPath a "$balatroExePath" "main.lua" -tzip
Pop-Location
Remove-Item -Path $tempDirForExtraction -Recurse -Force
Write-Host "Updated main.lua in archive."


$tempDirForExtraction = Join-Path -Path $env:TEMP -ChildPath ([System.IO.Path]::GetRandomFileName())
& $7ZipPath x "$balatroExePath" -o"$tempDirForExtraction" "*game.lua*" -r

# Determine the path to the extracted game.lua
$extractedGameLua = Get-ChildItem -Path $tempDirForExtraction
Write-Host $extractedGameLua
$extractedGameLuaPath = $extractedGameLua.FullName

Write-Host "Extracted game.lua path: $extractedGameLuaPath"

$lines = Get-Content -Path $extractedGameLuaPath -Encoding UTF8
$targetLine = "    self.SPEEDFACTOR = 1"
$insertLine = "    initSteamodded()"
$targetIndex = $null
            
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match $targetLine) {
        $targetIndex = $i
        break
    }
}

if ($targetIndex -ne $null) {
    Write-Host "Target line found. Inserting new line."
    $lines = $lines[0..$targetIndex] + $insertLine + $lines[($targetIndex+1)..($lines.Length-1)]
    Set-Content -Path $extractedGameLuaPath -Value $lines -Encoding UTF8

    Push-Location -Path $tempDirForExtraction
    & $7ZipPath a "$balatroExePath" "game.lua" -tzip
    Pop-Location

    Write-Host "Successfully modified game.lua."
    } else {
        Write-Host "Target line not found in game.lua."
}

Write-Host "SFX Archive updated."
Write-Host "Process completed successfully."
Write-Host "Press any key to exit..."
$null = Read-Host

# Cleanup
# Remove-Item -Path $tempDirForExtraction -Recurse -Force
