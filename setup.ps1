# Configura o projeto Grana no seu computador.
# Uso:  powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "=== Setup do projeto Grana ===" -ForegroundColor Cyan

# 1) Verifica o Flutter
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "Flutter SDK nao encontrado no PATH." -ForegroundColor Yellow
    $auto = Read-Host "Deseja baixar e instalar o Flutter automaticamente? (s/N)"
    if ($auto -match "^s") {
        $zip = "$env:TEMP\flutter_stable.zip"
        $dest = "$env:USERPROFILE\flutter"
        Write-Host "Baixando Flutter stable..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.32.3-stable.zip" -OutFile $zip
        Write-Host "Extraindo para $dest ..." -ForegroundColor Cyan
        if (-not (Test-Path $dest)) { Expand-Archive -Path $zip -DestinationPath $env:USERPROFILE -Force }
        Remove-Item $zip -Force
        $env:Path = "$dest\bin;$env:Path"
        [Environment]::SetEnvironmentVariable("Path", "$dest\bin;$([Environment]::GetEnvironmentVariable('Path','User'))", "User")
        Write-Host "Flutter instalado em $dest. Abra um novo terminal ou use: set PATH=$dest\bin;%PATH%" -ForegroundColor Green
    } else {
        Write-Host "Instale o Flutter primeiro (https://docs.flutter.dev/get-started/install/windows) e rode este script novamente." -ForegroundColor Red
        exit 1
    }
}

flutter --version

# 2) Gera as pastas de plataforma sem tocar no lib/ e pubspec.yaml
Write-Host "Gerando pastas de plataforma (android, ios, windows)..." -ForegroundColor Cyan
$tmp = Join-Path $env:TEMP "grana_platforms_$([guid]::NewGuid().ToString('N'))"
flutter create --org br.com.grana --project-name financas_jovem --platforms=android,ios,windows $tmp

foreach ($p in @("android", "ios", "windows")) {
    if (Test-Path ".\$p") {
        Write-Host "Pasta $p ja existe; mesclando arquivos de plataforma." -ForegroundColor Yellow
        $src = Join-Path $tmp $p
        Copy-Item "$src\*" -Destination ".\$p" -Recurse -Force
    } else {
        Copy-Item (Join-Path $tmp $p) -Destination ".\$p" -Recurse
    }
}
Remove-Item $tmp -Recurse -Force

# 3) Instala dependencias
Write-Host "Instalando dependencias (flutter pub get)..." -ForegroundColor Cyan
flutter pub get

# 4) Configura Android (para notificacoes)
Write-Host "Configurando Android (desugaring e permissoes)..." -ForegroundColor Cyan
& "$PSScriptRoot\scripts\configure_android.ps1"

# 5) Analise estatica
Write-Host "Rodando flutter analyze..." -ForegroundColor Cyan
flutter analyze

Write-Host ""
Write-Host "Pronto! Para rodar:" -ForegroundColor Green
Write-Host "  flutter run              (escolha o dispositivo)"
Write-Host "  flutter test             (rodar os testes)"
Write-Host "  flutter build apk        (Android)"
Write-Host "  flutter build appbundle  (Play Store)"
Write-Host "  flutter build ios        (App Store, no macOS)"