import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/rotina_app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'features/notifications/data/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseEnabled = await AppBootstrap.initialize();
  await LocalNotificationService.instance.initialize();
  runApp(ProviderScope(child: RotinaApp(supabaseEnabled: supabaseEnabled)));
}
