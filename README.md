# Jieli Linux Toolchain One-Click Install

A simple Bash script that installs the official Jieli Linux compiler toolchain on your machine. It downloads the latest package from Jieli’s pkgman service and extracts it to `/opt/jieli`, so you can build Jieli SDKs with `make` on Linux.

After a successful install, the compiler is available at `/opt/jieli/pi32v2/bin/clang`.

## Requirements

- Linux with `curl`, `tar`, and `xz`
- Root privileges (or `sudo`) to write under `/opt`

## Usage

```bash
chmod +x install.sh
./install.sh
```

Reinstall over an existing toolchain:

```bash
./install.sh --force
```

Optional environment variables:

| Variable           | Default                                          | Description      |
|--------------------|--------------------------------------------------|------------------|
| `JL_TOOLCHAIN_URL` | `http://pkgman.jieliapp.com/s/linux-toolchain`   | Download URL     |
| `JL_INSTALL_DIR`   | `/opt/jieli`                                     | Install path     |

If linking fails due to too many open files, raise the limit before building:

```bash
ulimit -n 8096
```
