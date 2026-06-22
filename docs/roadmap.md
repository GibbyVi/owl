# Owl Roadmap

## Version 0.15.x -- Progress bars and kioto extensions

- `term.bar` in kioto: `[===...]` style progress bars with ANSI colors
- Compiler emits JSON phase events to stderr during build
- Owl captures JSON and renders live progress bars (`--verbose` for debug tree)
- Progress bar integration in `owl build`, `owl run`, `owl test`
- Pacman subflags filled: `-Ss` (search registry), `-Ql` (list files),
  `-Qs` (search installed), `-Ci` (cache info)
- `owl sync` with remote HTTP registry (beyond git clone)
- `owl verify` SHA256 check integrated into sync pipeline
- Cache stats: `-Ci` shows entry counts, disk usage, hit/miss ratios

## Version 0.14.0 -- Pacman flags, test runner, bug fixes (current)

- Pacman-style short flags for all commands
- Test runner compiles+runs each `.mire` independently (10/10 pass)
- `owl info` shows live compiler version, target, profile
- Help redesigned with full flag reference
- Bug fixes: infinite loop scanner, info hang, TOML dependency format

## Version 0.13.x -- Tests, Profile and Import Mode

- `owl test` re-enabled with native test runner (`tests/*.mire` discovery + filter).
- `owl profile` re-enabled with cache/check history, JSON output and compare mode.
- Run cache key includes `source_hash + profile + opt + compiler + import_mode`.
- Compiler command resolution: `owl.toml` -> `[compiler].cmd` > `[build].compiler` > `PATH`.

## Version 0.12.0 -- Installer

- `scripts/install.sh` and `scripts/install-review.sh` for binary download from GitHub Releases.
- Precompiled tarballs for Linux/macOS on x86_64 and aarch64.

## Version 0.11.0 -- Check and Profile

- `owl check` with `--all`, `--strict`, `--deny` flags.
- `owl profile` with `--json`, `--history`, `--compare`.
- `run/build` short flags: `-r` (release), `-d` (debug).

## Version 0.10.0 -- Local-Only Redesign

- Removed external dependency management (install/remove/update/purge/deps).
- Core commands only: `new`, `run`, `build`, `test`, `clean`, `info`.

## Version 0.9.0 (Legacy)

- CLI redesign with simplified command model.
- `run/build` profile + optimization flags.
- Projectless compile/run support (`.cache` + `bin`).

## Next

- Enhanced machine-readable outputs (`--json`) for CI/IDE tooling
- `owl publish` for publishing packages to registry
- Self-hosting: `owl` compiles `owl` (Mire -> Mire bootstrap)
- `owl upgrade` for upgrading owl itself from registry
- Profile and optimization level persistence
