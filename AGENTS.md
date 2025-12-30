# Repository Guidelines

## Project Structure & Module Organization
- `zshrc.local` defines core shell behavior; keep Powerlevel10k instant prompt sourcing at the top.
- `work.zsh` holds machine-specific overrides—document any new env vars there.
- Helper scripts (e.g. `git-large-file-fix`, `sync-terminal-history.sh`, `test_dotfiles.zsh`) live at the root; vendored prompt assets reside in `zsh-git-prompt/`.
- Tests are organised under `tests/*.zsh`; add new global utilities as standalone `*.zsh` files and source them explicitly from `zshrc.local`.

## Build, Test, and Development Commands
- `make test` runs the full verification suite.
- `make test-basic` offers a quick sanity check.
- `./test_dotfiles.zsh --test performance` targets startup regressions; `./test_dotfiles.zsh --benchmark` records timing baselines.
- `make lint` validates shell syntax, `make install` appends `source ~/dotfiles/zshrc.local` to `~/.zshrc`, and `make help` lists automation tasks.

## Coding Style & Naming Conventions
- Use two-space indentation in zsh files and align multiline arrays as in `zshrc.local`.
- Name functions with snake_case verbs (`test_essential_aliases`), keep aliases short (`gl`, `gti`), and mirror the NVM lazy-load pattern when wrapping tools.
- Declare `local` variables before use, guard filesystem access with `[[ -f ... ]]`, and prefer single quotes unless expansion is required.

## Testing Guidelines
- Each file in `tests/` exports `test_`-prefixed functions that return success/failure codes and print PASS/FAIL lines.
- Register new suites inside `test_dotfiles.zsh` so they integrate with `make` targets.
- Skip platform-sensitive checks when `CI` or `GITHUB_ACTIONS` is set, and note performance tweaks alongside `./test_dotfiles.zsh --benchmark` output.

## Commit & Pull Request Guidelines
- Write imperative, capitalised subjects under ~60 chars (e.g. `Add Claude CLI to PATH`), referencing issues with `Refs #123` when relevant.
- PRs should summarize changes, include terminal snippets for UX or performance updates, and confirm `make test` plus any focused suites you touched.
- Highlight follow-up configuration steps for teammates, especially when modifying `work.zsh` or environment-dependent behavior.

## Security & Configuration Tips
- Never commit secrets; rely on `work.zsh` comments to describe required environment variables.
- Before submitting, run `make lint` to catch syntax slips and verify Powerlevel10k remains the first sourced component to preserve startup speed.
