# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Freiburg copy of `giessdenkiez-de-postgres-api` (Berlin upstream). Workspace rules (git remotes, PR target, data/secrets, language) live in `../../CLAUDE.md`. Architecture across services: `../../ARCHITECTURE.md`.

## What this is

There's no server code here: it's a Supabase project. The frontend talks to PostgREST, Supabase Auth and the Edge Functions directly. The behavior lives in:

- `supabase/migrations/` holds the schema, RLS, RPC functions, triggers and materialized views. Every DB change is a new migration. Never edit old ones, because they're already applied in prod.
- `supabase/functions/` holds the Deno Edge Functions (`gdk_stats`, `submit_contact_request`, `check_contact_request`). Shared code is in `_shared/` (CORS, env checks via `loadEnvVars`, error types). Each function fails at startup if a required env var is missing, e.g. `gdk_stats` needs `PUMPS_URL`.
- `supabase/seed.sql` is the local/CI seed. Per workspace rules, remove only the trees from it: it also creates the `data_assets` bucket.
- `src/` holds the Node Supabase clients plus the generated `database.ts` types. They're used only by the Jest tests.

## Commands

Local dev and tests need Docker and the Supabase CLI (CI uses CLI 2.20.3).

```bash
supabase start                     # local stack: API :54321, Studio :54323
cp .env.example .env               # fill in from `supabase status`
npm test                           # Jest, runInBand, runs against the local DB
npx jest tests/trees.test.ts -t "name"   # single file / test
npm run lint
npm run format
npm run supabase:types:local       # regenerate src/database.ts after schema changes
supabase db diff --file <name> --schema public --use-migra   # create migration from local changes
supabase db reset                  # re-apply migrations + seed
supabase test db                   # pgTAP tests in supabase/tests/database
```

Edge Functions (env in `supabase/.env`; `SUPABASE_*` vars are injected and can't be overridden there):

```bash
npm run dev:supabase:functions
# contact-request tests need mailhog + supabase/.env.test:
docker run -p 1025:1025 mailhog/mailhog
supabase functions serve --no-verify-jwt --env-file supabase/.env.test
deno test --allow-all supabase/functions/tests/submit-contact-request-tests.ts --env=supabase/.env.test
```

## Tests

- The Jest tests (`tests/`) create users and truncate tables through the service-role client (`tests/helper.ts`). Only run them against the local stack, never against a remote project.
- CI (`.github/workflows/tests.yml`) runs `supabase start`, then lint and test, then semantic-release.

## Deployment

Pushing to `staging` or `main` runs `supabase db push` and `supabase functions deploy` against the linked project (GitHub environments `staging`/`production`, secrets `PROJECT_ID`, `DB_PASSWORD`, `SUPABASE_ACCESS_TOKEN`). So merging a migration deploys it.

## Gotchas

- Materialized views (`most_frequent_tree_species`, `total_tree_species_count`, `trees_count`, …) are refreshed by triggers on `trees`. For bulk loads or restores, disable the `tg_refresh_*` triggers first, then refresh the views and re-enable the triggers (SQL in README "Database Caveats").
- The `trees` column names match the Berlin Baumkataster (migration `20240426114932_alter_column_names_match_kataster.sql`). The Freiburg mapping is in `../../freiburg-data/daten.md`.
- The README says types go in `./_types/database.ts`. That's outdated: the npm script writes `src/database.ts`.
