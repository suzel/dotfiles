#!/usr/bin/env zsh

# =============================================================================
# SvelteKit Project Setup
# =============================================================================
# Configures a project created with sv: package meta, tooling,
# database, auth, editor settings and Git.
# Run once from the project root, right after sv create
# (with prettier + eslint). Commits sv's output first, so every change
# of this script is one reviewable commit.
# Usage: sv-setup.zsh
# Requires: pnpm, node, git, gh, jq, yq
# docker for compose projects
# =============================================================================

set -euo pipefail

readonly DOTFILES=${0:A:h:h}
readonly GIT_ID=~/.config/git/config.local
readonly AUTHOR_NAME=$(git config -f $GIT_ID user.name || true)
readonly AUTHOR_EMAIL=$(git config -f $GIT_ID user.email || true)
readonly GH_USER=$(gh api user -q .login 2>/dev/null || true)
readonly NODE_MAJOR=${${$(node -v)#v}%%.*}
readonly NAME=$(pnpm pkg get name 2>/dev/null || true)
readonly HOMEPAGE=${$(pnpm pkg get homepage 2>/dev/null):-https://$NAME${${NAME:#*.*}:+.com}}

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Helper Functions
has_dep() { [[ $(pnpm pkg get {d,devD}ependencies"['$1']") == *:* ]]; }
add_vscode_ext() { yq -i ".recommendations += [${(j:,:)${(qqq)@}}]" .vscode/extensions.json; }
set_dotenv() { touch $3 && sed -i '' "/^$1=/d" $3 && print -r -- "$1=$2" >>$3; }
sed_patch() { local b=$(<$1) && sed -i '' "${@:2}" $1 && [[ $(<$1) != "$b" ]]; }
jsonc() { grep -v '^\s*//' $1; }
pick_tasks() { yq -py -oj ".tasks |= filter(.label == (${(j:,:)${(qqq)@}}))"; }
pick_keys() { yq -py -oj "with_entries(select(.key == (${(j:,:)${(qqq)@}})))"; }
merge_json() { touch $1 && yq -i -py -oj '. * load("/dev/stdin")' $1; }

# Error trap
TRAPZERR() { error "Error at ${funcfiletrace[-1]}"; }

# Checks
[[ -f package.json ]] && has_dep @sveltejs/kit || {
  error "Not a SvelteKit project: run from its root"
  exit 1
}

# husky needs a repo
[[ -d .git ]] || git init -q -b main

# Update package meta
info "Updating package meta..."
pnpm pkg set \
  homepage="$HOMEPAGE" \
  author.name="$AUTHOR_NAME" \
  author.email="$AUTHOR_EMAIL" \
  engines.node=">=$NODE_MAJOR" \
  packageManager="pnpm@$(pnpm --version)" \
  scripts.clean="rm -rf node_modules/.vite .svelte-kit build"

# Project Structure
info "Creating project folders..."
is_dynamic=$(has_dep @sveltejs/adapter-static || echo 1)
mkdir -p \
  src/lib/components \
  src/lib/types \
  ${is_dynamic:+src/lib/server} \
  ${is_dynamic:+src/lib/remote} \
  ${is_dynamic:+src/lib/schemas}

# Demos
if [[ -d src/routes/demo ]]; then
  info "Removing demos..."
  e2e=src/routes/demo/playwright/page.svelte.e2e.ts
  [[ -f $e2e ]] &&
    sed 's|/demo/playwright|/|' $e2e >src/routes/page.svelte.e2e.ts
  rm -rf src/routes/demo
fi

# Update project files
info "Updating project files..."
echo ${$(node -v)#v} >.node-version

# Build Approvals
info "Configuring pnpm workspace..."
pnpm -s approve-builds \
  esbuild sharp workerd

# Packages
info "Installing packages..."
pnpm add -s -D \
  unplugin-icons \
  @iconify-json/logos \
  svelte-sonner \
  zod \
  schema-dts

# TailwindCSS
# https://tailwindcss.com
if has_dep tailwindcss; then
  info "Configuring TailwindCSS..."
  mkdir -p src/lib/styles
  mv src/routes/layout.css src/lib/styles/layout.css
  sed_patch src/routes/+layout.svelte \
    -e "s|import './layout.css';|import '#lib/styles/layout.css';|"
  sed_patch prettier.config.js -e 's|routes/layout|lib/styles/layout|'
  # add_vscode_ext bradlc.vscode-tailwindcss (sv already adds it)
fi

# ESLint
# https://eslint.org
info "Configuring ESLint..."
sed_patch eslint.config.js \
  -e "s|rules: {}|rules: { 'svelte/no-at-html-tags': 'off' }|"

# Prettier
# https://prettier.io
# https://github.com/IanVS/prettier-plugin-sort-imports
# https://github.com/matzkoh/prettier-plugin-packagejson
info "Configuring Prettier..."
pnpm add -s -D \
  prettier-plugin-packagejson \
  @ianvs/prettier-plugin-sort-imports
order="['<BUILTIN_MODULES>', '<THIRD_PARTY_MODULES>', '', '^[#$]', '', '^[./]']"
sed_patch prettier.config.js -e 's/useTabs: true/useTabs: false/'
sed_patch prettier.config.js \
  -e "s|'prettier-plugin-svelte'|'@ianvs/prettier-plugin-sort-imports', &|" \
  -e "s|'prettier-plugin-svelte'|&, 'prettier-plugin-packagejson'|"
sed_patch prettier.config.js -E -e "s|^([[:space:]]*)plugins: .*|&\\
\\1importOrder: $order,|"

# Husky
# https://github.com/typicode/husky
info "Configuring Husky..."
pnpm add -s -D husky
pnpm exec husky >/dev/null
pnpm pkg set scripts.prepare="husky && svelte-kit sync || echo ''"
prepush='pnpm lint && pnpm check'
has_dep vitest && prepush+=' && pnpm test'
echo "$prepush" >.husky/pre-push

# lint-staged
# https://github.com/lint-staged/lint-staged
info "Configuring lint-staged..."
pnpm add -s -D lint-staged
echo 'pnpm exec lint-staged' >.husky/pre-commit
echo "/** @type {import('lint-staged').Configuration} */
export default {
  '*.{js,ts,svelte}': ['eslint --fix', 'prettier --write'],
  '*.{css,html,json,md,yaml,yml}': ['prettier --write']
};" >lint-staged.config.js

# Docker
# https://www.docker.com
if [[ -f compose.yaml ]]; then
  info "Configuring Docker..."
  mkdir -p docker && mv compose.yaml docker/
  touch docker/{compose.dev.yaml,Dockerfile,Dockerfile.dockerignore}
  has_dep postgres && yq -i '.services.db |= (
    .image = "postgres:18-alpine" | .ports = ["127.0.0.1:5432:5432"] |
    .healthcheck = {
      "test": "pg_isready -h 127.0.0.1", "interval": "2s", "retries": 15
    }
  )' docker/compose.yaml
  pnpm dlx -s dclint@3.1.0 -q --fix docker/compose.yaml ||
    warn "Fix compose lint errors: pnpm dlx dclint docker/compose.yaml"
  pnpm pkg delete 'scripts["db:start"]'
  pnpm pkg set \
    'scripts["docker:up"]'="docker compose up -d --wait" \
    'scripts["docker:down"]'="docker compose down"
  for f in .env .env.example; do
    set_dotenv COMPOSE_FILE "docker/compose.yaml:docker/compose.dev.yaml" $f
    set_dotenv COMPOSE_PROJECT_NAME "${${${PWD:t}:l}//[^a-z0-9_-]/-}" $f
  done
  COMPOSE_PROGRESS=quiet pnpm -s docker:up >/dev/null 2>&1 ||
    warn "Start the Docker services: pnpm docker:up"
fi

# Database
# https://orm.drizzle.team
if has_dep drizzle-kit; then
  info "Configuring Drizzle..."
  pnpm add -s -D drizzle-zod drizzle-seed
  db=src/lib/server/db
  if [[ -f $db/schema.ts ]]; then
    mkdir -p $db/schema && mv $db/schema.ts $db/schema/index.ts
    sed -i '' '/^export \*/!d' $db/schema/index.ts
    touch $db/schema/common.ts
  fi
  sed_patch drizzle.config.ts -e 's|db/schema\.ts|db/schema|'
  grep -q postgresql drizzle.config.ts &&
    add_vscode_ext ckolkman.vscode-postgres
  grep -q sqlite drizzle.config.ts && add_vscode_ext qwtel.sqlite-viewer
fi

# Better-Auth
# https://www.better-auth.com
if has_dep better-auth; then
  info "Configuring Better Auth..."
  [[ -f $db/auth.schema.ts ]] && mv $db/auth.schema.ts $db/schema/auth.ts
  sed_patch $db/schema/index.ts -e 's|/auth\.schema|/auth|'
  sed_patch package.json -e 's|db/auth\.schema\.ts|db/schema/auth.ts|'
  pnpm auth:schema >/dev/null 2>&1 ||
    warn "Generate the auth schema: pnpm auth:schema"
fi

# Migrations
# https://orm.drizzle.team/docs/migrations
if has_dep drizzle-kit; then
  info "Running migrations..."
  pnpm -s db:generate >/dev/null 2>&1 &&
    pnpm -s db:migrate >/dev/null 2>&1 ||
    warn "Migrate the database: pnpm db:generate && pnpm db:migrate"
fi

# Web Files
info "Creating web files..."
rm -f static/robots.txt
mkdir -p \
  'src/routes/(meta)/robots.txt' \
  'src/routes/(meta)/sitemap.xml' \
  src/lib/fonts \
  static/img
touch static/{manifest.json,humans.txt,llms.txt} \
  'src/routes/(meta)/'{robots.txt,sitemap.xml}/+server.ts
has_dep prettier && sed_patch .prettierignore \
  -e 's|^/static/$|/static/*\n!/static/manifest.json|'
if [[ -f src/lib/assets/favicon.svg ]]; then
  info "Generating favicons..."
  mkdir -p static/img/favicons
  mv src/lib/assets/favicon.svg static/img/favicons/
  rmdir src/lib/assets 2>/dev/null || true
  sed_patch src/routes/+layout.svelte \
    -e '/favicon/d' -e '/<svelte:head>/,/<\/svelte:head>/d'
  pnpm dlx -s @vite-pwa/assets-generator@2 --preset minimal-2023 \
    static/img/favicons/favicon.svg >/dev/null
fi

# Cloudflare
# https://svelte.dev/docs/kit/adapter-cloudflare
if has_dep @sveltejs/adapter-cloudflare; then
  info "Configuring Cloudflare..."
  export WRANGLER_SEND_METRICS=false WRANGLER_LOG=error
  domain=${${HOMEPAGE#*://}%%/*} yq -i -oj '
    .compatibility_flags = ["nodejs_compat"] |
    .vars.NODE_ENV = "production" |
    .routes = [{"pattern": strenv(domain), "custom_domain": true}]
  ' wrangler.jsonc
  if grep -qs d1-http drizzle.config.ts; then
    yq -i -oj '.d1_databases = [{
      "binding": "DB",
      "migrations_dir": "drizzle"
    }]' wrangler.jsonc
    pnpm pkg delete 'scripts["db:push"]'
    pnpm pkg set \
      'scripts["db:migrate"]'="wrangler d1 migrations apply DB --local"
  fi
  grep -qx '/backups/' .gitignore || echo '/backups/' >>.gitignore
  pnpm -s gen >/dev/null 2>&1 ||
    warn "Generate the Cloudflare types: pnpm gen"
fi

# Cache Headers
# https://developers.cloudflare.com/workers/static-assets/headers/
if [[ -z $is_dynamic ]]; then
  info "Creating cache headers..."
  print -r -- '/_app/immutable/*
  Cache-Control: public, max-age=31536000, immutable

/img/*
  Cache-Control: public, max-age=86400' >static/_headers
fi

# Vite
# https://vite.dev
if [[ -f vite.config.ts ]]; then
  pnpm pkg set scripts.dev="vite dev --open"
  # Quieter output: warnings only, no gzip size report on build
  quiet="logLevel: 'warn',\n\\1build: { reportCompressedSize: false },"
  sed_patch vite.config.ts -e "s|^\([[:space:]]*\)plugins: \[|\1$quiet\n&|"
  if [[ -z $is_dynamic ]]; then
    sed_patch vite.config.ts \
      -e "s/adapter: adapter()/adapter: adapter({ fallback: '404.html' })/"
    # homepage: its origin is url.origin when prerendering robots.txt and
    # sitemap.xml, its path the base (e.g. /repo on GitHub Pages)
    sed_patch vite.config.ts \
      -e "1s|^|import pkg from './package.json' with { type: 'json' };\n|" \
      -e "s|^export default|const site = new URL(pkg.homepage);\n\n&|"
    base="\`/\${site.pathname.split('/').filter(Boolean).join('/')}\`"
    paths="paths: { origin: site.origin, base: process.argv.includes('dev')"
    paths+=" || site.pathname === '/' ? '' : $base },"
    css='inlineStyleThreshold: 4096,'
    sed_patch vite.config.ts \
      -e "s#^\([[:space:]]*\)adapter: adapter(#\1$paths\n\1$css\n&#"
    grep -qs 'prerender' src/routes/+layout.ts ||
      echo "export const prerender = true;" >>src/routes/+layout.ts
  fi
  # https://github.com/unplugin/unplugin-icons
  sed_patch vite.config.ts \
    -e "s|^import { sveltekit }.*|&\nimport Icons from 'unplugin-icons/vite';|"
  icons="Icons({ compiler: 'svelte' })"
  sed_patch vite.config.ts \
    -e "/sveltekit({/,/^[[:space:]]*})/s|^\([[:space:]]*\)})|&,\n\1$icons|"
  sed_patch src/app.d.ts -e "1s|^|import 'unplugin-icons/types/svelte';\n\n|"
fi

# VSCode Tasks
# https://code.visualstudio.com
info "Configuring VS Code..."
tasks=('SvelteKit:*')
has_dep @sveltejs/adapter-cloudflare && tasks+=('Cloudflare:*')
jsonc $DOTFILES/config/vscode/tasks.json | pick_tasks $tasks >.vscode/tasks.json

# VSCode Launch
# TODO: copy $DOTFILES/config/vscode/launch.json to .vscode/launch.json

# VSCode Settings
settings=(
  'editor.codeActionsOnSave'
  'editor.defaultFormatter'
  'editor.foldingStrategy'
  'editor.format*'
  'editor.quickSuggestions'
  'eslint.*'
  'explorer.fileNesting.*'
  'files.*'
  'js/ts.*'
  'svelte.*'
  '[svelte]'
)
has_dep tailwindcss && settings+=('tailwindCSS.*')
jsonc $DOTFILES/config/vscode/settings.json | pick_keys $settings |
  merge_json .vscode/settings.json
# Without Tailwind, drop its *.css file association
has_dep tailwindcss || yq -i -oj '
  del(.["files.associations"][] | select(. == "tailwindcss"))
' .vscode/settings.json

# VSCode Extensions
add_vscode_ext \
  antfu.iconify \
  christian-kohler.path-intellisense \
  usernamehw.errorlens \
  formulahendry.auto-rename-tag \
  github.vscode-github-actions \
  anweber.vscode-httpyac

# Docs
# https://github.com/rafazafar/gh-scaffold
if [[ $(pnpm pkg get private) != true ]]; then
  info "Generating docs..."
  repo=$GH_USER/$NAME
  pnpm pkg set license=MIT
  pnpm dlx -s gh-scaffold@1.0.4 -w \
    --preset strict \
    --issue-templates forms \
    --license mit \
    --skip GOVERNANCE,MAINTAINERS,CHANGELOG,CODEOWNERS,FUNDING \
    </dev/null >/dev/null
  sed_patch LICENSE -e "s|<YEAR>|$(date +%Y)|"
  sed_patch LICENSE -e "s|<COPYRIGHT HOLDER>|$AUTHOR_NAME|"
  sed_patch SECURITY.md -e "s|(add contact here)|<$AUTHOR_EMAIL>|"
  sed_patch .github/ISSUE_TEMPLATE/config.yml \
    -e "s|url: https://github.com\$|&/$repo/blob/HEAD/SUPPORT.md|"
  echo "* @$GH_USER" >.github/CODEOWNERS
fi

# Claude
# https://www.claude.ai
if [[ -d .claude ]]; then
  info "Configuring Claude..."
  [[ -f AGENTS.md ]] && mv AGENTS.md .claude/ && touch .claude/CLAUDE.md
  jq -n '{
    enabledPlugins: {
      "svelte@svelte": true,
      "typescript-lsp@claude-plugins-official": true
    },
    extraKnownMarketplaces: {
      svelte: {source: {source: "github", repo: "sveltejs/ai-tools"}}
    }
  }' >.claude/settings.json
  yq -oj 'del(.mcpServers[] | select(to_json | contains("${")))' \
    $DOTFILES/config/claude/mcp.json >.mcp.json
  echo "/.claude/skills/" >>.prettierignore
  add_vscode_ext anthropic.claude-code
  # LSP plugins don't ship their binaries; each teammate installs them once:
  # npm i -g svelte-language-server typescript-language-server typescript
fi

# Tests
# https://vitest.dev
# https://playwright.dev
if has_dep vitest || has_dep @playwright/test; then
  info "Configuring tests..."
fi

# Github Actions
info "Creating GitHub workflows..."
mkdir -p .github/workflows
touch .github/dependabot.yml \
  .github/workflows/{ci,deploy,check,release}.yml

# Last Check
info "Updating dependencies & formatting..."
export PNPM_CONFIG_LOGLEVEL=silent
pnpm up
pnpm audit --fix=update ||
  warn "Review the remaining vulnerabilities: pnpm audit"
pnpm format --log-level=warn
pnpm exec eslint --quiet . || warn "Fix lint errors: pnpm lint"
pnpm check --threshold error --output human ||
  warn "Fix type errors: pnpm check"

# Git
info "Committing..."
pnpm pkg set \
  repository.type="git" \
  repository.url="git+https://github.com/$GH_USER/$NAME.git" \
  bugs.url="https://github.com/$GH_USER/$NAME/issues"
git add -A
git commit -qm "chore: project setup"
git switch -qc dev

success "Completed!"
