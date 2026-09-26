<%_
  const deps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };
  const isStatic = Boolean(deps['@sveltejs/adapter-static']);
-%>
import { env } from "$env/dynamic/public";
import type { RequestHandler } from "./types";
<% if (isStatic) { %>
export const prerender = true;
<% } %>
export const GET: RequestHandler = ({ url }) => {
  const SITE_URL = env.PUBLIC_SITE_URL || url.origin;

  const urls: {
    loc: string;
    lastmod?: string;
    changefreq?: string;
    priority?: string;
  }[] = [];

  // Manual entries
  urls.push({ loc: "/", changefreq: "weekly", priority: "1.0" });

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
          <urlset
            xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml"
        xmlns:mobile="http://www.google.com/schemas/sitemap-mobile/1.0"
        xmlns:news="http://www.google.com/schemas/sitemap-news/0.9"
        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
        xmlns:video="http://www.google.com/schemas/sitemap-video/1.1"
          >
        ${urls
          .map(
            (url) => `
            <url>
              <loc>${SITE_URL}${url.loc}</loc>${url.lastmod ? `<lastmod>${url.lastmod}</lastmod>\n` : ""}
              ${url.changefreq ? `<changefreq>${url.changefreq}</changefreq>\n` : ""}
              ${url.priority ? `    <priority>${url.priority}</priority>\n` : ""}
            </url>`,
          )
          .join("\n")}
    </urlset>`.trim();

  return new Response(xml, {
    headers: {
      "Content-Type": "application/xml; charset=utf-8",
      "Cache-Control":
        "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400",
    },
  });
};