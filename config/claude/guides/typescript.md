# TypeScript

- Write TypeScript in strict mode.
- No `any`. Use `unknown` and narrow it.
- No `as` casts or `!` non-null assertions, except right after a runtime check.
- Validate external data (API, JSON, env, form input) at the boundary with the
  project's schema library. Never trust a cast.
- Let inference work. Annotate only exported function parameters and return types.
- String literal unions or `as const` objects over `enum`.
- Use `satisfies` to check object literals without widening them.
- Model variants as discriminated unions and end each `switch` with a `never` check.
- Use `import type` for type-only imports.
- No `@ts-ignore`. Use `@ts-expect-error` only with a one-line reason.
- After changes, run the project's type check (`tsc --noEmit` or `svelte-check`).
