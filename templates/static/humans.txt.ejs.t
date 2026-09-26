<%# pnpm dlx ejs -n -l pkg humans.txt.ejs.t -f package.json -o static/humans.txt -%>
<%_
  const deps = { ...pkg.dependencies, ...pkg.devDependencies }

  // "Name <mail> (url)" | { name, email, url }
  const author = typeof pkg.author === 'string'
    ? {
        name: pkg.author.replace(/\s*[<(].*/, ''),
        email: pkg.author.match(/<(.+?)>/)?.[1],
        url: pkg.author.match(/\((.+)\)/)?.[1],
      }
    : pkg.author ?? {}

  const standards = ['HTML5', 'CSS3', deps.typescript ? 'TypeScript' : 'JavaScript']
  const components = [
    'SvelteKit',
    deps.tailwindcss && 'TailwindCSS',
    (deps['drizzle-orm'] || deps['drizzle-kit']) && 'Drizzle ORM',
    deps['better-auth'] && 'Better Auth',
    deps.zod && 'Zod',
  ].filter(Boolean)
-%>
/* TEAM */
<% if (author.name) { -%>
Developer: <%- author.name %>
<% } -%>
<% if (author.email) { -%>
Contact: <%- author.email %>
<% } -%>
<% if (author.url) { -%>
Site: <%- author.url %>
<% } -%>

/* SITE */
Doctype: HTML5
Standards: <%- standards.join(', ') %>
Components: <%- components.join(', ') %>
Software: Visual Studio Code
