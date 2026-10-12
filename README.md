# 🪙 Grana — Gestor financeiro pessoal

App **100% offline** para o público jovem, feito em **Flutter**. Roda em Android, iOS, Windows, macOS e Linux, pronto para publicar no **Google Play** e na **App Store**.

Sem backend: todos os dados ficam no aparelho do usuário. O backup é um arquivo compacto que a pessoa envia para o próprio e-mail pelo compartilhamento nativo do sistema.

---

## Funcionalidades

- **Receitas e despesas**: lançamentos com valor, categoria, data, descrição e observações.
- **Categorias**: crie, edite e personalize (nome, cor, ícone, tipo) ou use as padrão (`Salário`, `Mesada`, `Lanche`, `Rolê`, etc.).
- **Relatórios**: resumo por período (mês/30 dias/ano/tudo), gráfico de pizza por categoria, gráfico de barras dos últimos 6 meses e **exportação em CSV**.
- **Orçamentos**: limite mensal por categoria com barra de progresso e alerta de estouro.
- **Metas**: crie metas de poupança e registre contribuições.
- **Diário pessoal (agenda livre)**: escrita livre com título, humor 😄, tags e cores, busca e contagem de sequência de dias.
- **Lembretes e alarmes**: notificações com repetição diária/semanal/mensal, som customizado.
- **Personalização total**:
  - Tema claro/escuro/seguir o sistema
  - Cor principal e cor de destaque (seletor de cor)
  - Imagem de fundo própria (galeria ou câmera) com intensidade ajustável
  - Opacidade dos cards, tamanho da fonte, cards arredondados
  - Sons de toque customizados e vibração
- **Backup por e-mail**: gera um arquivo `.json`, abre o compartilhamento/e-mail do aparelho e, se quiser, lembra de fazer isso todo dia num horário escolhido. Também dá para **restaurar** de um arquivo.
- **Privacidade**: bloqueio opcional por PIN.
- **Moedas**: BRL, USD, EUR, GBP, ARS, MXN, JPY.

---

## Requisitos

- **Flutter SDK 3.32+** (Dart 3.7+) — [instalação](https://docs.flutter.dev/get-started/install)
- Android Studio / Xcode (macOS) para builds de loja
- Windows: ferramentas de build do Visual Studio para o app desktop (opcional)

## Rodando o projeto

```powershell
# 1) Gera as pastas android/ios/windows, baixa dependências e configura o Android
powershell -ExecutionPolicy Bypass -File setup.ps1

# 2) Testar no aparelho/emulador
flutter run

# 3) Rodar os testes
flutter test
```

Se o Flutter não estiver instalado, o `setup.ps1` pergunta se quer baixá-lo automaticamente (estável, Windows).

> Se preferir fazer na mão: `flutter create --org br.com.grana --project-name financas_jovem --platforms=android,ios,windows .` na pasta vazia e depois copie os arquivos deste `lib/`. Nunca rode `flutter create` numa pasta já populada sem antes fazer cópia de segurança do `lib/` e do `pubspec.yaml`.

---

## Publicação

### Google Play
```powershell
flutter build appbundle --release
# gera: build/app/outputs/bundle/release/app-release.aab
```
- Crie um projeto no **Play Console**, preencha a ficha do app e faça upload do `.aab`.
- Políticas: o app não pede permissões além das necessárias; os dados são 100% locais (sem backend), o que facilita a aprovação. Informe a declaração de privacidade "os dados ficam no dispositivo".
- Ícone: troque `android/app/src/main/res/mipmap-*` pelo seu ícone e o nome/splash em `android/app/src/main/AndroidManifest.xml`.

### App Store (precisa de macOS + Xcode)
```bash
flutter build ipa --release
```
- Crie o app no **App Store Connect** e envie o `.ipa` pelo Xcode/Transporter.
- iOS: o app usa `flutter_local_notifications`; as permissões de notificação são pedidas no onboarding.

### Desktop (Windows)
```powershell
flutter build windows --release
```

---

## Arquitetura

```
lib/
├── main.dart              # inicialização + providers
├── app.dart               # MaterialApp, tema e rota raiz
├── core
│   ├── constants.dart     # paleta, ícones, moedas
│   ├── theme/app_theme.dart
│   └── utils/             # formatação de moeda/data, id
├── data
│   ├── models/            # Transaction, Category, Budget, Goal, Reminder, AgendaEntry, AppSettings
│   ├── storage/local_database.dart   # banco JSON em arquivo (escritas atômicas)
│   └── repositories/seed_data.dart   # categorias padrão
├── services
│   ├── notification_service.dart  # lembretes/alarmes (flutter_local_notifications)
│   ├── backup_service.dart        # exportar/restaurar/importar JSON
│   ├── media_service.dart         # imagem de fundo e sons
│   └── sound_service.dart         # toques e vibração
├── state/                # controllers (Provider/ChangeNotifier)
└── screens/              # onboarding, home, extrato, relatórios, diário, metas, orçamentos, lembretes, categorias, ajustes
```

- **Persistência**: um único arquivo JSON no diretório de suporte do app, gravado de forma atômica (arquivo temporário + rename). Backup = esse mesmo arquivo embutido num envelope `.json`.
- **Estado**: `provider` com `ChangeNotifier`. Mudanças persistem na hora.
- **Notificações**: `flutter_local_notifications` + `timezone`, repetições por componentes (hora/dia da semana/dia do mês).

## Personalizar ainda mais

- Novas cores padrão: edite `kPaletteHex` em `lib/core/constants.dart`.
- Personagem/sons: o app aceita áudio arbitrário do usuário (`mp3/wav/ogg/m4a/aac`). Para um som de notificação executado com o app fechado no Android, o áudio precisa estar em `android/app/src/main/res/raw/` e ser referenciado por nome — limitação do sistema operacional, documentada aqui.