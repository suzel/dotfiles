# =============================================================================
# Go Project Creation — UNDER DEVELOPMENT
# =============================================================================
# Notes and TODOs only, nothing runs yet.
# Go counterpart of sv-setup.zsh: creates an API with go-blueprint, then
# configures tooling, database, logging, editor settings and Git.
# Usage: go-create.zsh <name>
# Requires: go, go-blueprint, git, gh, docker
# =============================================================================

# TODO: write it like sv-setup.zsh: set -euo pipefail, log functions,
#   error trap, checks; then chmod +x

# Go commands
# https://go.dev/doc/modules/managing-dependencies
# By hand; go-blueprint runs init, get and tidy itself.
# go mod init github.com/<user>/<name>  new project: writes go.mod
# go get <module>@latest                add or update a package
# go get -u ./...                       update all packages
# go get -tool <module>@latest          dev tool in go.mod, run: go tool <name>
# go mod tidy                           sync go.mod and go.sum with the imports
# go install <module>@latest            CLI into ~/go/bin, outside the project
# go run ./cmd/api                      build and run
# go build -o main ./cmd/api            build a binary
# go test ./...                         run the tests
# go vet ./... && go fmt ./...          check and format

# Create
# https://go-blueprint.dev
#   go install github.com/melkeydev/go-blueprint@latest (Brewfile)
# go-blueprint create -n my_project \
#   -f standard-library \
#   -d postgres -a \
#   --feature githubaction \
#   --feature docker \
#   -g commit
# Gives cmd/api, internal/{server,database}, Makefile, .air.toml, .env,
# Docker, CI + goreleaser and testcontainers tests (make itest).
# -g commit commits that output first, like sv-setup does with sv's.
# TODO: name from $1 instead of my_project; stop if the folder exists
# TODO: module path github.com/<gh user>/<name>, not the bare name

# Live reload
# https://github.com/air-verse/air
#   go install github.com/air-verse/air@latest (Brewfile)
#   Init: air init → .air.toml (blueprint writes one; run: make watch)

# Env
# Blueprint's .env is gitignored: BLUEPRINT_DB_* with demo credentials.
# TODO: rename BLUEPRINT_DB_* to DB_* (or one DATABASE_URL)
# TODO: commit a .env.example

# Lint
# https://golangci-lint.run
#   brew install golangci-lint
#   No init: write .golangci.yml, check it with golangci-lint config verify
# TODO: Brewfile: brew "golangci-lint" (installed, but not listed)
# TODO: .golangci.yml (v2) and a make lint target

# Logging
# https://pkg.go.dev/log/slog
# https://github.com/uber-go/zap
# https://github.com/rs/zerolog
# slog is stdlib and enough; zap/zerolog only if profiling asks for it:
#   go get go.uber.org/zap
#   go get github.com/rs/zerolog
# TODO: blueprint logs with log.Println: switch to slog, JSON handler
#   unless APP_ENV=local

# API
# Blueprint has / (hello), /health (DB stats), allow-all CORS and
# graceful shutdown.
# TODO: health: DB down → Health() log.Fatalf's and the server exits;
#   return 503 and keep DB stats internal
# TODO: common response: writeJSON/writeError helpers, one error shape
# TODO: CORS: allowed origins from env instead of *
# TODO: auth: session cookie + sessions table, or JWT? decide per project
# TODO: drop the / hello route: it catches every path, nothing 404s

# Database
# https://github.com/golang-migrate/migrate
#   brew install golang-migrate
#   go get github.com/golang-migrate/migrate/v4 (only to migrate from the app)
#   Init: migrate create -ext sql -dir migrations -seq init
# https://github.com/sqlc-dev/sqlc
#   go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest (Brewfile)
#   Init: sqlc init → empty sqlc.yaml
# TODO: Brewfile: brew "golang-migrate" (go install needs -tags postgres)
# TODO: migrations/ folder + make migrate-up / migrate-new targets
# TODO: sqlc.yaml: schema = migrations/ (sqlc skips .down.sql),
#   queries in queries/, make generate
# TODO: sqlc driver: database/sql like blueprint, or pgx/v5 + pgxpool?

# Docker
# Blueprint: Dockerfile (golang:1.24.4-alpine → alpine:3.20.1) and
# docker-compose.yml (app + postgres:latest).
# TODO: golang image from go.mod's go line: an older one fails the build
#   (the image sets GOTOOLCHAIN=local)
# TODO: smallest image: CGO_ENABLED=0 + distroless/static or scratch
# TODO: pin postgres to a major tag: latest jumps majors and the old
#   volume no longer starts
# TODO: .dockerignore (.git, .env, tmp/)

# CI / Release
# https://github.com/goreleaser/goreleaser
#   brew install goreleaser (local goreleaser check; CI uses the action)
#   Init: goreleaser init (blueprint already writes .goreleaser.yml)
# Blueprint (githubaction): go-test.yml (build + test), release.yml +
# .goreleaser.yml.
# TODO: setup-go pins '1.22.x': use go-version-file: go.mod
# TODO: lint (golangci-lint-action) and osv-scanner steps
# TODO: Docker-only API: drop release.yml + .goreleaser.yml
#   (goreleaser ships binaries; keep them for CLIs)

# VS Code
# Global settings already format Go with golang.go.
# TODO: _Go: tasks in config/vscode/tasks.json, copied like sv-setup's
# TODO: add_vscode_ext golang.go; launch.json for cmd/api (dlv)

# Docs
# TODO: public repos: sv-setup's gh-scaffold step; a real README

# Git
# https://github.com/evilmartians/lefthook
#   go install github.com/evilmartians/lefthook/v2@latest (Brewfile)
#   Init: lefthook install (hooks + a blank lefthook.yml if missing)
# git init + first commit: -g commit (see Create)
# TODO: .gitignore: drop .vscode (blueprint ignores it, sv-setup
#   commits .vscode)
# TODO: hooks: lefthook.yml with pre-commit gofmt + golangci-lint
# TODO: gh repo create <name> --private --source . --push
