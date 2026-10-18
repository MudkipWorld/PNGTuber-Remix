param([string]$GodotPath=$env:GODOT_PATH)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if(!$GodotPath){$GodotPath=(Get-Command godot -ErrorAction Stop).Source}
$logDir=Join-Path $projectRoot 'build/tests'
New-Item -ItemType Directory -Force $logDir | Out-Null
$logPath=Join-Path $logDir 'test.log'
if(!(Test-Path -LiteralPath (Join-Path $projectRoot 'Protected/generated/BuildKeys.gd'))){throw 'Generate private build keys first: ./tools/new-protected-keys.ps1'}
& $GodotPath --headless --path $projectRoot --editor --import --quit *> (Join-Path $logDir 'import.log')
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath (Join-Path $logDir 'import.log') -Pattern 'SCRIPT ERROR|Parse Error|Failed loading resource' -Quiet)){throw 'Import failed; inspect build/tests/import.log'}
& $GodotPath --headless --path $projectRoot --quit-after 600 res://tests/protected/run.tscn *> $logPath
$resultCode=$LASTEXITCODE
Get-Content -LiteralPath $logPath -Tail 45
if ($resultCode -ne 0 -or !(Select-String -LiteralPath $logPath -SimpleMatch 'PROTECTED TESTS PASSED' -Quiet) -or (Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR|Parse Error|Failed loading resource|FAIL:' -Quiet)) { exit 1 }
exit 0
