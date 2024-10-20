---
layout: post
title: "checking out alacritty"
description: "Investigating iTerm2 alternatives"
date: 2024-09-23
tags: [configuration,iterm2,shell,terminal]
---

A lot has changed since my last post. One of these is my terminal.

I've used iTerm2 for a while, but recent events have led me to reconsider. The [developer added AI integration](https://gitlab.com/gnachman/iterm2/-/issues/11470) into it, and although he [moved it out to a separate installable module](https://gitlab.com/gnachman/iterm2/-/issues/11470#note_1917647951), it made me question the direction of the project. 

A webhook to a remote AI service really shouldn't be a built-in feature of a terminal, which is one of the most privileged applications that can be installed and sees some of the most sensitive authorization information available on a computer. I also suspect the security of the built-in Python scripting features now, so instead of doing more research, I'm trialling one of the terminal alternatives that users [mentioned in ones of the many issues](https://gitlab.com/gnachman/iterm2/-/issues/11475#note_1915772232).

This has led me to [Alacritty](https://alacritty.org/).

---

### Alacritty

![Alacritty CPUfetch](/assets/images/alacritty-cpufetch.png){: .center-image}

Alacritty is a super minimal terminal. Yes, it's written in Rust and is advertised as running really fast, but that's the first thing that really stands out once you install it.

I've run it for a couple months, and here's some of my impressions:

__Pros__

- Very Minimal

	This was the most important to me, and I really like it. No fancy UI, window management, settings window - not even tabs.

- Useable settings

	Despite no settings UI, the settings are easy to configure and build out. I really like the use of TOML, which I prefer over YAML or JSON configuration files which are all-too common. Alacritty doesn't start with a default settings file, but drop one in one of the config file paths listed in the manpage (`man alacritty`), and you can start filling them out.

- Very fast

	While not as critical to me, the incredible snappiness and speed of the terminal is very nice. It doesn't feel bloated, doesn't hang up, and altogether feels transparent when working, which is exactly what I expect out of a good terminal.


__Cons__

- macOS support

	Alacritty has decent suport on macOS. There is support for borderless windows, transparency, blur, and a number of keyboard actions.

	However, there's some basic polish lacking:

	- Drop shadow rendering is flaky, occasionally disappearing if a minimized window is reopened or when changing desktops. Drop shadows are intentionally disabled if you enable terminal transparency. 

	- There is artifacting around the corners of the windows, a rectangular outline, and it intermittently appears whether the window is borderless or not.

	- Every new window gets its own app icon in the dock. I don't often run new windows so this hasn't affected me enough to find a workaround.

	- Additional windows are not listed when right-clicking the dock icon.

	- And while this is super nitpicky, the icon is abnormally shaped as a rectangle instead of providing a square one to match the icon format of every other modern mac application.

- Sensitive side scrolling

	One of the stranger features I've seen a terminal support, Alacritty allows for side scrolling. I have never seen this become useful, and it quickly becomes very annoying when using a trackpad. The slightest deviation from centerline in a pager (like less) instantly blanks out the terminal as it sharply veers off to the right. It's also irritating when using Vi mode in any application that supports it since the cursor wanders all over the place.

	Alacritty doesn't support disabling or adjusting this. I haven't found a way to intercept the scroll keycodes sent to the terminal, as Alacritty appears to be capturing them and sending them directly. 

- No ligatures

	A less important issue, but ligatures aren't supported and reading between the lines, the maintainers are adamant that they never will be. They pretty clearly don't think any user-submitted changes [are up to their standards, or integration](https://github.com/alacritty/alacritty/issues/50#issuecomment-796785904). Not critical to me, but interesting how they handled the request.

- No image printing

	Even less important to me, but this seems to be a more commonly accepted feature of modern terminals. [Same response/behavior as above](https://github.com/alacritty/alacritty/issues/51#issuecomment-650776702) with regards to ligatures.

- Maintainer behavior

	All of this would be fine and could be considered teething problems, but the maintainers' abrasive behavior is offputting. They seem to have a condescending and hostile reaction to anything mac-related, which they [struggle](https://github.com/alacritty/alacritty/issues/6511#issuecomment-1320201353) to keep [thinly veiled](https://github.com/alacritty/alacritty/issues/3926#issuecomment-655097995).

	I don't hold any animosity towards them, but it doesn't inspire confidence in the future of this app or the quick resolution of issues. Supporting the remapping of the Option key to Alt (a common and pretty obvious feature) [took 6 years to complete](https://github.com/alacritty/alacritty/issues/62#issuecomment-1411879675).

	Nevertheless, let's move onto some configurations.

### Configurations

The configs I'll be listing here are pretty minimal. I will be making future posts covering the advanced keybindings I use to send keycodes to both tmux and zsh, as they deserve dedicated topics unto themselves.

#### Theme

As with every other tool, I like to use the [Nord theme](https://www.nordtheme.com). However, it unfortunately appears that the lead maintainer has been on indefinite hiatus, so [it hasn't been migrated](https://github.com/nordtheme/alacritty/issues/40) from Alacritty's old YAML configuration format to TOML. 

Thankfully, someone put together a [Gist of the Nord theme in TOML](https://gist.github.com/candidtim/6097565040a3aec839a8a2d28cb8887d).

The only 2 modifications I made are:

```toml
[colors.selection]
text = "#3b4251"	# Text is always dark
background = "#d8dee8"	# Light background
```

#### App configs

```toml
# .alacritty.toml
import = ["~/.alacritty.nord-theme.toml"]   # Import Nord theme from a separate file
live_config_reload = true                   # Reload Alacritty on config changes

[window]
dimensions = { columns = 120, lines = 50 }
decorations = "Buttonless"                  # Remove the top title bar for a minimal look
resize_increments = true                    # Resize window content in character increments
option_as_alt = "Both"                      # Make the Mac Option key behave as Alt
decorations_theme_variant = "Dark"          # Force the OS window theme to be Dark

# Pad the terminal content
dynamic_padding = true
padding = { x = 25, y = 25 }

[scrolling]
history = 100000 # maximum

[font]
size = 15
normal = { family = "FiraCode Nerd Font Mono", style = "Regular" }

[selection]
save_to_clipboard = true                    # Immediately save selected text to clipboard

# Keep the cursor always blinking unless Alacritty is in Vi mode
[cursor]
style = { shape = "Block", blinking = "Always" }
vi_mode_style = { shape = "Block", blinking = "Off" }
blink_timeout = 0
```

As mentioned above, I will cover custom keybindings in a later post. Ideally, I'll flush out a consistent keybinding set across tmux, zsh, and vim that also isn't too convoluted to pick up and use.

## Resources

- [iTerm2 adds AI integration](https://gitlab.com/gnachman/iterm2/-/issues/11470)
- [iTerm2 moves AI to external module](https://gitlab.com/gnachman/iterm2/-/issues/11470#note_1917647951)
- [Alacritty](https://alacritty.org/)
- [Nord theme Gist for Alacritty](https://gist.github.com/candidtim/6097565040a3aec839a8a2d28cb8887d)
