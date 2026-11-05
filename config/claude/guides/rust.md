# Rust

- Libraries: typed errors with `thiserror`. Binaries: `anyhow` with `.context("doing x")`.
  Never drop an error.
- No `unwrap()`. `expect()` only for real invariants, with a message saying why it holds.
- Borrow before cloning: take `&str`, `&[T]`, `&Path` as parameters. Clone only when ownership
  is needed.
- Model state with enums and exhaustive `match`. No `_ =>` catch-all on your own enums.
- No `unsafe` without a `// SAFETY:` comment explaining why it is sound.

## Cargo

- Standard library first. No new crate for a few lines.
- Before adding a crate, run `cargo info <crate>` to confirm it exists and is the crate you
  mean. Add it with `cargo add`, not by writing a version from memory.
- Check a dependency's API in the locked version's source under `~/.cargo/registry/src` (run
  `cargo fetch` first), not from memory.
- After changes, run `cargo fmt` and `cargo clippy --workspace --all-targets -- -D warnings`.
- Fix warnings in the code instead of silencing them. If an exception is truly needed, put
  `#[expect(lint_name, reason = "why")]` on the smallest item, not `#[allow]`.

## Tests

- `unwrap()` is fine in tests.
- After changes, run `cargo test --workspace`.
