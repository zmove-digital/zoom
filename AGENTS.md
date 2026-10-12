# AGENTS.md — ZOOM

App Flutter **ZOOM** (ex-Grana): gestor financeiro pessoal, 100% offline e
personalizavel. Package Dart `zoom`, Android `applicationId`/namespace
`br.com.zmove.zoom`, iOS bundle `br.com.zmove.zoom`. Fonte **Poppins**.

- **Local:** `Z:\dev\projects\ZOOM` (unidade Z / SSD "DEV").
- **GitHub:** `zmove-digital/zoom` (SSH `C:\Users\Rezende\.ssh\id_ed25519`).
- **Dev/CI:** rodar sempre com `workdir` explicito.

## Toolchain (unidade Z)
- JDK 21 (`Z:\dev\jdk21`), Flutter 3.47.7 / Dart 3.13.5 (`Z:\dev\flutter`).
- Android SDK `Z:\dev\android-sdk` (android-36, build-tools 36.0.0, ndk 27, cmake 3.22.1, emulator).
- Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20; `GRADLE_USER_HOME=Z:\dev\gradle-home`.
- `PUB_CACHE=Z:\dev\pub-cache`; `ANDROID_AVD_HOME=Z:\dev\avd`.

## Comandos
- Rodar app (sobe o emulador e encaixa a janela a direita):
  `.\dev.ps1`  (aceita flags do `flutter run`, ex.: `.\dev.ps1 --release`, `-d windows`).
- Analise: `flutter analyze`
- Testes: `flutter test`  (8 testes)
- APK debug: `flutter build apk --debug`
- AAB release: `flutter build appbundle --release`

## Emulador
- AVD `Pixel_8` (emulator-5554), 1080x2400 @ density 420.
- **Boot so funciona com** `-gpu swiftshader_indirect`.
- Tela do laptop 1536x864 (area util 1536x816); `dev.ps1` usa `-scale 0.32` e
  reposiciona a janela via Win32 `MoveWindow` para a direita da tela.

## Regras
- Nao fazer `git commit`/`push` sem confirmacao do usuario.
- Ao renomear/mexer em arquivos dentro do projeto, **nao misturar com outros
  projetos**; se a ordem nao disser qual projeto, perguntar.
- Se um build travar na renomeacao/pastas, verificar daemons Java do Gradle.
