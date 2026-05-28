# Owl Technical Notes

## Architecture (v0.13.x)

### CLI core
- Entrypoint: `code/main.mire`
- Command parser resolves file, profile, optimization and import-mode flags.
- Public UX optimized for the compiler workflow (Avenys-first).

### Build/Run pipeline
- `run/build` resolve target from argument or `project.entry` in `owl.toml`.
- Two modes:
  - **Project mode** (`owl.toml` present): dependency preflight + compile.
  - **Projectless mode**: prints warning, uses local `.cache/` and `bin/`.
- Run fast path: skips recompile when source hash + profile + opt + compiler + import-mode match existing binary.
- `run/build` share a unified compile pipeline.
- Compiler command resolved from:
  1. `owl.toml` → `[compiler].cmd`
  2. `[build].compiler` (legacy)
  3. `mire` from `PATH`

### Module resolution
- Installed modules: `~/.owl/modules/<name>/` and `~/.owl/modules/<name>/code/`
- Project modules: `project_root/modules/<name>/`
- Compiler bundled: `project_root/<name>/` and compiler workspace paths

### Test runner
- Discovers `.mire` files under `tests/`.
- Executes each through the same compiler pipeline used by `run/build`.
- `--filter <text>` runs only matching test files.

### Cache management
- `owl clean --cache` clears compiled artifacts.
- `owl clean --bin` removes binaries.
- Profile-scoped directories under `bin/debug/`, `bin/release/`, `.cache/`.

### Current scope (v0.13.x)
- Project management: `new`, `run`, `build`, `test`, `clean`, `info`, `check`, `profile`.
- No external dependency management (planned for future release).
- No registry, lock files, or network operations.
