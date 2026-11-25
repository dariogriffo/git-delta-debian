<div align="center">

# delta

**A syntax-highlighting pager for git, diff, grep and blame output.**

![GitHub Release](https://img.shields.io/github/v/release/dandavison/delta?display_name=tag&color=%23a6a)
![GitHub License](https://img.shields.io/github/license/dandavison/delta)

</div>

## About

Delta adds language syntax highlighting, within-line insertion and deletion
detection, line numbers, a side-by-side view and clickable hyperlinks to the
output of `git diff`, `git show`, `git log -p`, `git blame` and `git grep`.
It can also compare two files directly: `delta file1 file2`.

**The package is `git-delta`; the command is `delta`.** To use it with git,
add this to `~/.gitconfig`:

```gitconfig
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true

[merge]
    conflictStyle = zdiff3
```

Shell completions for bash, zsh and fish are installed. The themes helper is
`/etc/delta/themes.gitconfig` (also at `/usr/share/delta/themes.gitconfig`);
see the comments at the top of that file to use its themes.

**[Read the documentation](https://dandavison.github.io/delta/)**
