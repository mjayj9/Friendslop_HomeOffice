$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path -LiteralPath "$PSScriptRoot/..").Path
$taskOutput=Join-Path $taskRoot 'build/_qa/corpus'
New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
Add-Type -AssemblyName System.Speech
$taskSynth=New-Object System.Speech.Synthesis.SpeechSynthesizer
$taskSynth.SelectVoice('Microsoft Heami Desktop')
try {
 foreach($item in (Get-Content -LiteralPath "$taskRoot/tests/korean-corpus.json" -Raw -Encoding UTF8 | ConvertFrom-Json)){
  $taskSynth.SetOutputToWaveFile((Join-Path $taskOutput ($item.id+'.wav')))
  $taskSynth.Speak($item.reference)
  $taskSynth.SetOutputToNull()
 }
} finally {$taskSynth.Dispose()}
Copy-Item -LiteralPath "$taskRoot/tests/korean-corpus.json" -Destination "$taskRoot/build/_qa/corpus.json"
Write-Output 'Six synthetic Korean utterances generated. These are not human/microphone recordings.'
