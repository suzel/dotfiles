<%_
  const deps = { ...pkg.dependencies, ...pkg.devDependencies }
  const scripts = pkg.scripts ?? {}

  // repository.url | homepage → "u/r"
  const slug = (pkg.repository?.url ?? pkg.repository ?? pkg.homepage ?? '')
    .replace(/^(git\+)?(ssh:\/\/)?git@github\.com[:/]/, 'https://github.com/')
    .replace(/(\.git)?(#.*)?$/, '')
    .match(/github\.com\/([^/]+\/[^/]+)/)?.[1]

  // ">=26" → "26"; falls back to the running Node, same as .node-version
  const node = (pkg.engines?.node ?? process.versions.node.split('.')[0]).replace(/^>=\s*/, '')
  const pnpm = pkg.engines?.pnpm ? ` \`${pkg.engines.pnpm}\`` : ''

  const purpose = {
    dev: 'Start Vite dev server with `--open`',
    build: 'Production build',
    preview: 'Preview built output',
    check: '`svelte-check` type checking',
    lint: 'Prettier check + ESLint',
    format: 'Prettier write',
    'docker:up': 'Start local services (database, etc.) via Compose',
    'docker:down': 'Stop local services',
  }
  const useful = Object.entries(purpose).filter(([name]) => scripts[name])

  // "`lint`, `check`, `build`"
  const ci = ['lint', 'check', 'build'].filter((name) => scripts[name]).map((name) => `\`${name}\``).join(', ')
-%>
# Contributing

Thanks for your interest in contributing. This document covers local setup, branching, commit conventions, and the pull request process.

## Prerequisites

- **Node.js** matching `.node-version` (currently Node <%- node %>+; see `engines.node` in `package.json`).
- **pnpm**<%- pnpm %> — install via [pnpm.io](https://pnpm.io/installation) or `corepack enable`.
<% if (scripts['docker:up']) { -%>
- **Docker** (optional) — required only if you run the local database via `pnpm docker:up`.
<% } -%>

Use a Node version manager (`nvm`, `fnm`, `asdf`, `volta`) to match `.node-version` automatically when entering the project directory.

## Initial Setup

```sh
<% if (slug) { -%>
git clone git@github.com:<%- slug %>.git
cd <%- slug.split('/')[1] %>
<% } -%>
pnpm install
pnpm dev
```
<% if (scripts.prepare) { -%>

`pnpm install` runs `prepare` (<%- deps.husky ? 'Husky + ' : '' %>`svelte-kit sync`) automatically.
<% } -%>

### Useful Scripts

| Command | Purpose |
| ------- | ------- |
<% for (const [name, text] of useful) { -%>
| `pnpm <%- name %>` | <%- text %> |
<% } -%>

## Branching

- `dev` is the integration branch for ongoing work.
- Branch off `dev` for all changes:
  - `feat/<short-description>` — new feature
  - `fix/<short-description>` — bug fix
  - `chore/<short-description>` — tooling, deps, config
  - `docs/<short-description>` — documentation only
  - `refactor/<short-description>` — internal refactor, no behavior change
- Keep branches small and focused. Rebase on `dev` before opening a pull request.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<optional scope>): <subject>

<optional body explaining why, not what>

<optional footer, e.g. BREAKING CHANGE: ...>
```

**Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `build`, `ci`, `style`, `revert`.

**Subject rules:**

- Imperative mood ("add", not "added"/"adds").
- Lowercase, no trailing period.
- Aim for ≤ 50 characters; hard cap at 72.

**Examples:**

```text
feat(auth): add password reset flow
fix(routing): resolve typed-route mismatch in nav config
chore(deps): bump @sveltejs/kit to 2.59.1
```

Explain _why_ in the body when the reason is not obvious from the diff.

## Code Style

<% if (deps.prettier) { -%>
- **Formatting:** Prettier — run `pnpm format` before committing.<%- deps['lint-staged'] ? ' Husky + `lint-staged` enforce this on commit.' : '' %>
<% } -%>
<% if (deps.eslint) { -%>
- **Linting:** ESLint — run `pnpm lint` locally; CI will reject style violations.
<% } -%>
<% if (deps.typescript) { -%>
- **Types:** TypeScript strict mode. Run `pnpm check` to verify.
<% } -%>
- **Routing:** Use `resolve()` from `$app/paths` for internal links — never hardcode pathname strings. See `.claude/CLAUDE.md` for nav conventions.

## Pull Requests

1. Push your branch and open a pull request against `dev`.
2. Fill in the PR template:
   - **Summary** — what changed and why.
   - **Test plan** — steps a reviewer can run to verify.
   - **Screenshots** — for UI changes.
3. Ensure CI is green (<%- ci %>).
4. Request review from a code owner if `CODEOWNERS` is configured.
5. Squash-merge is preferred unless the branch has a meaningful commit history worth preserving.

### Review Expectations

- Reviewers respond within 2 business days.
- Address review comments by pushing additional commits; do not force-push during active review unless requested.
- Once approved and CI is green, the author merges.

## Reporting Issues

- **Bugs and feature requests:** open a GitHub issue using the appropriate template.
- **Security vulnerabilities:** see [SECURITY.md](./SECURITY.md) — do not open public issues for security reports.
<% if (pkg.license) { -%>

## License

By contributing, you agree that your contributions will be licensed under the project's <%- pkg.license %> license.
<% } -%>
