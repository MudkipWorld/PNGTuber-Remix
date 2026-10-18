param([ValidateSet('creator','player')][string]$Role='player', [string]$GodotPath=$env:GODOT_PATH, [string]$TemplateDir='')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if(!$GodotPath){$GodotPath=(Get-Command godot -ErrorAction Stop).Source}
if(!(Test-Path -LiteralPath (Join-Path $projectRoot 'Protected/generated/BuildKeys.gd'))){throw 'Generate private build keys first: ./tools/new-protected-keys.ps1'}
$projectPath=Join-Path $projectRoot 'project.godot'
$presetsPath=Join-Path $projectRoot 'export_presets.cfg'
$originalProject=[IO.File]::ReadAllText($projectPath)
$originalPresets=[IO.File]::ReadAllText($presetsPath)
$outputDir=Join-Path $projectRoot "build/$Role"
New-Item -ItemType Directory -Force $outputDir | Out-Null
if(!$TemplateDir){$TemplateDir=Split-Path $GodotPath -Parent}
$templateDir=$TemplateDir
$releaseTemplate=(Join-Path $templateDir 'windows_release_x86_64.exe').Replace('\','/')
$debugTemplate=(Join-Path $templateDir 'windows_debug_x86_64.exe').Replace('\','/')
& $GodotPath --headless --path $projectRoot --editor --import --quit *> (Join-Path $outputDir 'import.log')
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath (Join-Path $outputDir 'import.log') -Pattern 'SCRIPT ERROR|Parse Error|Failed loading resource' -Quiet)){throw 'Import failed; inspect build/<role>/import.log'}
try {
    $feature=if($Role -eq 'player'){'protected_player'}else{'protected_creator'}
    $project=$originalProject.Replace('[application]', "[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"PNGRemixProtected/$Role`"")
    [IO.File]::WriteAllText($projectPath,$project)
    $presets=$originalPresets.Replace('custom_features=""', "custom_features=`"$feature`"")
    $presets=$presets.Replace('custom_template/release=""', "custom_template/release=`"$releaseTemplate`"").Replace('custom_template/debug=""', "custom_template/debug=`"$debugTemplate`"")
    $presets=$presets.Replace('exclude_filter=""', 'exclude_filter="tests/*,tools/*,docs/*,DemoModels/*.pngRemix,DemoModels/Old Demos/*.pngRemix,build/*,.superpowers/*"')
    $presets=$presets.Replace('binary_format/embed_pck=false','binary_format/embed_pck=true')
    [IO.File]::WriteAllText($presetsPath,$presets)
    $exe=Join-Path $outputDir "PNGRemix-Protected-$Role.exe"
    & $GodotPath --headless --path $projectRoot --export-release 'Windows Desktop' $exe *> (Join-Path $outputDir 'build.log')
    $buildCode=$LASTEXITCODE
    Get-Content (Join-Path $outputDir 'build.log') -Tail 15
    if($buildCode -ne 0 -or !(Test-Path -LiteralPath $exe) -or (Select-String -LiteralPath (Join-Path $outputDir 'build.log') -Pattern 'SCRIPT ERROR|Parse Error|Failed loading resource' -Quiet)) {throw "Build failed: $buildCode"}
    Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination $outputDir
    Get-ChildItem -LiteralPath (Join-Path $projectRoot 'docs/protected') -Filter '*.md' | Copy-Item -Destination $outputDir
    Get-FileHash -LiteralPath $exe -Algorithm SHA256 | Select-Object Path,Hash
} finally {
    [IO.File]::WriteAllText($projectPath,$originalProject)
    [IO.File]::WriteAllText($presetsPath,$originalPresets)
}
