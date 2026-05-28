# Owl

Package & project manager for the [Mire](https://github.com/mire-lang) (Avenys) language.

Owl provides project scaffolding, compilation orchestration, static analysis, test execution, and build profiling — all offline with no external dependencies.

## Installation

```bash
curl -fsSL https://github.com/mire-lang/owl/releases/latest/download/install.sh | bash
```

For an auditable flow: download `install-review.sh`, inspect it, then run.

## Quick Start

```bash
owl new myproject
cd myproject
owl run
```

## Commands

| Command | Description |
|---------|-------------|
| `new <name>` | Scaffold a new project |
| `run [file]` | Compile and execute |
| `build [file]` | Compile only |
| `check [file]` | Static analysis with warnings |
| `profile` | Build/profile metrics |
| `test [filter]` | Run test suite |
| `clean` | Remove artifacts |
| `info` | Project information |

## Documentation

- [Changelog](docs/changelog.md) — release history
- [Technical notes](docs/technical.md) — architecture overview
- [Roadmap](docs/roadmap.md) — planned features

## License

GNU General Public License v3.0
