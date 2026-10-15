// Server-authoritative Tien Len.
// POST { action, ...params } with the user's Supabase JWT.
// Actions: create, join, leave, start, play, pass, next.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { Card } from "../_shared/tienlen/cards.ts";
import {
  chooseBotMove,
  dealGame,
  fromPublic,
  GameError,
  type GameState,
  isOver,
  pass,
  play,
  type PublicState,
  SEATS,
  toPublic,
  winnerOf,
} from "../_shared/tienlen/engine.ts";

declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void } | undefined;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BOT_DELAY_MS = 900;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

interface Player {
  seat: number;
  user_id: string | null;
  display_name: string;
  is_bot: boolean;
}

interface Room {
  id: string;
  code: string;
  host_id: string;
  status: "lobby" | "playing" | "closed";
}

const admin: SupabaseClient = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false },
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const userId = await authenticate(req);
    const body = await req.json();
    const result = await dispatch(userId, body);
    return json(200, result ?? { ok: true });
  } catch (e) {
    if (e instanceof HttpError) return json(e.status, { error: e.message });
    if (e instanceof GameError) return json(400, { error: e.message });
    console.error(e);
    return json(500, { error: "Server error" });
  }
});

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

async function authenticate(req: Request): Promise<string> {
  const authorization = req.headers.get("Authorization");
  if (!authorization) throw new HttpError(401, "Not signed in");
  const client = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw new HttpError(401, "Not signed in");
  return data.user.id;
}

// deno-lint-ignore no-explicit-any
async function dispatch(userId: string, body: any) {
  switch (body.action) {
    case "create":
      return createRoom(userId, cleanName(body.name));
    case "join":
      return joinRoom(userId, String(body.code ?? "").toUpperCase().trim(), cleanName(body.name));
    case "leave":
      return leaveRoom(userId, body.roomId);
    case "start":
      return startRoom(userId, body.roomId);
    case "play":
      return humanMove(userId, body.roomId, (s, seat) => play(s, seat, parseCards(body.cards)));
    case "pass":
      return humanMove(userId, body.roomId, (s, seat) => pass(s, seat));
    case "next":
      return nextGame(userId, body.roomId);
    default:
      throw new HttpError(400, "Unknown action");
  }
}

function cleanName(name: unknown): string {
  const s = String(name ?? "").trim().slice(0, 16);
  return s || "Player";
}

function parseCards(raw: unknown): Card[] {
  if (!Array.isArray(raw) || raw.length === 0 || raw.length > 13) {
    throw new HttpError(400, "Invalid cards");
  }
  return raw.map((c) => {
    if (!Number.isInteger(c) || c < 0 || c > 51) throw new HttpError(400, "Invalid cards");
    return c as Card;
  });
}

// ---------- Rooms ----------

function randomCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  return Array.from(bytes, (b) => alphabet[b % alphabet.length]).join("");
}

async function createRoom(userId: string, name: string) {
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = randomCode();
    const { data: room, error } = await admin
      .from("rooms")
      .insert({ code, host_id: userId })
      .select()
      .single();
    if (error?.code === "23505") continue; // code collision
    if (error) throw error;
    await must(admin.from("room_players").insert({
      room_id: room.id,
      seat: 0,
      user_id: userId,
      display_name: name,
    }));
    return { roomId: room.id, code };
  }
  throw new HttpError(500, "Could not create room");
}

async function joinRoom(userId: string, code: string, name: string) {
  const { data: room } = await admin.from("rooms").select().eq("code", code).maybeSingle();
  if (!room || room.status === "closed") throw new HttpError(404, "Room not found");

  const players = await loadPlayers(room.id);
  if (players.some((p) => p.user_id === userId)) return { roomId: room.id, code };
  if (room.status !== "lobby") throw new HttpError(409, "Game already started");

  const taken = new Set(players.map((p) => p.seat));
  const seat = [0, 1, 2, 3].find((s) => !taken.has(s));
  if (seat === undefined) throw new HttpError(409, "Room is full");

  const { error } = await admin.from("room_players").insert({
    room_id: room.id,
    seat,
    user_id: userId,
    display_name: name,
  });
  if (error?.code === "23505") throw new HttpError(409, "Seat taken, try again");
  if (error) throw error;
  return { roomId: room.id, code };
}

async function leaveRoom(userId: string, roomId: string) {
  const room = await loadRoom(roomId);
  const players = await loadPlayers(roomId);
  const me = players.find((p) => p.user_id === userId);
  if (!me) return;

  const remainingHumans = players.filter((p) => !p.is_bot && p.user_id !== userId);
  if (room.status === "lobby") {
    await must(admin.from("room_players").delete().eq("room_id", roomId).eq("seat", me.seat));
  } else {
    // Mid-game: a bot takes over the seat so the others can keep playing.
    await must(
      admin.from("room_players")
        .update({ user_id: null, is_bot: true, display_name: `${me.display_name} (bot)` })
        .eq("room_id", roomId).eq("seat", me.seat),
    );
    await must(
      admin.from("hands").update({ user_id: null }).eq("room_id", roomId).eq("seat", me.seat),
    );
  }

  if (remainingHumans.length === 0) {
    await must(admin.from("rooms").update({ status: "closed" }).eq("id", roomId));
    return;
  }
  if (room.host_id === userId) {
    await must(
      admin.from("rooms").update({ host_id: remainingHumans[0].user_id }).eq("id", roomId),
    );
  }
  if (room.status === "playing") runInBackground(runBots(roomId));
}

async function startRoom(userId: string, roomId: string) {
  const room = await loadRoom(roomId);
  if (room.host_id !== userId) throw new HttpError(403, "Only the host can start");
  if (room.status !== "lobby") throw new HttpError(409, "Game already started");

  const players = await loadPlayers(roomId);
  const taken = new Set(players.map((p) => p.seat));
  let botNo = 1;
  const bots = [0, 1, 2, 3].filter((s) => !taken.has(s)).map((seat) => ({
    room_id: roomId,
    seat,
    user_id: null,
    display_name: `Bot ${botNo++}`,
    is_bot: true,
  }));
  if (bots.length) await must(admin.from("room_players").insert(bots));

  const existing = await admin.from("games").select("version").eq("room_id", roomId).maybeSingle();
  await saveGame(roomId, existing.data?.version ?? null, dealGame(1, null));
  await must(admin.from("rooms").update({ status: "playing" }).eq("id", roomId));
  runInBackground(runBots(roomId));
}

async function nextGame(userId: string, roomId: string) {
  const room = await loadRoom(roomId);
  if (room.host_id !== userId) throw new HttpError(403, "Only the host can deal");
  const { state, version } = await loadGame(roomId);
  if (!isOver(state)) throw new HttpError(409, "The game is not over yet");
  const saved = await saveGame(roomId, version, dealGame(state.gameNo + 1, winnerOf(state)));
  if (!saved) throw new HttpError(409, "Game changed, try again");
  runInBackground(runBots(roomId));
}

// ---------- Moves ----------

async function humanMove(
  userId: string,
  roomId: string,
  apply: (s: GameState, seat: number) => GameState,
) {
  const players = await loadPlayers(roomId);
  const me = players.find((p) => p.user_id === userId);
  if (!me) throw new HttpError(403, "You are not in this room");

  const { state, version } = await loadGame(roomId);
  const next = apply(state, me.seat);
  if (!(await saveGame(roomId, version, next))) {
    throw new HttpError(409, "Game changed, try again");
  }
  runInBackground(runBots(roomId));
}

/** Plays bot turns one at a time, with a delay so players can follow along. */
async function runBots(roomId: string) {
  for (let i = 0; i < 80; i++) {
    const players = await loadPlayers(roomId);
    const { state, version } = await loadGame(roomId);
    if (isOver(state) || !players.find((p) => p.seat === state.turn)?.is_bot) return;

    await new Promise((r) => setTimeout(r, BOT_DELAY_MS));
    const move = chooseBotMove(state, state.turn);
    const next = move === null ? pass(state, state.turn) : play(state, state.turn, move);
    // If a concurrent request already advanced the game, just re-read and continue.
    await saveGame(roomId, version, next);
  }
}

function runInBackground(p: Promise<unknown>) {
  const guarded = p.catch((e) => console.error("bot loop failed", e));
  if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(guarded);
}

// ---------- Persistence ----------

async function loadRoom(roomId: string): Promise<Room> {
  const { data } = await admin.from("rooms").select().eq("id", roomId).maybeSingle();
  if (!data) throw new HttpError(404, "Room not found");
  return data;
}

async function loadPlayers(roomId: string): Promise<Player[]> {
  const { data, error } = await admin
    .from("room_players")
    .select("seat, user_id, display_name, is_bot")
    .eq("room_id", roomId)
    .order("seat");
  if (error) throw error;
  return data;
}

async function loadGame(roomId: string): Promise<{ state: GameState; version: number }> {
  const { data: game } = await admin.from("games").select().eq("room_id", roomId).maybeSingle();
  if (!game) throw new HttpError(404, "No game in progress");
  const { data: hands, error } = await admin
    .from("hands").select("seat, cards").eq("room_id", roomId).order("seat");
  if (error) throw error;
  const bySeat: Card[][] = Array.from({ length: SEATS }, () => []);
  for (const h of hands) bySeat[h.seat] = h.cards;
  return { state: fromPublic(game.state as PublicState, bySeat), version: game.version };
}

async function saveGame(
  roomId: string,
  expectedVersion: number | null,
  state: GameState,
): Promise<boolean> {
  const players = await loadPlayers(roomId);
  const userBySeat = new Map(players.map((p) => [p.seat, p.user_id]));
  const { data, error } = await admin.rpc("save_game", {
    p_room_id: roomId,
    p_expected_version: expectedVersion,
    p_game_no: state.gameNo,
    p_state: toPublic(state),
    p_hands: state.hands.map((cards, seat) => ({
      seat,
      user_id: userBySeat.get(seat) ?? null,
      cards,
    })),
  });
  if (error) throw error;
  return data === true;
}

async function must<T extends { error: unknown }>(p: PromiseLike<T>): Promise<T> {
  const res = await p;
  if (res.error) throw res.error;
  return res;
}
