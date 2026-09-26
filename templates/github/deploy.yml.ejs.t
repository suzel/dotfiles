<%_
  // "@su/My.App" → "su-my-app" (Cloudflare Pages allows [a-z0-9-])
  const project = pkg.name.toLowerCase().replace(/^@/, '').replace(/[^a-z0-9-]/g, '-')
  const isStatic = pkg.devDependencies?.['@sveltejs/adapter-static'] || pkg.dependencies?.['@sveltejs/adapter-static']
-%>
name: Deploy Website

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write
    concurrency:
      group: ${{ github.workflow }}-${{ github.ref }}
      cancel-in-progress: true

    steps:
      - name: Repository Checkout
        uses: actions/checkout@v7

      - name: Install pnpm
        uses: pnpm/action-setup@v6

      - name: Setup Node.js
        uses: actions/setup-node@v6
        with:
          node-version-file: "package.json"
          cache: "pnpm"

      - name: Install dependencies
        run: pnpm install

      - name: Build
        run: pnpm run build
<% if (isStatic) { -%>

      - name: Deploy
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
          packageManager: pnpm
          command: pages deploy build --project-name=<%- project %>

      - name: Purge Cloudflare Cache
        run: |
          curl -X POST "https://api.cloudflare.com/client/v4/zones/${{ secrets.CLOUDFLARE_ZONE_ID }}/purge_cache" \
            -H "Authorization: Bearer ${{ secrets.CLOUDFLARE_API_PURGE_TOKEN }}" \
            -H "Content-Type: application/json" \
            --data '{"purge_everything":true}'
<% } -%>
