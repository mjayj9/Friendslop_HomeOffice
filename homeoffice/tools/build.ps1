param([string]$Godot = "$PSScriptRoot/../.runtime/godot/Godot_v4.6.1-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath "$PSScriptRoot/..").Path
$version = & $Godot --version
if ($version -notmatch '^4\.6\.1\.stable') { throw "Expected Godot 4.6.1 stable, received $version" }
New-Item -ItemType Directory -Path "$projectRoot/build" -Force | Out-Null
& $Godot --headless --path $projectRoot --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
& $Godot --headless --path $projectRoot --export-release Web "$projectRoot/build/index.html"
if ($LASTEXITCODE -ne 0) { throw 'Godot export failed' }
Get-ChildItem -LiteralPath "$projectRoot/web" -File | Where-Object { $_.Extension -in '.mjs','.css' -or $_.Name -eq 'peerjs.min.js' -or $_.Name -like '*.LEGAL.txt' } | Copy-Item -Destination "$projectRoot/build"
Copy-Item -LiteralPath "$projectRoot/web/onnx" -Destination "$projectRoot/build" -Recurse -Force
New-Item -ItemType File -Path "$projectRoot/build/.nojekyll" -Force | Out-Null
Get-ChildItem -LiteralPath "$projectRoot/build" -File | Select-Object Name,Length
