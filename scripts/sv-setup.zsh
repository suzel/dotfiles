#!/usr/bin/env zsh

# =============================================================================
# SvelteKit Project Setup
# =============================================================================
# Configures a project created with sv: package meta, project structure,
# tooling, database, auth, editor settings and Git.
# Run from the project root. Exits 1 if it is not a SvelteKit project.
# Usage: sv-setup
# Requires: pnpm, jq, yq
# =============================================================================

set -euo pipefail

# Error trap
TRAPZERR() {
  error "Error at ${funcfiletrace[1]}"
  exit 1
}

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

# Approvals
info "Configuring pnpm workspace..."
pnpm -s approve-builds esbuild sharp workerd

# Packages
# TODO: Add other packages
info "Installing packages..."
pnpm add -s -D \
  prettier-plugin-packagejson \
  @ianvs/prettier-plugin-sort-imports \
  @sveltejs/enhanced-img \
  unplugin-icons @iconify-json/logos \
  svelte-sonner \
  schema-dts \
  zod

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
  # https://github.com/IanVS/prettier-plugin-sort-imports
  grep -q prettier-plugin-sort-imports prettier.config.js ||
    sed -i '' -E \
      -e "s|(['\"])prettier-plugin-svelte(['\"])|\1@ianvs/prettier-plugin-sort-imports\2, &|" \
      -e $'s|^([[:space:]]*)plugins: .*|&\\\n\\1importOrder: [\'<BUILTIN_MODULES>\', \'<THIRD_PARTY_MODULES>\', \'\', \'^[$#]\', \'\', \'^[./]\'],|' \
      prettier.config.js
  add_vscode_ext esbenp.prettier-vscode
fi

# Vite
# https://vite.dev
# TODO: ???
if [[ -f vite.config.ts ]]; then
  pnpm pkg set scripts.dev="vite dev --open"

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

# shadcn-svelte
# https://www.shadcn-svelte.com
# info "Configuring shadcn-svelte..."
# pnpm dlx -s shadcn-svelte@latest init \
#   --cwd . \
#   --preset bIkeymG \
#   --base-color neutral \
#   --css src/lib/styles/layout.css \
#   --lib-alias '#lib' \
#   --components-alias '#lib/components' \
#   --ui-alias '#lib/components/ui' \
#   --utils-alias '#lib/utils' \
#   --hooks-alias '#lib/hooks' \
#   --reinstall \
#   --skip-preflight >/dev/null

# Assets
touch static/{manifest.json,humans.txt,llms.txt}
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
if [[ -f compose.yaml ]]; then
  info "Configuring Docker..."
  mkdir -p docker && mv compose.yaml docker/
  if has_dep postgres; then
    port=5432
    while lsof -iTCP:$port -sTCP:LISTEN >/dev/null; do ((port++)); done
    sed -i '' "s|@localhost:5432/|@localhost:$port/|" .env
    port=$port yq -i '.services.db |= (
      .image = "postgres:18-alpine" |
      .ports = ["127.0.0.1:" + strenv(port) + ":5432"] |
      .healthcheck = {
        "test": "pg_isready -h 127.0.0.1 -U $${POSTGRES_USER} -d $${POSTGRES_DB}",
        "interval": "2s",
        "retries": 15
      }
    )' docker/compose.yaml
  fi
  pnpm dlx -s dclint -q --fix docker/compose.yaml ||
    warn "Compose lint errors, run: pnpm dlx dclint docker/compose.yaml"
  pnpm pkg delete 'scripts["db:start"]'
  pnpm pkg set \
    'scripts["docker:up"]'="docker compose up -d --build --wait" \
    'scripts["docker:down"]'="docker compose down"
  set_dotenv COMPOSE_FILE "docker/compose.yaml" .env
  set_dotenv COMPOSE_PROJECT_NAME "${${${PWD:t}:l}//[^a-z0-9_-]/-}" .env
  COMPOSE_PROGRESS=quiet pnpm -s docker:up ||
    warn "Docker services not started, run later: pnpm docker:up"
fi

# Database
# https://orm.drizzle.team
if has_dep drizzle-kit; then
  info "Configuring Drizzle..."
  db=src/lib/server/db
  pnpm add -s -D drizzle-zod
  if [[ -f $db/schema.ts ]]; then
    mkdir -p $db/schema && mv $db/schema.ts $db/schema/index.ts
    sed -i '' '/^export \*/!d' $db/schema/index.ts
    touch $db/schema/common.ts
  fi
  sed -i '' 's|db/schema\.ts|db/schema|' drizzle.config.ts
  grep -q postgresql drizzle.config.ts && add_vscode_ext ckolkman.vscode-postgres
  grep -q sqlite drizzle.config.ts && add_vscode_ext qwtel.sqlite-viewer
fi

# Better-Auth
# https://www.better-auth.com
if has_dep better-auth; then
  info "Configuring Better Auth..."
  [[ -f $db/auth.schema.ts ]] && mv $db/auth.schema.ts $db/schema/auth.ts
  sed -i '' 's|/auth\.schema|/auth|' $db/schema/index.ts
  sed -i '' 's|db/auth\.schema\.ts|db/schema/auth.ts|' package.json
  pnpm auth:schema >/dev/null 2>&1 ||
    warn "Auth schema not generated, run later: pnpm auth:schema"
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
  if grep -qs d1-http drizzle.config.ts; then
    # TODO: 1. pnpm exec wrangler d1 create <name> -> ID to wrangler.jsonc database_id
    # TODO: 2. fill CLOUDFLARE_* in .env, then: pnpm db:generate && pnpm db:migrate
    # TODO: 3. pnpm db:migrate:remote
    yq -i -o=json '.d1_databases = [{
      "binding": "DB",
      "database_name": .name,
      "database_id": "local",
      "migrations_dir": "drizzle"
    }]' wrangler.jsonc
    pnpm pkg delete 'scripts["db:push"]'
    pnpm pkg set \
      'scripts["db:migrate"]'="wrangler d1 migrations apply DB --local" \
      'scripts["db:migrate:remote"]'="wrangler d1 migrations apply DB --remote" \
      'scripts["db:backup"]'="mkdir -p backups && wrangler d1 export DB --remote --output backups/DB-\$(date +%F-%H%M).sql"
    grep -qx '/backups/' .gitignore || echo '/backups/' >>.gitignore
  fi
  pnpm gen >/dev/null
fi

# Migrations
# https://orm.drizzle.team/docs/migrations
if has_dep drizzle-kit; then
  info "Running migrations..."
  pnpm db:generate >/dev/null && pnpm db:migrate >/dev/null ||
    warn "Database not migrated, run later: pnpm db:generate && pnpm db:migrate"
fi

# Claude
# https://www.claude.ai
# TODO: .lsp.json ???
if [[ -d .claude ]]; then
  info "Configuring Claude..."
  # TODO: Remove and move to templates ?
  [[ -f AGENTS.md ]] && mv AGENTS.md .claude/SvelteKit.md

  # settings.json is committed: plugins + their marketplaces only (no personal prefs, env, permissions)
  yq -oj '
    .enabledPlugins |= with_entries(select(.key == ("*typescript*", "*svelte*"))) |
    (.enabledPlugins | keys | map(sub(".*@", ""))) as $m |
    {"extraKnownMarketplaces": (.extraKnownMarketplaces | with_entries(select(.key == $m[]))), "enabledPlugins": .enabledPlugins}
  ' ~/.claude/settings.json >.claude/settings.json

  # .mcp.json is committed: user-scope servers with env/headers (tokens) are never copied,
  # svelte is dropped because the svelte plugin already ships it
  jq -s '
    def secret: ((.env // {}) + (.headers // {}) | length) > 0;
    { mcpServers: ((.[0].mcpServers // {}) + ((.[1].mcpServers // {}) | with_entries(select(.value | secret | not))) | del(.svelte)) }
  ' ../.mcp.json ~/.claude.json >.mcp.json

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
    'scripts["design:spec"]'="design.md spec --rules > .claude/DESIGN.spec.md" \
    'scripts["design:sync"]'="design.md export $design --format css-tailwind > $tokens"
  { pnpm design:spec && pnpm design:sync; } >/dev/null 2>&1 ||
    warn "DESIGN.md not exported, run later: pnpm design:spec && pnpm design:sync"
  [[ -f ${tokens:h}/layout.css ]] && ! grep -q ${tokens:t} ${tokens:h}/layout.css &&
    sed -i '' $'1a\\\n'"@import './${tokens:t}';" ${tokens:h}/layout.css
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
tasks=Svelte
has_dep @sveltejs/adapter-cloudflare && tasks+='|Cloudflare'
vscode_pick tasks.json '.tasks |= map(
  select(.label | test("^_('$tasks'):")) |
  .label |= sub("^_", "") |
  del(.hide)
)'
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
# TODO: Versioning ?
info "Generating Github Action files..."
mkdir -p .github/workflows
add_vscode_ext github.vscode-github-actions

# Docs
# https://github.com/rafazafar/gh-scaffold
info "Generating docs..."
mkdir -p docs
[[ $(pnpm pkg get private) == true ]] || pnpm pkg set license=MIT
repo="$(git config github.user)/$(pnpm pkg get name)"
pnpm dlx -s gh-scaffold@1.0.4 -w \
  --preset strict \
  --issue-templates forms \
  --license "${(L)$(pnpm pkg get license):-none}" \
  --skip GOVERNANCE,MAINTAINERS,CHANGELOG,CODEOWNERS,FUNDING \
  </dev/null >/dev/null
[[ -f LICENSE ]] &&
  sed -i '' "s|<YEAR>|$(date +%Y)|; s|<COPYRIGHT HOLDER>|$(git config user.name)|" LICENSE
sed -i '' "s|(add contact here)|<$(git config user.email)>|" SECURITY.md
echo "* @${repo%/*}" >.github/CODEOWNERS
sed -i '' "s|url: https://github.com\$|&/$repo/blob/HEAD/SUPPORT.md|" \
  .github/ISSUE_TEMPLATE/config.yml

# Last Check
info "Updating dependencies & formatting..."
pnpm -s up
pnpm audit --fix=update >/dev/null || warn "Some vulnerabilities could not be fixed"
pnpm format --log-level=silent
pnpm lint >/dev/null || warn "Lint errors, run: pnpm lint"
pnpm --silent check --threshold error || warn "Type errors, run: pnpm check"

# Git
# TODO: ! git rev-parse -q --verify HEAD >/dev/null; ???
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
# info "Creating GitHub repository..."
# license=$(pnpm pkg get license)
# gh repo create $repo \
#   --source=. \
#   --private \
#   --description "$(pnpm pkg get description)" \
#   --homepage "$(pnpm pkg get homepage)" \
#   --remote=origin \
#   --push \
#   ${license:+--license=$license} \
#   --disable-wiki
# # Secrets & variables
# [[ -f .env.production ]] && gh secret set -f .env.production
# [[ -f .env.production.public ]] && gh variable set -f .env.production.public

success "Completed!"
