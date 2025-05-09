---
title: eliminating ESC delays in tmux, vim and zsh
tags:
  - tmux
  - vim
  - zsh
date: 2025-05-09 17:36:40
---


For a while, I had vaguely noticed an odd delay whenever I pressed `ESC` in vim. It was not until I started using vim inside tmux that the delay became very obvious. After some quick research, it turned out this was an intentional feature of both programs (and certainly many more).

To cut a long story short, a number of key sequences that your keyboard transmits are actually a combination of `ESC` and a letter on your keyboard for historical reasons (known as an [`escape squence`](https://en.wikipedia.org/wiki/ANSI_escape_code)). As a result, older computers could have trouble telling the difference between them and a really fast typist. Programs such as tmux and vim get around this by adding an artifical delay any time the `ESC` key is pressed, so it remains slower then when it is used as an escape sequence.

Of course, these limitations rarely apply to modern computers anymore. Unless you're on a network connection with crazy latency, this is not an issue. The following are the settings to adjust in tmux, vim, and zsh to reduce this delay:

## tmux `escape-time`

Despite a lot of common advice, you should avoid setting the delay time to zero. Even though internet latency in general has never been shorter, the delay between characters is still not zero and can [lead to strange problems](https://superuser.com/a/1809494) if you set it that low.

I generally keep all of the combined delays to a value that is barely noticeable, often not perceptible at all. Anything above 100ms is annoying for me, and I currently keep the combined delay values across all 3 tools to 25ms.

For tmux, this means setting the delay to 5ms in `~/.tmux.conf`:

```
set -g escape-time 5
```

## vim `timeoutlen`, `ttimeoutlen`

vim has two settings for controlling delays. However by default, only one, `timeoutlen`, is used to set a delay of 1000ms (1 second) for both mappings and for the delays between escape sequences. Since mappings are deliberate sequences of characters that you (usually) can't start typing in less than 10ms, it makes sense to keep that one at 1000ms (or longer if needed). This leaves us with the second option `ttimeoutlen`, which we can set to a much lower value in `~/.vimrc`:

```
set timeoutlen=1000 ttimeoutlen=10
```

## zsh `KEYTIMEOUT`

Your shell will also have a delay for escape sequences. Since I use zsh, I set this in my `~/.zshrc` file:

```sh
KEYTIMEOUT=1
```

This value is in [hundredths of a second](https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell-1), so a value of 1 will result in a 10ms delay.

---

## resources

- An excellent historical breakdown on the origin of escape sequences:
    https://unix.stackexchange.com/a/608179
- Cautionary warning against setting escape delay times to zero:
    https://superuser.com/a/1809494