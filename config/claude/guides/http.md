# HTTP scenarios

Requests and API tests are .http files run with httpyac. Use httpyac syntax; REST Client syntax
doesn't work.

Everything lives in an http folder: .httpyac.json marks the root, http-client.env.json holds the
environments, http-client.private.env.json holds the secrets and is gitignored. Shared requests
such as auth go in their own file, flows go under scenarios. httpyac ignores $shared, so repeat
values in each environment.

Name every request. Refer to an earlier request's response by its name and mark it with @ref so
it runs first. Share requests across files with @import. Capture headers in a script block after
the request.

Assert with ?? lines. Use a test block only for checks ?? can't express. Group requests with tags.
Nothing that asks for input.

Always run with --all, --name or --tag, otherwise httpyac asks which request to send.

Scenarios clean up what they create, so they can run again. Never read or print the private env
file.

## Rust

Rust projects use Hurl instead of httpyac; the rules above don't apply there.

One scenario per .hurl file in the http folder. Variables come from the project's .env, which
Hurl reads as is. Never read or print .env.

Run with hurl --test and the .env as the variables file. Add --very-verbose to see a failing
request, --jobs 1 when files depend on order.

Take values from responses with Captures and check them with Asserts. Files can't import each
other, so each scenario logs in itself. Scenarios clean up what they create.
