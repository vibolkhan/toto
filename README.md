# Tiến Lên

A Flutter version of the Vietnamese card game **Tiến Lên** (also called *Thirteen*), for four players. You can play offline against bots or online with friends.

## Getting started

```sh
flutter pub get
flutter run            # or: flutter run -d chrome
```

Online play uses a Supabase backend. To set it up, see [supabase/README.md](supabase/README.md).

## How to play in the app

1. Enter your name on the home screen.
2. Choose a mode:
   - **Play with bots**: an offline game against three bots.
   - **Play with friends**: tap **Create a room** and share the room code, or enter a friend's code and tap **Join room**. The host starts the game. Any empty seats are filled by bots.
3. When it is your turn, tap cards in your hand to select them. Then tap **Play**, or tap **Pass** to skip.
4. When a game ends, tap **Next game** to deal again. Online, the host does this.

## Game rules

### Basics
- The game uses a standard 52-card deck. Each of the 4 players is dealt 13 cards.
- **The goal** is to be the first to get rid of all your cards. Play continues until only one player still has cards, and that player comes last.
- **Card order:** rank goes from low to high: `3 4 5 6 7 8 9 10 J Q K A 2`.
  - When two cards have the same rank, suit decides: ♠ < ♣ < ♦ < ♥.
  - **3♠ is the lowest card** and **2♥ is the highest**.

### Turns
- **In the first game**, the player holding **3♠** leads, and the first play must include it.
- **In later games**, the previous winner leads with anything.
- **Turn order:** play goes clockwise. On your turn you either:
  - **beat** the cards on the table with a higher combination of the same type, or
  - **pass**. Once you pass, you are locked out until the current round ends.
- When everyone else has passed, the last player to play wins the round and leads the next one. If that player has already gone out, the next active player clockwise leads.
- The leader may play any valid combination but cannot pass.

### Valid combinations

| Combination | Example | Notes |
|---|---|---|
| Single | `7♦` | |
| Pair | `9♠ 9♥` | |
| Triple | `5♣ 5♦ 5♥` | |
| Four of a kind | `J♠ J♣ J♦ J♥` | A bomb (see below) |
| Sequence | `4♦ 5♠ 6♥` | 3 or more consecutive ranks, any suits |
| Double sequence | `3♠ 3♣ 4♦ 4♥` | 2 or more consecutive pairs |
| Full house | `5♠ 5♣ 5♦ 6♠ 6♥` | A triple plus a pair of an **adjacent** rank |

**Limits on sequences and full houses:**
- **No 2s:** a 2 can never be part of a sequence, a double sequence or a full house. Runs top out at A.
- **No wrap-around:** `K A 2` and `A 2 3` are not valid.
- **Adjacent ranks only:** a full house can be `555 + 66` or `55 + 666`, but not `555 + 77` or `555 + KK`.

### Beating a combination
Unless a special rule below applies, you must play the **same type** with the **same number of cards** and a **higher top card**:
- **Singles, pairs, triples, fours, sequences, double sequences:** compare the highest card, by rank first and then by suit.
  - `7♠ 7♥` beats `7♣ 7♦`, because 7♥ is higher than 7♦.
  - A 4-card sequence cannot beat a 3-card sequence.
- **Full house:** only the triple counts, and the pair is ignored. `55 + 666` beats `555 + 66`.

### One-suit sequences
- A sequence whose cards are **all the same suit** (for example `3♠ 4♠ 5♠`) can only be beaten by **another one-suit sequence** of the **same length** with a **higher top card**. The new one may be any suit.
  - `4♥ 5♥ 6♥` beats `3♠ 4♠ 5♠`.
  - The mixed `6♦ 7♣ 8♥` does not beat it.
- A one-suit sequence of exactly 5 cards is a **straight flush**. It is also a bomb.

### Bombs (chopping)
Bombs can beat combinations of a different type:

| Bomb | Can beat |
|---|---|
| Four of a kind | A single 2, or a lower four of a kind |
| Straight flush (5 cards, one suit) | A single 2, any four of a kind, or a lower straight flush |
| 4-pair double sequence | A pair of 2s, any 3-pair double sequence, any four of a kind, or a lower 4-pair double sequence |

- A 3-pair double sequence is **not** a bomb. It only beats a higher-ranked 3-pair double sequence.
- A 4-pair double sequence cannot chop a single 2.
- Only a higher straight flush can beat a straight flush.

### Instant wins (tới trắng)
A player whose dealt hand contains one of these wins immediately. They are listed in priority order:

1. **Four 2s**
2. **Dragon:** one card of every rank from 3 to A
3. **Six pairs**
4. **Four triples**

### Scoring
Points add up across the games in a session. Each seat plate shows its running total.

| Event | Points |
|---|---|
| Finish 1st / 2nd / 3rd / 4th | +10 / +5 / −5 / −10 |
| Chop a single 2 with a bomb | Bomber +10, the player of the 2 −10 |
| Chop a pair of 2s with a bomb | Bomber +20, the player of the 2s −20 |
| Chop a bomb or a 3-pair double sequence with a bomb | Bomber +10, the chopped player −10 |
| Instant win | Winner +30, every other player −10 |

- Chop points are scored as soon as the bomb is played.
- If a bomb is chopped by a bigger bomb, each chop scores on its own.

## Sound

Sound effects play for dealing, playing, passing, bombs, going out, winning and losing, and when it is your turn. Tap the speaker icon in the top bar to mute them.

The sounds come from [Kenney.nl](https://kenney.nl) packs (Casino Audio, Interface Sounds, Impact Sounds and Music Jingles). They are CC0, so no credit is required. They were converted to `.m4a` so they play on every platform, and they live in `assets/sounds/`.

## Development

The rules are implemented twice, and the two copies must stay in sync:

- **Dart** (the app): `lib/engine/`
- **TypeScript** (the server-side game engine on Supabase): `supabase/functions/_shared/tienlen/`

Both test suites check the same rule cases in `test/fixtures/rules_cases.json`:

```sh
flutter test
node --test supabase/functions/_shared/tienlen/engine_test.ts
```
