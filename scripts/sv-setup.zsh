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
# Requires: pnpm, node, git, jq, yq (mikefarah v4); docker for compose projects
# =============================================================================

# TODO: pnpm pkg delete private
# TODO: src/lib/server/db/schema/common.ts
# TODO: version="0.0.1" - type="module"

# .mcp.json (314): ../.mcp.json'daki sunucular gizli bilgi filtresinden
# geçirilmiyor. Bugün orada token yok, yalnızca ALLOWED_SEARCH_ENGINES gibi
# ayarlar var.

# vscode_pick (58) yalnızca tam satır // yorumlarını siliyor.
# dotfiles'taki VS Code ayarlarına satır sonu yorumu ya da /* */ eklendiği
# gün yq parse hatası verir.

set -euo pipefail

# ${0:A} follows the ~/Scripts symlink back to the repo
readonly DOTFILES=${0:A:h:h}
readonly UNDO='git reset -q --hard && git clean -qfd'

# Log Functions: warn/error go to stderr, so $(...) never captures them
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Error trap: funcfiletrace[-1] is the script line even inside a helper
TRAPZERR() {
  error "Error at ${funcfiletrace[-1]}. Undo: $UNDO"
  exit 1
}

# Helper Functions
has_dep() {
  jq -e --arg d "$1" \
    '(.dependencies // {}) + (.devDependencies // {}) | has($d)' \
    package.json >/dev/null
}
set_dotenv() { touch $3 && sed -i '' "/^$1=/d" $3 && echo "$1=$2" >>$3; }
add_vscode_ext() {
  yq -i -oj ".recommendations |= (. + [${(j:,:)${(qqq)@}}] | unique)" \
    .vscode/extensions.json
}

# sed -i on a file sv generated; fails loudly if sv's template changed
patch() {
  local file=$1 before
  shift
  before=$(<$file)
  sed -i '' "$@" $file
  [[ $(<$file) != "$before" ]] || {
    error "Patch did not apply (sv template changed?): $file: $*"
    return 1
  }
}

# Deep-merges stdin JSON into $1 (stdin wins, the file's other keys stay)
json_merge() {
  [[ -f $1 ]] || echo '{}' >$1
  yq -oj ea '. as $f ireduce ({}; . * $f)' $1 - >$1.new
  mv $1.new $1
}

# Merges the picked keys of the dotfiles VS Code config into the project's file
vscode_pick() {
  grep -v '^\s*//' $DOTFILES/config/vscode/$1 | yq -oj "$2" |
    json_merge .vscode/$1
}

# Runs a command quietly; prints its output only when it fails
quiet() {
  local out
  out=$("$@" 2>&1) || {
    print -r -- "$out" >&2
    return 1
  }
}

next=() # follow-up steps, printed at the end

# Checks
for cmd in pnpm node git jq yq; do
  (($+commands[$cmd])) || {
    error "Missing command: $cmd"
    exit 1
  }
done
has_dep @sveltejs/kit && has_dep prettier && has_dep eslint || {
  error "Run from the root of a SvelteKit project" \
    "created by sv with prettier and eslint"
  exit 1
}
[[ ! -f .node-version ]] || {
  error "Already set up (.node-version exists). To redo a failed run: $UNDO"
  exit 1
}

# Git first: the identity's includeIf "gitdir:~/Projects/" needs a repo
[[ -d .git ]] || git init -q -b main
git_name=$(git config user.name || true)
git_email=$(git config user.email || true)
gh_user=$(git config github.user || true)
[[ -n $git_name && -n $git_email && -n $gh_user ]] || {
  error "Set git user.name, user.email and github.user"
  exit 1
}
repo="$gh_user/$(pnpm pkg get name)"
# Baseline: sv's output, so a failed run can be undone with git reset
git rev-parse -q --verify HEAD >/dev/null || {
  git add -A
  git commit -qm "chore: scaffold with sv" --no-verify
}

# Update package meta
info "Updating package meta..."
node -v | cut -c 2- | cut -d. -f1 >.node-version
pnpm pkg set \
  version="0.0.1" \
  type="module" \
  author.name="$git_name" \
  author.email="$git_email" \
  repository.type="git" \
  repository.url="git+https://github.com/$repo.git" \
  bugs.url="https://github.com/$repo/issues" \
  engines.node=">=$(<.node-version)" \
  packageManager="pnpm@$(pnpm --version)" \
  scripts.clean="rm -rf node_modules/.vite .svelte-kit build"

# adapter-static prerenders every page
if has_dep @sveltejs/adapter-static; then
  grep -qs 'prerender' src/routes/+layout.ts ||
    echo "export const prerender = true;" >>src/routes/+layout.ts
fi

# Approvals
info "Configuring pnpm workspace..."
pnpm -s approve-builds esbuild sharp workerd

# Packages
info "Installing packages..."
pkgs=(
  prettier-plugin-packagejson
  @ianvs/prettier-plugin-sort-imports
  unplugin-icons @iconify-json/logos
  svelte-sonner
  schema-dts
  zod
  husky lint-staged
)
has_dep drizzle-kit && pkgs+=(drizzle-zod drizzle-seed)
pnpm add -s -D $pkgs

# ESLint
# https://eslint.org
patch eslint.config.js \
  -e "s/rules: {}/rules: { 'svelte\/no-at-html-tags': 'off' }/"

# Vite
# https://vite.dev
if [[ -f vite.config.ts ]]; then
  pnpm pkg set scripts.dev="vite dev --open"
  if has_dep @sveltejs/adapter-static; then
    patch vite.config.ts \
      -e "s/adapter: adapter()/adapter: adapter({ fallback: '404.html' })/"
    # paths.origin: url.origin when prerendering robots.txt and sitemap.xml
    patch vite.config.ts \
      -e "1s|^|import pkg from './package.json' with { type: 'json' };\n|"
    origin='paths: { origin: (pkg as { homepage?: string }).homepage },'
    patch vite.config.ts \
      -e "s|^\([[:space:]]*\)adapter: adapter(|\1$origin\n&|"
  fi
  # https://github.com/unplugin/unplugin-icons
  patch vite.config.ts \
    -e "s|^import { sveltekit }.*|&\nimport Icons from 'unplugin-icons/vite';|"
  patch vite.config.ts \
    -e "s|^\([[:space:]]*\)plugins: \[|&\n\1\1Icons({ compiler: 'svelte' }),|"
  patch src/app.d.ts -e "1s|^|import 'unplugin-icons/types/svelte';\n\n|"
fi

# Husky
# https://github.com/typicode/husky
info "Configuring Husky & lint-staged..."
pnpm exec husky >/dev/null
pnpm pkg set scripts.prepare="husky && svelte-kit sync || echo ''"

# TailwindCSS
# https://tailwindcss.com
if has_dep tailwindcss; then
  info "Configuring TailwindCSS..."
  mkdir -p src/lib/styles
  mv src/routes/layout.css src/lib/styles/layout.css
fi

# Favicons
# https://vite-pwa-org.netlify.app/assets-generator/
if [[ -f src/lib/assets/favicon.svg ]]; then
  info "Generating favicons..."
  mkdir -p static/img/favicons
  mv src/lib/assets/favicon.svg static/img/favicons/
  rmdir src/lib/assets 2>/dev/null || true
  pnpm dlx -s @vite-pwa/assets-generator@2.0.0 --preset minimal-2023 \
    static/img/favicons/favicon.svg >/dev/null
fi
# Head links (prettier reformats app.html at the end, tag breaks are fine)
a=%sveltekit.assets%
fav=$a/img/favicons
patch src/app.html -e "/%sveltekit.head%/i\\
<link rel=\"icon\" href=\"$fav/favicon.ico\" sizes=\"48x48\" />\\
<link rel=\"icon\" href=\"$fav/favicon.svg\" sizes=\"any\"\\
type=\"image/svg+xml\" />\\
<link rel=\"apple-touch-icon\" href=\"$fav/apple-touch-icon-180x180.png\" />\\
<link rel=\"manifest\" href=\"$a/manifest.json\" />\\
<link rel=\"sitemap\" href=\"$a/sitemap.xml\" />\\
<link rel=\"author\" type=\"text/plain\" href=\"$a/humans.txt\" />
"
rm -f static/robots.txt # served by src/routes/(meta)/robots.txt

# Docker
# https://www.docker.com
if [[ -f compose.yaml ]]; then
  info "Configuring Docker..."
  mkdir -p docker && mv compose.yaml docker/
  if has_dep postgres; then
    port=5432
    while lsof -iTCP:$port -sTCP:LISTEN >/dev/null; do ((port++)); done
    if ((port != 5432)); then
      for f in .env .env.example; do
        patch $f -e "s|@localhost:5432/|@localhost:$port/|"
      done
    fi
    port=$port yq -i '.services.db |= (
      .image = "postgres:18-alpine" |
      .ports = ["127.0.0.1:" + strenv(port) + ":5432"] |
      .healthcheck = {
        "test": ("pg_isready -h 127.0.0.1" +
          " -U $${POSTGRES_USER} -d $${POSTGRES_DB}"),
        "interval": "2s",
        "retries": 15
      }
    )' docker/compose.yaml
  fi
  pnpm dlx -s dclint@3.1.0 -q --fix docker/compose.yaml ||
    next+=("Fix compose lint errors: pnpm dlx dclint docker/compose.yaml")
  pnpm pkg delete 'scripts["db:start"]'
  pnpm pkg set \
    'scripts["docker:up"]'="docker compose up -d --wait" \
    'scripts["docker:down"]'="docker compose down"
  # .env.example too: a fresh clone copies it to .env
  for f in .env .env.example; do
    set_dotenv COMPOSE_FILE "docker/compose.yaml" $f
    set_dotenv COMPOSE_PROJECT_NAME "${${${PWD:t}:l}//[^a-z0-9_-]/-}" $f
  done
  COMPOSE_PROGRESS=quiet pnpm -s docker:up >/dev/null 2>&1 ||
    next+=("Start the Docker services: pnpm docker:up")
fi

# Database
# https://orm.drizzle.team
db=src/lib/server/db
if has_dep drizzle-kit; then
  info "Configuring Drizzle..."
  if [[ -f $db/schema.ts ]]; then
    mkdir -p $db/schema && mv $db/schema.ts $db/schema/index.ts
    sed -i '' '/^export \*/!d' $db/schema/index.ts # drop sv's demo tables
    touch $db/schema/common.ts
  fi
  patch drizzle.config.ts -e 's|db/schema\.ts|db/schema|'
  grep -q postgresql drizzle.config.ts &&
    add_vscode_ext ckolkman.vscode-postgres
  grep -q sqlite drizzle.config.ts && add_vscode_ext qwtel.sqlite-viewer
fi

# Better-Auth
# https://www.better-auth.com
if has_dep better-auth; then
  info "Configuring Better Auth..."
  [[ -f $db/auth.schema.ts ]] && mv $db/auth.schema.ts $db/schema/auth.ts
  patch $db/schema/index.ts -e 's|/auth\.schema|/auth|'
  patch package.json -e 's|db/auth\.schema\.ts|db/schema/auth.ts|'
  pnpm auth:schema >/dev/null 2>&1 ||
    next+=("Generate the auth schema: pnpm auth:schema")
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
    yq -i -o=json '.d1_databases = [{
      "binding": "DB",
      "database_name": .name,
      "database_id": "local",
      "migrations_dir": "drizzle"
    }]' wrangler.jsonc
    apply='wrangler d1 migrations apply DB'
    backup='mkdir -p backups && wrangler d1 export DB --remote'
    backup+=' --output backups/DB-$(date +%F-%H%M).sql'
    pnpm pkg delete 'scripts["db:push"]'
    pnpm pkg set \
      'scripts["db:migrate"]'="$apply --local" \
      'scripts["db:migrate:remote"]'="$apply --remote" \
      'scripts["db:backup"]'="$backup"
    grep -qx '/backups/' .gitignore || echo '/backups/' >>.gitignore
    next+=(
      "D1: pnpm exec wrangler d1 create <name>"
      "D1: put its id into database_id in wrangler.jsonc"
      "D1: fill CLOUDFLARE_* in .env, then: pnpm db:migrate:remote"
    )
  fi
  quiet pnpm -s gen
fi

# Migrations
# https://orm.drizzle.team/docs/migrations
if has_dep drizzle-kit; then
  info "Running migrations..."
  # d1: generate never connects; the config just refuses empty CLOUDFLARE_*
  d1_env=()
  grep -qs d1-http drizzle.config.ts &&
    d1_env=(
      CLOUDFLARE_ACCOUNT_ID=local
      CLOUDFLARE_DATABASE_ID=local
      CLOUDFLARE_D1_TOKEN=local
    )
  env $d1_env pnpm -s db:generate >/dev/null 2>&1 &&
    pnpm -s db:migrate >/dev/null 2>&1 ||
    next+=("Migrate the database: pnpm db:generate && pnpm db:migrate")
fi

# Claude
# https://www.claude.ai
if [[ -d .claude ]]; then
  info "Configuring Claude..."
  # settings.json is committed: plugins + their marketplaces, nothing personal
  yq -oj '
    .enabledPlugins |= with_entries(
      select(.key == ("*typescript*", "*svelte*"))
    ) |
    (.enabledPlugins | keys | map(sub(".*@", ""))) as $m |
    {
      "extraKnownMarketplaces": (
        .extraKnownMarketplaces | with_entries(select(.key == $m[]))
      ),
      "enabledPlugins": .enabledPlugins
    }
  ' ~/.claude/settings.json | json_merge .claude/settings.json

  # .mcp.json: ../.mcp.json + user servers w/o env/headers, svelte via plugin
  jq -s '
    def secret: ((.env // {}) + (.headers // {}) | length) > 0;
    {
      mcpServers: (
        (.[0].mcpServers // {}) +
        ((.[1].mcpServers // {}) | with_entries(select(.value | secret | not)))
        | del(.svelte)
      )
    }
  ' <(cat ../.mcp.json 2>/dev/null || echo '{}') ~/.claude.json >.mcp.json

  echo "/.claude/skills/" >>.prettierignore
  add_vscode_ext anthropic.claude-code
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
) | (.tasks | to_json) as $used |
.inputs |= ((. // []) | map(select($used | contains("input:" + .id))))'
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
  antfu.iconify \
  christian-kohler.path-intellisense \
  usernamehw.errorlens \
  formulahendry.auto-rename-tag \
  github.vscode-github-actions

# Docs (public projects only: remove "private" from package.json before running)
# https://github.com/rafazafar/gh-scaffold
if [[ $(pnpm pkg get private) != true ]]; then
  info "Generating docs..."
  pnpm pkg set license=MIT
  pnpm dlx -s gh-scaffold@1.0.4 -w \
    --preset strict \
    --issue-templates forms \
    --license mit \
    --skip GOVERNANCE,MAINTAINERS,CHANGELOG,CODEOWNERS,FUNDING \
    </dev/null >/dev/null
  patch LICENSE -e "s|<YEAR>|$(date +%Y)|"
  patch LICENSE -e "s|<COPYRIGHT HOLDER>|$git_name|"
  patch SECURITY.md -e "s|(add contact here)|<$git_email>|"
  patch .github/ISSUE_TEMPLATE/config.yml \
    -e "s|url: https://github.com\$|&/$repo/blob/HEAD/SUPPORT.md|"
  echo "* @$gh_user" >.github/CODEOWNERS
fi

# Last Check
info "Updating dependencies & formatting..."
pnpm -s up
pnpm audit --fix=update >/dev/null ||
  next+=("Review the remaining vulnerabilities: pnpm audit")
quiet pnpm -s format --log-level=silent
quiet pnpm -s lint
quiet pnpm -s check --threshold error

# Git
info "Committing..."
git add -A
git commit -qm "chore: project setup" --no-verify
git switch -qc dev

((${#next})) && {
  warn "Next steps:"
  printf '  • %s\n' $next >&2
}
success "Completed!"
