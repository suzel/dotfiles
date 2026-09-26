<%_
  const deps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };
  const isStatic = Boolean(deps['@sveltejs/adapter-static']);
-%>
import { env } from '$env/dynamic/public';
import type { RequestHandler } from './types';
<% if (isStatic) { %>
export const prerender = true;
<% } %>
export const GET: RequestHandler = ({ url }) => {
  const SITE_URL = env.PUBLIC_SITE_URL || url.origin;

  const body = `
    # www.robotstxt.org
    
    # Allow crawling of all content
    User-agent: *

    # Disallow private paths
    Disallow: /404.html
<%_ if (!isStatic) { _%>
    Disallow: /admin
    Disallow: /api
    Disallow: /account
    Disallow: /sign-in
    Disallow: /sign-up
<%_ } _%>

    # Sitemap
    Sitemap: ${SITE_URL}/sitemap.xml
  `
    .replace(/^[^\S\r\n]+/gm, '')
    .trim();

  return new Response(body, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'public, max-age=3600, s-maxage=3600, stale-while-revalidate=86400'
    }
  });
};