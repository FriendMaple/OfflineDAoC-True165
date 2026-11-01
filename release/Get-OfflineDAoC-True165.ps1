# Offline DAoC True 1.65 downloader: installs the complete game into a NEW folder.
#
# GET-OFFLINE-DAOC-TRUE165.cmd runs this. It checks the PC, downloads the game in verified parts from the GitHub
# release (resuming if it is stopped), unpacks each part and deletes it, and offers a desktop shortcut. It never changes
# an existing game folder.
param(
    # Where the game goes (a new folder). Default: OfflineDAoC-True165 next to this downloader's folder, or
    # <drive>:\Games\OfflineDAoC-True165 when that path would be too long.
    [string]$Destination = '',
    [string]$ReleaseVersion = '0.1',
    # Testing only: read the release files from <folder>\v<version>\ instead of GitHub.
    [string]$LocalAssets = '',
    # Testing only: answer the questions with yes.
    [switch]$Yes
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = 'shadowofze/OfflineDAoC-True165'
$Product = 'Offline DAoC True 1.65'
# The new client keeps its graphics (shader) cache in new-client\save, up to 200 characters deeper, and Windows refuses
# paths over 260. So the game folder's own path should stay within 42 characters, or every start recompiles the shaders.
$MaxGamePath = 42
if (!$Destination) {
    $Destination = Join-Path (Split-Path -Parent $PSScriptRoot) 'OfflineDAoC-True165'
    if ([IO.Path]::GetFullPath($Destination).Length -gt $MaxGamePath) {
        $Destination = Join-Path ([IO.Path]::GetPathRoot($PSScriptRoot)) 'Games\OfflineDAoC-True165'
    }
}
$game = [IO.Path]::GetFullPath($Destination)
$cache = Join-Path $PSScriptRoot (Join-Path '.downloads' "v$ReleaseVersion")
$done = Join-Path $game '.install'

function Say([string]$text = '') { Write-Host $text }
function Ask([string]$question) {
    if ($Yes) { return $true }
    $answer = Read-Host "$question (Y/N)"
    return ($answer -match '^\s*[Yy]')
}
function Stop-Install([string]$why) {
    Say ''
    Write-Host $why -ForegroundColor Yellow
    exit 1
}

# ---------------------------------------------------------------- the PC
Say "$Product v$ReleaseVersion - downloader"
Say ''
Say 'Checking your PC...'
if (![Environment]::Is64BitOperatingSystem) { Stop-Install 'This game needs 64-bit Windows 10 or 11.' }
if ([Environment]::OSVersion.Version.Major -lt 10) { Stop-Install 'This game needs Windows 10 or 11.' }

Add-Type -Namespace OfflineDaoc -Name Cpu -MemberDefinition '[DllImport("kernel32.dll")] public static extern bool IsProcessorFeaturePresent(uint feature);'
if (![OfflineDaoc.Cpu]::IsProcessorFeaturePresent(40)) {   # 40 = PF_AVX2_INSTRUCTIONS_AVAILABLE
    Stop-Install 'Your CPU does not support AVX2, which the bots'' navigation needs (most CPUs from 2014 onward have it). The game cannot run on this PC.'
}
if (!(Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\vulkan-1.dll'))) {
    Say ''
    Say 'Vulkan was not found on this PC. The game is made for Vulkan; without it, it tries DirectX 12 instead.'
    Say 'Installing the latest graphics driver from NVIDIA, AMD or Intel usually adds Vulkan.'
    if (!(Ask 'Download anyway?')) { Stop-Install 'Nothing was downloaded.' }
}
$memory = (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory
if ($memory -and $memory -lt 15GB) {
    Say ("This PC has {0:N0} GB of memory; 16 GB is recommended. The game may run slowly with many bots." -f ($memory / 1GB))
}

# ---------------------------------------------------------------- the folder
if ($game -match 'OneDrive') {
    Say ''
    Say "The game folder would be inside OneDrive: $game"
    Say 'OneDrive can move or lock the game''s files while it runs. A folder such as C:\Games is safer.'
    if (!(Ask 'Install here anyway?')) { Stop-Install 'Nothing was downloaded. Move this downloader folder to a short path such as C:\Games\OfflineDAoC and run it again.' }
}
if ($game.Length -gt $MaxGamePath) {
    Say ''
    Say "The game folder's path is long ($($game.Length) characters): $game"
    Say "The game works best within $MaxGamePath characters, such as C:\Games\OfflineDAoC-True165. With a longer path it"
    Say 'still runs, but loads slowly (it cannot keep its graphics cache), and some files may not install.'
    if (!(Ask 'Install here anyway?')) { Stop-Install 'Nothing was downloaded. Run this again without choosing a folder, or choose a shorter one.' }
}
if ($game -match '[^\x20-\x7E]') {
    Say ''
    Say "The game folder's path has letters outside plain English ($game). Some tools the game uses may not handle that."
    if (!(Ask 'Install here anyway?')) { Stop-Install 'Nothing was downloaded. Move this downloader folder to a path such as C:\Games\OfflineDAoC and run it again.' }
}
if ((Test-Path -LiteralPath $game) -and !(Test-Path -LiteralPath $done)) {
    if (Test-Path -LiteralPath (Join-Path $game 'START OFFLINE DAOC TRUE 1.65.cmd')) {
        Say ''
        Say "$Product is already installed in $game."
        Say 'Double-click START OFFLINE DAOC TRUE 1.65.cmd in that folder to play.'
        exit 0
    }
    Stop-Install "The folder $game already exists. Move or rename it, or run this downloader from another folder. An existing folder is never overwritten."
}

# ---------------------------------------------------------------- downloads
function Get-Asset([string]$name, [string]$outFile, [int64]$bytes = -1) {
    if ($LocalAssets) {
        Copy-Item -LiteralPath (Join-Path (Join-Path $LocalAssets "v$ReleaseVersion") $name) -Destination $outFile -Force
        return
    }
    $url = "https://github.com/$Repo/releases/download/v$ReleaseVersion/$name"
    # Only a shorter, unfinished file is continued; anything else starts over.
    $existing = Get-Item -LiteralPath $outFile -ErrorAction SilentlyContinue
    if ($existing -and ($bytes -lt 0 -or $existing.Length -ge $bytes)) { Remove-Item -LiteralPath $outFile -Force }
    $curl = Join-Path $env:SystemRoot 'System32\curl.exe'
    if (Test-Path -LiteralPath $curl) {
        & $curl --location --fail --retry 10 --retry-delay 5 --continue-at - --progress-bar --output $outFile $url
        if ($LASTEXITCODE -eq 0) { return }
        Say "The download of $name stopped (code $LASTEXITCODE); trying another way..."
        Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue
    }
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $outFile
}

New-Item -ItemType Directory -Path $cache -Force | Out-Null
$manifestFile = Join-Path $cache 'download-manifest.json'
Say ''
Say 'Getting the list of files...'
try { Get-Asset 'download-manifest.json' $manifestFile } catch {
    Stop-Install "The download list could not be fetched. Check your internet connection and run this again. ($($_.Exception.Message))"
}
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
if ($manifest.Version -ne $ReleaseVersion -or !$manifest.RootFolder -or !$manifest.Parts) { Stop-Install 'The download list is not what this downloader expects. Get the newest downloader from the release page.' }
$parts = @($manifest.Parts)
$totalDownload = [int64](($parts | Measure-Object -Property Bytes -Sum).Sum)
$installed = [int64]$manifest.InstalledBytes

$drive = New-Object IO.DriveInfo ([IO.Path]::GetPathRoot($game))
$largest = [int64](($parts | Measure-Object -Property Bytes -Maximum).Maximum)
$need = $installed + $largest + 1GB
if (!(Test-Path -LiteralPath $done) -and $drive.AvailableFreeSpace -lt $need) {
    Stop-Install ("The game needs about {0:N0} GB of free space on {1} while it installs ({2:N0} GB free). Free up space, or move this downloader folder to another drive, and run it again." -f ($need / 1GB), $drive.Name, ($drive.AvailableFreeSpace / 1GB))
}

Say ''
Say ("This installs $Product v$ReleaseVersion into this new folder:")
Say "  $game"
Say ("Download: {0:N1} GB in {1} parts. Installed size: {2:N1} GB." -f ($totalDownload / 1GB), $parts.Count, ($installed / 1GB))
Say 'If it stops (or you close this window), run the same file again: it continues where it stopped.'
if (!(Test-Path -LiteralPath $done) -and !(Ask 'Start the download?')) { Stop-Install 'Nothing was downloaded.' }

[IO.Directory]::CreateDirectory($done) | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$prefix = $manifest.RootFolder + '/'
$gamePrefix = $game.TrimEnd('\') + '\'
$index = 0
foreach ($part in $parts) {
    $index++
    if ($part.Name -notmatch '^[A-Za-z0-9._-]+\.zip$' -or $part.SHA256 -notmatch '^[A-Fa-f0-9]{64}$') { Stop-Install 'The download list has an invalid entry.' }
    $marker = Join-Path $done ($part.Name + '.done')
    if (Test-Path -LiteralPath $marker) { continue }
    $file = Join-Path $cache $part.Name
    $ok = (Test-Path -LiteralPath $file) -and (Get-Item -LiteralPath $file).Length -eq $part.Bytes
    if ($ok) { $ok = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -eq $part.SHA256 }
    if (!$ok) {
        Say ''
        Say ("Downloading part {0} of {1} ({2:N2} GB)..." -f $index, $parts.Count, ($part.Bytes / 1GB))
        try { Get-Asset $part.Name $file ([int64]$part.Bytes) } catch {
            Stop-Install "The download stopped: $($_.Exception.Message). Run this file again to continue; finished parts are kept."
        }
        Say 'Checking it...'
        if ((Get-Item -LiteralPath $file).Length -ne $part.Bytes -or (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $part.SHA256) {
            Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
            Stop-Install 'That part did not download correctly. Run this file again to retry it; finished parts are kept.'
        }
    }
    Say ("Unpacking part {0} of {1}..." -f $index, $parts.Count)
    $zip = [IO.Compression.ZipFile]::OpenRead($file)
    try {
        foreach ($entry in $zip.Entries) {   # check every entry before writing anything
            $name = $entry.FullName.Replace('\','/')
            if (!$name.StartsWith($prefix,[StringComparison]::Ordinal) -or $name.Contains(':') -or $name.Contains('/../')) { Stop-Install 'A downloaded part has an unexpected layout.' }
            $rel = $name.Substring($prefix.Length)
            if ($rel -and ![IO.Path]::GetFullPath((Join-Path $game $rel)).StartsWith($gamePrefix,[StringComparison]::OrdinalIgnoreCase)) { Stop-Install 'A downloaded part has an unsafe entry.' }
        }
        foreach ($entry in $zip.Entries) {
            $rel = $entry.FullName.Replace('\','/').Substring($prefix.Length)
            if (!$rel -or $rel.EndsWith('/')) { continue }
            $path = Join-Path $game $rel
            [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $path, $true)
        }
    } finally { $zip.Dispose() }
    Set-Content -LiteralPath $marker -Value $part.SHA256 -Encoding ASCII
    Remove-Item -LiteralPath $file -Force
}

foreach ($rel in @($manifest.Required)) {
    if (!(Test-Path -LiteralPath (Join-Path $game $rel) -PathType Leaf)) { Stop-Install "The install is missing $rel. Run this file again." }
}
Remove-Item -LiteralPath $done -Recurse -Force
Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------- finish
$start = Join-Path $game 'START OFFLINE DAOC TRUE 1.65.cmd'
Say ''
if (Ask 'Put a shortcut to the game on your desktop?') {
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Offline DAoC True 1.65.lnk'))
    $link.TargetPath = $start
    $link.WorkingDirectory = $game
    $link.Save()
    Say 'A shortcut "Offline DAoC True 1.65" is on your desktop.'
}
Say ''
Write-Host "$Product v$ReleaseVersion is installed in $game" -ForegroundColor Green
Say ''
Say 'To play:'
Say '  1. Double-click START OFFLINE DAOC TRUE 1.65.cmd in that folder (or the desktop shortcut).'
Say '  2. Click START SERVER and wait until the launcher shows RUNNING. The first start takes a few minutes.'
Say '  3. Click ENTER REALM. Your account is created the first time.'
Say '  4. Add bots with the + Lv.1 buttons in the launcher. Start small.'
Say ''
Say 'READ ME FIRST.txt in the game folder has more, and you can delete this downloader folder now.'
