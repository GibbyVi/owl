#!/usr/bin/env bash
set -euo pipefail

# Owl installer (non-interactive)
# Installs precompiled owl binary and optionally mire from GitHub Releases.

OWL_REPO_DEFAULT="mire-lang/owl"
MIRE_REPO_DEFAULT="mire-lang/Avenys-rust"

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
INSTALL_MIRE="0"
OWL_VERSION="latest"
MIRE_VERSION="latest"
OWL_REPO="$OWL_REPO_DEFAULT"
MIRE_REPO="$MIRE_REPO_DEFAULT"

usage() {
  cat <<USAGE
Usage: install.sh [options]

Options:
  --prefix <path>         Install prefix (default: ~/.local)
  --bin-dir <path>        Binary directory (default: <prefix>/bin)
  --owl-version <tag>     Owl tag version (default: latest)
  --mire-version <tag>    Mire tag version (default: latest)
  --owl-repo <owner/repo> Owl GitHub repo (default: ${OWL_REPO_DEFAULT})
  --mire-repo <owner/repo> Mire GitHub repo (default: ${MIRE_REPO_DEFAULT})
  --with-mire             Install mire binary too
  -h, --help              Show this help
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prefix) PREFIX="$2"; BIN_DIR="$2/bin"; shift 2 ;;
      --bin-dir) BIN_DIR="$2"; shift 2 ;;
      --owl-version) OWL_VERSION="$2"; shift 2 ;;
      --mire-version) MIRE_VERSION="$2"; shift 2 ;;
      --owl-repo) OWL_REPO="$2"; shift 2 ;;
      --mire-repo) MIRE_REPO="$2"; shift 2 ;;
      --with-mire) INSTALL_MIRE="1"; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "error: unknown option: $1" >&2; usage; exit 1 ;;
    esac
  done
}

platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$os" in
    linux) os="linux" ;;
    darwin) os="darwin" ;;
    *) echo "error: unsupported OS: $os" >&2; exit 1 ;;
  esac

  case "$arch" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) echo "error: unsupported arch: $arch" >&2; exit 1 ;;
  esac

  printf '%s-%s' "$os" "$arch"
}

download_asset() {
  local repo="$1" version="$2" asset="$3" out="$4"
  local url

  if [[ "$version" == "latest" ]]; then
    url="https://github.com/${repo}/releases/latest/download/${asset}"
  else
    url="https://github.com/${repo}/releases/download/${version}/${asset}"
  fi

  echo "-> downloading ${repo}:${version} (${asset})"
  curl -fL "$url" -o "$out"
}

install_tar_binary() {
  local tarball="$1" bin_name="$2" target="$3"
  local tmpdir
  tmpdir="$(mktemp -d)"
  tar -xzf "$tarball" -C "$tmpdir"

  if [[ -f "$tmpdir/$bin_name" ]]; then
    install -m 0755 "$tmpdir/$bin_name" "$target"
  else
    local found
    found="$(find "$tmpdir" -type f -name "$bin_name" | head -n 1 || true)"
    if [[ -z "$found" ]]; then
      echo "error: binary ${bin_name} not found in tarball" >&2
      rm -rf "$tmpdir"
      exit 1
    fi
    install -m 0755 "$found" "$target"
  fi

  rm -rf "$tmpdir"
}

setup_owl_dirs() {
  local owl_home="$HOME/.owl"
  mkdir -p "$owl_home/modules"
  mkdir -p "$owl_home/tmp"

  if [[ ! -f "$owl_home/config.toml" ]]; then
    cat > "$owl_home/config.toml" << 'CONFIG'
# Owl global configuration
[owl]
version = "1.0.0"

[modules]
path = "$HOME/.owl/modules"

[download]
timeout = 30
retry = 3
CONFIG
    echo "created: $owl_home/config.toml"
  fi

  echo "created: $owl_home/modules/"
  echo "created: $owl_home/tmp/"
}

main() {
  parse_args "$@"
  require_cmd curl
  require_cmd tar
  require_cmd install

  setup_owl_dirs

  mkdir -p "$BIN_DIR"
  local plat tmp
  plat="$(platform)"
  tmp="$(mktemp -d)"

  local owl_asset mire_asset
  owl_asset="owl-${plat}.tar.gz"
  mire_asset="mire-${plat}.tar.gz"

  download_asset "$OWL_REPO" "$OWL_VERSION" "$owl_asset" "$tmp/$owl_asset"
  install_tar_binary "$tmp/$owl_asset" "owl" "$BIN_DIR/owl"

  if [[ "$INSTALL_MIRE" == "1" ]]; then
    download_asset "$MIRE_REPO" "$MIRE_VERSION" "$mire_asset" "$tmp/$mire_asset"
    install_tar_binary "$tmp/$mire_asset" "mire" "$BIN_DIR/mire"
  fi

  rm -rf "$tmp"

  echo "installed: $BIN_DIR/owl"
  if [[ "$INSTALL_MIRE" == "1" ]]; then
    echo "installed: $BIN_DIR/mire"
  fi

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      echo
      echo "warning: $BIN_DIR is not in PATH"
      echo "add this line to your shell profile:"
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
      ;;
  esac
}

main "$@"
