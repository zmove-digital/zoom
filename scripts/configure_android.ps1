#requires -Version 5.1
<#
    Ajusta o projeto Android gerado pelo Flutter para suportar
    flutter_local_notifications e local_auth (biometria):
      - desugaring (core library desugaring)
      - permissoes de notificacao / alarme / boot / biometria no AndroidManifest.xml
      - MainActivity herdando de FlutterFragmentActivity (local_auth)
      - LaunchTheme com parent AppCompat (local_auth, evita crash no Android 8-)

    Suporta tanto o Gradle Groovy (build.gradle) quanto o Kotlin DSL
    (build.gradle.kts). E idempotente: pode rodar varias vezes sem duplicar.
#>

[CmdletBinding()]
param(
    [string]$AppDir
)

$ErrorActionPreference = 'Stop'

if (-not $AppDir) {
    $AppDir = Join-Path $PSScriptRoot '..\android\app'
}

function Get-Text([string]$Path) {
    return [System.IO.File]::ReadAllText($Path)
}

function Set-Text([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Configure-Desugaring([string]$Path, [bool]$IsKts) {
    $text = Get-Text $Path
    $changed = $false

    if ($IsKts) {
        if ($text -notmatch 'isCoreLibraryDesugaringEnabled') {
            if ($text -match '(?m)^([ \t]*)compileOptions[ \t]*\{') {
                $re = [regex]'(?m)^([ \t]*)compileOptions[ \t]*\{'
                $text = $re.Replace($text, {
                        param($m)
                        $ind = $m.Groups[1].Value
                        "$($m.Value)`r`n$ind    isCoreLibraryDesugaringEnabled = true"
                    }, 1)
            } else {
                $re = [regex]'(?m)^([ \t]*)android[ \t]*\{'
                $text = $re.Replace($text, {
                        param($m)
                        $ind = $m.Groups[1].Value
                        "$($m.Value)`r`n$ind    compileOptions {`r`n$ind        isCoreLibraryDesugaringEnabled = true`r`n$ind    }"
                    }, 1)
            }
            $changed = $true
        }
        if ($text -notmatch 'coreLibraryDesugaring\s*[("]') {
            if ($text -match '(?m)^([ \t]*)dependencies[ \t]*\{') {
                $re = [regex]'(?m)^([ \t]*)dependencies[ \t]*\{'
                $text = $re.Replace($text, {
                        param($m)
                        $ind = $m.Groups[1].Value
                        "$($m.Value)`r`n$ind    coreLibraryDesugaring(`"com.android.tools:desugar_jdk_libs:2.1.4`")"
                    }, 1)
                $changed = $true
            } else {
                Write-Host "  AVISO: bloco 'dependencies { }' nao encontrado em $Path" -ForegroundColor Yellow
            }
        }
    } else {
        if ($text -notmatch 'coreLibraryDesugaringEnabled') {
            $re = [regex]'(?m)^([ \t]*)android[ \t]*\{'
            $text = $re.Replace($text, {
                    param($m)
                    $ind = $m.Groups[1].Value
                    "$($m.Value)`r`n$ind    compileOptions {`r`n$ind        coreLibraryDesugaringEnabled true`r`n$ind    }"
                }, 1)
            $changed = $true
        }
        if ($text -notmatch "coreLibraryDesugaring\s+['""]") {
            if ($text -match '(?m)^([ \t]*)dependencies[ \t]*\{') {
                $re = [regex]'(?m)^([ \t]*)dependencies[ \t]*\{'
                $text = $re.Replace($text, {
                        param($m)
                        $ind = $m.Groups[1].Value
                        "$($m.Value)`r`n$ind    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'"
                    }, 1)
                $changed = $true
            } else {
                Write-Host "  AVISO: bloco 'dependencies { }' nao encontrado em $Path" -ForegroundColor Yellow
            }
        }
    }

    if ($changed) {
        Set-Text $Path $text
        Write-Host "  atualizado (desugaring): $Path" -ForegroundColor Green
    } else {
        Write-Host "  ja configurado (desugaring): $Path" -ForegroundColor DarkGray
    }
}

function Configure-Manifest([string]$Path) {
    $text = Get-Text $Path
    $changed = $false

    # Permissoes necessarias para notificacoes/alarmes.
    $permissions = @(
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.SCHEDULE_EXACT_ALARM',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.USE_BIOMETRIC'
    )
    $missing = @()
    foreach ($p in $permissions) {
        if ($text -notmatch [regex]::Escape($p)) { $missing += $p }
    }
    if ($missing.Count -gt 0) {
        if ($text -notmatch '(?m)^[ \t]*<application') {
            Write-Host "  AVISO: tag <application> nao encontrada em $Path" -ForegroundColor Yellow
        } else {
            $block = ($missing | ForEach-Object { "    <uses-permission android:name=`"$_`"/>" }) -join "`r`n"
            $re = [regex]'(?m)^([ \t]*)<application'
            $text = $re.Replace($text, {
                    param($m)
                    "$block`r`n$($m.Value)"
                }, 1)
            $changed = $true
            Write-Host "  permissoes adicionadas: $($missing -join ', ')" -ForegroundColor Green
        }
    }

    # Receivers do flutter_local_notifications (notificacoes agendadas).
    if ($text -notmatch 'ScheduledNotificationBootReceiver') {
        if ($text -notmatch '(?m)^[ \t]*</application>') {
            Write-Host "  AVISO: tag </application> nao encontrada em $Path" -ForegroundColor Yellow
        } else {
            $receivers = @(
                '        <receiver',
                '            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"',
                '            android:exported="false" />',
                '        <receiver',
                '            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"',
                '            android:exported="false">',
                '            <intent-filter>',
                '                <action android:name="android.intent.action.BOOT_COMPLETED"/>',
                '                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>',
                '                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>',
                '                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>',
                '            </intent-filter>',
                '        </receiver>'
            ) -join "`r`n"
            $re = [regex]'(?m)^([ \t]*)</application>'
            $text = $re.Replace($text, {
                    param($m)
                    "$receivers`r`n$($m.Value)"
                }, 1)
            $changed = $true
            Write-Host "  receivers de notificacao adicionados" -ForegroundColor Green
        }
    }

    if ($changed) {
        Set-Text $Path $text
        Write-Host "  atualizado (manifesto): $Path" -ForegroundColor Green
    } else {
        Write-Host "  ja configurado (manifesto): $Path" -ForegroundColor DarkGray
    }
}

function Configure-MainActivity([string]$MainRoot) {
    $kotlinDir = Join-Path $MainRoot 'kotlin'
    if (-not (Test-Path -LiteralPath $kotlinDir)) {
        Write-Host "  AVISO: pasta 'kotlin' nao encontrada em $MainRoot" -ForegroundColor Yellow
        return
    }
    $activity = Get-ChildItem -LiteralPath $kotlinDir -Recurse -Filter 'MainActivity.kt' |
        Select-Object -First 1
    if (-not $activity) {
        Write-Host "  AVISO: MainActivity.kt nao encontrado em $kotlinDir" -ForegroundColor Yellow
        return
    }
    $text = Get-Text $activity.FullName
    if ($text -match 'FlutterFragmentActivity') {
        Write-Host "  ja configurado (MainActivity): $($activity.Name)" -ForegroundColor DarkGray
        return
    }
    $text = $text -replace 'io\.flutter\.embedding\.android\.FlutterActivity', 'io.flutter.embedding.android.FlutterFragmentActivity'
    $text = $text -replace 'FlutterActivity\(\)', 'FlutterFragmentActivity()'
    Set-Text $activity.FullName $text
    Write-Host "  atualizado (MainActivity -> FlutterFragmentActivity): $($activity.FullName)" -ForegroundColor Green
}

function Configure-LaunchTheme([string]$ResDir) {
    foreach ($variant in @('values', 'values-night')) {
        $path = Join-Path $ResDir "$variant\styles.xml"
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $text = Get-Text $path
        if ($text -match 'Theme\.AppCompat') {
            Write-Host "  ja configurado (LaunchTheme): $path" -ForegroundColor DarkGray
            continue
        }
        $re = [regex]'(<style\s+name="LaunchTheme"\s+parent=")[^"]*(")'
        if ($re.IsMatch($text)) {
            $text = $re.Replace($text, '${1}Theme.AppCompat.DayNight.NoActionBar${2}', 1)
            Set-Text $path $text
            Write-Host "  atualizado (LaunchTheme): $path" -ForegroundColor Green
        } else {
            Write-Host "  AVISO: LaunchTheme nao encontrado em $path" -ForegroundColor Yellow
        }
    }
}

$buildGradleKts = Join-Path $AppDir 'build.gradle.kts'
$buildGradleGroovy = Join-Path $AppDir 'build.gradle'
$manifest = Join-Path $AppDir 'src\main\AndroidManifest.xml'
$mainRoot = Join-Path $AppDir 'src\main'
$resDir = Join-Path $mainRoot 'res'

Write-Host "Configurando projeto Android..." -ForegroundColor Cyan

if (Test-Path -LiteralPath $buildGradleKts) {
    Configure-Desugaring -Path $buildGradleKts -IsKts $true
} elseif (Test-Path -LiteralPath $buildGradleGroovy) {
    Configure-Desugaring -Path $buildGradleGroovy -IsKts $false
} else {
    Write-Host "  AVISO: nao encontrei build.gradle nem build.gradle.kts em $AppDir" -ForegroundColor Yellow
}

if (Test-Path -LiteralPath $manifest) {
    Configure-Manifest -Path $manifest
} else {
    Write-Host "  AVISO: AndroidManifest.xml nao encontrado em $AppDir" -ForegroundColor Yellow
}

if (Test-Path -LiteralPath $mainRoot) {
    Configure-MainActivity -MainRoot $mainRoot
} else {
    Write-Host "  AVISO: pasta src\main nao encontrada em $AppDir" -ForegroundColor Yellow
}

if (Test-Path -LiteralPath $resDir) {
    Configure-LaunchTheme -ResDir $resDir
} else {
    Write-Host "  AVISO: pasta res nao encontrada em $mainRoot" -ForegroundColor Yellow
}

Write-Host "Configuracao Android concluida." -ForegroundColor Green
