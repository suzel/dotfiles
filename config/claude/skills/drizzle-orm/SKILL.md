---
name: drizzle-orm
disable-model-invocation: true
description: >
  Best practices for using Drizzle ORM inside a SvelteKit (Svelte 5 / SvelteKit 2)
  project, covering BOTH SQLite and PostgreSQL. Use this skill whenever the user is
  setting up a database in SvelteKit, mentions Drizzle, drizzle-kit, drizzle.config,
  a schema file, migrations, `sv add drizzle`, postgres.js / better-sqlite3 / libsql /
  Turso / Neon, or asks how to query/load data from a database in a +page.server.ts,
  +server.ts, or form action — even if they don't say the word "best practice". Also
  use it when the user wants to support two database dialects (e.g. SQLite locally,
  Postgres in production), because Drizzle schemas are dialect-specific and this needs
  deliberate structure.
---

<skill name="drizzle-orm" stack="Svelte 5 + SvelteKit 2, TypeScript strict">

<objective>
Build a typed, secure, production-ready DB layer in SvelteKit for SQLite and/or PostgreSQL.
Hardest constraint: **Drizzle schemas are dialect-specific** — one schema cannot serve both
SQLite and Postgres. If the project targets both, read `<two_dialect_strategy>` before writing
any schema.
</objective>

<assumptions>
- **ALWAYS TypeScript, never JavaScript.** Every file is `.ts`/`.svelte` with `<script lang="ts">`;
  `strict: true`. No `.js`/`jsconfig` scaffolds, no JS fallback — if a tool prompts for a language,
  always pick TypeScript.
- Svelte 5 + SvelteKit 2.
- `drizzle-orm` pinned ≥ the release that fixed `sql.identifier()` / `sql.as()` escaping
  (CWE-89 SQL injection). Older versions did not escape those helpers. Verify with
  `pnpm view drizzle-orm version`; use a current one.
- Relations API depends on major version: v1 → `defineRelations`; `0.4x` → classic `relations()`.
  Check installed version before writing relations — do not guess.
</assumptions>

<rules priority="critical">
These are non-negotiable. Violating any one is a defect.

1. **Server-only boundary.** DB client + `DATABASE_URL` live ONLY in `$lib/server/**` or
   `*.server.ts`. Never reach the browser bundle. Never a `PUBLIC_` prefix on credentials.
2. **Schema is ALWAYS a `schema/` folder** — one file per domain + barrel `index.ts`. Never a
   single `schema.ts`, regardless of table count.
3. **Relations live in the table's own domain file** — never a separate `relations.ts`.
4. **One client singleton** at module scope, reused. Never a connection per request.
5. **DB code only in server contexts** — `+page.server.ts`/`+layout.server.ts` load, form
   `actions`, `+server.ts`, `$lib/server/**`. NEVER in `+page.ts`/`+page.js` or `.svelte`.
6. **Validate every external input** (drizzle-zod / zod) before insert/update.
7. **SQLite: `PRAGMA foreign_keys = ON`** — off by default.
8. **Two dialects ⇒ parallel `schema.pg/` and `schema.sqlite/` folders.** No transparent sharing.
   </rules>

<workflow>

<step n="0" name="Scaffold with official CLI — don't hand-roll">
SvelteKit's `sv` CLI (replaced `create-svelte`/`svelte-add`) ships a Drizzle add-on that wires
the client, schema file, `drizzle.config.ts`, `.env`, package scripts (push/migrate/studio), optional
Docker. Prefer it over manual setup. Add-on puts DB code in the server-only location — keep it there.

```sh
pnpm dlx sv create my-app        # SvelteKit minimal + TypeScript — ALWAYS pick TypeScript, never JS
cd my-app
pnpm dlx sv add drizzle          # interactive — detects pnpm via lockfile
# non-interactive — Postgres + postgres.js + local Docker db:
pnpm dlx sv add drizzle="database:postgresql+client:postgres.js+docker:yes"
# SQLite + better-sqlite3:
pnpm dlx sv add drizzle="database:sqlite+client:better-sqlite3"
```

Client options: Postgres → `postgres.js` or `neon`; SQLite → `better-sqlite3`, `libsql`, `turso`.
Pick a placeholder, swap driver later if needed.

<rule name="docker-over-file" priority="high">
Docker available (docker-compose.yml, Dockerfile, or user runs Docker) ⇒ use a container DB, not a
local on-disk file. SQLite → libsql `sqld` container over `http://localhost:...` with `libsql`
client (NOT `better-sqlite3` + `file:` path). Postgres → add-on's `docker:yes`. Keeps dev/prod
parity, avoids stray DB file in repo. Fall back to local file only when Docker genuinely absent.
</rule>
</step>

<step n="1" name="Choose driver — drives adapter choice">
<drivers dialect="sqlite">
- `better-sqlite3` — sync, native bindings, fastest for single long-running Node server. Requires
  `@sveltejs/adapter-node`. NOT usable on edge/serverless.
- `libsql` (`@libsql/client`) — async; local (`file:`) and remote. Use for SQLite semantics + edge/serverless.
- `turso` — libsql at Turso cloud; edge-friendly, replicated.
</drivers>
<drivers dialect="postgresql">
- `postgres.js` (`postgres`) — general-purpose, pooled, ideal for long-running servers.
- `neon` (`@neondatabase/serverless`) — HTTP/WebSocket driver for serverless/edge (no persistent TCP pool).
</drivers>
<rule name="adapter">
`adapter-auto` may resolve to a serverless target that can't run native modules. Using
`better-sqlite3` ⇒ set `@sveltejs/adapter-node` explicitly. Edge ⇒ HTTP-based driver
(libsql/Turso or Neon), not a native one.
</rule>
</step>

<step n="2" name="File layout + server-only boundary" priority="security-critical">
Never let the DB client or credentials reach the browser bundle. SvelteKit enforces this — use it:
- `src/lib/server/**` is guaranteed server-only; importing from client code is a build error. Put
  client + schema here.
- `*.server.ts` files are server-only too.

```
src/lib/server/db/
├── index.ts          # client singleton (and migrate() helper if used)
└── schema/
    ├── columns.ts    # shared timestamps / soft-delete columns
    ├── users.ts      # one file per domain: table defs + inferred types + relations
    ├── posts.ts
    └── index.ts      # barrel: export * from each domain file
```

```ts
// src/lib/server/db/schema/index.ts
export * from "./users";
export * from "./posts";
```

New table → new domain file (or existing one) → re-export from `schema/index.ts`. Client still does
`import * as schema from './schema'` unchanged. **Relations live in the table's own domain file**:
table + its `relations()` (or v1 `defineRelations` entry) side by side, then re-exported via barrel.
A relation goes in whichever domain file owns the table that declares it; import the other table
across files. One file fully describes a domain; barrel re-export wires relations into the `schema`
object the client loads.

<env_vars>

- `$env/static/private` (build-time, tree-shaken, errors if missing) for fixed config; or
  `$env/dynamic/private` (runtime) when value varies per container/deploy (Docker, many PaaS).
- NEVER credentials behind `PUBLIC_` or in `$env/*/public`.
  </env_vars>
  </step>

<step n="3" name="Connection management — commonly gotten wrong">
One client at module scope, reused. No connection per request.

<code driver="postgres.js" note="pool + TLS in prod">
```ts
// src/lib/server/db/index.ts
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { dev } from '$app/environment';
import { env } from '$env/dynamic/private';
import * as schema from './schema';

if (!env.DATABASE_URL) throw new Error('DATABASE_URL is not set');

const client = postgres(env.DATABASE_URL, {
max: dev ? 1 : 10, // small pool in dev; tune for prod / your DB limits
idle_timeout: 20,
ssl: dev ? false : 'require' // require TLS in production
});

export const db = drizzle(client, { schema });
