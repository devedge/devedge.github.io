---
title: minimally functional zsh config for servers
tags:
  - zsh
  - fedora
  - systemd
date: 2026-02-28 22:27:37
---


As I set up servers, I have a fairly minimal ZSH configuration I like to deploy to keep consistent behavior across all systems. A number of these tweaks make the shell much more usable and modify inconvenient defaults.

ZSH has a massive list of options that can be modified, so for logical clarity, I will be grouping my configs below based on the `manpages` where you can find them. This will make it easier to reference them and find related commands if needed. (If you need a quick refresher on using `manpages`, I have written up {% post_link man-man 'a guide right here' %})

_[Jump to the complete `~/.zshrc` config here](#full-zsh-config)_


## zshparam

ZSH parameters (`man zshparam`) are the variables that can be set to configure ZSH defaults. I set a default `HISTFILE` filename of `~/.zsh_history` that follows the same convention as Bash's `~/.bash_history`.

I also set a generous `HISTSIZE` of 10 million lines to save in memory, and set `SAVEHIST` to the same value for the number of lines in the history file:

```bash
HISTFILE=~/.zsh_history
HISTSIZE=10000000
SAVEHIST=$HISTSIZE
```

The `KEYTIMEOUT` is set to 1 (10ms) to minimize the `ESC` delay in the shell. I have another post {% post_link eliminating-esc-delays-in-tmux-vim-and-zsh 'that elaborates on this issue' %}:

```bash
KEYTIMEOUT=1
```


## zshoptions

ZSH options (`man zshoptions`) are toggles that can be flipped to modify default ZSH behavior. I adjust these to provide a better shell history experience.

The first option ensures that every single shell instance immediately writes to `~/.zsh_history` as commands are typed. This ensures that I never lose a command, or that they get written in blocks as the shell exits as opposed to chronological order.

An important point to note is that this doesn't update the in-memory history of each shell session. Thus, scrolling through the history with either the arrow keys or `CTRL+r` means that the history still looks contiguous per-shell. New shell sessions will have the entire history loaded in chronological order, as they were typed:

```bash
setopt INC_APPEND_HISTORY_TIME
```

This next option ensures the history also captures the instant timestamp (format: `:start:elapsed;command`) of when a command was run, and for how long:

```bash
setopt EXTENDED_HISTORY
```

These next two options are for search convenience. The first doesn't display duplicate lines while searching (with the up arrow or `CTRL+r`), and the second option strips out unecessary spaces between commands (eg,. if you accidentally double-tapped the spacebar):

```bash
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
```

This next option allows you to deliberately exclude a specific command from being written to ZSH history by typing a space first. This is especially useful when specifying passwords or secret keys in environment variables before a command, so that it doesn't get recorded in shell history. Note that it is temporarily saved in-memory until the next command is entered, so that you can use the up arrow to edit the command & re-run it:

```bash
setopt HIST_IGNORE_SPACE
```

This is a simple command that automatically expands `!!` into the previous command after you type a space. The advantage is better visibility into exactly what command you are re-running, which is a nice safeguard especially when typing `sudo !!`:

```bash
setopt BANG_HIST
```

This last option disables a particularly annoying behavior: when using unquoted URLs in the shell (such as with `curl` or `wget`), certain common characters in the URL are the same ones that the shell uses for glob matching, such as `?`. While Bash silently ignores it, ZSH fails the command with an error; unsetting the option causes ZSH to behave like Bash:

```bash
unsetopt NOMATCH
```


## zshcompsys, zshcontrib, zshbuiltins

These are a collection of smaller functions that allow for advanced functionality in ZSH.

ZSH has a completion system (`man zshcompsys`) that allows for autocompletion of many command-line flags, options, and more. ZSH creates a dumped (cached) configuration file under `~/.zcompdump` that gets intelligently updated as CLI programs are upgraded:

```bash
autoload -U compinit; compinit
```

To navigate quickly over CLI options, I frequently use `Control/Alt` to jump between words quickly instead of scrolling character-by-character. Bash only considers alphanumeric sequences of characters as words, so to mimic this in ZSH, set the word-style as Bash (`man zshcontrib`, `ZLE FUNCTIONS` section) with:

```bash
autoload -U select-word-style; select-word-style bash
```

ZSH builtins (`man zshbuiltins`) are additional commands, bundled with ZSH, that expand on the functionality of the shell. One of these functions is the command `fc`, which controls various aspects of the shell history.

I can never remember this command name, so I alias 2 of the most useful functions to more memorable commands. 

`zread` will instantly update the current shell's in-memory history with the `~/.zsh_history` file (which is being written to in realtime). I use this when I want to update command history from another open shell session into the current one (a common occurrence when I have multiple shells open in `tmux`).

`zhist` is a quick way to preview the last few commands (globally, from `~/.zsh_history`) with the exact date-timestamps they were executed. By default, it only lists the last 10 commands. If a negative number is specified afterwards (eg., `zhist -32`), it displays the last X number of lines.

```bash
alias zread='fc -R'
alias zhist='fc -lni'
```


## systemd bonus

`systemd` sets some frustrating options when the `less` pager is called (by default, the full list of options passed to `less` are: `FRSXMK` (found in `man systemctl`)).

These two options are:

- `S` This automatically chops lines that are wider than the terminal width instead of wrapping them. As a result, you have to start scrolling first right and then left to trigger the `less` pager and read the entire line.

- `X`: This prevents the terminal from restoring its previous view after you've exited the pager. This means that output from commands such as `journalctl` completely fill up the terminal with lingering output.

By removing both of these options, you can have a more friendly default:

```bash
export SYSTEMD_LESS='FRMK'
```


## fedora double bonus

When I exited an `ssh` session from my Fedora servers, it would clear the entire terminal pane. I didn't like this, since sometimes I was just jumping in to check a quick config option and this would reset my viewport.

After some digging, I found that Fedora sets a default `zlogout` in `/etc/zlogout` that gets called every time I exit an `ssh` session. I simply commented out the following line to disable the behavior:

```bash
#command -v clear &> /dev/null && clear
```


## full zsh config

Here is the full `~/.zshrc` config file, annotated with short comments:

```bash
# zsh configuration
#
# man zshparam
HISTFILE=~/.zsh_history         # history file
HISTSIZE=10000000               # in-memory history
SAVEHIST=$HISTSIZE              # history file size
KEYTIMEOUT=1                    # 10ms delay for key sequences
# man zshoptions
setopt INC_APPEND_HISTORY_TIME  # write history immediately, not when shell exits
setopt EXTENDED_HISTORY         # history format: ":start:elapsed;command"
setopt HIST_FIND_NO_DUPS        # don't display duplicate lines when searching
setopt HIST_REDUCE_BLANKS       # remove superfluous blanks
setopt HIST_IGNORE_SPACE        # don't save lines that start with a space
setopt BANG_HIST                # automatically expand !! after typing a space
unsetopt NOMATCH                # allow typing URLs without quoting them
# man zshcompsys, zshcontrib, zshbuiltins
autoload -U compinit; compinit  # initialize zsh completion
autoload -U select-word-style; select-word-style bash   # bash-style word jumping
alias zread='fc -R'             # read latest shell history from file into memory
alias zhist='fc -lni'           # list last 10 historical commands (zhist -<number> for more)

# remove 'X' and 'S' options
export SYSTEMD_LESS='FRMK'
```

---

## resources

- Good reference for many of these options:
    https://unix.stackexchange.com/a/273863
- Manpage guide:
    {% post_link man-man %}
- Escape Delay post:
    {% post_link eliminating-esc-delays-in-tmux-vim-and-zsh %}
