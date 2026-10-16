import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../engine/combo.dart';
import '../engine/rules.dart';
import 'game_controller.dart';

/// Sound effects. Files live in assets/sounds/ (Kenney.nl packs, CC0).
enum Sfx { deal, play, combo, pass, bomb, out, win, lose, turn, error }

/// The sounds to play when the table changes from [prev] to [next].
/// Works from views alone, so bot games and online games sound the same.
List<Sfx> soundsFor(TableView? prev, TableView next) {
  final sounds = <Sfx>[];
  final newGame = prev == null || prev.gameNo != next.gameNo;
  if (newGame) sounds.add(Sfx.deal);

  final last = next.lastAction;
  if (!newGame && last != null && _actionKey(prev) != _actionKey(next)) {
    if (last.passed) {
      sounds.add(Sfx.pass);
    } else {
      final combo = Combo.detect(last.cards);
      final beaten = Combo.detect(prev.trickCards);
      if (combo != null && beaten != null && chopPoints(beaten, combo) > 0) {
        sounds.add(Sfx.bomb);
      } else {
        sounds.add(last.cards.length > 1 ? Sfx.combo : Sfx.play);
      }
    }
  }

  if (next.isOver && (newGame || !prev.isOver)) {
    sounds.add(next.winner == next.mySeat ? Sfx.win : Sfx.lose);
  } else if (!newGame && next.finished.length > prev.finished.length) {
    sounds.add(Sfx.out);
  }

  if (!newGame && next.isMyTurn && !prev.isMyTurn) sounds.add(Sfx.turn);
  return sounds;
}

/// Changes whenever someone plays or passes, even if the same seat repeats.
String? _actionKey(TableView v) {
  final a = v.lastAction;
  if (a == null) return null;
  final cardsLeft = v.handCounts.fold(0, (sum, n) => sum + n);
  return '${a.seat}|${a.passed}|${a.cards.map((c) => c.value)}'
      '|$cardsLeft|${v.passed.length}';
}

/// Plays [Sfx] for a table, following its controller.
class GameSounds {
  GameSounds({Random? random}) : _random = random ?? Random();

  /// Shared across tables so the mute choice sticks for the app session.
  static final muted = ValueNotifier(false);

  static const _variants = {Sfx.play: 4, Sfx.combo: 4};

  final Random _random;

  // A few players so overlapping sounds don't cut each other off. Created
  // on first use; null once audio has failed, which silences the table.
  List<AudioPlayer>? _players;
  var _broken = false;
  var _next = 0;
  TableView? _lastView;
  String? _lastError;

  /// Call whenever the controller notifies.
  void update(GameController c) {
    final view = c.view;
    if (view != null) {
      for (final sfx in soundsFor(_lastView, view)) {
        _play(sfx);
      }
      _lastView = view;
    }
    if (c.error != null && c.error != _lastError) _play(Sfx.error);
    _lastError = c.error;
  }

  /// AudioPlayer sets itself up in the background and reports a failure
  /// (e.g. the plugin missing after a hot restart) as an uncaught error, so
  /// create the players in a zone that catches it and turns sound off.
  List<AudioPlayer>? _ensurePlayers() {
    if (_broken) return null;
    return _players ??= runZonedGuarded(
      () => [for (var i = 0; i < 4; i++) AudioPlayer()],
      (e, _) {
        if (_broken) return;
        _broken = true;
        debugPrint('Sound disabled: $e');
      },
    );
  }

  void _play(Sfx sfx) {
    if (muted.value) return;
    final players = _ensurePlayers();
    if (players == null) return;
    final variants = _variants[sfx];
    final name = variants == null
        ? sfx.name
        : '${sfx.name}_${_random.nextInt(variants) + 1}';
    final player = players[_next];
    _next = (_next + 1) % players.length;
    // Sound is decoration: never let a playback failure (e.g. a browser
    // blocking autoplay) reach the game.
    player
        .stop()
        .then((_) => player.play(AssetSource('sounds/$name.m4a')))
        .catchError((Object e) {
          if (!_broken) debugPrint('Sound $name failed: $e');
        });
  }

  void dispose() {
    for (final p in _players ?? const <AudioPlayer>[]) {
      p.dispose().ignore();
    }
  }
}
