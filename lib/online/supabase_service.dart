import 'package:supabase_flutter/supabase_flutter.dart';

import '../engine/card.dart';

class OnlineError implements Exception {
  const OnlineError(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper around Supabase: anonymous auth, the `tienlen` Edge
/// Function, and realtime streams of the tables players may read.
class SupabaseService {
  SupabaseService._();

  // Defaults target the hosted project; override with --dart-define (e.g.
  // for a local `supabase start` stack). The publishable key is safe to ship
  // in the client — access is governed by RLS.
  static const _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ghdnquahenigsbrachda.supabase.co',
  );
  static const _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_epFvVEs89OFQT1NGUuy9uQ_kRrLqWLc',
  );

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    // Either the legacy anon key or the newer publishable key works here.
    await Supabase.initialize(url: _url, publishableKey: _anonKey);
  }

  static SupabaseClient get _client => Supabase.instance.client;

  static String? get userId => _client.auth.currentUser?.id;

  static Future<String> ensureSignedIn() async {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;
    final res = await _client.auth.signInAnonymously();
    return res.user!.id;
  }

  static Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, dynamic> params = const {},
  ]) async {
    await ensureSignedIn();
    try {
      final res = await _client.functions.invoke(
        'tienlen',
        body: {'action': action, ...params},
      );
      return (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] is String
          ? details['error'] as String
          : 'Server error (${e.status})';
      throw OnlineError(message);
    }
  }

  /// Returns the new room's id.
  static Future<String> createRoom(String name) async =>
      (await _call('create', {'name': name}))['roomId'] as String;

  /// Returns the joined room's id.
  static Future<String> joinRoom(String code, String name) async =>
      (await _call('join', {'code': code, 'name': name}))['roomId'] as String;

  static Future<void> leaveRoom(String roomId) =>
      _call('leave', {'roomId': roomId});

  static Future<void> startGame(String roomId) =>
      _call('start', {'roomId': roomId});

  static Future<void> play(String roomId, List<PlayingCard> cards) =>
      _call('play', {
        'roomId': roomId,
        'cards': [for (final c in cards) c.value],
      });

  static Future<void> pass(String roomId) => _call('pass', {'roomId': roomId});

  static Future<void> nextGame(String roomId) =>
      _call('next', {'roomId': roomId});

  static Stream<Map<String, dynamic>?> room(String roomId) => _client
      .from('rooms')
      .stream(primaryKey: ['id'])
      .eq('id', roomId)
      .map((rows) => rows.isEmpty ? null : rows.first);

  static Stream<List<Map<String, dynamic>>> players(String roomId) => _client
      .from('room_players')
      .stream(primaryKey: ['room_id', 'seat'])
      .eq('room_id', roomId)
      .order('seat', ascending: true);

  static Stream<Map<String, dynamic>?> game(String roomId) => _client
      .from('games')
      .stream(primaryKey: ['room_id'])
      .eq('room_id', roomId)
      .map((rows) => rows.isEmpty ? null : rows.first);

  /// RLS only returns the caller's own hand.
  static Stream<List<Map<String, dynamic>>> myHands(String roomId) => _client
      .from('hands')
      .stream(primaryKey: ['room_id', 'seat'])
      .eq('room_id', roomId);
}
