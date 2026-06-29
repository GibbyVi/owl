# Owl Technical Notes

## Architecture (v0.16.0)

### CLI core
- Entrypoint: `code/main.mire` (~1530 lines)
- Supports both long commands and pacman-style short flags (`-B`, `-T`, `-S`, etc.)
- Subflags like `-Si`, `-Qi`, `-Syu` parsed via string prefix matching
- Public UX optimized for the compiler workflow (Avenys-first)

### Command dispatch
- `main()` reads `env_args()[1]` as the command
- `-V`, `-h`, `-N`/`new` handled first (no args copy needed)
- Remaining commands use `a1..a15` args copy chain for ownership
- Pacman subflags (`-Ss`, `-Qi`, etc.) handled in fallback block
  after all named commands

### Build/Run pipeline
- `compile_pipeline()` resolves file, profile, and optimization flags
- Builds command string: `mire <build|run> <file> --debug|--release -O <n>`
- Delegates to `proc_run()` which maps to `pal_proc_run` C function
- Returns compiler stdout to user

### Test runner
- `find_mire_files("tests")` -- recursive `.mire` discovery, skips `lib/`
- Each file compiled with `mire build <file> --debug -O0`
- Binary extracted from `bin/debug/<stem>` where stem = last path component
- Executed via `proc_run("./" + bin_path)`
- Pass/fail counted; `lib/` directories excluded from discovery

### TOML parser
- `toml_get(file, section, key)` -- reads a single key from a TOML section
- `toml_keys(file, section)` -- lists all keys in a TOML section
- Handles `[section]` headers, `key = "value"` pairs, `# comments`
- Strips quotes from values automatically
- Used by `cmd_info`, `cmd_sync`, `cmd_add`, `upsert_manifest_dependency`

### Package management
- `~/.owl/` directory structure:
  - `config.toml` -- owl global config
  - `registry/<pkg>.toml` -- package metadata (source_url, sha256, build)
  - `store/<pkg>/<build>/` -- installed package files
  - `modules/<name>/` -- symlink to active version
  - `tmp/` -- temporary clones for sync
- `import-repo <url>` -- clones git repo, registers all packages
- `sync <pkg>` -- downloads, validates TOML, verifies SHA256, installs
- `drop <pkg>` -- removes from store and registry
- `verify <pkg>` -- computes and compares SHA256

### Module resolution
- Installed modules: `~/.owl/modules/<name>/`
- Project modules: resolved via `owl.toml [dependencies]`
- Compiler bundled: `../kioto` relative path by default
- `load kioto` in owl code imports all kioto standard library modules

### Built-in functions used
Owl relies on compiler built-ins (not kioto imports):
- `proc_run` -- execute command, capture stdout
- `dasu` -- print to stdout
- `fs_exists`, `fs_is_dir`, `fs_read`, `fs_write`, `fs_drop`, `fs_list`,
  `fs_mkdir`, `fs_rmdir`, `fs_copy`, `fs_move`
- `strings::split`, `strings::trim`, `strings::startswith`, `strings::endswith`,
  `strings::substr`, `strings::replace`, `strings::index_of`, `strings::join`
- `lists::get`, `lists::push`, `len`
- `env_args`, `env_get`
- `rt_vec_get_str`, `rt_vec_len`, `rt_i64_to_string`, `rt_string_to_i64`

### Cache management
- `owl clean --cache` clears `.cache/`
- `owl clean --bin` removes `bin/`
- `owl clean --all` removes both plus `deps/` and `_test_harness.mire`

### Current scope (v0.16.0)
- Project management: `new`, `run`, `build`, `test`, `clean`, `info`, `check`, `checkup`, `profile`
- `checkup` validates all 11 owl.toml fields and dependency count
- Package management: `add`, `import-repo`, `sync`, `drop`, `verify`
- Pacman-style short flags for all primary commands
- Offline operation for all core commands
- Registry requires git access for sync operations
