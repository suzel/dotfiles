#!/usr/bin/env zsh
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
vscopy() { sed '/^[[:space:]]*\/\//d' ~/Library/Application\ Support/Code/User/$1 | yq -oj "$2" >.vscode/$1; }

# Checks
installed @sveltejs/kit || {
  error "Not a SvelteKit project"
  exit 1
}

# Update package meta
pnpm pkg set \
  version="0.0.1" \
  description="${$(pnpm pkg get description | perl -pe 's/^./\u$&/'):-${(C)$(pnpm pkg get name)//[-_]/ }}" \
  homepage="https://github.com/suzel/$(pnpm pkg get name)#readme" \
  author.name="$(git config user.name || echo '')" \
  author.email="$(git config user.email || echo '')" \
  type="module" \
  packageManager="pnpm@$(pnpm --version)" \
  scripts.clean="rm -rf .svelte-kit build node_modules/.vite$(installed wrangler && echo ' .wrangler')" \
  scripts.dev="vite dev --open" \
  engines.node=">=$(node -p 'process.versions.node.split(".")[0]')" \
  engines.pnpm=">=$(pnpm --version | cut -d. -f1)"

# Project Structure
mkdir -p \
  docs \
  scripts \
  static/img/favicons \
  .github/workflows \
  src/lib/{utils,stores,types,styles,remote,config} \
  src/lib/components/{admin/ui,layout} \
  src/lib/server/{db,services,storage,images,integrations} \
  src/routes/{admin,api} \
  src/params

# Project Files
node --version | cut -d 'v' -f 2 >.node-version
touch src/{hooks.client,service-workers}.ts
touch src/lib/components/layout/{Header,Footer,GoogleAnalytics}.svelte

# Build scripts allowlist
echo "allowBuilds:
  '@profullstack/favicon-generator': true
  esbuild: true
  sharp: true
  workerd: true
update:
  ignoreDeps:
    - typescript" >pnpm-workspace.yaml

# Packages
packages=(
  # Vite plugins
  @sveltejs/enhanced-img
  unplugin-icons @iconify-json/logos
  # Tooling
  prettier-plugin-packagejson
  svelte-check
  # Types
  schema-dts
  # Runtime
  zod
  svelte-sonner
)
pnpm add -s -D --loglevel warn $packages

# License & publish metadata
if [[ $(pnpm pkg get private) != true ]]; then
  pnpm pkg set license="MIT"
  pnpm dlx -s license MIT \
    -n "$(git config user.name)" \
    -e "$(git config user.email)" \
    -y "$(date +%Y)"
fi

# ESLint
if installed eslint; then
  sed -i '' "s/rules: {}/rules: { 'svelte\/no-at-html-tags': 'off' }/" eslint.config.js
  vsext dbaeumer.vscode-eslint
fi

# Prettier
if installed prettier; then
  sed -i '' 's/useTabs: true/useTabs: false/' prettier.config.js
  sed -i '' -E "s/(['\"])prettier-plugin-svelte(['\"])/&, \1prettier-plugin-packagejson\2/" prettier.config.js
  vsext esbenp.prettier-vscode
fi

# TypeScript
if installed typescript; then
  yq -i -o=json '.compilerOptions.strict = true' tsconfig.json
fi

# Vite plugins
if ! grep -q enhancedImages vite.config.ts; then
  sed -i '' "s|^import { sveltekit } from '@sveltejs/kit/vite';|import { enhancedImages } from '@sveltejs/enhanced-img';\n&\nimport Icons from 'unplugin-icons/vite';|" vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)tailwindcss(),|\1enhancedImages(),\n&|" vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)sveltekit()\(,\{0,1\}\)$|\1sveltekit(),\n\1Icons({ compiler: 'svelte' })\2|" vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)plugins: \[|\1build: {\n\1\1reportCompressedSize: false\n\1},\n&|" vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)plugins: \[|\1logLevel: 'warn',\n&|" vite.config.ts
  sed -i '' "s|^\([[:space:]]*\)adapter: adapter(),|\1adapter: adapter({\n\1\tpages: 'build',\n\1\tassets: 'build',\n\1\tfallback: '404.html',\n\1\tprecompress: false,\n\1\tstrict: true\n\1}),|" vite.config.ts
  # sed -i '' "s|^\([[:space:]]*\)adapter: adapter(|\1inlineStyleThreshold: 16384,\n\1prerender: {\n\1\torigin: 'https://www.sukruuzel.com'\n\1},\n&|" vite.config.ts
  csp="// Static build: CSP is injected as <meta http-equiv> in prerendered HTML.
  // report-uri, report-to and frame-ancestors are not supported via meta — set them via host headers.
  csp: {
    mode: 'auto',
    directives: {
      'script-src': ['self', 'https://www.googletagmanager.com'],
      'connect-src': ['self', 'https://*.google-analytics.com']
    },
    reportOnly: {
      'report-uri': ['/api/csp-report'],
      'script-src': ['self', 'https://www.googletagmanager.com'],
      'connect-src': ['self', 'https://*.google-analytics.com']
    }
  },"
  CSP=$csp perl -pi -e 's{^([ \t]*)(?=experimental: \{ remoteFunctions)}{my $i = $1; $i . $ENV{CSP} =~ s/\n  /\n$i/gr . "\n$i"}e' vite.config.ts
fi

# Husky &  Lint-staged
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
  touch src/lib/styles/design-token.css
  if [[ -f src/routes/layout.css ]]; then
    mv src/routes/layout.css src/lib/styles/layout.css
    sed -i '' $'1a\\\n@import \'./design-token.css\';' src/lib/styles/layout.css
    sed -i "" "s@import './layout.css';@import '#lib/styles/layout.css';@" src/routes/+layout.svelte
    sed -i "" "s|tailwindStylesheet: './src/routes/layout.css'|tailwindStylesheet: './src/lib/styles/layout.css'|" prettier.config.js
  fi
  vsext bradlc.vscode-tailwindcss
fi

# pnpm dlx shadcn-svelte@latest init --reinstall \
#   --preset bIkeymG \
#   --skip-preflight \
#   --css src/lib/styles/shadcn.css \
#   --components-alias '#lib/components' \
#   --lib-alias '#lib' \
#   --utils-alias '#lib/utils' \
#   --hooks-alias '#lib/hooks' \
#   --ui-alias '#lib/components/ui'

# touch src/lib/styles/shadcn.css
# pnpm dlx shadcn-svelte@latest init \
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
#   --skip-preflight

# Web files
# npx @vite-pwa/assets-generator@latest --preset minimal-2023 static/img/favicons/favicon.svg
# https://www.sopyo.com/llms.txt
touch static/{humans.txt,manifest.json}
grep -qs '^Sitemap:' static/robots.txt || echo "\nSitemap: https://yourdomain.com/sitemap.xml" >>static/robots.txt
logo=${TMPDIR:-/tmp}/svelte-logo.svg
[[ -f $logo ]] || curl -fsSL -o $logo https://raw.githubusercontent.com/sveltejs/branding/master/svelte-logo.svg
[[ -f static/img/logo.svg ]] || cp $logo static/img/logo.svg
pnpm add -D -s --loglevel warn @profullstack/favicon-generator
pnpm pkg set \
  'scripts["gen:favicon"]'="fav -i ./static/img/logo.svg -o ./static/img/favicons --silent"

# Database
if installed drizzle-kit; then
  pnpm pkg set \
    'scripts["db:studio"]'="(sleep 2 && open https://local.drizzle.studio) & drizzle-kit studio" \
    'scripts["db:push"]'="drizzle-kit push --force"
  sed -i '' 's/strict: true/strict: false/' drizzle.config.ts
  vsext ckolkman.vscode-postgres
fi

# Better-Auth
if installed better-auth; then
  envset RATE_LIMIT_MAX 100
  envset RATE_LIMIT_WINDOW 60
  pnpm auth:schema
fi

# Docker
if [[ -f compose.yaml ]]; then
  mkdir -p docker
  mv compose.yaml docker/compose.yaml
  touch docker/{compose.dev.yaml,Dockerfile,Dockerfile.dockerignore}
  yq -i '.name = "sveltekit-project"' docker/compose.yaml
  yq -i '.volumes.pgdata.name = "pgdata"' docker/compose.yaml
  yq -i '.services.db.image = "postgres:18-alpine"' docker/compose.yaml
  sed -E -i '' "s/- (['\"]?)5432:5432/- \1127.0.0.1:5432:5432/" docker/compose.yaml
  pnpm dlx -s dclint -q --fix docker/compose.yaml
  pnpm pkg set \
    'scripts["docker:up"]'="docker compose up -d --build" \
    'scripts["docker:down"]'="docker compose down"
  envset COMPOSE_FILE "docker/compose.yaml:docker/compose.dev.yaml" .env
fi

# Cloudflare
# https://svelte.dev/docs/kit/adapter-cloudflare
if installed @sveltejs/adapter-cloudflare; then
  export WRANGLER_SEND_METRICS=false WRANGLER_LOG=error
  # pnpm add -D --loglevel warn @sveltejs/adapter-cloudflare wrangler
  # pnpm exec wrangler setup --yes
  # pnpm exec wrangler d1 create members-db
  # yq -i -o=json '
  #   .compatibility_flags = ["nodejs_compat"] |
  #   .vars.NODE_ENV = "production"
  # ' wrangler.jsonc
  # pnpm exec wrangler types ./src/cf-worker.d.ts
  # pnpm pkg set \
  #   'scripts["gen:wrangler:types"]'="wrangler types ./src/cf-worker.d.ts"
fi

# Claude
# TODO: claude init ?
# TODO: CLAUDE.md template ?
if [[ -d .claude ]]; then
  [[ -f AGENTS.md ]] && mv AGENTS.md .claude/CLAUDE.md
  installed prettier && echo "/.claude/skills/" >>.prettierignore
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

  vsext anthropic.claude-code
fi

if [[ -d .claude ]]; then
  # DESIGN.md
  touch .claude/DESIGN.md
  pnpm add -D -s --loglevel error @google/design.md
  pnpm dlx -s @google/design.md spec --rules >docs/DESIGN.spec.md
  # pnpm exec design.md spec --rules > docs/DESIGN.spec.md
  # 3. DESIGN.md'yi yazdır
  # pnpm exec design.md lint .claude/DESIGN.md
  # pnpm exec design.md export .claude/DESIGN.md --format css-tailwind > src/lib/styles/design-tokens.css

  pnpm pkg set \
    'scripts["design:lint"]'="design.md lint .claude/DESIGN.md" \
    'scripts["design:spec"]'="design.md spec --rules > docs/DESIGN.spec.md" \
    'scripts["design:sync"]'="design.md export .claude/DESIGN.md --format css-tailwind > src/lib/styles/design-tokens.css"

  # '.claude/DESIGN.md': [
  #   'pnpm design:lint',
  #   () => 'pnpm design:sync',
  #   () => 'git add src/lib/styles/design-tokens.css'
  # ]

#   node --input-type=module -e "
# import { loadFile, writeFile, builders } from 'magicast';
# const mod = await loadFile('lint-staged.config.js');
# mod.exports.default['.claude/DESIGN.md'] ??= builders.raw(\`[
#   'pnpm design:lint',
#   () => 'pnpm design:sync',
#   () => 'git add src/lib/styles/design-tokens.css'
# ]\`);
# await writeFile(mod, 'lint-staged.config.js');
# "
#   pnpm prettier --write lint-staged.config.js

fi

# VSCode
# TODO: launch.json
vscopy tasks.json '.tasks |= map(select(.label == "Svelte*"))'
vscopy settings.json 'with_entries(select(.key == (
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
)))'
vsext \
  svelte.svelte-vscode \
  antfu.iconify \
  christian-kohler.path-intellisense \
  usernamehw.errorlens \
  formulahendry.auto-rename-tag \
  editorconfig.editorconfig

# Github Actions
# TODO: Dependabot / Renovate → auto PR
# TODO: Versioning ?
# TODO: yml validation, is working ?
touch .github/workflows/{ci.yml,deploy.yml}
vsext github.vscode-github-actions

# Last Check
# npx npm-check-updates -u --target minor && npm install
# npm audit
# npm audit fix
# pnpm dlx knip
# https://osv.dev/
# go install github.com/google/osv-scanner/v2/cmd/osv-scanner@v2
# osv-scanner .
# https://github.com/GoogleChrome/lighthouse
# pnpm add -g lighthouse
pnpm up --loglevel error
pnpm --loglevel silent format --log-level=warn

# Docs
# TODO: docs/README.md
# TODO: README.md

# Git
# TODO: .gitignore ?
# [ -d .git ] || git init -q
if [[ ! -d .git ]]; then
  git init -q -b main
  git add .
  git commit -q -m "Initial commit"
  git switch -q -c dev
fi
# TODO: git remote add origin https://github.com/<your-gh-username>/<repository-name>
# git push -q -u origin main dev

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

pnpm pkg set \
  repository.type="git" \
  repository.url="git+https://github.com/suzel/sveltekit-project.git" \
  bugs.url="https://github.com/suzel/sveltekit-project/issues"
