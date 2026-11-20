import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabasePublishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';

  static const defaultTimezone = 'America/Sao_Paulo';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
