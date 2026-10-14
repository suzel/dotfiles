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

# includeIf needs a repo, so read the file
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

# Env Files
# snippet template kontrol edilceek.
# web adresi, post, proje adı gibi değerler eklenebilir.
# Docker tarfında okunacak verilere de dikkat edilmesi gerekir.

# Docker
# https://www.docker.com
# env. bağlantısı
# compose.dev.yaml → template geliştirlmesi proje tipine göre → snippetler if
# compose.yml → proje tipine göre hazırlanması
# Dockerfile.web → proje tipine göre hazırlanması
# Dcokerignore → proje tipine göre hazırlanması
# pnpm scripleri ve sv-setup docker ı aya kadlırp servisleri çalıştırmaıs gerek.
# docker için olan snippetleri kontrol et güncellemeler yap.
# Dockerfile en küçük çıktıyı vermesi gerekiyor.
if [[ -f compose.yaml ]]; then
  info "Configuring Docker..."
  mkdir -p docker && mv compose.yaml docker/
  if has_dep postgres; then
    port=5432
    while lsof -iTCP:$port -sTCP:LISTEN >/dev/null; do ((port++)); done
    if ((port != 5432)); then
      for f in .env .env.example; do
        sed_patch $f -e "s|@localhost:5432/|@localhost:$port/|"
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
    warn "Fix compose lint errors: pnpm dlx dclint docker/compose.yaml"
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
    warn "Start the Docker services: pnpm docker:up"
fi

# | `bits-ui` | Headless component primitives
# | `embla-carousel-svelte` | Ürün slider/carousel
# | Custom RBAC middleware | Admin / Editor / Customer rol yönetimi
# | `@stripe/stripe-js` | Client-side Stripe Elements
# | Webhook handler (custom) | Ödeme durumu senkronizasyonu
# | `@uploadthing/svelte` veya `@aws-sdk/client-s3` | Dosya upload
# | Custom image pipeline | Otomatik thumbnail, responsive srcset üretimi
# | `resend` veya `nodemailer` | Transactional email
# | `svelte-email` | Email template'leri
# | `web-push`   | Push notification (sipariş durumu vb.)
# | `meilisearch` veya `minisearch`  | Full-text ürün arama
# | Custom faceted filter  | URL-based çoklu filtre (fiyat, renk, beden vb.)
# | Rate Limiting | `@upstash/ratelimit` — API abuse koruması
# | Queue / Background Jobs | `bullmq` veya `inngest` — email gönderimi, stok güncelleme, rapor oluşturma
# | Error Tracking | `@sentry/sveltekit` — hata izleme
# | A/B Testing | Banner, fiyat, layout denemeleri — feature flag sistemi (`@vercel/flags` veya custom)

# Database
# https://orm.drizzle.team
# Postgres için snippet var ama sqlite için özellikle CF ortamında ? (drizzle::table for sqlite)
# Ne oacak ? (cols > title:200!, createdOn:date=now, authorId>user)
# Drizzle Seed için snipetler ve nasıl kullanılacak ?
# Drizzle ORM de transaction nasık kullanılacak ? (snippets)
# sql > snippet kullanımının son haline getirilmesi.
# Drizzle ORM cache kullanımı nasıl oluyor ? (CF + Non redis)
# VSCode da Drizzle ORM için hazır taskların hazırlanması.
# PostgreSQL için RLS yapısı ve snippetlerinin hazırlanması.
# Zod entegrasyonunun mantığının öğrenilmesi.
# Drizzle ORM Relations mantığı ve snippetlerinin hazırlanması.
# Drizzle ORM dökümanlarının okunması.

# https://orm.drizzle.team/docs/overview
# https://orm.drizzle.team/docs/seed-overview
# https://orm.drizzle.team/docs/cache
# https://orm.drizzle.team/docs/zod
# https://orm.drizzle.team/docs/rls
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
# https://better-auth.com/docs/infrastructure/services/email
# https://better-auth.com/docs/plugins/admin
# https://better-auth.com/docs/plugins/stripe
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
# https://vite-pwa-org.netlify.app/assets-generator/
# TODO: app.html içine meta taglerin eklenmesi ?
# TODO: manifest.json ın prettier tarafından formatlanması için güncelle yap.
# TODO: https://www.sopyo.com/llms.txt ???
# TODO: OG images ?
# fonts: not static/fonts, Vite hashes and preloads them
# img: images, favicons
rm -f static/robots.txt
mkdir -p \
  'src/routes/(meta)/robots.txt' \
  'src/routes/(meta)/sitemap.xml' \
  src/lib/fonts \
  static/img
touch \
  'src/routes/(meta)/'{robots.txt,sitemap.xml}/+server.ts
if [[ -f src/lib/assets/favicon.svg ]]; then
  info "Generating favicons..."
  mkdir -p static/img/favicons
  mv src/lib/assets/favicon.svg static/img/favicons/
  rmdir src/lib/assets 2>/dev/null || true
  sed_patch src/routes/+layout.svelte \
    -e '/favicon/d' -e '/<svelte:head>/,/<\/svelte:head>/d'
  pnpm dlx -s @vite-pwa/assets-generator@2.0.0 --preset minimal-2023 \
    static/img/favicons/favicon.svg >/dev/null
fi

# Cloudflare
# https://svelte.dev/docs/kit/adapter-cloudflare
# CF project init
# CF README.md badget, section
# CF test
# CF log, analytics
# CF DB, KV, Workflow, R2, AI, DO
# VSCode tasks
# VSCode snippets for CF
# .env, secret ve dev,prod,stage
# domain redirect
# Drizzle ORM settings
# Assets caching
# SSL ?
if has_dep @sveltejs/adapter-cloudflare; then
  info "Configuring Cloudflare..."
  export WRANGLER_SEND_METRICS=false WRANGLER_LOG=error
  yq -i -oj '
    .compatibility_flags = ["nodejs_compat"] |
    .vars.NODE_ENV = "production"
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

# TODO: ???
# Head links (prettier reformats app.html at the end, tag breaks are fine)
# a=%sveltekit.assets%
# fav=$a/img/favicons
# sed_patch src/app.html -e "/%sveltekit.head%/i\\
# <link rel=\"icon\" href=\"$fav/favicon.ico\" sizes=\"48x48\" />\\
# <link rel=\"icon\" href=\"$fav/favicon.svg\" sizes=\"any\"\\
# type=\"image/svg+xml\" />\\
# <link rel=\"apple-touch-icon\" href=\"$fav/apple-touch-icon-180x180.png\" />\\
# <link rel=\"manifest\" href=\"$a/manifest.json\" />\\
# <link rel=\"sitemap\" href=\"$a/sitemap.xml\" />\\
# <link rel=\"author\" type=\"text/plain\" href=\"$a/humans.txt\" />
# "
# rm -f static/robots.txt # served by src/routes/(meta)/robots.txt
# # Empty on purpose: Cmd+. in an empty file offers the seo:: file templates
# touch static/{manifest.json,humans.txt,llms.txt}
# # sv ignores all of static/; keep formatting manifest.json
# sed_patch .prettierignore -e 's|^/static/$|/static/*|' -e '/^\/static\/\*$/a\
# !/static/manifest.json
# '

# Vite
# https://vite.dev
# TODO: paths: { origin: (pkg as { homepage?: string }).homepage }, ???
# TODO: `adapter: adapter({ fallback: '404.html' }),` düzenleme ve eklemeler ?(chunk ve diğer eklemeler)
# TODO: `Icons({ compiler: 'svelte' }),` sveltekir den sora gelmesi gerekiyor.
# TODO: Static site için veya site performansu için chunk ayarlarının yapılması.
# TODO: Obsidian dökümanlarına bak
if [[ -f vite.config.ts ]]; then
  pnpm pkg set scripts.dev="vite dev --open"
  # Quieter output: warnings only, no gzip size report on build
  quiet="logLevel: 'warn',\n\\1build: { reportCompressedSize: false },"
  sed_patch vite.config.ts -e "s|^\([[:space:]]*\)plugins: \[|\1$quiet\n&|"
  if [[ -z $is_dynamic ]]; then
    sed_patch vite.config.ts \
      -e "s/adapter: adapter()/adapter: adapter({ fallback: '404.html' })/"
    # paths.origin: url.origin when prerendering robots.txt and sitemap.xml
    sed_patch vite.config.ts \
      -e "1s|^|import pkg from './package.json' with { type: 'json' };\n|"
    origin='paths: { origin: (pkg as { homepage?: string }).homepage },'
    sed_patch vite.config.ts \
      -e "s|^\([[:space:]]*\)adapter: adapter(|\1$origin\n&|"
    grep -qs 'prerender' src/routes/+layout.ts ||
      echo "export const prerender = true;" >>src/routes/+layout.ts
  fi
  # https://github.com/unplugin/unplugin-icons
  sed_patch vite.config.ts \
    -e "s|^import { sveltekit }.*|&\nimport Icons from 'unplugin-icons/vite';|"
  sed_patch vite.config.ts \
    -e "s|^\([[:space:]]*\)plugins: \[|&\n\1\1Icons({ compiler: 'svelte' }),|"
  sed_patch src/app.d.ts -e "1s|^|import 'unplugin-icons/types/svelte';\n\n|"
fi

# VSCode
# https://code.visualstudio.com
# TODO: settings.json snippetin güncellenmesi.
# TODO: settings.json problem var.
# setting.json yorum satırları ve order olabilir mi ?
# extensions.json da çif kayıt olabilir mi ? order ?
# taskların geliştirilmesi
# 	isimlendirme ve filtreleme mekanizması kurulması.
# 	Diğer tasklar mesela cf ile bir de db ille iligi beliki docker bir performace için scripts deki çağıran

info "Configuring VS Code..."
readonly DOTFILES=${0:A:h:h}
tasks=SvelteKit
has_dep @sveltejs/adapter-cloudflare && tasks+='|Cloudflare'
grep -v '^\s*//' $DOTFILES/config/vscode/tasks.json >.vscode/tasks.json
# -py: the YAML parser also reads JSONC trailing commas
yq -i -py -oj '
  .tasks |= map(
    select(.label | test("^_('$tasks'):")) |
    .label |= sub("^_", "") |
    del(.hide)
  ) |
  (.tasks | to_json) as $used |
  .inputs |= ((. // []) | map(select($used | contains("input:" + .id))))
' .vscode/tasks.json
[[ -s .vscode/settings.json ]] || echo '{}' >.vscode/settings.json
grep -v '^\s*//' $DOTFILES/config/vscode/settings.json |
  yq -i -py -oj ea 'select(fi == 0) * (select(fi == 1) | with_entries(select(
    .key == ("files.*", "explorer.fileNesting.*", "tailwindCSS.*",
      "editor.codeActionsOnSave", "editor.quickSuggestions",
      "editor.defaultFormatter", "editor.foldingStrategy", "editor.format*",
      "js/ts.*", "svelte.*", "[svelte]", "eslint.*")
  )))' .vscode/settings.json -
has_dep tailwindcss || yq -i -oj '
  with_entries(select(.key | test("^tailwindCSS") | not)) |
  del(.["files.associations"][] | select(. == "tailwindcss"))
' .vscode/settings.json
add_vscode_ext \
  antfu.iconify \
  christian-kohler.path-intellisense \
  usernamehw.errorlens \
  formulahendry.auto-rename-tag \
  github.vscode-github-actions \
  humao.rest-client

# Docs (public projects only: remove "private" from package.json before running)
# TODO: Static sitede MIT lisansı nasıl aktive edilir ?
# TODO: README.md hazırlanması. Tüm modüller için snippet hazırlanması.
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
  yq -oj '
    pick(["enabledPlugins", "extraKnownMarketplaces"]) |
    .[] |= with_entries(select(.key | test("typescript|svelte"))) |
    .enabledPlugins[] = true
  ' ~/.claude/settings.json >.claude/settings.json
  yq -oj 'del(.mcpServers[] | select(to_json | contains("${")))' \
    $DOTFILES/config/claude/mcp.json >.mcp.json
  echo "/.claude/skills/" >>.prettierignore
  add_vscode_ext anthropic.claude-code
fi

# Tests
# https://vitest.dev
# https://playwright.dev
if has_dep vitest || has_dep @playwright/test; then
  info "Configuring tests..."
fi

# Github Actions
# TODO: Versioning
# TODO: Performans ve güvenlik için workflowların eklenmesi.
info "Creating GitHub workflows..."
mkdir -p .github/workflows
touch \
  .github/workflows/ci.yml \
  .github/workflows/deploy.yml

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
