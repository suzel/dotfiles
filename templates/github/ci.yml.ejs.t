<%# pnpm dlx ejs -n -l pkg ci.yml.ejs.t -f package.json -o .github/workflows/ci.yml -%>
<%_ const scripts = pkg.scripts ?? {} -%>
name: CI

on:
  push:
    branches:
      - main
      - dev
  pull_request:
    branches:
      - main
      - dev

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - uses: pnpm/action-setup@v6

      - uses: actions/setup-node@v6
        with:
          node-version-file: "package.json"
          cache: "pnpm"

      - name: Install dependencies
        run: pnpm install --frozen-lockfile
<% if (scripts.lint) { -%>

      - name: Run linter and formatter
        run: pnpm lint
<% } -%>
<% if (scripts.check) { -%>

      - name: Check
        run: pnpm check
<% } -%>
<% if (scripts.test) { -%>

      - name: Test
        run: pnpm test
<% } -%>
<% if (scripts.build) { -%>

      - name: Build
        run: pnpm build
<% } -%>
