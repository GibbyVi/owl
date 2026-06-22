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
entry = "code/main.mire"

[dependencies]
kioto = { path = "../kioto" }

[build]
default_profile = "debug"
default_opt_level = "0"
```

## Documentation

- [Changelog](docs/changelog.md) -- release history
- [Technical notes](docs/technical.md) -- architecture overview
- [Roadmap](docs/roadmap.md) -- planned features

## License

GNU General Public License v3.0
