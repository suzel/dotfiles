# Go

- Wrap errors with context: `fmt.Errorf("doing x: %w", err)`. Never drop an error.
- Pass `context.Context` as the first parameter of functions that do I/O.
- Define interfaces where they are used, not where they are implemented.
- Standard library first. No new dependency for a few lines.
- After changes, run `gofmt -w` and `go vet ./...`.
