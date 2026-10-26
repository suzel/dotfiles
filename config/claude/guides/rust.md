# Rust

- Libraries: typed errors with `thiserror`. Binaries: `anyhow` with `.context("doing x")`.
  Never drop an error.
- No `unwrap()` outside tests. `expect()` only for real invariants, with a message saying why
  it holds.
- Borrow before cloning: take `&str`, `&[T]`, `&Path` as parameters. Clone only when ownership
  is needed.
- Model state with enums and exhaustive `match`. No `_ =>` catch-all on your own enums.
- No `unsafe` without a `// SAFETY:` comment explaining why it is sound.
- Never hold a `Mutex` guard or `RefCell` borrow across `.await`.
- Standard library first. No new crate for a few lines.
- Before adding a crate, confirm on crates.io that it exists and is widely used. Add it with
  `cargo add`, not by writing a version from memory.
- Check a dependency's API in the locked version's source under `~/.cargo/registry/src` (run
  `cargo fetch` first), not from memory.
- After changes, run `cargo fmt`, `cargo clippy --all-targets -- -D warnings` and `cargo test`.
