#!/usr/bin/env zsh

# =============================================================================
# Rust Project Setup
# =============================================================================
# Configures a project created with cargo new: package meta, lints,
# crates, web crates with .env and Docker, Git hooks, editor settings,
# docs, Claude, GitHub workflows and Git. Source files come from the
# rust:: snippets.
# Run once from the project root, right after cargo new (--lib for a
# library, then cargo add axum for a web API with Postgres).
# Commits cargo's output first, so every change of this script
# is one reviewable commit. Public unless Cargo.toml has publish = false;
# public projects get docs and an MIT license.
# Usage: rust-setup.zsh
# Requires: cargo, rustc, git, gh, yq, lefthook
# pnpm for public projects
# =============================================================================

set -euo pipefail

readonly DOTFILES=${0:A:h:h}
readonly GIT_ID=~/.config/git/config.local
readonly AUTHOR_NAME=$(git config -f $GIT_ID user.name || true)
readonly AUTHOR_EMAIL=$(git config -f $GIT_ID user.email || true)
readonly GH_USER=$(gh api user -q .login 2>/dev/null || true)
readonly RUST_VERSION=${${${(z)$(rustc -V)}[2]}%.*}
readonly NAME=$(yq -ptoml -oy .package.name Cargo.toml 2>/dev/null || true)

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Helper Functions
toml() { yq -i -ptoml -otoml "$1" Cargo.toml; }
add_vscode_ext() {
  yq -i ".recommendations += [${(j:,:)${(qqq)@}}] |
    .recommendations |= unique" .vscode/extensions.json
}
add_dotenv() { grep -qs "^$1=" $3 || print -r -- "$1=$2" >>$3; }
sed_patch() { local b=$(<$1) && sed -i '' "${@:2}" $1 && [[ $(<$1) != "$b" ]]; }
jsonc() { grep -v '^\s*//' $1; }
pick_keys() { yq -py -oj "with_entries(select(.key == (${(j:,:)${(qqq)@}})))"; }
merge_json() { touch $1 && yq -i -py -oj '. * load("/dev/stdin")' $1; }

# Error trap
TRAPZERR() { error "Error at ${funcfiletrace[-1]}"; }

# Checks
[[ -f Cargo.toml && $NAME != (|null) ]] || {
  error "Not a Cargo package: run from its root"
  exit 1
}

# Commit cargo's output
[[ -d .git ]] || git init -q -b main
git rev-parse -q --verify HEAD >/dev/null || {
  git add -A && git commit -qm "chore: cargo new"
}

# Update package meta
info "Updating package meta..."
is_public=$([[ $(yq -ptoml -oy .package.publish Cargo.toml) == false ]] ||
  echo 1)
msrv=$RUST_VERSION url=https://github.com/$GH_USER/$NAME toml '
  .package.rust-version = strenv(msrv) |
  .package.repository = strenv(url)
'
[[ -n $is_public ]] && toml '.package.license = "MIT"'

# Clippy
# https://doc.rust-lang.org/clippy
info "Configuring Clippy..."
grep -q '^\[lints' Cargo.toml || print -r -- '
[lints.clippy]
undocumented_unsafe_blocks = "warn"' >>Cargo.toml

# Crates
# https://docs.rs/anyhow
# https://docs.rs/thiserror
info "Installing crates..."
[[ -f src/main.rs ]] && cargo add -q anyhow
[[ -f src/lib.rs ]] && cargo add -q thiserror

# Web
# https://github.com/tokio-rs/axum
# https://github.com/launchbadge/sqlx
if [[ $(yq -ptoml -oy .dependencies.axum Cargo.toml) != null ]]; then
  info "Configuring web..."
  features=(
    tokio/{macros,rt-multi-thread,signal}
    serde/derive
    tower-http/{trace,cors,timeout,request-id,compression-full}
    tracing-subscriber/{env-filter,json}
    sqlx/{runtime-tokio,tls-rustls,postgres,migrate,macros,uuid,chrono}
    uuid/{v7,serde}
    chrono/serde
  )
  cargo add -q tokio serde serde_json tower-http tracing tracing-subscriber \
    thiserror dotenvy sqlx uuid chrono -F ${(j:,:)features}
  cargo add -q --dev tower -F util
  crate=${NAME//-/_}
  url=postgres://postgres:postgres@localhost:5432/$crate
  for f in .env .env.example; do
    add_dotenv DATABASE_URL $url $f
    add_dotenv ADDR 127.0.0.1:3000 $f
    add_dotenv RUST_LOG info,$crate=debug,tower_http=debug $f
    add_dotenv COMPOSE_FILE docker/compose.yaml $f
    add_dotenv COMPOSE_PROJECT_NAME ${NAME:l} $f
  done
  grep -qx '/.env' .gitignore || echo '/.env' >>.gitignore
  mkdir -p migrations docker && touch migrations/.gitkeep
  touch docker/{compose.yaml,Dockerfile,Dockerfile.dockerignore}
fi

# Lefthook
# https://lefthook.dev
info "Configuring Lefthook..."
print -r -- 'pre-commit:
  jobs:
    - glob: "*.rs"
      run: cargo fmt
      stage_fixed: true

pre-push:
  jobs:
    - run: cargo clippy --all-targets -- -D warnings
    - run: cargo test' >lefthook.yml
lefthook install >/dev/null

# VSCode Settings
# https://code.visualstudio.com
info "Configuring VS Code..."
mkdir -p .vscode
settings=(
  'editor.formatOnSave'
  'files.insertFinalNewline'
  'files.trim*'
  'rust-analyzer.*'
  '[rust]'
  '[toml]'
)
jsonc $DOTFILES/config/vscode/settings.json | pick_keys $settings |
  merge_json .vscode/settings.json

# VSCode Extensions
[[ -f .vscode/extensions.json ]] ||
  print -r -- '{ "recommendations": [] }' >.vscode/extensions.json
add_vscode_ext \
  rust-lang.rust-analyzer \
  tamasfe.even-better-toml \
  fill-labs.dependi \
  vadimcn.vscode-lldb \
  usernamehw.errorlens

# Docs
# https://github.com/rafazafar/gh-scaffold
if [[ -n $is_public && ! -f LICENSE ]]; then
  info "Generating docs..."
  repo=$GH_USER/$NAME
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
info "Configuring Claude..."
mkdir -p .claude && touch .claude/CLAUDE.md
print -r -- '{
  "enabledPlugins": {
    "rust-analyzer-lsp@claude-plugins-official": true
  }
}' >.claude/settings.json
yq -oj '.mcpServers |= pick(
  ["grep-mcp", "semble", "web-fetch", "web-search"]
)' $DOTFILES/config/claude/mcp.json >.mcp.json
add_vscode_ext anthropic.claude-code
# The LSP plugin doesn't ship its binary; each teammate installs it once:
# rustup component add rust-analyzer

# Github Actions
info "Creating GitHub workflows..."
mkdir -p .github/workflows
touch .github/dependabot.yml .github/workflows/ci.yml

# Developer Tools
# Exempt apps' child processes from XProtect scans (faster Rust builds)
# Apps can't be added from the command line, so open the pane for that
# sudo spctl developer-mode enable-terminal
# open "x-apple.systempreferences:com.apple.preference.security?Privacy_DevTools"
# info "Developer Tools: enable Terminal, add Ghostty and VS Code, restart them."

# Last Check
info "Formatting & linting..."
cargo fmt
cargo clippy -q --all-targets -- -D warnings ||
  warn "Fix lint errors: cargo clippy --all-targets"

# Git
info "Committing..."
git add -A
git diff --cached --quiet || git commit -qm "chore: project setup"
git switch -q dev 2>/dev/null || git switch -qc dev

success "Completed!"
