import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../state/settings_controller.dart';
import '../shell/app_shell.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _controller = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _error = false;
  bool _deviceAuthAvailable = false;
  bool _authenticating = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (context.read<SettingsController>().pinLocked) {
      _startTicker();
    }
    _checkDeviceAuth();
  }

  Future<void> _checkDeviceAuth() async {
    bool available = false;
    try {
      available = await _auth.isDeviceSupported();
    } on LocalAuthException {
      available = false;
    }
    if (mounted) setState(() => _deviceAuthAvailable = available);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!context.read<SettingsController>().pinLocked) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
  }

  String _formatRemaining(Duration d) {
    final int minutes = d.inMinutes;
    final int seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _tryUnlock() {
    final SettingsController settings = context.read<SettingsController>();
    if (settings.pinLocked) return;

    if (_controller.text == settings.settings.pin) {
      settings.clearPinAttempts();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
      );
    } else {
      settings.registerFailedPinAttempt();
      setState(() => _error = true);
      _controller.clear();
      if (settings.pinLocked) {
        _startTicker();
      }
    }
  }

  Future<void> _unlockWithDevice() async {
    if (_authenticating) return;
    final SettingsController settings = context.read<SettingsController>();
    _authenticating = true;
    bool ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: 'Desbloqueie o ${AppInfo.appName}',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      ok = false;
    } finally {
      _authenticating = false;
    }
    if (!mounted) return;
    if (ok) {
      settings.clearPinAttempts();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível desbloquear com o aparelho')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();
    final bool locked = settings.pinLocked;
    final int remaining =
        SecurityRules.maxPinAttempts - settings.settings.pinAttempts;

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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(locked ? Icons.lock_clock : Icons.lock_outline,
                      size: 64, color: theme.colorScheme.onPrimary),
                  const SizedBox(height: 20),
                  Text(
                    locked ? 'Bloqueado temporariamente' : 'Digite seu PIN',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (locked) ...<Widget>[
                    Text(
                      'Muitas tentativas erradas.\nTente novamente em '
                      '${_formatRemaining(settings.pinLockRemaining)}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ] else ...<Widget>[
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: SecurityRules.pinLength,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, letterSpacing: 12),
                      decoration: InputDecoration(
                        counterText: '',
                        errorText: _error
                            ? 'PIN incorreto • $remaining tentativa(s)'
                            : null,
                      ),
                      onSubmitted: (_) => _tryUnlock(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _tryUnlock,
                        child: const Text('Desbloquear'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_deviceAuthAvailable)
                    TextButton.icon(
                      onPressed: _unlockWithDevice,
                      icon: Icon(Icons.fingerprint,
                          color: theme.colorScheme.onPrimary),
                      label: Text(
                        'Usar biometria ou senha do aparelho',
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
