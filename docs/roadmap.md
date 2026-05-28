# Owl Roadmap

## Version 0.13.x — Tests, Profile & Import Mode

- `owl test` re-enabled with native test runner (`tests/*.mire` discovery + filter).
- `owl profile` re-enabled with cache/check history, JSON output and compare mode.
- `--import-mode <legacy|reachable>` flag in `run/build` with fallback to legacy.
- Run cache key includes `source_hash + profile + opt + compiler + import_mode`.
- Dependency preflight in project mode: validates lock for declared deps (`semver` + `sha256:`).
- `run/build` unified into shared compile pipeline to reduce duplicated parsing.
- Compiler command resolution: `owl.toml` → `[compiler].cmd` > `[build].compiler` > `PATH`.

## Version 0.12.0 — Installer

- `scripts/install.sh` and `scripts/install-review.sh` for binary download from GitHub Releases.
- Precompiled tarballs for Linux/macOS on x86_64 and aarch64.
- `--with-mire` flag to install Avenys compiler alongside Owl.

## Version 0.11.0 — Check & Profile

- `owl check` with `--all`, `--strict`, `--deny` flags.
- `owl profile` with `--json`, `--history`, `--compare`.
- `run/build` short flags: `-r` (release), `-d` (debug).
- `clean` selective cleanup: `--cache`, `--bin`, `--all`.
- `info` redesigned with diagnostics-style layout.

## Version 0.10.0 — Local-Only Redesign

- Removed external dependency management (install/remove/update/purge/deps).
- Eliminated modules: `deps`, `registry`, `download`, `lock`, `semver`.
- Core commands only: `new`, `run`, `build`, `test`, `clean`, `info`.
- Module paths integration: `~/.owl/modules/` and `project_root/modules/`.

## Version 0.9.0 (Legacy)

- CLI redesign with simplified command model.
- `run/build` profile + optimization flags.
- Projectless compile/run support (`.cache` + `bin`).
- Run hash cache for faster repeated execution.
- Full compile-path ownership hardening for dependency and command flows.
- Module integration cleanup to avoid symbol redefinition at backend lowering time.

## Next

- Enhanced machine-readable outputs (`--json`) for CI/IDE tooling.
- Extended cache management options.
- Profile and optimization level persistence.
- Reintroducing external dependency management (v2 design) based on lock preflight validation.
