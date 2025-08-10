---
title: vim encoding/decoding base64 in Kubernetes secrets
tags:
  - vim
  - kubernetes
date: 2025-08-09 21:54:21
---


Kubernetes provides the ability to edit secrets from the command line, but there's a catch: they're encoded with base64 and `kubectl` provides no way to encode/decode it.

There are several solutions online to this problem, often involving installing another tool. However, vim can do this with the help of the `base64` binary commonly found on Linux systems.

The following solution is based on [this StackOverflow post](https://stackoverflow.com/a/7846569), but with a critical modification to fix unintended behavior.


## echo decode in Command Mode

These commands rely on using Visual selection mode to select a block of text that should be encoded or decoded.

This first configuration entry, which can be added in `~/.vimrc`, only decodes the selected text in Visual mode and prints it into the Command Mode line at the bottom of the vim editor:

```vim
vnoremap <leader>64 y:echo system('base64 --wrap=0 --decode', @")<cr>
```

After making a visual selection, type `\` quickly followed by `64` to print the base64 decoded line. The 'quickly' is because `\`, known as the 'leader', is a special character used to prefix these kinds of custom mappings and has a timeout of 1 second. 

This can be extended by setting the `timeoutlen` variable in vim, but be sure to utilize the `ttimeoutlen` variable so pressing ESC does not also use the same delay. {% post_link eliminating-esc-delays-in-tmux-vim-and-zsh This post %} dives into this further.

The `--wrap=0` is very important because by default, `base64` wraps to 76 characters - that flag will disable this behavior.


## decode inline

This configuration line does the same as above, but actually modifies the text inline in the vim editor:

```vim
vnoremap <leader>d64 c<c-r>=system('base64 --wrap=0 --decode', @")<cr><esc>
```

Use this by typing `\` followed by `d64` (decode 64).


## encode inline

After making modifications to a secret, it should be re-encoded. This following configuration entry allows for re-encoding a block of visually selected text inline in the vim editor:

```vim
vnoremap <leader>e64 c<c-r>=system('base64 --wrap=0', @")<cr><esc>
```

Use this by typing `\` followed by `e64` (encode 64)


## correctly selecting text in Visual Mode

It might make sense to start Visual selection mode and select an entire line of text to the end with `v$`. However, this would be a mistake since it _also_ selects the newline character `\n`.

Instead, to select to the end without the newline, type: `vg_`

Alternatively if the cursor is already at the end of the line, the reverse selection up to (but not including) the first space character can be done with v + SHIFT t + SPACE (`vT `). 

---

## resources

- Reference StackOverflow post
    https://stackoverflow.com/a/7846569
- Excellent resource for creating vim mappings
    https://alldrops.info/posts/vim-drops/2018-05-15_understand-vim-mappings-and-create-your-own-shortcuts/
