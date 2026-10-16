# Svelte

- Use Svelte 5 runes: `$state`, `$derived`, `$effect`, `$props`.
- No legacy syntax: `export let`, `$:`, `on:click`, `<slot>`, stores for local state.
- Events as attributes (`onclick`), content as snippets (`{#snippet}`, `{@render}`).
- Prefer `$derived` over `$effect`. Use `$effect` only for side effects.
