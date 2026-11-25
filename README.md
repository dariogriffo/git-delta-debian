![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/git-delta-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/git-delta-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/git-delta-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/git-delta-debian)

<h1>
   <p align="center">
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/git-delta-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104"></a>
     <br>delta for Debian
   </p>
</h1>
<p align="center">
 A syntax-highlighting pager for git, diff, grep and blame output.
</p>

# delta for Debian

This repository contains build scripts to produce the _unofficial_ Debian and
Ubuntu packages (.deb) for [delta](https://github.com/dandavison/delta/) hosted at
[deb.griffo.io](https://deb.griffo.io)

**The package is called `git-delta` and the command is `delta`**, the same
names as the package in the official Debian and Ubuntu archives. This package
carries the latest upstream release, so it replaces the archive's older
`git-delta` on a normal `apt upgrade`. Like the archive package, it is
unrelated to the `delta` package (`multidelta`, `singledelta`) and to
`git-extras`' `git-delta` command.

Currently supported distros are:
- Debian Bookworm (v12), Trixie (v13), Forky (v14), Sid
- Ubuntu Jammy (22.04), Noble (24.04), Questing (25.10), Resolute (26.04), Stonking (26.10)

Supported architectures:
- amd64 (x86_64) - All distributions
- arm64 (aarch64) - All distributions
- armhf (32-bit ARM) - All distributions
- i386 (32-bit x86) - Debian Trixie, Forky and Sid

Upstream builds its i386 release against glibc 2.39, so it does not run on
Bookworm, and the mirror carries no Ubuntu i386 packages. Upstream only
publishes Linux builds for these four architectures, so there are no armel,
ppc64el, s390x or riscv64 packages.

One package per architecture is built and shared by every suite
(`git-delta_<version>-<build>~griffo_<arch>.deb`). It repackages upstream's own
`.deb`: the `delta` binary is shipped unchanged, with dependencies declared per
architecture so they resolve on every supported suite (upstream's i386 package
names the amd64 multilib libraries, so its own Depends can't be used). On top
of upstream's package it adds the bash, zsh and fish completions and the
`themes.gitconfig` helper from upstream's source at the same tag, installed
where Debian's own package puts them (`/etc/delta/themes.gitconfig`, symlinked
from `/usr/share/delta/`), so a git config that includes it keeps working.
Upstream ships no man page; `delta --help` is the reference.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the delta source code, see
[delta](https://github.com/dandavison/delta/).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-git-delta-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-git-delta-in-ubuntu.html)

### The Debian way

> ⚠️ **apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/git-delta-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y git-delta
```

Then make it git's pager in `~/.gitconfig`:

```gitconfig
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
```

### Manual Installation

1. Download the .deb package for your architecture from
   the [Releases](https://github.com/dariogriffo/git-delta-debian/releases) page.
2. Install it with apt, so the dependencies are pulled in.

```sh
sudo apt install ./<filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

### Build for single architecture
```sh
./build.sh <git_delta_version> <build_version> <architecture>
# Example: ./build.sh 0.22.0 1 arm64
```

### Build for all architectures
```sh
./build.sh <git_delta_version> <build_version> all
# Example: ./build.sh 0.22.0 1 all
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Multi-architecture support (amd64, arm64, armhf, i386)

## Disclaimer

- This repo is not open for issues related to delta. This repo is only for _unofficial_ Debian packaging.
