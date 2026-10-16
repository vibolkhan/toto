import 'package:flutter/material.dart';

import '../engine/card.dart';
import '../game/game_controller.dart';
import '../game/game_sounds.dart';
import 'widgets/card_widget.dart';
import 'widgets/hand_view.dart';
import 'widgets/opponent_seat.dart';

const feltGradient = RadialGradient(
  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20), Color(0xFF0D3B12)],
  radius: 1.1,
);

class TableScreen extends StatefulWidget {
  const TableScreen({super.key, required this.controller, this.title});

  final GameController controller;
  final String? title;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final Set<PlayingCard> _selected = {};
  final _sounds = GameSounds();

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onControllerChanged);
    _onControllerChanged();
  }

  void _onControllerChanged() => _sounds.update(_c);

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    _sounds.dispose();
    _c.dispose();
    super.dispose();
  }

  void _toggle(PlayingCard card) {
    setState(() {
      if (!_selected.remove(card)) _selected.add(card);
    });
  }

  Future<void> _play() async {
    final cards = _selected.toList();
    await _c.play(cards);
    if (_c.error == null) setState(_selected.clear);
  }

  Future<void> _confirmLeave() async {
    final warning = _c.leaveWarning;
    final isOver = _c.view?.isOver ?? false;
    if (warning != null && !isOver) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(warning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    _c.leave().ignore();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: feltGradient),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _c,
            builder: (context, _) {
              final v = _c.view;
              if (v == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              _selected.removeWhere((card) => !v.myHand.contains(card));
              return Stack(
                children: [
                  _buildTable(context, v),
                  if (v.isOver) _ResultsPanel(view: v, controller: _c),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, TableView v) {
    int seatAt(int offset) => (v.mySeat + offset) % 4;
    Widget plate(int seat) => SeatPlate(
      name: v.seatNames[seat],
      cardCount: v.handCounts[seat],
      isTurn: !v.isOver && v.turn == seat,
      isBot: v.isBot[seat],
      passed: v.passed.contains(seat),
      place: v.placeOf(seat),
      score: v.scores[seat],
    );

    final hint =
        _c.error ??
        (v.isMyTurn
            ? (_selected.isEmpty
                  ? (v.mustPlayThreeOfSpades
                        ? 'Your lead — include 3♠'
                        : v.isLeading
                        ? 'Your lead'
                        : 'Your turn — beat it or pass')
                  : v.validateSelection(_selected.toList()))
            : null);
    final canPlay =
        v.isMyTurn &&
        !_c.busy &&
        _selected.isNotEmpty &&
        v.validateSelection(_selected.toList()) == null;
    final canPass = v.isMyTurn && !_c.busy && !v.isLeading;

    return Column(
      children: [
        _TopBar(title: widget.title ?? 'Tiến Lên', gameNo: v.gameNo),
        Expanded(
          child: Stack(
            children: [
              // Play is clockwise: the next seat sits on my left.
              Align(alignment: Alignment.topCenter, child: plate(seatAt(2))),
              Align(
                alignment: const Alignment(-1, -0.2),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: plate(seatAt(1)),
                ),
              ),
              Align(
                alignment: const Alignment(1, -0.2),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: plate(seatAt(3)),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.15),
                child: _TrickArea(view: v),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            hint ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _c.error != null ? const Color(0xFFFFAB91) : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SeatPlate(
                name: v.seatNames[v.mySeat],
                cardCount: v.handCounts[v.mySeat],
                isTurn: v.isMyTurn,
                isBot: false,
                passed: v.passed.contains(v.mySeat),
                place: v.placeOf(v.mySeat),
                score: v.scores[v.mySeat],
                showBacks: false,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: canPass ? _c.pass : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('Pass'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: canPlay ? _play : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Play'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: HandView(
            cards: v.myHand,
            selected: _selected,
            onToggle: _toggle,
            enabled: !v.isOver,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.gameNo});

  final String title;
  final int gameNo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text('Game $gameNo', style: const TextStyle(color: Colors.white70)),
          ValueListenableBuilder(
            valueListenable: GameSounds.muted,
            builder: (context, muted, _) => IconButton(
              tooltip: muted ? 'Sound off' : 'Sound on',
              icon: Icon(
                muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white70,
              ),
              onPressed: () => GameSounds.muted.value = !muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrickArea extends StatelessWidget {
  const _TrickArea({required this.view});

  final TableView view;

  @override
  Widget build(BuildContext context) {
    final v = view;
    final last = v.lastAction;
    final String caption;
    if (v.isLeading) {
      caption = v.isOver
          ? ''
          : v.isMyTurn
          ? 'You lead'
          : '${v.seatNames[v.turn]} leads';
    } else {
      caption = v.trickOwner == v.mySeat
          ? 'You played'
          : '${v.seatNames[v.trickOwner!]} played';
    }
    final passNote = last != null && last.passed
        ? '${last.seat == v.mySeat ? 'You' : v.seatNames[last.seat]} passed'
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.0).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: SizedBox(
            key: ValueKey(v.trickCards.map((c) => c.value).join(',')),
            height: 80,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final card in v.trickCards)
                  Align(
                    widthFactor: 0.7,
                    child: CardWidget(card: card, width: 52),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        if (passNote != null)
          Text(
            passNote,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
      ],
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.view, required this.controller});

  final TableView view;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final seats = List.generate(4, (i) => i)
      ..sort((a, b) => (view.placeOf(a) ?? 9).compareTo(view.placeOf(b) ?? 9));
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  view.winner == view.mySeat ? 'You win!' : 'Game over',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (view.instantWinLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Instant win: ${view.instantWinLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 12),
                for (final seat in seats)
                  ListTile(
                    dense: true,
                    leading: Text(
                      ordinal(view.placeOf(seat) ?? 4),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    title: Text(
                      seat == view.mySeat
                          ? '${view.seatNames[seat]} (you)'
                          : view.seatNames[seat],
                    ),
                    trailing: _PointsText(
                      points: view.gamePoints[seat],
                      total: view.scores[seat],
                    ),
                  ),
                const SizedBox(height: 12),
                if (controller.canStartNextGame)
                  FilledButton(
                    onPressed: controller.busy ? null : controller.nextGame,
                    child: const Text('Next game'),
                  )
                else
                  const Text('Waiting for the host to start the next game…'),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Leave table'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// This game's points (green or red) followed by the running total.
class _PointsText extends StatelessWidget {
  const _PointsText({required this.points, required this.total});

  final int points;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = points > 0
        ? Colors.green.shade700
        : points < 0
        ? Colors.red.shade700
        : null;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: points > 0 ? '+$points' : '$points',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          TextSpan(text: '  ·  $total'),
        ],
      ),
    );
  }
}
