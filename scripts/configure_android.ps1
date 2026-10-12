# Ajusta o projeto Android gerado pelo Flutter para suportar
# flutter_local_notifications (desugaring) e as permissoes de notificacao/alarme.

$ErrorActionPreference = "Stop"

function Replace-InFile {
    param(
        [string]$Path,
        [string]$Find,
        [string]$ReplaceWith,
        [bool]$InsertBefore = $false
    )
    $original = [System.IO.File]::ReadAllText($Path)
    if ($original.Contains($Find)) {
        Write-Host "  ja configurado: $Find" -ForegroundColor DarkGray
        return
    }
    $updated = $original
    if ($InsertBefore) {
        $updated = $updated.Replace($Find, "$ReplaceWith`r`n$Find")
    } else {
        $updated = $updated.Replace($Find, "$Find`r`n$ReplaceWith")
    }
    [System.IO.File]::WriteAllText($Path, $updated, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  atualizado: $Path" -ForegroundColor Green
}

$appDir = Join-Path $PSScriptRoot "..\android\app"
$buildGradle = Join-Path $appDir "build.gradle"
$manifest = Join-Path $appDir "src\main\AndroidManifest.xml"

if (-not (Test-Path $buildGradle)) {
    Write-Host "AVISO: não encontrei $buildGradle. Se o Flutter gerou build.gradle.kts, adicione manualmente: compileOptions { coreLibraryDesugaringEnabled true } e coreLibraryDesugaring no dependencies." -ForegroundColor Yellow
} else {
    # Ativa desugaring dentro de android { }
    Replace-InFile -Path $buildGradle -Find "android {" `
        -ReplaceWith "    compileOptions {
        coreLibraryDesugaringEnabled true
    }" -InsertBefore $true

    # Adiciona a dependencia do desugar_jdk_libs
    Replace-InFile -Path $buildGradle -Find "dependencies {" `
        -ReplaceWith "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.2'"
}

if (Test-Path $manifest) {
    Replace-InFile -Path $manifest -Find "<application" `
        -ReplaceWith @"
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
"@ -InsertBefore $true
    Write-Host "Permissoes de notificacao adicionadas ao AndroidManifest.xml" -ForegroundColor Green
} else {
    Write-Host "AVISO: manifest nao encontrado." -ForegroundColor Yellow
}

Write-Host "Configuracao Android concluida." -ForegroundColor Green