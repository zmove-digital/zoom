import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../services/notification_service.dart';
import '../../state/settings_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  int _page = 0;
  String _currency = 'BRL';

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final SettingsController settings = context.read<SettingsController>();
    final NotificationService notifications =
        context.read<NotificationService>();
    await notifications.requestPermissions();
    if (!mounted) return;
    settings.completeOnboarding(
      name: _name.text,
      currencyCode: _currency,
      backupEmail: _email.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              theme.colorScheme.primary,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (int i) => setState(() => _page = i),
                  children: <Widget>[
                    _welcome(theme),
                    _profile(theme),
                    _backup(theme),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(_page == 2 ? 'Começar' : 'Continuar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcome(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings_rounded,
              size: 72,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Bem-vindo ao ${AppInfo.appName}',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppInfo.tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Controle suas receitas e despesas, organize categorias, veja relatórios, escreva na sua agenda pessoal e deixe tudo com a sua cara. Tudo offline, no seu aparelho.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profile(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 24),
          Text(
            'Como podemos te chamar?',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),
          Text('Moeda', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.attach_money),
            ),
            items: kCurrencyOptions
                .map(
                  (String c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text('$c (${kCurrencySymbols[c]})'),
                  ),
                )
                .toList(),
            onChanged: (String? v) => setState(() => _currency = v ?? 'BRL'),
          ),
        ],
      ),
    );
  }

  Widget _backup(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 24),
          Text(
            'Backup dos seus dados',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'Seus dados ficam só no seu aparelho. Para não perdê-los, você pode gerar um arquivo de backup e enviar para o seu e-mail quando quiser.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail para backup (opcional)',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vamos pedir permissão para enviar lembretes e alarmes. Você pode mudar isso depois nas configurações.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
