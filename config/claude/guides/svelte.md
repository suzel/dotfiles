# Svelte

## Components

- Use Svelte 5 runes: `$state`, `$derived`, `$effect`, `$props`.
- No legacy syntax: `export let`, `$:`, `on:click`, `<slot>`, stores for local state.
- Events as attributes (`onclick`), content as snippets (`{#snippet}`, `{@render}`).
- Prefer `$derived` over `$effect`. Use `$effect` only for side effects.

## SvelteKit

- Load data in `+page.server.ts` or `+layout.server.ts`, not in components.
- Use form actions for mutations, with `use:enhance` for progressive enhancement.
- Read secrets only from `$app/env/private`, declared with `defineEnvVars` in `src/env.ts`
  (SvelteKit 2: `$env/static/private` or `$env/dynamic/private`).
- Keep server-only code in `#lib/server` (SvelteKit 2: `$lib/server`).
