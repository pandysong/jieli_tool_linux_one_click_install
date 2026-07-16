#!/usr/bin/env bash
# Jieli Linux toolchain one-click installer
# Downloads from pkgman and installs to /opt/jieli
set -euo pipefail

TOOLCHAIN_URL="${JL_TOOLCHAIN_URL:-http://pkgman.jieliapp.com/s/linux-toolchain}"
INSTALL_DIR="${JL_INSTALL_DIR:-/opt/jieli}"
CLANG_PATH="${INSTALL_DIR}/pi32v2/bin/clang"
FORCE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -f, --force    Reinstall even if toolchain already exists
  -h, --help     Show this help

Environment:
  JL_TOOLCHAIN_URL   Download URL (default: ${TOOLCHAIN_URL})
  JL_INSTALL_DIR     Install path  (default: ${INSTALL_DIR})
EOF
}

log()  { printf '[*] %s\n' "$*"; }
ok()   { printf '[+] %s\n' "$*"; }
err()  { printf '[!] %s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force) FORCE=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Missing required command: $1"
    exit 1
  }
}

need_cmd curl
need_cmd tar
need_cmd xz

if [[ -x "${CLANG_PATH}" && "${FORCE}" -eq 0 ]]; then
  ok "Toolchain already installed: ${CLANG_PATH}"
  "${CLANG_PATH}" --version 2>/dev/null | head -n 1 || true
  exit 0
fi

TMP_DIR="$(mktemp -d)"
ARCHIVE="${TMP_DIR}/jieli-linux-toolchain.tar.xz"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

log "Downloading toolchain from ${TOOLCHAIN_URL}"
curl -fL --progress-bar -o "${ARCHIVE}" "${TOOLCHAIN_URL}"
ok "Downloaded ($(du -h "${ARCHIVE}" | awk '{print $1}'))"

log "Extracting to ${INSTALL_DIR}"
# Archive layout: <version-dir>/{pi32v2,common,...}
# Strip top-level so result is /opt/jieli/pi32v2/bin/clang
if [[ "$(id -u)" -eq 0 ]]; then
  mkdir -p "${INSTALL_DIR}"
  tar -xJf "${ARCHIVE}" -C "${INSTALL_DIR}" --strip-components=1
else
  if ! command -v sudo >/dev/null 2>&1; then
    err "Need root to write ${INSTALL_DIR}. Re-run as root or install sudo."
    exit 1
  fi
  sudo mkdir -p "${INSTALL_DIR}"
  sudo tar -xJf "${ARCHIVE}" -C "${INSTALL_DIR}" --strip-components=1
fi

if [[ ! -x "${CLANG_PATH}" ]]; then
  err "Install finished but compiler not found: ${CLANG_PATH}"
  err "Check archive layout / install path."
  exit 1
fi

ok "Installed: ${CLANG_PATH}"
"${CLANG_PATH}" --version 2>/dev/null | head -n 3 || true

# Linker opens many files; raise soft limit for current shell advice
ULIMIT_N="$(ulimit -n 2>/dev/null || echo 0)"
if [[ "${ULIMIT_N}" != "unlimited" ]] && [[ "${ULIMIT_N}" -lt 8096 ]]; then
  log "Tip: raise open-file limit before linking (current ulimit -n=${ULIMIT_N}):"
  printf '    ulimit -n 8096\n'
fi

ok "Done. Toolchain root: ${INSTALL_DIR}"
