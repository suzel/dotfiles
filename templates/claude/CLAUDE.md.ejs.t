<%# pnpm dlx ejs -n -l pkg CLAUDE.md.ejs.t -f package.json -o .claude/CLAUDE.md -%>
<%_
  const deps = { ...pkg.dependencies, ...pkg.devDependencies }
  const scripts = pkg.scripts ?? {}

  // "^2.63.0" → "2"
  const major = (dep) => deps[dep]?.match(/\d+/)?.[0] ?? ''
  const node = pkg.engines?.node ? ` (Node ${pkg.engines.node})` : ''
  const pnpm = pkg.engines?.pnpm ? ` (${pkg.engines.pnpm})` : ''

  // "@sveltejs/adapter-static" → "adapter-static"
  const adapter = Object.keys(deps).find((dep) => dep.startsWith('@sveltejs/adapter-'))?.replace('@sveltejs/', '')
  const server = adapter !== 'adapter-static'
  const db = deps['drizzle-orm'] || deps['drizzle-kit']
  const auth = deps['better-auth']

  const tools = [
    deps.prettier && 'Prettier',
    deps.eslint && 'ESLint',
    deps.vitest && 'Vitest',
    deps['@playwright/test'] && 'Playwright',
    deps.husky && 'Husky',
    deps['lint-staged'] && 'lint-staged',
  ].filter(Boolean)

  // known scripts get a description, others show their command; git hooks are hidden
  const describe = {
    dev: 'Dev server',
    build: 'Production build',
    preview: 'Preview prod build',
    check: 'svelte-check (types)',
    lint: 'Prettier check + ESLint',
    format: 'Prettier write',
    'design:lint': 'Validate .claude/DESIGN.md vs spec',
    'design:sync': 'DESIGN.md → CSS tokens',
  }
  const commands = Object.entries(scripts)
    .filter(([name]) => !['prepare', 'lint-staged'].includes(name))
    .map(([name, cmd]) => [name, describe[name] ?? `\`${cmd.replaceAll('|', '\\|')}\``])

  // "... > src/lib/styles/design-tokens.css" → "src/lib/styles/design-tokens.css"
  const tokensFile = scripts['design:sync']?.match(/>\s*(\S+)/)?.[1]

  // [label, value] → "- **label**: value"   (falsy rows are skipped)
  const list = (rows) => rows
    .filter(Boolean)
    .map(([label, value]) => `- **${label}**: ${value}`)
    .join('\n')

  // [path, note] → "├── path   # note"      (falsy rows are skipped, last one gets └──)
  const tree = (rows) => rows
    .filter(Boolean)
    .map(([path, note], i, all) => `${i < all.length - 1 ? '├──' : '└──'} ${path.padEnd(22)}# ${note}`)
    .join('\n')
-%>
# Project Configuration

## Tech Stack

<%- list([
  ['Framework', `SvelteKit ${major('@sveltejs/kit')} + Svelte ${major('svelte')} (runes — no legacy stores API)`],
  ['Language', (deps.typescript ? 'TypeScript' : 'JavaScript') + node],
  ['Build', `Vite ${major('vite')}`],
  ['Package Manager', 'pnpm' + pnpm],
  deps.tailwindcss && ['Styling', `Tailwind CSS v${major('tailwindcss')}`],
  deps.zod && ['Validation', `Zod ${major('zod')}`],
  db && ['Database', 'Drizzle ORM'],
  auth && ['Auth', 'better-auth'],
  adapter && ['Deploy', adapter + (scripts['docker:up'] ? ' (Docker available)' : '')],
  tools.length && ['Tooling', tools.join(', ')],
]) %>

## Commands

| Command | What it does |
| ------- | ------------ |
<% for (const [name, text] of commands) { -%>
| `pnpm <%- name %>` | <%- text %> |
<% } -%>
<% if (tokensFile) { -%>

**Never** hand-edit `<%- tokensFile %>` — edit `.claude/DESIGN.md`, then run `pnpm design:sync`.
<% } -%>

## Production Directory Structure

```text
src/lib/
<%- tree([
  ['components/ui/', 'Buttons, inputs, cards'],
  ['components/layout/', 'Header, Footer, Sidebar'],
  server && db && ['server/db/', 'Database (Drizzle)'],
  server && auth && ['server/auth/', 'Auth logic (better-auth)'],
  ['stores/', 'Svelte stores / runes'],
  ['utils/', 'Helper functions'],
  deps.zod && ['schemas/', 'Zod schemas (validation) — type via z.infer'],
  ['types/', 'Pure TS types (no runtime, no validation)'],
]) %>
src/routes/
<%- tree([
  ['(landing)/', 'Public marketing pages (home, pricing, about)'],
  server && auth && ['(app)/', 'Auth-required pages — guard in +layout.svelte'],
  server && auth && ['(auth)/', 'Login / register'],
  server && ['api/', 'API endpoints (+server.ts)'],
]) %>
```

## File & Naming Conventions

| Thing          | Rule                | Example           |
| -------------- | ------------------- | ----------------- |
| Component      | PascalCase          | `UserCard.svelte` |
| Utility        | camelCase           | `formatDate.ts`   |
| Route          | kebab-case          | `user-settings/`  |
| Constant       | UPPER_SNAKE         | `MAX_RETRY = 3`   |
| Type/Interface | PascalCase          | `UserProfile`     |
| Server util    | `.server.ts` suffix | `auth.server.ts`  |
<% if (scripts['design:sync']) { -%>

## References

- @DESIGN.md — UI / styling / visual. MUST follow, single source for design rules.
<% } -%>
