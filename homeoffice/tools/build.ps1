param(
    [string]$Godot = "$PSScriptRoot/../.runtime/godot/Godot_v4.6.1-stable_win64_console.exe",
    [switch]$LocalOnly
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath "$PSScriptRoot/..").Path
if (-not (Get-Command $Godot -ErrorAction SilentlyContinue)) { throw 'Godot 4.6.1 is required to rebuild. Pass -Godot <executable>. The checked-in docs/ export can run with npm run dev without Godot.' }
foreach ($template in @('web_nothreads_debug.zip','web_nothreads_release.zip')) {
    if (-not (Test-Path -LiteralPath "$projectRoot/.runtime/templates/$template")) { throw "Missing matching Godot 4.6.1 export template: $template. See README build setup." }
}
$version = & $Godot --version
if ($version -notmatch '^4\.6\.1\.stable') { throw "Expected Godot 4.6.1 stable, received $version" }
& python "$PSScriptRoot/write_build_info.py" prepare
if ($LASTEXITCODE -ne 0) { throw 'Build identity failed' }
New-Item -ItemType Directory -Path "$projectRoot/build" -Force | Out-Null
if (Test-Path -LiteralPath "$projectRoot/node_modules") {
    New-Item -ItemType File -Path "$projectRoot/node_modules/.gdignore" -Force | Out-Null
}
$importOutput = & $Godot --headless --path $projectRoot --editor --import --quit 2>&1
$importExit = $LASTEXITCODE
$importOutput | Write-Output
if ($importExit -ne 0 -or ($importOutput -match "SCRIPT ERROR|Parse Error|ERROR: Failed to load")) { throw 'Godot import failed' }
& $Godot --headless --path $projectRoot --export-release Web "$projectRoot/build/index.html"
if ($LASTEXITCODE -ne 0) { throw 'Godot export failed' }
Get-ChildItem -LiteralPath "$projectRoot/web" -File | Where-Object { $_.Extension -in '.mjs','.css' -or $_.Name -eq 'peerjs.min.js' -or $_.Name -like '*.LEGAL.txt' } | Copy-Item -Destination "$projectRoot/build"
if (Test-Path -LiteralPath "$projectRoot/web/catalog") { Copy-Item -LiteralPath "$projectRoot/web/catalog" -Destination "$projectRoot/build" -Recurse -Force }
Copy-Item -LiteralPath "$projectRoot/web/onnx" -Destination "$projectRoot/build" -Recurse -Force
New-Item -ItemType File -Path "$projectRoot/build/.nojekyll" -Force | Out-Null
Copy-Item -LiteralPath "$projectRoot/docs/licenses" -Destination "$projectRoot/build" -Recurse -Force
Copy-Item -LiteralPath "$projectRoot/schemas" -Destination "$projectRoot/build" -Recurse -Force
Copy-Item -LiteralPath "$projectRoot/docs/third-party-notices.md" -Destination "$projectRoot/build"
& python "$PSScriptRoot/write_build_info.py" finalize
if ($LASTEXITCODE -ne 0) { throw "Build manifest failed" }
& python "$PSScriptRoot/site_artifact.py" verify "$projectRoot/build" --source
if ($LASTEXITCODE -ne 0) { throw 'Export verification failed' }
if (-not $LocalOnly) {
    & python "$PSScriptRoot/site_artifact.py" publish
    if ($LASTEXITCODE -ne 0) { throw 'Publishing the checked-in docs/ export failed' }
}
Get-ChildItem -LiteralPath "$projectRoot/build" -File | Select-Object Name,Length
