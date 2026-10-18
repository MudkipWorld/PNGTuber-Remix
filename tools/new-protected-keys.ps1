param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$path=Join-Path $root 'Protected/generated/BuildKeys.gd'
if(Test-Path -LiteralPath $path){throw 'Keys already exist. Back up and retain them to keep existing models compatible.'}
New-Item -ItemType Directory -Force (Split-Path $path -Parent) | Out-Null
$bytes=New-Object byte[] 80
$rng=[Security.Cryptography.RandomNumberGenerator]::Create()
try {$rng.GetBytes($bytes)} finally {$rng.Dispose()}
$enc=([BitConverter]::ToString($bytes[0..31])).Replace('-','').ToLowerInvariant()
$mac=([BitConverter]::ToString($bytes[32..63])).Replace('-','').ToLowerInvariant()
$id=([BitConverter]::ToString($bytes[64..79])).Replace('-','').ToLowerInvariant()
$content="extends RefCounted`nstatic func get_keys() -> Dictionary:`n`treturn {`"enc`": `"$enc`".hex_decode(), `"mac`": `"$mac`".hex_decode(), `"id`": `"$id`".hex_decode()}`n"
[IO.File]::WriteAllText($path,$content)
Write-Output 'Private build keys created. Back up securely; never distribute the source key file.'
