// Runs under both Deno (`deno test`) and Node 22.18+ (`node --test`).
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

import { canBeat, chopPoints, detectCombo, detectInstantWin, parseCard } from "./cards.ts";
import { chooseBotMove, dealGame, isOver, pass, play, startGame, winnerOf } from "./engine.ts";

const fixture = JSON.parse(
  readFileSync(new URL("../../../../test/fixtures/rules_cases.json", import.meta.url), "utf8"),
);
const cards = (raw: string[]) => raw.map(parseCard);

test("combo detection matches shared fixture", () => {
  for (const c of fixture.detect) {
    assert.equal(detectCombo(cards(c.cards))?.type ?? null, c.type, JSON.stringify(c));
  }
});

test("canBeat matches shared fixture", () => {
  for (const c of fixture.beats) {
    const prev = c.prev === null ? null : detectCombo(cards(c.prev));
    assert.equal(canBeat(prev, detectCombo(cards(c.next))!), c.expected, JSON.stringify(c));
  }
});

test("instant win matches shared fixture", () => {
  for (const c of fixture.instantWin) {
    assert.equal(detectInstantWin(cards(c.hand)), c.expected, JSON.stringify(c));
  }
});

test("chop points match shared fixture", () => {
  for (const c of fixture.chops) {
    const prev = detectCombo(cards(c.prev))!;
    assert.equal(chopPoints(prev, detectCombo(cards(c.next))!), c.points, JSON.stringify(c));
  }
});

test("scoring: placement, chops, instant win and carry-over", () => {
  const h = (s: string) => cards(s.split(" "));

  let s = startGame([h("3S"), h("4S"), h("5S"), h("6S")], 1, null, [1, 2, 3, 4]);
  s = play(s, 0, h("3S"));
  s = play(s, 1, h("4S"));
  s = play(s, 2, h("5S"));
  assert.deepEqual(s.gamePoints, [10, 5, -5, -10]);
  assert.deepEqual(s.scores, [11, 7, -2, -6]);

  s = startGame([h("2S 3S"), h("7S 7C 7D 7H 4S"), h("5S 6S"), h("8S 9S")], 2, 0);
  s = play(s, 0, h("2S"));
  s = play(s, 1, h("7S 7C 7D 7H"));
  assert.deepEqual(s.gamePoints, [-10, 10, 0, 0]);

  s = startGame([
    h("2S 2C 2D 2H 3S 4S 5S 6S 7S 8S 9S 10S JS"),
    h("3C 4C 5C 6C 7C 8C 9C 10C JC QC KC AC QS"),
    h("3D 4D 5D 6D 7D 8D 9D 10D JD QD KD AD KS"),
    h("3H 4H 5H 6H 7H 8H 9H 10H JH QH KH AH AS"),
  ]);
  assert.deepEqual(s.gamePoints, [30, -10, -10, -10]);
});

test("pass lockout and trick clearing", () => {
  const h = (s: string) => cards(s.split(" "));
  let s = startGame([
    h("4S 5C 6D 7H 8S 9C 10D JH QS KC AD 2H KD"),
    h("3S 4C 5D 6H 7S 8C 9D 10H JS QC 2S AH 3C"),
    h("3D 4D 5H 6S 7C 8D 9H 10S JC QD 2C AS 4H"),
    h("3H 5S 6C 7D 8H 9S 10C JD QH KS AC KH 2D"),
  ]);
  assert.equal(s.turn, 1);
  assert.throws(() => play(s, 1, h("4C")));
  s = play(s, 1, h("3S"));
  s = pass(s, 2);
  s = play(s, 3, h("5S"));
  s = play(s, 0, h("6D"));
  assert.equal(s.turn, 1);
  s = play(s, 1, h("7S"));
  assert.equal(s.turn, 3);
  s = pass(s, 3);
  s = pass(s, 0);
  assert.equal(s.turn, 1);
  assert.equal(s.trick, null);
  assert.deepEqual(s.passed, []);
});

test("500 bot-only games terminate with a full ordering", () => {
  let previousWinner: number | null = null;
  for (let g = 0; g < 500; g++) {
    let s = dealGame(g + 1, previousWinner);
    let moves = 0;
    while (!isOver(s)) {
      const move = chooseBotMove(s, s.turn);
      s = move === null ? pass(s, s.turn) : play(s, s.turn, move);
      assert.ok(++moves < 500, `game ${g} did not terminate`);
    }
    if (s.instantWin === null) assert.equal(new Set(s.finished).size, 4);
    assert.equal(s.gamePoints.reduce((a, b) => a + b, 0), 0);
    previousWinner = winnerOf(s);
  }
});
