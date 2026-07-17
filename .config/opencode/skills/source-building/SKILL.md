---
name: source-building
description: Build third-party software from source on Ubuntu. Use when apt packages or vendor packages are unsuitable and the user approves a source build. Covers CMake, Meson, Autotools, and Make-only projects with build isolation and install boundaries.
---

# Source Building

Use source builds only when apt or official vendor packages are unavailable, too old, or unsuitable. Prefer apt/vendor packages when they meet the requirement.

## Safety rules

- Build under `~/build/<project>`.
- Capture logs under `~/ops-agent/logs/source-build/<project>/`.
- Build and test as normal user. Do not run `sudo make install` by default.
- Prefer `DESTDIR` staging and review staged files before proposing any install.
- Ask before installing dependencies, writing to `/usr/local`, changing linker paths, editing shell startup files, or using sudo-like commands.
- Keep output bounded. Summarize logs with `scripts/source-build-log-summary`.
- Scripts at `/home/workstation/ops-agent/scripts/source-build-*`.

## Initialize

```sh
./scripts/source-build-init PROJECT --source ~/build/PROJECT        # full init
./scripts/source-build-init PROJECT --source /path/to/source --dry-run  # plan only
```

The initializer does not configure, compile, test, install, or use sudo. It records the expected build root, log directory, staging path, detected build system, dependency diagnostics, and recommended commands.

## Build commands by system

**CMake:**
```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build
ctest --test-dir build --output-on-failure
DESTDIR=~/build/PROJECT/stage cmake --install build
```

**Meson:**
```sh
meson setup build --prefix=/usr/local --buildtype=release
meson compile -C build
meson test -C build
DESTDIR=~/build/PROJECT/stage meson install -C build
```

**Autotools:**
```sh
./configure --prefix=/usr/local
make -j"$(nproc)"
make check
make DESTDIR=~/build/PROJECT/stage install
```

**Make-only:**
```sh
make -n                                  # dry-run first
make -j"$(nproc)"
make test
make DESTDIR=~/build/PROJECT/stage PREFIX=/usr/local install
```

## Dependency diagnosis

```sh
pkg-config --list-all | rg -i 'name-or-library'
pkg-config --cflags --libs package-name
ldconfig -p | rg -i 'library-name'
ldd ./build/path/to/binary
apt-file search /usr/include/header.h
dpkg -S /path/to/file
dpkg -L package-name | head -120
```

## Log summaries

```sh
./scripts/source-build-log-summary PROJECT
./scripts/source-build-log-summary ~/ops-agent/logs/source-build/PROJECT/build.log
```

Extracts likely first errors and a short tail without pasting full build transcripts.

## Install review (before any system install)

```sh
find ~/build/PROJECT/stage -type f | sort | head -200
```

Confirm staged files are expected. Identify runtime library paths. Propose the exact install command. Any write to `/usr/local`, `ldconfig`, service changes, or sudo-like operation needs explicit approval.

## Post-install verification

Verify the installed binary path and version after any approved install. See also: `ops-agent-docs` runbook `source-build.md`.
