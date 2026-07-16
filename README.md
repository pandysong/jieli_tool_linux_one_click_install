# Jieli Linux Toolchain One-Click Install

A simple Bash script that installs the official Jieli Linux compiler toolchain and postbuild tools. It downloads packages from Jieli’s pkgman service so you can build Jieli SDKs with `make` on Linux. It also installs required system libraries via `apt` so the tools can run.

After a successful install:

- Compiler: `/opt/jieli/pi32v2/bin/clang`
- Postbuild: `/opt/utils/fw_add` (and related tools)
- Apt deps: `libsm6`, `libxkbcommon0`, `libgbm1`, `libgl1-mesa-glx` (or `libgl1`), `libegl1`

## Requirements

- Debian/Ubuntu Linux with `curl`, `tar`, `xz`, and `apt`
- Root privileges (or `sudo`) to write under `/opt` and install packages

## Usage

```bash
chmod +x install.sh
./install.sh
```

Reinstall over existing tools:

```bash
./install.sh --force
```

Optional environment variables:

| Variable           | Default                                           | Description              |
|--------------------|---------------------------------------------------|--------------------------|
| `JL_TOOLCHAIN_URL` | `https://pkgman.jieliapp.com/s/linux-toolchain`   | Toolchain download URL   |
| `JL_INSTALL_DIR`   | `/opt/jieli`                                      | Toolchain install path   |
| `JL_POSTBUILD_URL` | `https://pkgman.jieliapp.com/s/linux-postbuild`   | Postbuild download URL   |
| `JL_UTILS_DIR`     | `/opt/utils`                                      | Postbuild install path   |

If linking fails due to too many open files, raise the limit before building:

```bash
ulimit -n 8096
```
