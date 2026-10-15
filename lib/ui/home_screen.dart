import 'package:flutter/material.dart';

import '../game/local_game_controller.dart';
import '../online/supabase_service.dart';
import 'lobby_screen.dart';
import 'table_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _name = TextEditingController(text: 'Player');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _playerName =>
      _name.text.trim().isEmpty ? 'Player' : _name.text.trim();

  void _playWithBots() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TableScreen(
          title: 'Vs Bots',
          controller: LocalGameController(playerName: _playerName),
        ),
      ),
    );
  }

  void _playWithFriends() {
    if (!SupabaseService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Online play is not configured. Run with '
            '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LobbyScreen(playerName: _playerName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: feltGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '♠ ♥ ♣ ♦',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 28),
                    ),
                    const Text(
                      'Tiến Lên',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _name,
                      maxLength: 16,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        labelStyle: TextStyle(color: Colors.white70),
                        counterStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFC107)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _playWithBots,
                      icon: const Icon(Icons.smart_toy),
                      label: const Text('Play with bots'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _playWithFriends,
                      icon: const Icon(Icons.group),
                      label: const Text('Play with friends'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
