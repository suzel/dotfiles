# Zsh scripts

- Minimalism first: fewest lines that work.
- No unrequested options, flags or helpers.
- Max 80 columns. One-line conditionals over if blocks.
- Start: shebang, strict mode, readonly UPPER_SNAKE constants.
- Then logs: info, warn, error, success.
- Then error trap, required command checks, steps.
- Function variables: local, lowercase.
- Zsh builtins over external tools. Data via `print -r --`.
- macOS only: BSD tools, no GNU flags.
- Safe to rerun. Never delete via empty variables.
- Call `sudo` inside, never run as root.
- Short comment above each function. None inside.
- Format with `shfmt -w`, no flags. Lint with `zsh -n`.
- New scripts get `chmod +x`.
