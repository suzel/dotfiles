# HTTP scenarios

- Requests and API tests are `.http` files run with httpyac: the httpYac VS Code extension and
  the `httpyac` CLI. REST Client syntax such as `{{login.response.body.$.id}}` fails in httpyac.
- Layout: `http/` with `.httpyac.json` (marks the root), `http-client.env.json` (environments,
  committed), `http-client.private.env.json` (secrets, gitignored), shared requests such as
  `auth.http`, and flows under `scenarios/`. httpyac ignores `$shared`: repeat values per
  environment.
- Name every request with `# @name`. Use its response as `{{name.field}}` and add `# @ref name`
  so it runs first. Share requests across files with `# @import ./auth.http`.
- Capture a header in a script block after the request, `{{` and `}}` on their own lines:
  `exports.token = response.headers['set-auth-token'];`
- Assert with `??` lines: `?? status == 201`, `?? js response.parsedBody.id == {{id}}`. Use a
  `{{ test(...) }}` block only for checks `??` can't express.
- Scenarios clean up what they create, so they can run again.
- Group requests with `# @tag`. Nothing that asks for input: `$input`, `$password`, `$pick`.
- Never read or print `http-client.private.env.json`.
- Always pass `--all`, `--name` or `--tag`, otherwise httpyac asks which request to send:
  `httpyac send <file> --tag smoke -e dev --var id=1 --filter only-failed -o none`. Add `--json`
  for each request's file, line and test results, `--bail` to stop at the first failure. Exit
  code 0 means all passed.
- `--repeat N --repeat-mode parallel` merges responses into status counts, so only `?? status`
  asserts work there.
