# Owl

Package and project manager for the [Mire](https://github.com/mire-lang) (Avenys) language.
Written in Mire, compiled by Avenys.

Owl provides project scaffolding, compilation orchestration, static analysis,
test execution, package management, and build profiling.

## Quick Start

```bash
owl new myproject
cd myproject
owl run
```

## Commands

### Build (pacman-style flags available)

| Short | Command        | Description |
|-------|---------------|-------------|
| `-B`  | `build`       | Compile project to binary |
|       | `run`         | Compile and execute |
| `-K`  | `check`       | Static analysis with warnings |
| `-T`  | `test`        | Run test suite |
| `-D`  | `debug`       | Debug build with IR emission |

### Project

| Short | Command        | Description |
|-------|---------------|-------------|
| `-N`  | `new <name>`  | Scaffold a new project |
|       | `add <name>`  | Add dependency to owl.toml |
| `-C`  | `clean`       | Remove build artifacts and cache |
|       | `checkup`     | Validate all owl.toml fields and environment |
|       | `checkup --fix` | Regenerate owl.toml with defaults preserving existing values |
|       | `profile`     | Build/profile metrics |
| `-Q`  | `info [pkg]`  | Project or package information |

### Package (pacman-style)

| Flag  | Action                     |
|-------|----------------------------|
| `-S`  | Sync package from registry |
| `-Ss` | Search packages            |
| `-Si` | Show package details       |
| `-Syu`| Sync and upgrade all       |
| `-R`  | Remove package             |
| `-Rs` | Remove + delete installed  |
| `-Qi` | Query installed package    |
| `-Ql` | List installed files       |

### Global

| Flag  | Description |
|-------|-------------|
| `-V`  | Show version |
| `-h`  | Show help    |

## Build profiles

```bash
owl build --release -O3          # Release mode, max optimization
owl run -r -Os                   # Release, size optimization
owl check --all --strict          # Full static analysis
owl test --filter smoke           # Run matching tests only
```

## Project structure

```
myproject/
  owl.toml          -- Project manifest
  code/main.mire    -- Entry point
  tests/            -- Test files
  bin/
    debug/          -- Debug binaries
    release/        -- Release binaries
    .cache/         -- Build cache
```

## owl.toml

```toml
[project]
name = "myproject"
version = "0.1.0"
description = ""
entry = "code/main.mire"

[build]
compiler = "mire"
profile = "debug"
opt-level = 0

[paths]
sources = "code"
tests = "tests"
output = "bin"
cache = "bin/.cache"

[dependencies]
```

## Documentation

- [Changelog](docs/changelog.md) — release history
- [Technical notes](docs/technical.md) — architecture overview
- [Roadmap](docs/roadmap.md) — planned features

## Recent changes (v0.16.0)

- **Full owl.toml validation:** `cmd_checkup` now validates all 11 fields
  (`name`, `version`, `description`, `entry`, `profile`, `opt-level`,
  `compiler`, `output`, `cache`, `sources`, `tests`) plus dependency counting.
  Missing fields produce `[FAIL]` or `[WARN]` with clear messages.
- **Dependency check:** `checkup` counts `[dependencies]` entries and reports
  `[WARN]` if none configured.
- **`checkup --fix`:** Regenerates `owl.toml` preserving all existing values,
  only filling missing fields with defaults.
- **De-hardcoded config:** All paths (`entry`, `profile`, `opt-level`, `tests`, `output`, `cache`)
  now read exclusively from `owl.toml`. Missing fields produce errors instead of silent fallbacks.
- **Removed `bin/main` shortcut:** `owl run` always delegates to `mire run`, using MIR's
  incremental cache for fast recompilation.
- **Standalone files:** Running `owl run file.mire` without a project delegates directly to
  `mire run file.mire`.

## License

GNU General Public License v3.0
