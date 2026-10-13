#requires -Version 5.1
<#
    Troca a senha do keystore de upload do ZOOM e atualiza o android/key.properties.

    Uso:
        powershell -ExecutionPolicy Bypass -File .\trocar-senha-keystore.ps1

    Depois de trocar, gere o pacote normalmente:
        flutter build appbundle --release
#>
[CmdletBinding()]
param(
    [string]$KeystorePath = (Join-Path $PSScriptRoot 'android\app\upload-keystore.jks'),
    [string]$PropertiesPath = (Join-Path $PSScriptRoot 'android\key.properties'),
    [string]$Alias = 'upload'
)

$ErrorActionPreference = 'Stop'

function Get-Keytool {
    $candidates = @()
    if ($env:JAVA_HOME) { $candidates += (Join-Path $env:JAVA_HOME 'bin\keytool.exe') }
    $candidates += 'Z:\dev\jdk21\bin\keytool.exe'
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    $cmd = Get-Command keytool.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'keytool.exe nao encontrado. Defina a variavel JAVA_HOME ou instale um JDK.'
}

function Read-Plain([string]$Prompt) {
    $sec = Read-Host $Prompt -AsSecureString
    return [System.Net.NetworkCredential]::new('', $sec).Password
}

if (-not (Test-Path -LiteralPath $KeystorePath)) {
    throw "Keystore nao encontrado: $KeystorePath"
}

$keytool = Get-Keytool
Write-Host "Keystore: $KeystorePath" -ForegroundColor Cyan

$current = Read-Plain 'Senha ATUAL do keystore'
$new1 = Read-Plain 'Nova senha'
$new2 = Read-Plain 'Repita a nova senha'

if ($new1 -ne $new2) { throw 'As senhas novas nao coincidem.' }
if ([string]::IsNullOrWhiteSpace($new1)) { throw 'A nova senha nao pode ser vazia.' }

& $keytool -storepasswd -keystore $KeystorePath -storepass $current -new $new1
if ($LASTEXITCODE -ne 0) { throw 'Falha ao trocar a senha (senha atual incorreta?).' }

& $keytool -list -keystore $KeystorePath -storepass $new1 -alias $Alias | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'A nova senha nao foi validada no keystore.' }

$storeFile = [System.IO.Path]::GetFileName($KeystorePath)
$content = "storePassword=$new1`nkeyPassword=$new1`nkeyAlias=$Alias`nstoreFile=$storeFile`n"
Set-Content -LiteralPath $PropertiesPath -Value $content -Encoding ASCII -NoNewline

Write-Host ''
Write-Host 'OK! Senha do keystore trocada e key.properties atualizado.' -ForegroundColor Green
Write-Host 'Agora rode:  flutter build appbundle --release' -ForegroundColor Green
