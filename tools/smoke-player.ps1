param()
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$dir=Join-Path $root 'build/player'
$log=Join-Path $dir 'smoke.log'
$out=Join-Path $dir 'smoke-stdout.log'
$err=Join-Path $dir 'smoke-stderr.log'
$model=Join-Path $root 'tests/protected/out/测试 protected.pngRemixProtected'
Add-Type @"
using System; using System.Runtime.InteropServices; public class ProtectedSmokeWindow { public delegate bool CB(IntPtr h, IntPtr l); [DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l); [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p); [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l); public static void Close(uint target){EnumWindows((h,l)=>{uint p;GetWindowThreadProcessId(h,out p);if(p==target)PostMessage(h,0x10,IntPtr.Zero,IntPtr.Zero);return true;},IntPtr.Zero);} }
"@
$p=Start-Process -FilePath (Join-Path $dir 'PNGRemix-Protected-player.exe') -WorkingDirectory $dir -ArgumentList @('--verbose','--rendering-method','gl_compatibility','--rendering-driver','opengl3','--log-file',('"'+$log+'"'),'--',('"model='+$model+'"')) -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
$loaded=$false
try {
 for($i=0;$i -lt 40;$i++) {
  Start-Sleep -Milliseconds 500
  if((Test-Path $out) -and (Select-String -LiteralPath $out -SimpleMatch -Pattern 'Protected model loaded successfully' -Quiet)){$loaded=$true;break}
  if($p.HasExited){break}
 }
 if(!$loaded){throw 'Packaged model load failed; inspect smoke logs'}
 [ProtectedSmokeWindow]::Close([uint32]$p.Id)
 if(!$p.WaitForExit(10000)){throw 'Normal window close timed out'}
 if(Select-String -LiteralPath $out,$err -Pattern 'SCRIPT ERROR|Parse Error|Failed loading|CrashHandlerException' -Quiet){throw 'Runtime error; inspect smoke logs'}
 Write-Output "PACKAGED PLAYER LOAD AND WINDOW CLOSE PASSED (exit $($p.ExitCode))"
} finally {if(!$p.HasExited){Stop-Process -Id $p.Id}}
