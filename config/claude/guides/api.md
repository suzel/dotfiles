# REST APIs

- An existing API's conventions win over this guide: match its other endpoints.
- Paths are plural nouns, with `/orders/{id}` for one item. Nest one level at most:
  `/users/{id}/orders`. An action that isn't plain CRUD is a POST to a sub-path:
  `POST /orders/{id}/cancel`.
- GET never changes state. POST creates and returns 201 with a `Location` header and the new
  resource. Updates are PATCH; PUT only when the client sends the whole resource. DELETE
  returns 204.
- PATCH merges: an absent field stays unchanged, `null` clears it. The request type must tell
  the two apart.
- POSTs where a duplicate is costly (orders, payments) take an `Idempotency-Key` header and
  return the stored response when a key repeats.
- Status codes: 400 when the body or query can't be parsed, 422 when validation fails, 409
  when the request conflicts with current state (duplicate, invalid transition). 401 when not
  authenticated, 403 when not allowed, 404 instead of 403 when the resource's existence is
  private. 429 with `Retry-After`. Never 200 with an error in the body.
- Errors are `{"error": {"code", "message", "details": [{"field", "message"}]}}`. `code` is a
  stable string clients branch on (`email_taken`), `message` is for people, `details` lists
  every invalid field, not just the first. 5xx bodies never expose internals such as SQL or
  stack traces: log them and return a generic message.
- Query parameters filter, sort and paginate, never act: `?status=paid&sort=-created_at`. No
  tokens or passwords in paths or query strings: they end up in logs.
- Path segments, query parameters and JSON fields are snake_case. Timestamps are RFC 3339 in
  UTC (`2026-10-28T09:30:00Z`), dates `YYYY-MM-DD`. IDs are strings: JavaScript loses integers
  above 2^53. Money is integer minor units (cents) with a currency code, never a float.
- Paginate every list from the first version, since adding it later breaks clients:
  `?limit=20&cursor=...`, response `{"data": [...], "next_cursor": "..."}` with `null` on the
  last page. `limit` has a maximum. Never a bare top-level array.
- Breaking changes: removing, renaming or retyping a response field or making it nullable, a
  new required request field, stricter validation, a changed status or error code. A new enum
  value breaks clients that reject unknown values. Say so before making any of these. Adding
  an optional field is safe as long as clients ignore unknown fields.
- Version with a `/v1` path prefix. Bump it only for breaking changes and keep the old version
  until its clients have moved.
