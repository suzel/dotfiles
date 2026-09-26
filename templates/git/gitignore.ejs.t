<%# pnpm dlx ejs -n -l pkg gitignore.ejs.t -f package.json -o .gitignore -%>
<%_
  const deps = { ...pkg.dependencies, ...pkg.devDependencies }
  // adapters that write the compiled app to /build
  const buildDir = ['static', 'node', 'netlify'].some((name) => deps[`@sveltejs/adapter-${name}`])
  // conditional sections mirror what `sv add` appends, so re-rendering doesn't drop them
-%>
# macOS
._*
.AppleDouble
.DS_Store
.LSOverride
.Spotlight-V100
.Trashes

# VSCode
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
!.vscode/*.code-snippets

# Node.js
node_modules
<% if (deps.eslint) { -%>

# ESLint
.eslintcache
<% } -%>

# Environment
.env
.env.*
!.env.example
!.env.test

# Vite
vite.config.js.timestamp-*
vite.config.ts.timestamp-*

# SvelteKit
/.svelte-kit
<% if (buildDir) { -%>
/build
<% } else { -%>
.output
<% } -%>
<% if (deps.wrangler || deps['@sveltejs/adapter-cloudflare']) { -%>

# Cloudflare
.wrangler
<% } -%>
<% if (deps['@playwright/test']) { -%>

# Playwright
test-results
<% } -%>
<% if (deps['better-sqlite3'] || deps['@libsql/client']) { -%>

# SQLite
*.db
<% } -%>
<% if (deps['@inlang/paraglide-js']) { -%>

# Paraglide
src/lib/paraglide
project.inlang/cache/
<% } -%>
