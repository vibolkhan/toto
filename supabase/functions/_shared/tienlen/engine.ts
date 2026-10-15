// TypeScript port of lib/engine/game_engine.dart and lib/engine/bot.dart.

import {
  canBeat,
  type Card,
  type Combo,
  dealHands,
  detectCombo,
  detectInstantWin,
  highest,
  INSTANT_WINS,
  type InstantWin,
  pairCount,
  RANK_TWO,
  rankOf,
  THREE_OF_SPADES,
} from "./cards.ts";

export const SEATS = 4;

export interface LastAction {
  seat: number;
  passed: boolean;
  cards: Card[];
}

/** Full engine state. Everything except `hands` is safe to show every player. */
export interface GameState {
  hands: Card[][];
  turn: number;
  gameNo: number;
  trick: Card[] | null;
  trickOwner: number | null;
  passed: number[];
  finished: number[];
  mustPlayThreeOfSpades: boolean;
  lastAction: LastAction | null;
  instantWin: InstantWin | null;
  instantWinSeat: number | null;
}

/** The part of the state stored in `games.state`, visible to every player. */
export type PublicState = Omit<GameState, "hands"> & {
  handCounts: number[];
  isOver: boolean;
};

export class GameError extends Error {}

export const isOver = (s: GameState): boolean =>
  s.finished.length === SEATS || s.instantWin !== null;

export const winnerOf = (s: GameState): number | null =>
  s.instantWinSeat ?? (s.finished.length ? s.finished[0] : null);

export function toPublic(s: GameState): PublicState {
  const { hands, ...rest } = s;
  return { ...rest, handCounts: hands.map((h) => h.length), isOver: isOver(s) };
}

export function fromPublic(p: PublicState, hands: Card[][]): GameState {
  const { handCounts: _c, isOver: _o, ...rest } = p;
  return { ...rest, hands };
}

export function startGame(
  dealt: Card[][],
  gameNo = 1,
  previousWinner: number | null = null,
): GameState {
  const hands = dealt.map((h) => [...h].sort((a, b) => a - b));
  const leader = previousWinner ?? hands.findIndex((h) => h.includes(THREE_OF_SPADES));
  const base: GameState = {
    hands,
    turn: leader,
    gameNo,
    trick: null,
    trickOwner: null,
    passed: [],
    finished: [],
    mustPlayThreeOfSpades: previousWinner === null,
    lastAction: null,
    instantWin: null,
    instantWinSeat: null,
  };
  for (const kind of INSTANT_WINS) {
    for (let i = 0; i < SEATS; i++) {
      const seat = (leader + i) % SEATS;
      if (detectInstantWin(hands[seat]) === kind) {
        return {
          ...base,
          turn: seat,
          finished: [seat],
          mustPlayThreeOfSpades: false,
          instantWin: kind,
          instantWinSeat: seat,
        };
      }
    }
  }
  return base;
}

export const dealGame = (gameNo = 1, previousWinner: number | null = null) =>
  startGame(dealHands(), gameNo, previousWinner);

export function validatePlay(s: GameState, seat: number, cards: Card[]): string | null {
  if (isOver(s)) return "The game is over";
  if (s.turn !== seat) return "Not your turn";
  if (cards.length === 0) return "Select cards to play";
  if (!cards.every((c) => s.hands[seat].includes(c))) return "You do not hold those cards";
  const combo = detectCombo(cards);
  if (!combo) return "Not a valid combination";
  if (s.mustPlayThreeOfSpades && !cards.includes(THREE_OF_SPADES)) {
    return "The first play must include 3♠";
  }
  const trick = s.trick ? detectCombo(s.trick) : null;
  if (!canBeat(trick, combo)) return "Does not beat the cards on the table";
  return null;
}

export function play(s: GameState, seat: number, cards: Card[]): GameState {
  const error = validatePlay(s, seat, cards);
  if (error) throw new GameError(error);
  const combo = detectCombo(cards)!;

  const hands = s.hands.map((h, i) => i === seat ? h.filter((c) => !cards.includes(c)) : h);
  const finished = [...s.finished];
  if (hands[seat].length === 0) finished.push(seat);

  const next: GameState = {
    ...s,
    hands,
    trick: combo.cards,
    trickOwner: seat,
    finished,
    mustPlayThreeOfSpades: false,
    lastAction: { seat, passed: false, cards: combo.cards },
  };
  const active = [0, 1, 2, 3].filter((i) => !finished.includes(i));
  if (active.length === 1) return { ...next, finished: [...finished, active[0]] };
  return advance(next, seat);
}

export function pass(s: GameState, seat: number): GameState {
  if (isOver(s)) throw new GameError("The game is over");
  if (s.turn !== seat) throw new GameError("Not your turn");
  if (s.trick === null) throw new GameError("You must lead, you cannot pass");
  return advance(
    { ...s, passed: [...s.passed, seat], lastAction: { seat, passed: true, cards: [] } },
    seat,
  );
}

function advance(s: GameState, from: number): GameState {
  const owner = s.trickOwner!;
  const isActive = (seat: number) => !s.finished.includes(seat);
  const canRespond = (seat: number) =>
    seat !== owner && isActive(seat) && !s.passed.includes(seat);

  if (![0, 1, 2, 3].some(canRespond)) {
    let leader = owner;
    while (!isActive(leader)) leader = (leader + 1) % SEATS;
    return { ...s, turn: leader, trick: null, trickOwner: null, passed: [] };
  }
  let seat = (from + 1) % SEATS;
  while (!canRespond(seat)) seat = (seat + 1) % SEATS;
  return { ...s, turn: seat };
}

function subsets(cards: Card[]): Card[][] {
  const out: Card[][] = [];
  for (let mask = 1; mask < (1 << cards.length); mask++) {
    out.push(cards.filter((_, i) => mask & (1 << i)));
  }
  return out;
}

export function possibleCombos(hand: Card[]): Combo[] {
  const byRank: Card[][] = Array.from({ length: 13 }, () => []);
  for (const c of hand) byRank[rankOf(c)].push(c);
  byRank.forEach((r) => r.sort((a, b) => a - b));

  const result: Combo[] = [];
  const add = (cards: Card[]) => {
    const combo = detectCombo(cards);
    if (combo) result.push(combo);
  };

  for (const cards of byRank) subsets(cards).forEach(add);

  for (let start = 0; start < 13; start++) {
    for (let end = start + 2; end < 13; end++) {
      if (byRank.slice(start, end + 1).some((r) => r.length === 0)) break;
      const base: Card[] = [];
      for (let r = start; r < end; r++) base.push(byRank[r][0]);
      for (const top of byRank[end]) add([...base, top]);
    }
  }

  for (let start = 0; start < 13; start++) {
    for (let end = start + 2; end < 13; end++) {
      if (byRank.slice(start, end + 1).some((r) => r.length < 2)) break;
      const base: Card[] = [];
      for (let r = start; r < end; r++) base.push(...byRank[r].slice(0, 2));
      for (const top of subsets(byRank[end]).filter((p) => p.length === 2)) {
        add([...base, ...top]);
      }
    }
  }
  return result;
}

export const legalPlays = (s: GameState, seat: number): Combo[] =>
  possibleCombos(s.hands[seat]).filter((c) => validatePlay(s, seat, c.cards) === null);

const isBomb = (c: Combo) => c.type === "four" || pairCount(c) >= 3;

/** Heuristic bot, mirrors chooseBotMove in lib/engine/bot.dart. Null means pass. */
export function chooseBotMove(s: GameState, seat: number): Card[] | null {
  const hand = s.hands[seat];
  const legal = legalPlays(s, seat);
  if (legal.length === 0) return null;

  const finishing = legal.find((c) => c.cards.length === hand.length);
  if (finishing) return finishing.cards;

  const opponentsNearOut = [0, 1, 2, 3].some((i) =>
    i !== seat && !s.finished.includes(i) && s.hands[i].length <= 3
  );
  const counts = new Array(13).fill(0);
  for (const c of hand) counts[rankOf(c)]++;

  const cost = (c: Combo): number => {
    let score = highest(c);
    if (c.cards.some((x) => rankOf(x) === RANK_TWO)) score += 60;
    if (isBomb(c)) score += 80;
    if (
      (c.type === "single" || c.type === "pair" || c.type === "triple") &&
      counts[rankOf(highest(c))] > c.cards.length
    ) score += 15;
    if (c.type === "sequence") {
      score += c.cards.filter((x) => counts[rankOf(x)] >= 2).length * 4;
    }
    return score;
  };

  if (s.trick === null) {
    const lowest = hand[0];
    let options = legal.filter((c) => c.cards.includes(lowest));
    if (opponentsNearOut) {
      const nonSingles = legal.filter((c) => c.type !== "single");
      if (nonSingles.length === 0) return [hand[hand.length - 1]];
      options = nonSingles;
    }
    options.sort((a, b) => (b.cards.length - a.cards.length) || (cost(a) - cost(b)));
    const safe = options.filter((c) => !isBomb(c));
    return (safe.length ? safe : options)[0].cards;
  }

  const trickTop = s.trick[s.trick.length - 1];
  const choppingTwo = rankOf(trickTop) === RANK_TWO;
  const candidates = legal.filter((c) => {
    const expensive = isBomb(c) || c.cards.some((x) => rankOf(x) === RANK_TWO);
    return !expensive || choppingTwo || opponentsNearOut || hand.length <= 4;
  }).sort((a, b) => cost(a) - cost(b));
  if (candidates.length === 0) return null;

  const best = candidates[0];
  if (!choppingTwo && !opponentsNearOut && cost(best) > 70 && hand.length > 6) return null;
  return best.cards;
}
