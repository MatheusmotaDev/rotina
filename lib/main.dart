import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/rotina_app.dart';
import 'core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseEnabled = await AppBootstrap.initialize();
  runApp(ProviderScope(child: RotinaApp(supabaseEnabled: supabaseEnabled)));
}
