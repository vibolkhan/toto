# Supabase backend for online play

Online games are server-authoritative: the `tienlen` Edge Function validates every
move and runs the bots, and RLS lets each player read only their own hand.

## One-time setup

1. Install the CLI: `brew install supabase/tap/supabase`
2. `supabase login` then `supabase link --project-ref ghdnquahenigsbrachda`
3. Dashboard → Authentication → Sign In / Providers → enable **Anonymous sign-ins**.
4. Apply the schema: `supabase db push`
5. Deploy the function: `supabase functions deploy tienlen`
   (`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are provided
   to Edge Functions automatically.)

## Run the app against it

The app targets the hosted project (`ghdnquahenigsbrachda`) by default:

```sh
flutter run -d chrome
```

To point it elsewhere (e.g. a local `supabase start` stack), override with dart-defines:

```sh
flutter run -d chrome \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon or publishable key>
```

Open a second browser (or an incognito window) to get a second anonymous player.

## Tests

The TS engine shares rule vectors with the Dart engine (`test/fixtures/rules_cases.json`):

```sh
node --test supabase/functions/_shared/tienlen/engine_test.ts   # or: deno test --allow-read
```
