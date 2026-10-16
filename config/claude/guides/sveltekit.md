# SvelteKit

- Load data in `+page.server.ts` or `+layout.server.ts`, not in components.
- Use form actions for mutations, with `use:enhance` for progressive enhancement.
- Read secrets only from `$env/static/private` or `$env/dynamic/private`.
- Keep server-only code in `$lib/server`.
