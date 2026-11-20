import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

abstract final class AppBootstrap {
  static Future<bool> initialize() async {
    await dotenv.load();

    if (!AppConfig.isSupabaseConfigured) return false;

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );

    return true;
  }
}
