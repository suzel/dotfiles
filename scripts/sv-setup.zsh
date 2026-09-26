#!/usr/bin/env zsh

# sv setup script
# Run from the project root. Exits 1 when a ❌ check fails, so it can gate CI.

set -euo pipefail

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m"; }
error() { echo "\033[0;31m❌ $*\033[0m"; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Helper Functions
installed() { [[ -n $(pnpm pkg get "devDependencies[\"$1\"]") ]]; }
envset() { pnpm dlx -s @dotenvx/dotenvx set "$1" "$2" --plain -q -f "${3:-.env,.env.example}"; }
vsext() { IDS="$*" yq -i -oj '.recommendations |= (. + (strenv(IDS) | split(" ")) | unique)' .vscode/extensions.json; }
template() { pnpm dlx -s ejs -n -l pkg ~/Projects/dotfiles/templates/$1.ejs.t -f package.json -o "${2:-${1:t}}"; }

# Checks
installed @sveltejs/kit || {
  error "Not a SvelteKit project"
  exit 1
}

# Update package meta
info "Updating package meta..."
pnpm pkg set \
  version="0.0.1" \
  author.name="$(git config user.name || echo '')" \
  author.email="$(git config user.email || echo '')" \
  type="module" \
  packageManager="pnpm@$(pnpm --version)" \
  scripts.clean="rm -rf .svelte-kit build node_modules/.vite .wrangler" \
  scripts.dev="vite dev --open" \
  engines.node=">=$(node -p 'process.versions.node.split(".")[0]')" \
  engines.pnpm=">=$(pnpm --version | cut -d. -f1)"

# Project Structure
info "Creating project structure..."
mkdir -p \
  .github/workflows \
  docs \
  scripts \
  src/lib/{config,styles,types,utils} \
  src/lib/components/layout \
  $(installed @sveltejs/adapter-static || echo src/lib/{remote,stores}) \
  $(installed @sveltejs/adapter-static || echo src/lib/components/admin/ui) \
  $(installed @sveltejs/adapter-static || echo src/lib/server/{db,images,integrations,services,storage}) \
  $(installed @sveltejs/adapter-static || echo src/params) \
  $(installed @sveltejs/adapter-static || echo src/routes/{admin,api})

# Project Files
info "Creating project files..."
node --version | cut -d 'v' -f 2 >.node-version
touch \
  src/{hooks.client,service-workers}.ts \
  src/lib/components/layout/{Header,Footer,GoogleAnalytics}.svelte
if installed @sveltejs/adapter-static; then
  grep -qs 'prerender' src/routes/+layout.ts || echo "export const prerender = true;" >>src/routes/+layout.ts
fi

# Build scripts allowlist
info "Configuring pnpm workspace..."
echo "allowBuilds:
  esbuild: true
  sharp: true
  workerd: true
update:
  ignoreDeps:
    - typescript" >pnpm-workspace.yaml

# Packages
info "Installing packages..."
packages=(
  @sveltejs/enhanced-img
  unplugin-icons @iconify-json/logos
  prettier-plugin-packagejson
  svelte-check
  schema-dts
  zod
  svelte-sonner
)
pnpm add -s -D --loglevel warn $packages

# License & publish metadata
if [[ $(pnpm pkg get private) != true ]]; then
  pnpm pkg set license="MIT"
  template docs/LICENSE
fi

# ESLint
if installed eslint; then
  sed -i '' "s/rules: {}/rules: { 'svelte\/no-at-html-tags': 'off' }/" eslint.config.js
  vsext dbaeumer.vscode-eslint
fi

# Prettier
if installed prettier; then
  sed -i '' 's/useTabs: true/useTabs: false/' prettier.config.js
  grep -q prettier-plugin-packagejson prettier.config.js ||
    sed -i '' -E "s/(['\"])prettier-plugin-svelte(['\"])/&, \1prettier-plugin-packagejson\2/" prettier.config.js
  vsext esbenp.prettier-vscode
fi

# Vite plugins
if ! grep -q enhancedImages vite.config.ts; then

  sed -i '' $'s|^import { sveltekit } from .@sveltejs/kit/vite.;$|&\\\nimport { enhancedImages } from \'@sveltejs/enhanced-img\';|' vite.config.ts
  sed -i '' $'s|^\\(\t*\\)sveltekit(|\\1enhancedImages(),\\\n\\1sveltekit(|' vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)plugins: \[|\1logLevel: 'warn',\n&|" vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)plugins: \[|\1build: {\n\1\1reportCompressedSize: false\n\1},\n&|" vite.config.ts

  if installed @sveltejs/adapter-static; then
    sed -i '' "s|^\([[:space:]]*\)adapter: adapter(),|\1adapter: adapter({\n\1\tpages: 'build',\n\1\tassets: 'build',\n\1\tfallback: '404.html',\n\1\tprecompress: false,\n\1\tstrict: true\n\1}),|" vite.config.ts
    sed -i '' "s|^\([[:space:]]*\)adapter: adapter(|\1inlineStyleThreshold: 16384,\n\1prerender: {\n\1\torigin: 'https://www.domain.com'\n\1},\n&|" vite.config.ts
  fi

  sed -i '' $'s|^import { sveltekit }.*|&\\\nimport Icons from \'unplugin-icons/vite\';|' vite.config.ts
  sed -i '' $'s/^\t\t})$/\t\t}),/;s/^\t]$/\t\tIcons({ compiler: \'svelte\' })\\\n&/' vite.config.ts
  sed -i '' $'1s|^|import \'unplugin-icons/types/svelte\';\\\n\\\n|' src/app.d.ts
fi

# Husky &  Lint-staged
info "Configuring Husky & lint-staged..."
[ -d .git ] || git init -q
pnpm add -D -s --loglevel warn husky lint-staged
pnpm exec husky
echo 'pnpm lint-staged' >.husky/pre-commit
prepush='pnpm lint && pnpm check'
installed vitest && prepush+=' && pnpm test'
echo "$prepush" >.husky/pre-push
echo "/** @type {import('lint-staged').Configuration} */
export default {
  '*.{js,ts,svelte}': ['eslint --fix', 'prettier --write'],
  '*.{css,html,json,md,yaml,yml}': ['prettier --write']
};" >lint-staged.config.js
pnpm pkg set \
  scripts.prepare="husky && svelte-kit sync || echo ''" \
  scripts.lint-staged="lint-staged"

# TailwindCSS
if installed tailwindcss; then
  info "Configuring TailwindCSS..."
  old=src/routes/layout.css
  new=src/lib/styles/layout.css
  if [[ -f $old ]]; then
    mv $old $new
    sed -i "" "s|import './${old:t}';|import '#${new#src/}';|" src/routes/+layout.svelte
    sed -i "" "s|tailwindStylesheet: './$old'|tailwindStylesheet: './$new'|" prettier.config.js
  fi
  vsext bradlc.vscode-tailwindcss
fi

# shadcn-svelte
# https://www.shadcn-svelte.com/
# info "Configuring shadcn-svelte..."
# touch src/lib/styles/shadcn.css
# pnpm dlx -s shadcn-svelte@latest init \
#   --cwd . \
#   --preset bIkeymG \
#   --base-color neutral \
#   --css src/lib/styles/shadcn.css \
#   --lib-alias '#lib' \
#   --components-alias '#lib/components' \
#   --ui-alias '#lib/components/ui' \
#   --utils-alias '#lib/utils' \
#   --hooks-alias '#lib/hooks' \
#   --reinstall \
#   --skip-preflight >/dev/null

# Web files
template assets/humans.txt static/humans.txt
template assets/llms.txt static/llms.txt
template assets/manifest.json static/manifest.json
template assets/app.html src/app.html
template svelte/robots.ts "src/routes/(meta)/robots.txt/+server.ts"
template svelte/sitemap.ts "src/routes/(meta)/sitemap.xml/+server.ts"

info "Generating favicons..."
mv -f src/lib/assets/favicon.svg static/img/favicons/favicon.svg &&
  rmdir src/lib/assets &&
  sed -i '' '/favicon/d' src/routes/+layout.svelte &&
  npx @vite-pwa/assets-generator@latest \
    --preset minimal-2023 \
    static/img/favicons/favicon.svg >/dev/null

# Docker
# https://www.docker.com
if installed drizzle-kit; then
  info "Configuring Docker..."
  rm -f compose.yaml && mkdir -p docker/sql
  touch docker/{compose.dev.yaml,Dockerfile,Dockerfile.dockerignore}
  template docker/compose.yaml docker/compose.yaml
  template docker/init.sql docker/sql/init.sql
  pnpm dlx -s dclint -q --fix docker/compose.yaml
  pnpm pkg set \
    'scripts["docker:up"]'="docker compose up -d --build" \
    'scripts["docker:down"]'="docker compose down" \
    'scripts["db:start"]'="docker compose up -d --wait postgres"
  envset COMPOSE_FILE "docker/compose.yaml:docker/compose.dev.yaml" .env
  if installed postgres; then
    # sv's DATABASE_URL defaults: postgres://root:mysecretpassword@localhost:5432/local
    envset POSTGRES_USER root
    envset POSTGRES_PASSWORD mysecretpassword
    envset POSTGRES_DB local
    pnpm db:start || warn "Database not started, run later: pnpm db:start"
  fi
fi

# Database
# https://orm.drizzle.team
if installed drizzle-kit; then
  info "Configuring Drizzle..."
  pnpm pkg set \
    'scripts["db:studio"]'="(sleep 2 && open https://local.drizzle.studio) & drizzle-kit studio" \
    'scripts["db:push"]'="drizzle-kit push --force"
  sed -i '' 's/strict: true/strict: false/' drizzle.config.ts
  vsext ckolkman.vscode-postgres
  pnpm db:generate >/dev/null && pnpm db:migrate >/dev/null ||
    warn "Database not migrated, run later: pnpm db:generate && pnpm db:migrate"
fi

# Better-Auth
# https://www.better-auth.com
if installed better-auth; then
  info "Configuring Better Auth..."
  envset BETTER_AUTH_SECRET "$(openssl rand -base64 32)" .env
  envset RATE_LIMIT_MAX 100
  envset RATE_LIMIT_WINDOW 60
  pnpm auth:schema
  pnpm db:generate >/dev/null && pnpm db:migrate >/dev/null ||
    warn "Auth tables not created, run later: pnpm db:generate && pnpm db:migrate"
fi

# Cloudflare
# https://svelte.dev/docs/kit/adapter-cloudflare
if installed @sveltejs/adapter-cloudflare; then
  info "Configuring Cloudflare..."
  export WRANGLER_SEND_METRICS=false WRANGLER_LOG=error
  yq -i -o=json '
    .compatibility_flags = ["nodejs_compat"] |
    .vars.NODE_ENV = "production"
  ' wrangler.jsonc
fi

# Claude
if [[ -d .claude ]]; then
  info "Configuring Claude..."
  [[ -f AGENTS.md ]] && mv AGENTS.md .claude/SvelteKit.md
  template claude/CLAUDE.md .claude/CLAUDE.md

  yq -oj '
    del(.hooks, .extraKnownMarketplaces, .permissions, .modelSettings) |
    .enabledPlugins |= with_entries(select(.key == ("*typescript*", "*svelte*")))
  ' ~/.claude/settings.json >.claude/settings.json
  jq -s '{ mcpServers: (map(.mcpServers // {}) | add) }' \
    ../.mcp.json <(jq '{ mcpServers: (.mcpServers // {}) }' ~/.claude.json) >.mcp.json

  lsp_exclude=(gopls)
  plugins=$(claude plugin list --json | jq -c 'map(select(.enabled))')
  manifests=(~/.claude/plugins/marketplaces/*/.claude-plugin/marketplace.json ${(f)"$(jq -r '.[].installPath + "/.claude-plugin/plugin.json"' <<<$plugins)"})
  jq -n --argjson on "$plugins" '
    [inputs | if .plugins then .name as $m | .plugins[] | select("\(.name)@\($m)" | IN($on[].id)) end | .lspServers // empty]
    | add // {} | del(.[$ARGS.positional[]])' ${^manifests}(N) --args $lsp_exclude >.lsp.json

  installed prettier && echo "/.claude/skills/" >>.prettierignore
  vsext anthropic.claude-code
fi

# DESIGN.md
# https://github.com/google-labs-code/design.md
if [[ -d .claude ]]; then
  info "Configuring DESIGN.md..."
  design=.claude/DESIGN.md
  tokens=src/lib/styles/design-tokens.css
  lsc=lint-staged.config.js
  template claude/DESIGN.md $design
  pnpm add -D -s --loglevel error @google/design.md
  pnpm pkg set \
    'scripts["design:lint"]'="design.md lint $design" \
    'scripts["design:spec"]'="design.md spec --rules > docs/DESIGN.spec.md" \
    'scripts["design:sync"]'="design.md export $design --format css-tailwind > $tokens"
  pnpm design:spec && pnpm design:sync
  sed -i '' $'1a\\\n'"@import './${tokens:t}';" ${tokens:h}/layout.css
  sed -i '' "s/\]\$/],/;/^};\$/i\\
  '$design': [\\
    'pnpm design:lint',\\
    () => 'pnpm design:sync',\\
    () => 'git add $tokens'\\
  ]" $lsc
  pnpm prettier --write $lsc
fi

# VSCode
# https://code.visualstudio.com
info "Configuring VSCode..."
vscat=(grep -v '^\s*//' ~/Library/Application\ Support/Code/User)
$vscat/tasks.json | yq -oj '.tasks |= map(select(.label == "Svelte*"))' >.vscode/tasks.json
$vscat/settings.json | yq -oj 'with_entries(select(.key == (
  "files.exclude",
  "files.associations",
  "explorer.fileNesting.*",
  "tailwindCSS.experimental.classRegex",
  "editor.codeActionsOnSave",
  "editor.quickSuggestions",
  "editor.defaultFormatter",
  "editor.foldingStrategy",
  "editor.formatOnSave",
  "editor.formatOnPaste",
  "js/ts.*",
  "svelte.*",
  "[svelte]",
  "eslint.validate"
)))' >.vscode/settings.json
vsext \
  svelte.svelte-vscode \
  antfu.iconify \
  christian-kohler.path-intellisense \
  usernamehw.errorlens \
  formulahendry.auto-rename-tag \
  editorconfig.editorconfig

# Github Actions
# TODO: Dependabot / Renovate → Auto PR
# TODO: Versioning ?
template github/deploy.yml .github/workflows/deploy.yml
template github/ci.yml .github/workflows/ci.yml
vsext github.vscode-github-actions

# Docs
info "Generating docs..."
template docs/README.md
template docs/CONTRIBUTING.md
template docs/SECURITY.md
template docs/DOCS_README.md docs/README.md

# Last Check
info "Updating dependencies & formatting..."
pnpm audit --fix >/dev/null || warn "Some vulnerabilities could not be fixed"
pnpm up --loglevel error
pnpm --loglevel silent format --log-level=warn

# Git
if [[ -d .git ]]; then
  info "Initializing Git repository..."
  template git/gitignore .gitignore
  git init -q -b main
  git add .
  git commit -q -m "Initial commit"
  git switch -q -c dev
  git remote add origin https://github.com/suzel/sveltekit-project.git
  pnpm pkg set \
    repository.type="git" \
    repository.url="git+https://github.com/suzel/sveltekit-project.git" \
    bugs.url="https://github.com/suzel/sveltekit-project/issues"
fi

# TODO: gh cli
# gh repo create suzel/repo \
#   --source=. \
#   --private \
#   --description "Project" \
#   --homepage "https://github.com/suzel/sveltekit-project" \
#   --remote=origin \
#   --push \
#   --license MIT \
#   --disable-issues \
#   --disable-wiki

# Set secret & variables
# gh secret set DATABASE_URL --body "postgres://user:password@host:5432/dbname"
# gh variable set PUBLIC_GA_MEASUREMENT_ID --body ""
# gh variable set PUBLIC_SITE_URL --body "https://yourdomain.com"
