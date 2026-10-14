---
name: better-auth-sveltekit
disable-model-invocation: true
description: Set up and configure Better Auth in a SvelteKit project that uses Drizzle ORM. Covers the Drizzle adapter, the SvelteKit server handler and session locals, schema generation/migration, email/password with email verification and password reset sent through Resend (optionally with Svelte email components), admin/user roles and role-based access control via the admin plugin, and security hardening. Use this whenever the user mentions Better Auth, better-auth, auth.ts, authentication, login/sign-in, sign-up, sessions, email verification, password reset, user roles, RBAC, or an admin panel in a SvelteKit + Drizzle project — even if they do not say "Better Auth" explicitly.
---

# Better Auth + SvelteKit + Drizzle Integration Guide

**Always consult [better-auth.com/docs](https://better-auth.com/docs) for the latest API.** Better Auth changes quickly; treat the snippets here as a starting skeleton, not a frozen spec. This guide bundles the official `better-auth/skills` best-practices with SvelteKit-, Drizzle-, and Resend-specific details.

---

## Setup Workflow

1. Install: `pnpm add -D better-auth`
2. Set env vars: `BETTER_AUTH_SECRET` (min 32 chars) and `BETTER_AUTH_URL`
3. Create `src/lib/auth.ts` with the Drizzle adapter + config
4. Create `src/lib/auth-client.ts` (Svelte client)
5. Mount the handler in `src/hooks.server.ts` and populate `event.locals`
6. Generate the schema: `pnpm dlx @better-auth/cli@latest generate`, then migrate with Drizzle Kit
7. Verify: call `GET /api/auth/ok` — should return `{ status: "ok" }`
8. Re-run schema generation after adding or changing ANY plugin

---

## Environment Variables

- `BETTER_AUTH_SECRET` — encryption secret, min 32 chars. Generate: `openssl rand -base64 32`
- `BETTER_AUTH_URL` — base URL (e.g. `http://localhost:5173` in dev, `https://example.com` in prod)
- `RESEND_API_KEY` — for transactional email (see Email section)

Only set `baseURL`/`secret` in the config object if the env vars are NOT defined.

---

## Dependencies vs devDependencies

In SvelteKit the runtime-vs-dev split is fuzzy: Vite tree-shakes imported modules into the build at build time, so a package ends up in the bundle when your code uses it regardless of which `package.json` section it sits in. Because of this, scaffolding tools and the SvelteKit convention frequently drop packages — including runtime libraries — into `devDependencies`.

This guide follows that SvelteKit convention and installs packages as `devDependencies` (`-D`), matching what scaffolders like `sv add` produce:

- **Installed as `-D`:** `better-auth`, `resend`, `drizzle-orm`, `better-svelte-email`, `drizzle-kit`, and your DB driver (`pg` / `postgres` for Postgres).
- `@better-auth/cli` is not installed at all — run it via `pnpm dlx`.

**adapter-node caveat (do not skip):** because the runtime libraries above live in `devDependencies`, deploying with `@sveltejs/adapter-node` and a production-only install (`pnpm install --prod`, which omits `devDependencies`) will break — any runtime package Vite _externalizes_ instead of bundling (e.g. `better-auth` or the DB driver) won't be resolvable at runtime. For that deploy target, move the runtime packages to `dependencies` first. For fully bundled targets (static, serverless/edge) the `-D` placement is fine and the distinction does not matter.

---

## Server: `src/lib/auth.ts`

Use the Drizzle adapter. Pass the correct `provider` (`pg` for Postgres; `sqlite` is the other option) and your Drizzle schema object.

```ts
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { admin } from "better-auth/plugins";
import { sveltekitCookies } from "better-auth/svelte-kit";
import { getRequestEvent } from "$app/server";
import { db } from "$lib/server/db";
import * as schema from "$lib/server/db/schema";

export const auth = betterAuth({
  database: drizzleAdapter(db, { provider: "pg", schema }),
  session: {
    expiresIn: 60 * 60 * 24 * 7, // total session lifetime (default: 7 days; bump to 30/90 days for e-commerce "stay logged in")
    updateAge: 60 * 60 * 24, // sliding window: once the session is this stale, the next use extends its expiry (default: 1 day)
    freshAge: 60 * 60 * 24, // max age to still count as "fresh"; sensitive ops require a fresh session (default: 1 day; 0 disables the check)
    // disableSessionRefresh: true, // turn OFF the sliding extension → fixed lifetime regardless of activity
    cookieCache: {
      enabled: true,
      maxAge: 60 * 5, // cache the session in the cookie to skip a DB read per request (default: 5 min); independent of expiresIn
      // version: "1",              // bump this value + redeploy to invalidate ALL sessions at once (mass logout)
    },
  },
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: true,
    sendResetPassword: async ({ user, url }) => {
      await sendEmail({
        to: user.email,
        subject: "Reset your password",
        html: `...${url}...`,
      });
    },
  },
  emailVerification: {
    sendOnSignUp: true,
    autoSignInAfterVerification: true,
    sendVerificationEmail: async ({ user, url }) => {
      await sendEmail({
        to: user.email,
        subject: "Verify your email",
        html: `...${url}...`,
      });
    },
  },
  plugins: [
    admin(),
    sveltekitCookies(getRequestEvent), // MUST be the last plugin in the array
  ],
});
```

`sveltekitCookies(getRequestEvent)` has to be last so it can set cookies on the response after other plugins run. Putting it earlier silently breaks cookie handling.

---

## Client: `src/lib/auth-client.ts`

Import the Svelte client and mirror any plugins you registered on the server.

```ts
import { createAuthClient } from "better-auth/svelte";
import { adminClient } from "better-auth/client/plugins";

export const authClient = createAuthClient({
  plugins: [adminClient()],
});
```

Key methods: `signUp.email()`, `signIn.email()`, `signIn.social()`, `signOut()`, `useSession()`, `getSession()`, `revokeSession()`, `revokeSessions()`.

---

## Remember me

Surface a "Remember me" checkbox on login screens and pass its value as the `rememberMe` argument of `signIn.email`. It is a per-login parameter, NOT an `auth.ts` config option, and defaults to `true`. With `rememberMe: false` the cookie becomes a session cookie (cleared on browser close) and the sliding session refresh is suppressed. Keep it checked by default to match Better Auth's behavior — unchecking is mainly for shared/public devices — and you can omit the checkbox entirely if you don't need that option, since the default already remembers the user.

---

## Hook: `src/hooks.server.ts`

`svelteKitHandler` mounts the auth routes but does NOT populate `event.locals.user` / `event.locals.session`. Do that yourself if server code (load functions, actions, endpoints) needs the session.

```ts
import { auth } from "$lib/auth";
import { svelteKitHandler } from "better-auth/svelte-kit";
import { building } from "$app/environment";

export async function handle({ event, resolve }) {
  const session = await auth.api.getSession({ headers: event.request.headers });
  if (session) {
    event.locals.session = session.session;
    event.locals.user = session.user;
  }
  return svelteKitHandler({ event, resolve, auth, building });
}
```

Add the matching types in `src/app.d.ts` (`locals.user`, `locals.session`).

---

## Schema Generation & Migration (Drizzle)

Better Auth owns its tables. Generate the Drizzle schema with its CLI, then migrate with Drizzle Kit.

```bash
# Generate the auth tables into your schema folder, then migrate with Drizzle Kit
pnpm dlx @better-auth/cli@latest generate \
  --config src/lib/auth.ts \
  --output src/lib/server/db/schema/auth.ts \
  --yes
pnpm dlx drizzle-kit migrate                 # or: pnpm dlx drizzle-kit push
```

`--config` points at the auth instance, `--output` writes the generated tables into your schema folder, and `--yes` skips the confirmation prompt (good for scripts/CI). On Better Auth 1.5+ the same works via the new CLI: `pnpm dlx auth@latest generate ...`.

Because the schema is a folder, re-export the generated `auth.ts` from the barrel (`schema/index.ts` → `export * from "./auth";`). That barrel is what `drizzleAdapter`'s `import * as schema from "$lib/server/db/schema"` resolves to, so the auth tables are only picked up once they're exported there.

Without `--config`/`--output` the CLI searches `./`, `./lib`, `./utils`, or under `./src` for `auth.ts` and writes to a default location — pass the flags to keep it deterministic.

**Re-run `generate` + migrate after adding or changing ANY plugin** — plugins add columns (e.g. the admin plugin adds `role`, `banned`, `banReason`, `banExpires` to `user` and `impersonatedBy` to `session`).

---

## Email (Resend)

Better Auth does NOT send email itself — it calls your callbacks (`sendVerificationEmail`, `sendResetPassword`, and plugin equivalents) and you bring your own provider. Better Auth supplies `url` and `token`; you only deliver the message.

```bash
pnpm add -D resend
```

```ts
// src/lib/server/email.ts  (server-only)
import { Resend } from "resend";
import { RESEND_API_KEY } from "$env/static/private";

const resend = new Resend(RESEND_API_KEY);

export async function sendEmail(opts: {
  to: string;
  subject: string;
  html: string;
}) {
  const { error } = await resend.emails.send({
    from: "App <noreply@your-verified-domain.com>", // domain must be verified in Resend
    to: opts.to,
    subject: opts.subject,
    html: opts.html,
  });
  if (error) throw new Error(error.message);
}
```

**Email templates as components (optional):** use `better-svelte-email` to author `.svelte` email templates and render them to email-safe HTML, then pass the result to `sendEmail`:

```ts
import Renderer from "better-svelte-email/render";
import VerifyEmail from "$lib/emails/verify-email.svelte";
const renderer = new Renderer();
const html = await renderer.render(VerifyEmail, {
  props: { url, name: user.name },
});
```

`svelte-email-tailwind` is an alternative with a built-in preview/test-send UI. For the simplest path, return plain HTML strings from helper functions (no extra dependency).

---

## Admin & Roles (admin plugin)

The admin plugin provides two default roles: `admin` (full control over other users) and `user` (none). It exposes user creation, role assignment, banning/unbanning, session management, impersonation, and password administration.

**Custom roles + permissions** via access control:

```ts
// src/lib/permissions.ts
import { createAccessControl } from "better-auth/plugins/access";
import { defaultStatements, adminAc } from "better-auth/plugins/admin/access";

const statement = {
  ...defaultStatements,
  project: ["create", "update", "delete"],
} as const;

export const ac = createAccessControl(statement);
export const user = ac.newRole({ project: ["create"] });
export const editor = ac.newRole({ project: ["create", "update"] });
export const admin = ac.newRole({
  ...adminAc.statements,
  project: ["create", "update", "delete"],
});
```

Pass `ac` + `roles` to BOTH the server `admin({ ac, roles })` and the client `adminClient({ ac, roles })` — otherwise the client's TypeScript only knows `admin`/`user`.

**Assigning roles:** `authClient.admin.setRole({ userId, role: "editor" })`, or set `role` when creating a user. A user can hold multiple roles, stored as a comma-separated string in the single `role` column.

**Where things live:** the role _name_ is persisted in the DB (`user.role`); the _permissions_ for each role live in code (`createAccessControl`). To change what a role can do, edit code and redeploy — it is not editable from the DB at runtime. Check permissions with `hasPermission` / `userHasPermission`.

For org/team-scoped roles (owner/admin/member, multi-tenant) use the `organization` plugin instead.

---

## Security (from the official security skill)

- `secret` — set via `BETTER_AUTH_SECRET`. Required; min 32 chars.
- `trustedOrigins` — CSRF whitelist for callback/redirect URLs. The `baseURL` origin is trusted automatically. Supports wildcards (`"*.example.com"`) and an async function for multi-tenant. Also settable via `BETTER_AUTH_TRUSTED_ORIGINS`.
- `rateLimit` — enabled by default in production (`window: 10`, `max: 100`). Storage: `"memory"` (avoid on serverless), `"database"`, or `"secondary-storage"`.
- In `advanced`: `useSecureCookies` (force HTTPS cookies), `crossSubDomainCookies.enabled` (share across subdomains), `ipAddress.ipAddressHeaders` (behind proxies). Do NOT set `disableCSRFCheck` / `disableOriginCheck` outside local testing.

---

## Type Safety

Infer types from the server instance: `typeof auth.$Infer.Session`, `typeof auth.$Infer.Session.user`. For a separate client-only project, type the client with `createAuthClient<typeof auth>()`.

---

## SvelteKit-Specific Gotchas

1. **`sveltekitCookies` must be the LAST plugin** in the `plugins` array.
2. **`svelteKitHandler` does not populate `event.locals`** — fetch the session in `hooks.server.ts` and assign `locals.user` / `locals.session` yourself.
3. **The Better Auth CLI runs outside Vite**, so it cannot resolve SvelteKit aliases like `$env/static/private` or `$lib` when it imports `auth.ts`. If `generate` fails, read secrets via `process.env.*` in `auth.ts`, or keep a separate CLI-only config file. (`$env/static/private` works fine at runtime.)
4. **Use `$env/static/private` (or `$env/dynamic/private`) for secrets** — `auth.ts` and `email.ts` are server-only; never import them into client code.
5. **`event.locals` types** must be declared in `src/app.d.ts`.

---

## General Gotchas (from the official best-practices skill)

1. **Model vs table name** — config uses the ORM model name, not the DB table name.
2. **Plugin schema** — re-run the CLI after adding plugins.
3. **Secondary storage** — if configured (Redis/KV), sessions go there by default, not the DB.
4. **Cookie cache** — custom session fields are NOT cached; they are re-fetched.
5. **Stateless mode** — no DB means the session lives only in the cookie; logout happens on cache expiry.
6. **Change-email flow** — confirmation goes to the current email first, then the new one.
7. **Plugin imports** — prefer dedicated paths for tree-shaking (e.g. `better-auth/plugins/two-factor`) where available.

---

## Resources

- Better Auth docs: <https://better-auth.com/docs>
- Options reference: <https://better-auth.com/docs/reference/options>
- LLMs.txt (machine-readable docs): <https://better-auth.com/llms.txt>
- Official skills repo (best-practices + security): <https://github.com/better-auth/skills>
- SvelteKit integration: <https://better-auth.com/docs/integrations/svelte-kit>
- Admin plugin: <https://better-auth.com/docs/plugins/admin>
