+++
title = "Replacing macOS BSD utils with GNU coreutils"
date = "2026-03-14 17:35:40"

[taxonomies]
tags = ["macOS", "coreutils"]
+++


By default, macOS is packaged with the BSD versions of many common CLI utilities such as `grep`, `sed`, `awk`, and more. These are not the same ones that can be found on most Linux distributions, and the slight differences between them can be confusing when working with both systems at the same time.

Thankfully, most of these can be installed through Homebrew. There are some caveats, but for the most part, they can be treated as a one-to-one replacement. The `coreutils` package is commonly cited, but over time, I have compiled a larger list of other non-GNU utilities that can be replaced.


## Installation

The full list of default mac packages that I've replaced are:

```bash
brew install \
    coreutils \
    diffutils \
    findutils \
    man-db \
    gawk \
    gnu-sed \
    watch \
    grep \
    gzip \
    less \
    curl \
    wget \
    rsync \
    git \
    vim
```


## Configuration

Since the BSD and GNU utils have the same names, these new utils are usually installed with a `g` prefix. Additionally, their `manpages` may not be properly pointed to the installed application either. As a result, you'll have to redefine the `PATH` and `MANPATH` shell variables for a number of these tools.

However, it may not be clear which ones are necessary to set. I will provide a full list of these paths below, but this is the strategy I followed to build it.

First, I made sure there were no `PATH` or `MANPATH` variables set in my `~/.zshrc` or remaining ZSH environment. Then, I closed out all ZSH sessions that might exist in the user environment, including `tmux` sessions and the terminal. Then, I reopened my terminal and `echo`'d the path variables to get a clear list of the default paths that macOS uses:

```bash
$ echo $PATH | tr ':' '\n'
/opt/homebrew/bin
/opt/homebrew/sbin
/usr/local/bin
/System/Cryptexes/App/usr/bin
/usr/bin
/bin
/usr/sbin
/sbin
/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin
/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin
/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin
/Applications/Ghostty.app/Contents/MacOS

$ echo $MANPATH | tr ':' '\n'
/usr/share/man
/usr/local/share/man
/Applications/Ghostty.app/Contents/Resources/ghostty/../man
```

Next, I added the `PATH` for `coreutils` that was recommended during installation. (You can also re-print the message by running `brew info coreutils`):

```bash
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
```

The `MANPATH` location usually follows 2 directory conventions. They are located under either:

```bash
/opt/homebrew/opt/<APPLICATION NAME>/libexec/gnuman

# or

/opt/homebrew/opt/<APPLICATION NAME>/share/man
```

For `coreutils`, `diffutils` and `findutils`, the `PATH` and `MANPATH` values were fairly straightforward:

```bash
# coreutils
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/coreutils/libexec/gnuman:$MANPATH"

# diffutils
export PATH="/opt/homebrew/opt/diffutils/bin:$PATH"
export MANPATH="/opt/homebrew/opt/diffutils/share/man:$MANPATH"

# findutils
export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/findutils/libexec/gnuman:$MANPATH"
```

The other applications are not as clear. I first added `man`, following the [guide here](@/posts/man-man.md#manpages-on-macos). 

```bash
# man
export PATH="/opt/homebrew/opt/man-db/libexec/bin:$PATH"
export MANPATH="/opt/homebrew/opt/man-db/libexec/man:$MANPATH"
```

This makes the next step simpler, which is to identify the default binary and manpath location. By running `which <APPLICATION NAME>` and `man --path <APPLICATION NAME>`, I can identify where they are located. Homebrew installs everything underneath `/opt/homebrew/`, so if the path doesn't start there, then I know it needs to be reconfigured.

In these three examples, `awk` is not configured automatically at all, `gzip` only has its binary in `PATH`, and `git` is automatically configured correctly for both its `PATH` and `MANPATH`:

```bash
$ which awk && man --path awk
/usr/bin/awk
/usr/share/man/man1/awk.1

$ which gzip && man --path gzip
/opt/homebrew/bin/gzip
/usr/share/man/man1/gunzip.1

$ which git && man --path git
/opt/homebrew/bin/git
/opt/homebrew/Cellar/git/2.53.0/share/man/man1/git.1
```

The remaining list of values that need to be configured after `man` are:

```bash
# awk
export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/gawk/libexec/gnuman:$MANPATH"

# sed
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/gnu-sed/libexec/gnuman:$MANPATH"

# grep
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/grep/libexec/gnuman:$MANPATH"

# curl
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
export MANPATH="/opt/homebrew/opt/curl/share/man:$MANPATH"

# gzip
export MANPATH="/opt/homebrew/opt/gzip/share/man:$MANPATH"

# less
export MANPATH="/opt/homebrew/opt/less/share/man:$MANPATH"

# rsync
export MANPATH="/opt/homebrew/opt/rsync/share/man:$MANPATH"

# vim
export MANPATH="/opt/homebrew/opt/vim/share/man:$MANPATH"
```

For logical separation, I place all of these configurations in a file called `gnu-coreutils.sh`, and source it in `~/.zshrc`:

```bash
# GNU coreutils, diffutils and findutils
# coreutils
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/coreutils/libexec/gnuman:$MANPATH"

# diffutils
export PATH="/opt/homebrew/opt/diffutils/bin:$PATH"
export MANPATH="/opt/homebrew/opt/diffutils/share/man:$MANPATH"

# findutils
export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/findutils/libexec/gnuman:$MANPATH"


# Other CLI tools either installed with `g` prefix, or not under /opt/homebrew/bin
# man
export PATH="/opt/homebrew/opt/man-db/libexec/bin:$PATH"
export MANPATH="/opt/homebrew/opt/man-db/libexec/man:$MANPATH"

# awk
export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/gawk/libexec/gnuman:$MANPATH"

# sed
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/gnu-sed/libexec/gnuman:$MANPATH"

# grep
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
export MANPATH="/opt/homebrew/opt/grep/libexec/gnuman:$MANPATH"

# curl
export PATH="/opt/homebrew/opt/curl/bin:$PATH"
export MANPATH="/opt/homebrew/opt/curl/share/man:$MANPATH"


# CLI tools that already exist under /opt/homebrew/bin but don't
# have their manpath correctly updated
# gzip
export MANPATH="/opt/homebrew/opt/gzip/share/man:$MANPATH"

# less
export MANPATH="/opt/homebrew/opt/less/share/man:$MANPATH"

# rsync
export MANPATH="/opt/homebrew/opt/rsync/share/man:$MANPATH"

# vim
export MANPATH="/opt/homebrew/opt/vim/share/man:$MANPATH"
```


## Exclusions

There are some notable exclusions from this list of programs. Specifically, `openssh`, `unzip` and `tar`. The reason for this is that the default versions bundled with macOS have been modified to recognize macOS-specific extended attributes/additional functionality, which the GNU versions do not recognize.

For example, the `coreutils` tools `mv` and `cp` tools [do not preserve tags](https://brettterpstra.com/2014/07/03/mavericks-tags-and-coreutils-a-warning/). `unzip` and `tar` also reportedly [do not recognize macOS metadata](https://apple.stackexchange.com/a/71120). I've found that the bundled OpenSSH has a configuration option `UseKeychain` that can cache your SSH key in macOS's Keychain.

There may be many more examples, but these are the only ones I am aware of. I have re-aliased `mv` & `cp`, and haven't updated the `PATH`/`MANPATH` for `unzip` and `gnu-tar`:

```bash
#...
alias mv="/bin/mv"
alias cp="/bin/cp"
#...
```

I also haven't found a reason to replace the bundled `zsh` as of yet.

---

## Resources

- [Older guide for installing `coreutils`](https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/)
- [Stackexchange guide for installing `coreutils`](https://apple.stackexchange.com/a/69332)
- [Warning regarding tag preservation failure](https://brettterpstra.com/2014/07/03/mavericks-tags-and-coreutils-a-warning/)
- [Good guide on ZSH configuration for macOS](https://scriptingosx.com/2019/06/moving-to-zsh-part-2-configuration-files/)
