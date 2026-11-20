import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<Session?> get sessionChanges async* {
    yield currentSession;
    yield* _client.auth.onAuthStateChange.map((event) => event.session);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await _ensureProfile(response.user);
    return response;
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nome': cleanName},
    );

    if (response.session != null) {
      await _ensureProfile(response.user, name: cleanName);
    }
    return response;
  }

  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> _ensureProfile(User? user, {String? name}) async {
    if (user == null || currentSession == null) return;

    final metadataName = user.userMetadata?['nome'] as String?;
    await _client
        .from('perfis')
        .upsert(
          {
            'id': user.id,
            'nome': name ?? metadataName,
            'fuso_horario': AppConfig.defaultTimezone,
          },
          onConflict: 'id',
          ignoreDuplicates: true,
        );
  }
}
