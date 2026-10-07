#!/usr/bin/env node
/*
 * meta-gen mini: EJS templates + front-matter, optional meta.config.{js,mjs}
 *
 *   meta-gen [gen]                  list generators / actions
 *   meta-gen <gen> <action> [name] [--key value | --key=value | --flag]
 *            [--dry] [--force]
 *
 * ── Dependencies ─────────────────────────────────────────────────────────────
 *
 *   Node ≥ 24        brew "node" (module.registerHooks, RegExp.escape)
 *   @clack/prompts   npm "@clack/prompts"  prompts (loaded only when
 *                                          something is asked)
 *   ejs              npm "ejs"             template engine
 *   yaml             npm "yaml"            front-matter
 *
 *   All are in config/brew/Brewfile (npm Packages). Install: setup.zsh packages
 *   or just these: npm install -g @clack/prompts ejs yaml
 *   Global packages are required from $HOMEBREW_PREFIX/lib/node_modules
 *   (NODE_PATH works too).
 *   If missing: ✖ Cannot find module 'ejs'
 *     → npm install -g @clack/prompts ejs yaml
 *
 * ── Folder ($META_GEN_TEMPLATES or ./_templates) ─────────────────────────────
 *
 *   crud/new/
 *     meta.config.js        optional. Without it, variables come only from
 *                           the CLI (--key value)
 *     model.ts.ejs.t        template with front-matter
 *     src/app.ts.ejs.t      no front-matter → rendered to the same path:
 *                           src/app.ts
 *     static/logo.png       not .ejs / .t → copied without rendering
 *                           (binary too)
 *     _row.ejs, _util.js    paths with a segment starting with `_` or `.`
 *                           are not generated (partials, helpers)
 *
 * ── meta.config.js ───────────────────────────────────────────────────────────
 *
 *   import { up } from './_util.js'
 *
 *   export default {
 *     // Asked in order in the terminal via @clack/prompts. Not asked when
 *     // given on the CLI or when there is no terminal (TTY): the default is
 *     // used. Without `type`, it is inferred from the default
 *     prompts: {
 *       // text. Empty → error: Missing value: --name
 *       name:    { message: 'Entity name', required: true },
 *       // select
 *       kind:    { enum: ['page', 'layout'], default: 'page' },
 *       // multiselect (array + enum)
 *       methods: { enum: ['GET', 'POST'], default: ['GET'] },
 *       // text, comma-separated: "a,b" → ['a', 'b']
 *       fields:  { default: ['title', 'body'] },
 *       // confirm. CLI: y / yes / true / 1
 *       pages:   { type: 'boolean', default: true },
 *       // text. Not a number → error (CLI too)
 *       port:    { type: 'number', default: 3000 },
 *       // password (masked)
 *       token:   { format: 'password' },
 *       // dynamic default (may be async)
 *       table:   { default: (vars) => `${vars.name}s` },
 *     },
 *     // Never asked. Computed after the prompts, in definition order.
 *     // Overridable from the CLI (--srcDir lib)
 *     params: {
 *       srcDir: 'src',
 *       // sync or async
 *       Name: (vars) => vars.name[0].toUpperCase() + vars.name.slice(1),
 *     },
 *     helpers: { up }, // in templates: h.up(name)
 *   }
 *
 * ── Template: front-matter + EJS ─────────────────────────────────────────────
 *
 * Every key (use only what you need). Values are rendered too; one that
 * renders to '' or 'false' is off.
 * In templates: the variables, h, item, index. <%= %> does not HTML-escape.
 * include paths are relative to the template file: <%- include('_row') %>
 *
 *   ---
 *   to: src/<%= name %>.ts     # target. Skipped if it renders empty,
 *                              # e.g. "<%= pages ? 'x.ts' : '' %>"
 *   force: true                # overwrite an existing file (or --force).
 *                              # Otherwise it is skipped
 *   unless_exists: true        # skip if the file exists, even with --force
 *   each: fields               # once per array item: to: src/<%= item %>.ts
 *   inject: true               # insert into an existing file, unless the same
 *                              # lines are already there. Position (one of):
 *   at_line: 3                 #   0-based line number
 *   before: ^export default    #   regex or plain text. Error if not found
 *   after: ^import             #   after the line where the match ends
 *   prepend: true              #   start of the file
 *   append: true               #   end of the file (default when no position)
 *   skip_if: <%= Name %>       # don't insert if this matches the file
 *   sh: pnpm prettier --write src   # command. The rendered body goes to
 *                                   # its stdin (sh: bash -e → script)
 *   message: <%= Name %> ready # printed at the end, after all files
 *   ---
 *   export const <%= name %> = <%= port %>
 */
import { execSync } from 'node:child_process'
import { existsSync, realpathSync } from 'node:fs'
import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises'
import { createRequire, registerHooks } from 'node:module'
import { dirname, join, relative, resolve } from 'node:path'
import { pathToFileURL } from 'node:url'

process.on('uncaughtException', (e) => {
  // syntax errors (EJS's already name the file): Node prints file and line
  if (e instanceof SyntaxError && !e.message.includes('while compiling ejs'))
    throw e
  const hint =
    e.code === 'MODULE_NOT_FOUND' ? ' → npm install -g @clack/prompts ejs yaml'
    : ''
  console.error(`✖ ${hint ? e.message.split('\n')[0] : e.message}${hint}`)
  process.exit(1)
})

// Global deps (Brewfile): `import` can't see them, require can (NODE_PATH too)
const require = createRequire(
  join(process.env.HOMEBREW_PREFIX ?? '/opt/homebrew', 'lib/node_modules/'),
)
const ejs = require('ejs')
const { parse } = require('yaml')

const log = (op, to) => console.log(`  ${op.padEnd(9)} ${to}`)
const dirs = async (p) =>
  (await readdir(p, { withFileTypes: true }))
    .filter((d) => d.isDirectory())
    .map((d) => d.name)

// CLI values and answers are text; type: prompt's `type`, else its default's
const coerce = (v, type) =>
  typeof v !== 'string' ? v
  : type === 'boolean' ? /^(y|yes|true|1)$/i.test(v)
  : type === 'number' ? Number(v)
  : type === 'array' ? v.split(',').map((s) => s.trim()).filter(Boolean)
  : v

// One clack prompt per type; clack is loaded only when something is asked
async function ask(k, p, type, def) {
  const clack = require('@clack/prompts')
  const message = p.message ?? k
  const options = p.enum?.map((value) => ({ value }))
  const validate = (s) =>
    !s ? (p.required && def === undefined ? 'Required' : undefined)
    : type === 'number' && isNaN(s) ? 'Enter a number'
    : undefined
  const answer =
    type === 'boolean' ? await clack.confirm({ message, initialValue: def })
    : options && type === 'array' ?
      await clack.multiselect({
        message,
        options,
        initialValues: def,
        required: !!p.required,
      })
    : options ? await clack.select({ message, options, initialValue: def })
    : p.format === 'password' ? await clack.password({ message, validate })
    : await clack.text({
        message,
        placeholder: def?.toString(),
        defaultValue: def?.toString(),
        validate,
      })
  if (clack.isCancel(answer)) {
    clack.cancel('Cancelled')
    process.exit(1)
  }
  return answer === '' ? def : answer
}

// An invalid regex is searched as plain text (e.g. `const components = [`)
const regex = (s) => {
  try {
    return new RegExp(s, 'm')
  } catch {
    return new RegExp(RegExp.escape(s), 'm')
  }
}

// New content or null; at_line > before > after > prepend > append (default)
function inject(cur, text, a, to) {
  // line endings follow the file: work in LF, convert back at the end
  const crlf = cur.includes('\r\n')
  cur = cur.replaceAll('\r\n', '\n')
  text = text.replaceAll('\r\n', '\n')
  // already there = the same whole lines (`.env` is not in `.env.local`)
  if (
    !text.trim() ||
    `\n${cur}\n`.includes(`\n${text.trimEnd()}\n`) ||
    (a.skip_if && regex(a.skip_if).test(cur))
  )
    return null
  let at = a.prepend ? 0 : cur.length
  const anchor = a.before ?? a.after
  if (a.at_line != null) {
    // 0-based: at_line: 1 → before the second line
    at = Math.min(
      cur.split('\n').slice(0, a.at_line).reduce((n, l) => n + l.length + 1, 0),
      cur.length,
    )
  } else if (anchor) {
    const hit = regex(anchor).exec(cur)
    if (!hit) throw new Error(`${to}: '${anchor}' not found`)
    // before: start of the match's line, after: end of the line it ends on
    at = a.before
      ? hit.index && cur.lastIndexOf('\n', hit.index - 1) + 1
      : cur.indexOf('\n', hit.index + Math.max(hit[0].length - 1, 0)) + 1 ||
        cur.length
  }
  const nl = at === cur.length && cur && !cur.endsWith('\n') ? '\n' : ''
  const out = cur.slice(0, at) + nl + text + cur.slice(at)
  return crlf ? out.replaceAll('\n', '\r\n') : out
}

// ── argv ── ponytail: by hand, parseArgs reads `--name shop` as a flag
const argv = process.argv.slice(2)
const pos = []
const args = {}
for (let i = 0; i < argv.length; i++) {
  if (!argv[i].startsWith('--')) {
    pos.push(argv[i])
    continue
  }
  const [k, v] = argv[i].slice(2).split(/=(.*)/s)
  // --dry / --force never take the next argument (--force=false works)
  args[k] =
    k === 'dry' || k === 'force' ? coerce(v ?? 'true', 'boolean')
    : v ?? ((argv[i + 1] ?? '--').startsWith('--') || argv[++i])
}
const [gen, action, name] = pos
const { dry, force, ...vars } = args

// --dry: files "written" so far, so later templates can inject into them
const mem = {}
async function put(to, content, a = {}) {
  const path = resolve(to)
  const exists = path in mem || existsSync(path)
  if (a.inject) {
    const cur = mem[path] ?? (await readFile(path, 'utf8'))
    content = inject(cur, content.replace(/\n?$/, '\n'), a, to)
    if (content === null) return log('skip', to)
  } else if (exists && (a.unless_exists || !(force || a.force))) {
    return log('exists', to)
  }
  log(a.inject ? 'inject' : exists ? 'overwrite' : 'add', to)
  if (dry) return void (mem[path] = content)
  await mkdir(dirname(path), { recursive: true })
  await writeFile(path, content)
}

// ── generator ──
const root = resolve(process.env.META_GEN_TEMPLATES ?? '_templates')
const dir = join(root, gen ?? '', action ?? '')
if (!existsSync(dir)) throw new Error(`Template folder not found: ${dir}`)
if (!action) {
  for (const g of gen ? [gen] : await dirs(root))
    console.log(`${g}: ${(await dirs(join(root, g))).join(', ')}`)
  process.exit()
}
if (name !== undefined) vars.name ??= name

// templates' .js is always ESM (realpath: the loader sees resolved symlinks)
const rootUrl = pathToFileURL(realpathSync(root) + '/').href
registerHooks({
  load: (url, ctx, next) =>
    url.startsWith(rootUrl) && url.endsWith('.js') ?
      next(url, { ...ctx, format: 'module' })
    : next(url, ctx),
})
const cfgFile = ['js', 'mjs']
  .map((e) => join(dir, `meta.config.${e}`))
  .find(existsSync)
const cfg = cfgFile ? (await import(pathToFileURL(cfgFile).href)).default : {}
const { prompts = {}, params = {}, helpers: h = {} } = cfg

// ── values ── prompts (TTY, not given on the CLI), then params in order
for (const [k, p] of Object.entries(prompts)) {
  // resolve a dynamic default first: its value decides the type (CLI too)
  const def =
    typeof p.default === 'function' ? await p.default(vars) : p.default
  const type = p.type ?? (Array.isArray(def) ? 'array' : typeof def)
  const v =
    vars[k] ?? (process.stdin.isTTY ? await ask(k, p, type, def) : def)
  if (p.required && `${v ?? ''}` === '')
    throw new Error(`Missing value: --${k}`)
  vars[k] = coerce(v, type)
  if (Number.isNaN(vars[k])) throw new Error(`Not a number: --${k}`)
}
for (const [k, v] of Object.entries(params))
  vars[k] ??= typeof v === 'function' ? await v(vars) : v

// ── files ──
const files = (await readdir(dir, { recursive: true, withFileTypes: true }))
  .filter((d) => d.isFile())
  .map((d) => relative(dir, join(d.parentPath, d.name)))
  .filter((rel) => !/^meta\.config\.|(^|\/)[_.]/.test(rel))
  .sort()

const messages = []
for (const rel of files) {
  const file = join(dir, rel)
  const to = rel.replace(/(\.ejs)?(\.t)?$/, '') // a/b.ts.ejs.t → a/b.ts
  if (to === rel) {
    // not .ejs / .t: copied to the same path without rendering (binary too)
    await put(rel, await readFile(file))
    continue
  }
  const src = await readFile(file, 'utf8')
  const fm = /^\uFEFF?---\r?\n(.*?)(?<=\n)---\r?\n?/s.exec(src)
  // without front-matter the folder layout is mirrored
  const attrs = fm ? (parse(fm[1]) ?? {}) : { to }
  const body = fm ? src.slice(fm[0].length) : src
  // each: one render per array item, with item / index in the template
  const items =
    attrs.each ? [].concat(coerce(vars[attrs.each] ?? [], 'array'))
    : [undefined]

  for (const [index, item] of items.entries()) {
    const locals = { ...vars, h, item, index }
    // ponytail: escaping off, we generate code (keeps Map<K, V> intact)
    const opts = { filename: file, escape: (x) => x }
    const render = (s) =>
      typeof s === 'string' ? ejs.render(s, locals, opts) : s
    // YAML parses before EJS: `force: <%= flag %>` arrives as 'false'
    const a = Object.fromEntries(
      Object.entries(attrs)
        .map(([k, v]) => [k, render(v)])
        .map(([k, v]) => [k, v === 'false' ? false : v]),
    )
    // a skipped template's body may not even render
    const text = a.to || a.sh ? render(body) : ''
    // empty `to` = skip (conditional generation)
    if (a.to) await put(a.to, text, a)
    if (a.sh) log('sh', a.sh)
    if (a.sh && !dry)
      execSync(a.sh, { input: text, stdio: ['pipe', 'inherit', 'inherit'] })
    if (a.message) messages.push(a.message)
  }
}
for (const m of messages) console.log(m)
