# VS Code snippets

Snippets live in ~/Library/Application Support/Code/User/snippets/, one file per area.

## Before adding a snippet

- Grep the snippets folder for each prefix and the name you plan to use, e.g.
  `grep -rn '"kit::page"' ~/Library/Application\ Support/Code/User/snippets/`. If either is
  taken, pick another.

## Naming

- Prefix: `area::name`, lowercase, e.g. `kit::load`, `github::deploy.yml`. Reuse an existing area
  before adding one. A short alias may follow as a second prefix: `["col::date", "date"]`.
- Name: `Area Thing`, e.g. `Kit Load`. A file template may use its file name, e.g. `CLAUDE.md`.
- Prefixes, aliases included, are unique per scope, and names are unique across files.
- Snippet names are references: `auto-snippets.snippets` in VS Code settings and
  `insertSnippet` in keybindings.json call them by name. When renaming, update them there too.

## Fields

- Key order: `scope`, `prefix`, the other fields, then `body` last.
- Always set `scope`. Without it the snippet shows in every language.
- Give every snippet a one-line `description` of what it inserts.
- A file template for a fixed file name sets `isFileTemplate: true` and `include` to that name,
  e.g. `compose.yaml`, `+page.svelte`. Add `exclude` for paths that must not get the template.
- A template that should fill new files on its own also goes in `auto-snippets.snippets`.

## Body

- Code in a body follows the guide for its language (see the list in CLAUDE.md).
- Exception: GitHub Actions in snippets stay on version tags (`@v7`), not commit SHAs.
- Every path, workflow, package or URL the body refers to must exist.
- Indent with `\t`. VS Code inserts it as the editor's indentation, 2 spaces in my projects.
- Text built by a `${VAR/regex/format/}` transform is not re-indented: indent it with 2 spaces.
- In a format, `${n:+text}` prints only when group n matched; `${n:?a:b}` needs both texts, and `a` can't
  contain `:`.
- Escape a literal `$` as `\\$`, e.g. `\\$state`, `\\$lib`, `\\${id}`, or VS Code reads it as a
  variable.

## Placeholders

- Number tab stops in the order the user fills them. End with `$0` where the cursor belongs.
- Offer a known set of values as a choice: `${1|a,b|}`.
- Derive a repeated name with a transform, e.g. `${1/(.*)/${1:/pascalcase}/}`, instead of asking
  for it twice.

## Comments

- Steps the user must take after inserting go in `TODO:` comments, short and actionable.
- Other comments explain what the generated code can't say, in one short line.
- Write comments and descriptions in English.

## After changes

- Check that each changed file still parses: JSON with comments and trailing commas.
- Confirm every name in `auto-snippets.snippets` and keybindings.json still exists.
- Update the snippet's row in its doc.

## Documentation

- Each snippet file has a doc in
  ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Personal/Development/Snippets/, e.g.
  `drizzle.code-snippets` → `Drizzle Snippets.md`. A new snippet file gets one in the same format.
- Format, in English with nothing else: `# <Area> Snippets`, one `##` per prefix area, each with a
  table: `Snippet | Alias | Language | Where | Template | Description | Requires`.
- Where comes from `include` / `exclude`, Description from the snippet's `description`. Put code
  in backticks: a bare `<svelte:head>` renders as HTML.
