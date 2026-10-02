#!/usr/bin/env zsh

# =============================================================================
# SvelteKit Project Setup
# =============================================================================
# Configures a project created with sv: package meta, project structure,
# tooling, database, auth, editor settings and Git.
# Run from the project root. Exits 1 if it is not a SvelteKit project.
# Usage: sv-setup [--admin] [--publish]
#   --admin    also configures shadcn-svelte
#   --publish  also creates the GitHub repository
# Requires: pnpm, jq, yq
# =============================================================================

# Resources:
# https://svelte.dev/docs/kit/service-workers
# https://svelte.dev/docs/kit/migrating-to-sveltekit-3

set -euo pipefail

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m"; }
error() { echo "\033[0;31m❌ $*\033[0m"; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Helper Functions
has_dep() { [[ -n $(pnpm pkg get "devDependencies[\"$1\"]") ]]; }
set_dotenv() { touch $3 && sed -i '' "/^$1=/d" $3 && echo "$1=$2" >>$3; }
add_vscode_ext() { yq -i -oj ".recommendations |= (. + [${(j:,:)${(qqq)@}}] | unique)" .vscode/extensions.json; }
vscode_pick() { grep -v '^\s*//' ~/Library/Application\ Support/Code/User/$1 | yq -oj $2 >.vscode/$1; }

# Checks
has_dep @sveltejs/kit || {
  error "Not a SvelteKit project"
  exit 1
}

# Update package meta
info "Updating package meta..."
pnpm pkg set \
  version="0.0.1" \
  type="module" \
  author.name="$(git config user.name || echo '')" \
  author.email="$(git config user.email || echo '')" \
  engines.node=">=$(node -v | cut -c 2- | cut -d. -f1)" \
  engines.pnpm=">=$(pnpm --version | cut -d. -f1)" \
  packageManager="pnpm@$(pnpm --version)" \
  scripts.clean="rm -rf node_modules/.vite .svelte-kit build"

# Project Structure
info "Creating project structure..."
mkdir -p \
  scripts \
  src/lib/{config,remote,schemas,state,styles,types,utils} \
  src/lib/components/{layout,ui} \
  src/lib/server/services \
  src/routes/"(meta)"/{robots.txt,sitemap.xml} \
  $(has_dep @sveltejs/adapter-static || echo src/routes/api)

# Project Files
info "Creating project files..."
node --version | cut -d 'v' -f 2 >.node-version
touch \
  src/hooks.client.ts \
  src/lib/components/layout/{Header,Footer,GoogleAnalytics}.svelte \
  $(has_dep @sveltejs/adapter-static && echo src/routes/+layout.ts)
# TODO: ?
if has_dep @sveltejs/adapter-static; then
  grep -qs 'prerender' src/routes/+layout.ts || echo "export const prerender = true;" >>src/routes/+layout.ts
fi

# Build scripts allowlist
info "Configuring pnpm workspace..."
pnpm -s approve-builds esbuild sharp workerd

# Packages
info "Installing packages..."
pnpm add -s -D \
  prettier-plugin-packagejson \
  @sveltejs/enhanced-img \
  unplugin-icons @iconify-json/logos \
  svelte-sonner \
  schema-dts \
  zod

# License & publish metadata
# TODO: License type ?
if [[ $(pnpm pkg get private) != true ]]; then
  pnpm pkg set license="MIT"
fi

# ESLint
# https://eslint.org
if has_dep eslint; then
  sed -i '' "s/rules: {}/rules: { 'svelte\/no-at-html-tags': 'off' }/" eslint.config.js
  add_vscode_ext dbaeumer.vscode-eslint
fi

# Prettier
# https://prettier.io
if has_dep prettier; then
  sed -i '' 's/useTabs: true/useTabs: false/' prettier.config.js
  grep -q prettier-plugin-packagejson prettier.config.js ||
    sed -i '' -E "s/(['\"])prettier-plugin-svelte(['\"])/&, \1prettier-plugin-packagejson\2/" prettier.config.js
  add_vscode_ext esbenp.prettier-vscode
fi

# Vite
# https://vite.dev
pnpm pkg set scripts.dev="vite dev --open"
if ! grep -q enhancedImages vite.config.ts; then

  sed -i '' $'s|^import { sveltekit } from .@sveltejs/kit/vite.;$|&\\\nimport { enhancedImages } from \'@sveltejs/enhanced-img\';|' vite.config.ts
  sed -i '' $'s|^\\(\t*\\)sveltekit(|\\1enhancedImages(),\\\n\\1sveltekit(|' vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)plugins: \[|\1logLevel: 'warn',\n&|" vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)plugins: \[|\1build: {\n\1\1reportCompressedSize: false\n\1},\n&|" vite.config.ts

  if has_dep @sveltejs/adapter-static; then
    sed -i '' "s|^\([[:space:]]*\)adapter: adapter(),|\1adapter: adapter({\n\1\tpages: 'build',\n\1\tassets: 'build',\n\1\tfallback: '404.html',\n\1\tprecompress: false,\n\1\tstrict: true\n\1}),|" vite.config.ts
    # sed -i '' "s|^\([[:space:]]*\)adapter: adapter(|\1inlineStyleThreshold: 16384,\n\1prerender: {\n\1\torigin: 'https://www.domain.com'\n\1},\n&|" vite.config.ts
  fi

  sed -i '' $'s|^import { sveltekit }.*|&\\\nimport Icons from \'unplugin-icons/vite\';|' vite.config.ts
  sed -i '' $'s/^\t\t})$/\t\t}),/;s/^\t]$/\t\tIcons({ compiler: \'svelte\' })\\\n&/' vite.config.ts
  sed -i '' $'1s|^|import \'unplugin-icons/types/svelte\';\\\n\\\n|' src/app.d.ts
fi

# Husky
# https://github.com/typicode/husky
info "Configuring Husky & lint-staged..."
[ -d .git ] || git init -q -b main
pnpm add -s -D husky
pnpm exec husky
echo 'pnpm lint-staged' >.husky/pre-commit
prepush='pnpm lint && pnpm check'
has_dep vitest && prepush+=' && pnpm test'
echo "$prepush" >.husky/pre-push
pnpm pkg set scripts.prepare="husky && svelte-kit sync || echo ''"

# Lint-staged
# https://github.com/lint-staged/lint-staged
pnpm add -s -D lint-staged
echo "/** @type {import('lint-staged').Configuration} */
export default {
  '*.{js,ts,svelte}': ['eslint --fix', 'prettier --write'],
  '*.{css,html,json,md,yaml,yml}': ['prettier --write']
};" >lint-staged.config.js
pnpm pkg set scripts.lint-staged="lint-staged"

# TailwindCSS
# https://tailwindcss.com
if has_dep tailwindcss; then
  info "Configuring TailwindCSS..."
  old=src/routes/layout.css
  new=src/lib/styles/layout.css
  if [[ -f $old ]]; then
    mv $old $new
    sed -i "" "s|import './${old:t}';|import '#${new#src/}';|" src/routes/+layout.svelte
    sed -i "" "s|tailwindStylesheet: './$old'|tailwindStylesheet: './$new'|" prettier.config.js
  fi
  add_vscode_ext bradlc.vscode-tailwindcss
fi

# shadcn-svelte (opt-in: sv-setup --admin)
# https://www.shadcn-svelte.com
if ((${argv[(Ie)--admin]})); then
  info "Configuring shadcn-svelte..."
  pnpm dlx -s shadcn-svelte@latest init \
    --cwd . \
    --preset bIkeymG \
    --base-color neutral \
    --css src/lib/styles/layout.css \
    --lib-alias '#lib' \
    --components-alias '#lib/components' \
    --ui-alias '#lib/components/ui' \
    --utils-alias '#lib/utils' \
    --hooks-alias '#lib/hooks' \
    --reinstall \
    --skip-preflight >/dev/null
fi

# Web files
[[ -f "static/robots.txt" ]] && rm static/robots.txt
if [[ -f "src/lib/assets/favicon.svg" ]]; then
  info "Generating favicons..."
  mkdir -p static/img/favicons
  mv -f src/lib/assets/favicon.svg static/img/favicons/favicon.svg &&
    rmdir src/lib/assets &&
    sed -i '' '/favicon/d' src/routes/+layout.svelte &&
    pnpm dlx -s @vite-pwa/assets-generator@latest \
      --preset minimal-2023 \
      static/img/favicons/favicon.svg >/dev/null
fi

# Docker
# https://www.docker.com
if has_dep drizzle-kit; then
  info "Configuring Docker..."
  rm -f compose.yaml && mkdir -p docker/sql
  pnpm dlx -s dclint -q --fix docker/compose.yaml
  pnpm pkg set \
    'scripts["docker:up"]'="docker compose up -d --build" \
    'scripts["docker:down"]'="docker compose down" \
    'scripts["db:start"]'="docker compose up -d --wait postgres"
  set_dotenv COMPOSE_FILE "docker/compose.yaml:docker/compose.dev.yaml" .env
  if has_dep postgres; then
    set_dotenv POSTGRES_USER root .env
    set_dotenv POSTGRES_PASSWORD mysecretpassword .env
    set_dotenv POSTGRES_DB local .env
    pnpm db:start || warn "Database not started, run later: pnpm db:start"
  fi
fi

# Database
# https://orm.drizzle.team
if has_dep drizzle-kit; then
  info "Configuring Drizzle..."
  pnpm pkg set \
    'scripts["db:studio"]'="(sleep 2 && open https://local.drizzle.studio) & drizzle-kit studio" \
    'scripts["db:push"]'="drizzle-kit push --force"
  sed -i '' 's/strict: true/strict: false/' drizzle.config.ts
  add_vscode_ext ckolkman.vscode-postgres
  pnpm db:generate >/dev/null && pnpm db:migrate >/dev/null ||
    warn "Database not migrated, run later: pnpm db:generate && pnpm db:migrate"
fi

# Better-Auth
# https://www.better-auth.com
if has_dep better-auth; then
  info "Configuring Better Auth..."
  pnpm auth:schema
  pnpm db:generate >/dev/null && pnpm db:migrate >/dev/null ||
    warn "Auth tables not created, run later: pnpm db:generate && pnpm db:migrate"
fi

# Cloudflare
# https://svelte.dev/docs/kit/adapter-cloudflare
if has_dep @sveltejs/adapter-cloudflare; then
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
  # TODO: Remove and move to templates ?
  [[ -f AGENTS.md ]] && mv AGENTS.md .claude/SvelteKit.md

  yq -oj '
    del(.hooks, .extraKnownMarketplaces, .permissions, .modelSettings, .skillListing*) |
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

  has_dep prettier && echo "/.claude/skills/" >>.prettierignore
  add_vscode_ext anthropic.claude-code
fi

# DESIGN.md
# https://github.com/google-labs-code/design.md
if [[ -d .claude ]]; then
  info "Configuring DESIGN.md..."
  design=.claude/DESIGN.md
  tokens=src/lib/styles/design-tokens.css
  pnpm add -s -D @google/design.md
  pnpm pkg set \
    'scripts["design:lint"]'="design.md lint $design" \
    'scripts["design:spec"]'="design.md spec --rules > docs/DESIGN.spec.md" \
    'scripts["design:sync"]'="design.md export $design --format css-tailwind > $tokens"
  pnpm design:spec >/dev/null 2>&1 && pnpm design:sync >/dev/null 2>&1
  #   grep -qF "@import './${tokens:t}';" "${tokens:h}/layout.css" ||
  #     sed -i '' $'1a\\\n'"@import './${tokens:t}';" ${tokens:h}/layout.css
  sed -i '' "s/\]\$/],/;/^};\$/i\\
  '$design': [\\
    'pnpm design:lint',\\
    () => 'pnpm design:sync',\\
    () => 'git add $tokens'\\
  ]" lint-staged.config.js
fi

# VSCode
# https://code.visualstudio.com
info "Configuring VSCode..."
vscode_pick tasks.json '.tasks |= map(select(.label == "Svelte*"))'
vscode_pick settings.json 'with_entries(select(.key == (
  "files.*",
  "explorer.fileNesting.*",
  "tailwindCSS.*",
  "editor.codeActionsOnSave",
  "editor.quickSuggestions",
  "editor.defaultFormatter",
  "editor.foldingStrategy",
  "editor.format*",
  "js/ts.*",
  "svelte.*",
  "[svelte]",
  "eslint.*"
)))'
add_vscode_ext \
  svelte.svelte-vscode \
  antfu.iconify \
  christian-kohler.path-intellisense \
  usernamehw.errorlens \
  formulahendry.auto-rename-tag \
  editorconfig.editorconfig

# Github Actions
# TODO: Dependabot / Renovate → Auto PR
# TODO: Versioning ?
info "Generating Github Action files..."
mkdir -p .github/workflows
add_vscode_ext github.vscode-github-actions

# Docs
# TODO: Doc templates, e.g. DESIGN.md, ARCHITECTURE.md, ROADMAP.md, etc.
# https://github.com/rafazafar/gh-scaffold
info "Generating docs..."
mkdir -p docs
pnpm dlx -s gh-scaffold@1.0.4 -w \
  --preset strict \
  --issue-templates forms \
  --license "${$(pnpm pkg get license | tr A-Z a-z):-none}" \
  --skip GOVERNANCE,MAINTAINERS,CHANGELOG \
  </dev/null >/dev/null
[[ -f LICENSE ]] &&
  sed -i '' "s|<YEAR>|$(date +%Y)|; s|<COPYRIGHT HOLDER>|$(git config user.name)|" LICENSE
sed -i '' "s|(add contact here)|$(git config user.email)|" SECURITY.md

# Last Check
info "Updating dependencies & formatting..."
pnpm -s up
pnpm audit --fix=update >/dev/null || warn "Some vulnerabilities could not be fixed"
pnpm format --log-level=silent
pnpm lint >/dev/null || warn "Lint errors, run: pnpm lint"
pnpm --silent check --threshold error || warn "Type errors, run: pnpm check"

# Git
repo="$(git config github.user)/$(pnpm pkg get name)"
if ! git rev-parse -q --verify HEAD >/dev/null; then
  info "Creating initial commit..."
  pnpm pkg set \
    repository.type="git" \
    repository.url="git+https://github.com/$repo.git" \
    bugs.url="https://github.com/$repo/issues"
  git add .
  git switch -q -c dev
  git commit -q -m "Initial commit"
fi

# GitHub (opt-in: sv-setup --publish)
# TODO: .env.production.public ???
if ((${argv[(Ie)--publish]})); then
  info "Creating GitHub repository..."
  license=$(pnpm pkg get license)
  gh repo create $repo \
    --source=. \
    --private \
    --description "$(pnpm pkg get description)" \
    --homepage "$(pnpm pkg get homepage)" \
    --remote=origin \
    --push \
    ${license:+--license=$license} \
    --disable-wiki
  # Secrets & variables
  [[ -f .env.production ]] && gh secret set -f .env.production
  [[ -f .env.production.public ]] && gh variable set -f .env.production.public
fi

success "Completed!"
