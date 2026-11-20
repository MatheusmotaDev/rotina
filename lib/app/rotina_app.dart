import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/views/auth_gate.dart';
import '../features/shell/presentation/views/app_shell.dart';

class RotinaApp extends StatelessWidget {
  const RotinaApp({this.supabaseEnabled = false, super.key});

  final bool supabaseEnabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rotina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: supabaseEnabled ? const AuthGate() : const AppShell(),
    );
  }
}
