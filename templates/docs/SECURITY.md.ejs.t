<%_
  // repository.url | homepage → "u/r"
  const slug = (pkg.repository?.url ?? pkg.repository ?? pkg.homepage ?? '')
    .replace(/^(git\+)?(ssh:\/\/)?git@github\.com[:/]/, 'https://github.com/')
    .replace(/(\.git)?(#.*)?$/, '')
    .match(/github\.com\/([^/]+\/[^/]+)/)?.[1]

  // "Name <mail> (url)" | { email }
  const email = typeof pkg.author === 'string' ? pkg.author.match(/<(.+?)>/)?.[1] : pkg.author?.email
-%>
# Security Policy

## Supported Versions

Security updates are applied to the latest release on the `dev` branch. Older versions are not supported.

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| older   | :x:                |

## Reporting a Vulnerability

**Do not open public GitHub issues for security vulnerabilities.**

If you discover a security vulnerability, please report it privately using one of the following channels:

<% if (slug) { -%>
- **Preferred:** [GitHub Security Advisories](https://github.com/<%- slug %>/security/advisories/new) — Use the "Report a vulnerability" button to open a private advisory.
<% } -%>
<% if (email) { -%>
- **Email:** <<%- email %>> — Use subject line `[SECURITY] <%- pkg.name %>: <short description>`.
<% } -%>

### What to include

To help us triage quickly, include:

- A description of the vulnerability and its potential impact.
- Steps to reproduce, including affected commit SHA, route, or endpoint.
- Any proof-of-concept code, screenshots, or logs (redact secrets).
- Your assessment of severity (CVSS score optional).
- Whether the issue is already public or under coordinated disclosure elsewhere.

### What to expect

- **Acknowledgement** within 72 hours of report receipt.
- **Initial triage** within 7 days, including severity assessment and a planned remediation window.
- **Fix and disclosure** coordinated with the reporter. Public disclosure typically follows the patched release; we will credit reporters who wish to be named.

### Scope

In scope:

- The SvelteKit application code in this repository.
- Build, CI, and deployment configuration committed to this repository.
- Dependencies pinned by this repository's lockfile (vulnerabilities are reported upstream, but coordination here is welcome).

Out of scope:

- Third-party services the application connects to (report directly to those vendors).
- Self-hosted forks or modifications not present in this repository.
- Social engineering, physical attacks, or denial-of-service via volumetric attacks.

## Safe Harbor

Good-faith security research conducted under this policy is authorized. We will not pursue legal action against researchers who:

- Make a good-faith effort to avoid privacy violations, data destruction, and service disruption.
- Report vulnerabilities promptly and do not exploit them beyond what is necessary to demonstrate impact.
- Give us reasonable time to remediate before public disclosure.
