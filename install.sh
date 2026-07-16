#!/usr/bin/env bash
# Jieli Linux toolchain + postbuild tools one-click installer
# - Toolchain  -> /opt/jieli  (clang at pi32v2/bin/clang)
# - Postbuild  -> /opt/utils  (fw_add, isd_download, ...)
set -euo pipefail

TOOLCHAIN_URL="${JL_TOOLCHAIN_URL:-https://pkgman.jieliapp.com/s/linux-toolchain}"
TOOLCHAIN_DIR="${JL_INSTALL_DIR:-/opt/jieli}"
CLANG_PATH="${TOOLCHAIN_DIR}/pi32v2/bin/clang"

POSTBUILD_URL="${JL_POSTBUILD_URL:-https://pkgman.jieliapp.com/s/linux-postbuild}"
UTILS_DIR="${JL_UTILS_DIR:-/opt/utils}"
FW_ADD_PATH="${UTILS_DIR}/fw_add"

FORCE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -f, --force    Reinstall even if tools already exist
  -h, --help     Show this help

Environment:
  JL_TOOLCHAIN_URL   Toolchain download URL (default: ${TOOLCHAIN_URL})
  JL_INSTALL_DIR     Toolchain install path (default: ${TOOLCHAIN_DIR})
  JL_POSTBUILD_URL   Postbuild download URL (default: ${POSTBUILD_URL})
  JL_UTILS_DIR       Postbuild install path (default: ${UTILS_DIR})
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

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    if ! command -v sudo >/dev/null 2>&1; then
      err "Need root to write under /opt. Re-run as root or install sudo."
      exit 1
    fi
    sudo "$@"
  fi
}

install_apt_deps() {
  if ! command -v apt-get >/dev/null 2>&1; then
    err "apt-get not found; skip system library install (Debian/Ubuntu required for apt deps)."
    return 0
  fi

  # Required shared libs so postbuild tools (e.g. fw_add) can run under make
  local pkgs=(libsm6 libxkbcommon0 libgbm1 libegl1)
  local gl_pkg="libgl1-mesa-glx"

  log "Installing system libraries via apt"
  run_as_root apt-get update -y
  # libgl1-mesa-glx may be gone on newer Ubuntu; fall back to libgl1
  if ! run_as_root apt-get install -y "${pkgs[@]}" "${gl_pkg}"; then
    log "${gl_pkg} unavailable; trying libgl1 instead"
    run_as_root apt-get install -y "${pkgs[@]}" libgl1
  fi
  ok "System libraries installed"
}

extract_xz_to() {
  local archive="$1"
  local dest="$2"
  run_as_root mkdir -p "${dest}"
  run_as_root tar -xJf "${archive}" -C "${dest}" --strip-components=1
}

# --- System libraries (apt) ---
install_apt_deps

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

# --- Toolchain (/opt/jieli) ---
if [[ -x "${CLANG_PATH}" && "${FORCE}" -eq 0 ]]; then
  ok "Toolchain already installed: ${CLANG_PATH}"
  "${CLANG_PATH}" --version 2>/dev/null | head -n 1 || true
else
  ARCHIVE="${TMP_DIR}/jieli-linux-toolchain.tar.xz"
  log "Downloading toolchain from ${TOOLCHAIN_URL}"
  curl -fL --progress-bar -o "${ARCHIVE}" "${TOOLCHAIN_URL}"
  ok "Downloaded ($(du -h "${ARCHIVE}" | awk '{print $1}'))"

  log "Extracting toolchain to ${TOOLCHAIN_DIR}"
  extract_xz_to "${ARCHIVE}" "${TOOLCHAIN_DIR}"

  if [[ ! -x "${CLANG_PATH}" ]]; then
    err "Install finished but compiler not found: ${CLANG_PATH}"
    exit 1
  fi
  ok "Installed: ${CLANG_PATH}"
  "${CLANG_PATH}" --version 2>/dev/null | head -n 3 || true
fi

# --- Postbuild tools (/opt/utils) ---
if [[ -x "${FW_ADD_PATH}" && "${FORCE}" -eq 0 ]]; then
  ok "Postbuild tools already installed: ${FW_ADD_PATH}"
else
  ARCHIVE="${TMP_DIR}/jieli-linux-postbuild.tar.xz"
  log "Downloading postbuild tools from ${POSTBUILD_URL}"
  curl -fL --progress-bar -o "${ARCHIVE}" "${POSTBUILD_URL}"
  ok "Downloaded ($(du -h "${ARCHIVE}" | awk '{print $1}'))"

  log "Extracting postbuild tools to ${UTILS_DIR}"
  extract_xz_to "${ARCHIVE}" "${UTILS_DIR}"

  if [[ ! -x "${FW_ADD_PATH}" ]]; then
    err "Install finished but tool not found: ${FW_ADD_PATH}"
    exit 1
  fi
  ok "Installed: ${FW_ADD_PATH}"
fi

# Linker opens many files; raise soft limit for current shell advice
ULIMIT_N="$(ulimit -n 2>/dev/null || echo 0)"
if [[ "${ULIMIT_N}" != "unlimited" ]] && [[ "${ULIMIT_N}" -lt 8096 ]]; then
  log "Tip: raise open-file limit before linking (current ulimit -n=${ULIMIT_N}):"
  printf '    ulimit -n 8096\n'
fi

ok "Done."
ok "  Toolchain: ${TOOLCHAIN_DIR}"
ok "  Utils:     ${UTILS_DIR}"
