<%# pnpm dlx ejs -n -l pkg README.md.ejs.t -f package.json -o README.md -%>
<%_
  // repository.url | homepage → "u/r"
  const slug = (pkg.repository?.url ?? pkg.repository ?? pkg.homepage ?? '')
    .replace(/^(git\+)?(ssh:\/\/)?git@github\.com[:/]/, 'https://github.com/')
    .replace(/(\.git)?(#.*)?$/, '')
    .match(/github\.com\/([^/]+\/[^/]+)/)?.[1]

  // "Name <mail> (url)" | { name, url }
  const author = typeof pkg.author === 'string'
    ? { name: pkg.author.replace(/\s*[<(].*/, ''), url: pkg.author.match(/\((.+)\)/)?.[1] }
    : pkg.author ?? {}
  const authorLink = author.url ? `[${author.name}](${author.url})` : author.name

  // "my-app" → "My App"
  const title = pkg.name.replace(/[-_]/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())

  // ">=25" → " (v25 or later)"
  const since = (range) => (range ? ` (${range.replace(/^>=\s*(.+)/, 'v$1 or later')})` : '')

  const deps = { ...pkg.dependencies, ...pkg.devDependencies }
-%>
# <%- title %>

<% if (slug) { -%>
[![Workflow][workflow-icon]][workflow-url]
[![Commit][commit-icon]][commit-url]
<% } -%>
[![Svelte][svelte-icon]][svelte-url]
[![Platform][platform-icon]][platform-url]
<% if (deps.prettier) { -%>
[![CodeStyle][prettier-icon]][prettier-url]
<% } -%>
<% if (deps.eslint) { -%>
[![Linter][eslint-icon]][eslint-url]
<% } -%>
<% if (pkg.license) { -%>
[![License][license-icon]][license-url]
<% } -%>
<% if (pkg.description) { -%>

<%- pkg.description %>
<% } -%>

## Requirements

- [Node.js](https://nodejs.org/)<%- since(pkg.engines?.node) %>
- [pnpm](https://pnpm.io/)<%- since(pkg.engines?.pnpm) %>

## Getting Started

Follow these steps to set up and run the project locally.
<% if (slug) { -%>

### Clone this Repository

Clone the repository to your local machine.

```sh
git clone https://github.com/<%- slug %>.git
```
<% } -%>

### Installation

Install project dependencies with pnpm.

```sh
pnpm install
```
<% if (pkg.scripts?.dev) { -%>

### Development

Start the development server and open the project in your browser at `http://localhost:5173`

```sh
pnpm run dev
```
<% } -%>
<% if (pkg.scripts?.build) { -%>

### Build

Build the project for production.

```sh
pnpm run build
```
<% } -%>
<% if (author.name) { -%>

## Contributors

<%- authorLink %>
<% } -%>

<% if (slug) { -%>
[workflow-icon]: https://github.com/<%- slug %>/actions/workflows/deploy.yml/badge.svg
[workflow-url]: https://github.com/<%- slug %>/actions/workflows/deploy.yml
[commit-icon]: https://img.shields.io/github/last-commit/<%- slug %>?style=flat-square
[commit-url]: https://github.com/<%- slug %>/commits/main
<% } -%>
[svelte-icon]: https://img.shields.io/badge/framework-sveltekit-%23ff3e00.svg?style=flat-square
[svelte-url]: https://svelte.dev/docs/kit
[platform-icon]: https://img.shields.io/badge/macOS-gray?style=flat-square&logo=apple&logoColor=white
[platform-url]: https://www.apple.com/macos
<% if (deps.prettier) { -%>
[prettier-icon]: https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square
[prettier-url]: https://github.com/prettier/prettier
<% } -%>
<% if (deps.eslint) { -%>
[eslint-icon]: https://img.shields.io/badge/linter-eslint-4b32c3.svg?style=flat-square
[eslint-url]: https://github.com/eslint/eslint
<% } -%>
<% if (pkg.license) { -%>
[license-icon]: https://img.shields.io/badge/license-<%- pkg.license %>-blue.svg?style=flat-square
[license-url]: LICENSE
<% } -%>
