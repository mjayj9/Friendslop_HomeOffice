param([string]$Godot = "$PSScriptRoot/../.runtime/godot/Godot_v4.6.1-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath "$PSScriptRoot/..").Path
$evidenceRoot = Join-Path $projectRoot 'evidence/v3'
$runs = @()
$tests = @('gameplay','authority-physics','physics-lab','dribble','living-props','legacy-interactions','legacy-authority')
foreach ($name in $tests) {
    $started = [DateTime]::UtcNow.ToString('o')
    $log = Join-Path $evidenceRoot "engine-final-$name.log"
    & $Godot --headless --path $projectRoot --script "res://tests/v3-$name.gd" *> $log
    $code = $LASTEXITCODE
    $content = Get-Content -LiteralPath $log -Raw
    $failed = $code -ne 0 -or $content -match 'SCRIPT ERROR|Parse Error|(?m)^FAIL '
    $runs += [ordered]@{ test = $name; startedAt = $started; finishedAt = [DateTime]::UtcNow.ToString('o'); exitCode = $code; passed = -not $failed; log = "engine-final-$name.log" }
    Get-Content -LiteralPath $log | Where-Object { $_ -match 'PASS |FAIL |ERROR' } | Write-Output
    if ($failed) { break }
}
$build = Get-Content -LiteralPath (Join-Path $evidenceRoot 'build-info.json') -Raw | ConvertFrom-Json
$record = [ordered]@{ environment = 'Godot/Jolt headless; controlled fixtures, not browser input'; buildId = $build.buildId; sourceDigest = $build.source.digest; completed = $runs.Count -eq $tests.Count -and @($runs | Where-Object { -not $_.passed }).Count -eq 0; runs = $runs }
$record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidenceRoot 'engine-final-run.json') -Encoding utf8
if (-not $record.completed) { throw 'V3 engine regression failed. Inspect the recorded log.' }
