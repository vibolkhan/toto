import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/online_game_controller.dart';
import '../online/supabase_service.dart';
import 'table_screen.dart';

/// Create a room or join one by code, then wait for players. The host
/// starts the game; empty seats are filled with bots.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.playerName});

  final String playerName;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _codeField = TextEditingController();
  String? _roomId;
  String? _code;
  Map<String, dynamic>? _room;
  List<Map<String, dynamic>> _players = const [];
  final List<StreamSubscription<Object?>> _subs = [];
  bool _busy = false;
  String? _error;
  bool _enteredTable = false;

  @override
  void dispose() {
    _codeField.dispose();
    _unsubscribe();
    super.dispose();
  }

  void _unsubscribe() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on OnlineError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Connection problem: $e';
    }
    if (mounted) setState(() => _busy = false);
  }

  void _enterRoom(String roomId) {
    _roomId = roomId;
    _subs
      ..add(
        SupabaseService.room(roomId).listen((room) {
          setState(() {
            _room = room;
            _code = room?['code'] as String? ?? _code;
          });
          if (room?['status'] == 'playing') _openTable();
        }),
      )
      ..add(
        SupabaseService.players(roomId).listen((p) {
          setState(() => _players = p);
        }),
      );
  }

  void _openTable() {
    if (_enteredTable || _roomId == null) return;
    _enteredTable = true;
    final roomId = _roomId!;
    _unsubscribe();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TableScreen(
          title: 'Room ${_code ?? ''}',
          controller: OnlineGameController(roomId: roomId, code: _code ?? ''),
        ),
      ),
    );
  }

  Future<void> _create() => _run(() async {
    final id = await SupabaseService.createRoom(widget.playerName);
    _enterRoom(id);
  });

  Future<void> _join() => _run(() async {
    final code = _codeField.text.trim().toUpperCase();
    if (code.isEmpty) throw const OnlineError('Enter a room code');
    _code = code;
    final id = await SupabaseService.joinRoom(code, widget.playerName);
    _enterRoom(id);
  });

  Future<void> _leave() async {
    final id = _roomId;
    if (id != null) {
      _unsubscribe();
      SupabaseService.leaveRoom(id).ignore();
    }
    if (mounted) Navigator.of(context).pop();
  }

  bool get _isHost =>
      _room != null && _room!['host_id'] == SupabaseService.userId;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _roomId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Play with friends'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: feltGradient),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _roomId == null ? _buildChooser() : _buildRoom(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChooser() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : _create,
          icon: const Icon(Icons.add),
          label: const Text('Create a room'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('or', textAlign: TextAlign.center),
        ),
        TextField(
          controller: _codeField,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Room code',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _join(),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _join,
          icon: const Icon(Icons.login),
          label: const Text('Join room'),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _buildRoom() {
    final bySeat = {for (final p in _players) p['seat'] as int: p};
    final humans = _players.where((p) => p['is_bot'] != true).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Room code', textAlign: TextAlign.center),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SelectableText(
              _code ?? '…',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            IconButton(
              tooltip: 'Copy code',
              icon: const Icon(Icons.copy),
              onPressed: _code == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: _code!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied')),
                      );
                    },
            ),
          ],
        ),
        const Text(
          'Share this code with friends so they can join.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        for (var seat = 0; seat < 4; seat++)
          ListTile(
            leading: CircleAvatar(child: Text('${seat + 1}')),
            title: Text(
              bySeat[seat]?['display_name'] as String? ?? 'Open seat',
              style: TextStyle(
                color: bySeat[seat] == null ? Colors.grey : null,
              ),
            ),
            subtitle: bySeat[seat] == null
                ? const Text('A bot will play here')
                : bySeat[seat]!['user_id'] == _room?['host_id']
                ? const Text('Host')
                : null,
          ),
        const SizedBox(height: 12),
        if (_isHost)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() => SupabaseService.startGame(_roomId!)),
            child: Text(
              humans == 4
                  ? 'Start game'
                  : 'Start with ${4 - humans} bot${4 - humans == 1 ? '' : 's'}',
            ),
          )
        else
          const Text(
            'Waiting for the host to start…',
            textAlign: TextAlign.center,
          ),
        TextButton(onPressed: _leave, child: const Text('Leave room')),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }
}
