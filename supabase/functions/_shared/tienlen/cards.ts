// TypeScript port of lib/engine/{card,combo,rules,instant_win}.dart.
// Keep in sync with the Dart engine; test/fixtures/rules_cases.json is
// checked by both test suites.

/** Card value = rank * 4 + suit. Ranks 0..12 are 3..2, suits 0..3 are S,C,D,H. */
export type Card = number;

export const RANK_TWO = 12;
export const THREE_OF_SPADES: Card = 0;
const RANK_LABELS = ["3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2"];

export const rankOf = (c: Card): number => Math.floor(c / 4);

export function parseCard(text: string): Card {
  const rank = RANK_LABELS.indexOf(text.slice(0, -1));
  const suit = "SCDH".indexOf(text.slice(-1));
  if (rank < 0 || suit < 0) throw new Error(`Bad card: ${text}`);
  return rank * 4 + suit;
}

export function dealHands(players = 4): Card[][] {
  const deck = Array.from({ length: 52 }, (_, i) => i);
  for (let i = deck.length - 1; i > 0; i--) {
    const j = crypto.getRandomValues(new Uint32Array(1))[0] % (i + 1);
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return Array.from({ length: players }, (_, i) =>
    deck.slice(i * 13, i * 13 + 13).sort((a, b) => a - b));
}

export type ComboType = "single" | "pair" | "triple" | "four" | "sequence" | "doubleSequence";

export interface Combo {
  type: ComboType;
  cards: Card[]; // sorted ascending
}

export const highest = (c: Combo): Card => c.cards[c.cards.length - 1];
export const pairCount = (c: Combo): number =>
  c.type === "doubleSequence" ? c.cards.length / 2 : 0;
const isSingleTwo = (c: Combo) => c.type === "single" && rankOf(highest(c)) === RANK_TWO;
const isPairOfTwos = (c: Combo) => c.type === "pair" && rankOf(highest(c)) === RANK_TWO;

function isConsecutive(ranks: number[]): boolean {
  for (let i = 1; i < ranks.length; i++) {
    if (ranks[i] !== ranks[i - 1] + 1) return false;
  }
  return true;
}

export function detectCombo(input: Card[]): Combo | null {
  const cards = [...input].sort((a, b) => a - b);
  const n = cards.length;
  if (n === 0 || new Set(cards).size !== n) return null;
  if (cards.some((c) => !Number.isInteger(c) || c < 0 || c > 51)) return null;

  const ranks = cards.map(rankOf);
  if (ranks.every((r) => r === ranks[0])) {
    const types: (ComboType | null)[] = [null, "single", "pair", "triple", "four"];
    const type = types[n] ?? null;
    return type ? { type, cards } : null;
  }
  if (n >= 3 && isConsecutive(ranks)) return { type: "sequence", cards };
  if (n >= 6 && n % 2 === 0) {
    const pairRanks: number[] = [];
    for (let i = 0; i < n; i += 2) {
      if (ranks[i] !== ranks[i + 1]) return null;
      pairRanks.push(ranks[i]);
    }
    if (isConsecutive(pairRanks)) return { type: "doubleSequence", cards };
  }
  return null;
}

export function canBeat(previous: Combo | null, next: Combo): boolean {
  if (previous === null) return true;
  if (
    previous.type === next.type &&
    previous.cards.length === next.cards.length &&
    highest(next) > highest(previous)
  ) return true;

  const nextPairs = pairCount(next);
  if (next.type === "doubleSequence" && nextPairs === 3) {
    return isSingleTwo(previous);
  }
  if (next.type === "four") {
    return isSingleTwo(previous) || isPairOfTwos(previous) || pairCount(previous) === 3;
  }
  if (next.type === "doubleSequence" && nextPairs === 4) {
    return isSingleTwo(previous) || isPairOfTwos(previous) ||
      pairCount(previous) === 3 || previous.type === "four";
  }
  return false;
}

export type InstantWin = "fourTwos" | "dragon" | "sixPairs" | "fourTriples";
export const INSTANT_WINS: InstantWin[] = ["fourTwos", "dragon", "sixPairs", "fourTriples"];

export function detectInstantWin(hand: Card[]): InstantWin | null {
  const counts = new Array(13).fill(0);
  for (const c of hand) counts[rankOf(c)]++;
  if (counts[RANK_TWO] === 4) return "fourTwos";
  if (counts.slice(0, RANK_TWO).every((c) => c > 0)) return "dragon";
  if (counts.reduce((sum, c) => sum + Math.floor(c / 2), 0) >= 6) return "sixPairs";
  if (counts.filter((c) => c >= 3).length >= 4) return "fourTriples";
  return null;
}
