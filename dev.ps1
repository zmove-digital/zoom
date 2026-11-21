param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

# Raiz das ferramentas: <unidade>:\dev (o projeto fica em <unidade>:\dev\projects\ZOOM).
# Assim funciona tanto no SSD Z: quanto no disco D:.
$DevRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$env:JAVA_HOME        = Join-Path $DevRoot 'jdk21'
$env:ANDROID_HOME     = Join-Path $DevRoot 'android-sdk'
$env:ANDROID_SDK_ROOT = Join-Path $DevRoot 'android-sdk'
$env:GRADLE_USER_HOME = Join-Path $DevRoot 'gradle-home'
$env:PUB_CACHE        = Join-Path $DevRoot 'pub-cache'
$env:ANDROID_AVD_HOME = Join-Path $DevRoot 'avd'

$extra = @(
  (Join-Path $DevRoot 'flutter\bin'),
  (Join-Path $DevRoot 'jdk21\bin'),
  (Join-Path $DevRoot 'git\cmd'),
  (Join-Path $DevRoot 'android-sdk\platform-tools'),
  (Join-Path $DevRoot 'android-sdk\emulator')
)
foreach ($p in $extra) {
  if (($env:Path -split ';') -notcontains $p) { $env:Path = "$p;$env:Path" }
}

if (-not ('ZoomWin' -as [type])) {
  Add-Type @"
using System;
using System.Runtime.InteropServices;
public class ZoomWin {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out ZoomRect r);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int t, bool repaint);
  [StructLayout(LayoutKind.Sequential)] public struct ZoomRect { public int L, T, Rt, B; }
}
"@
}
Add-Type -AssemblyName System.Windows.Forms

function Fit-EmulatorWindow {
  $proc = $null
  for ($i = 0; $i -lt 20; $i++) {
    $proc = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match 'Android Emulator' } | Select-Object -First 1
    if ($proc) { break }
    Start-Sleep -Milliseconds 500
  }
  if (-not $proc) { return }
  $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
  $r = New-Object ZoomWin+ZoomRect
  [void][ZoomWin]::GetWindowRect($proc.MainWindowHandle, [ref]$r)
  $w = $r.Rt - $r.L
  $h = $r.B - $r.T
  if ($w -le 0 -or $h -le 0) { return }
  $f = [Math]::Min(($wa.Width - 40) / $w, ($wa.Height - 40) / $h)
  if ($f -gt 1) { $f = 1 }
  $nw = [int]($w * $f)
  $nh = [int]($h * $f)
  [void][ZoomWin]::MoveWindow($proc.MainWindowHandle, $wa.Right - $nw - 20, 20, $nw, $nh, $true)
}

$adb = Join-Path $DevRoot 'android-sdk\platform-tools\adb.exe'
$emu = Join-Path $DevRoot 'android-sdk\emulator\emulator.exe'
$avd = 'Pixel_8'

$targetGiven = @($FlutterArgs) | Where-Object { $_ -in @('-d', '--device-id') }
if (-not $targetGiven) {
  $running = & $adb devices | Select-String 'emulator-\d+\s+device'
  if (-not $running) {
    Write-Host "Ligando emulador $avd ..." -ForegroundColor Cyan
    Start-Process -FilePath $emu -ArgumentList '-avd', $avd, '-gpu', 'swiftshader_indirect', '-scale', '0.32'
    Write-Host "Aguardando boot (~1 min)..." -ForegroundColor Cyan
    & $adb wait-for-device
    $waited = 0
    while (((& $adb shell getprop sys.boot_completed) -join '').Trim() -ne '1') {
      Start-Sleep -Seconds 3
      $waited += 3
      if ($waited -ge 240) { Write-Host 'Timeout no boot; seguindo mesmo assim.' -ForegroundColor Yellow; break }
    }
  } else {
    Write-Host 'Emulador ja conectado.' -ForegroundColor Green
  }
  Fit-EmulatorWindow
}

Write-Host ('flutter run ' + ($FlutterArgs -join ' ')) -ForegroundColor Cyan
flutter run @FlutterArgs
