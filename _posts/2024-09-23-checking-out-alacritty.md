---
layout: post
title: "checking out alacritty"
description: "Investigating iTerm2 alternatives"
date: 2024-09-23
tags: [configuration,iterm2,shell,terminal]
---

A lot has changed since my last post. One of them is my terminal.

I've used iTerm2 for a while, but recent events have led me to reconsider. The developer added AI integration into it, and although he moved it out to a separate installable module, it made me question the direction of the project. 

A webhook to a remote AI service really shouldn't be a built-in feature of a terminal, usually one of the most privileged applications that can be installed, and which usually sees some of the most sensitive authorization information. I also suspect the security of the built-in Python scripting features now, so instead of doing more research, I'm trialling one of the terminal alternatives that users mentioned in the Issue.

This has let me to Alacritty.

---

### Alacritty

![Alacritty CPUfetch](/assets/images/alacritty-cpufetch.png){: .center-image}

Alacritty is a super minimal terminal. Yes, it's written in Rust and is advertised as running really fast, but that's the first thing that really stands out once you install it.

I've run it for a couple months, and here's some of my impressions:

Pros

- Very Minimal

	This was the most important to me, and I really like it. No fancy UI, window management, settings window - not even tabs.

- Useable settings

	Despite no settings UI, the settings are easy to configure and build out. I really like the use of TOML, which I prefer over YAML or JSON configuration files which are all-too common. Alacritty doesn't start with a default settings file, but drop one in one of the config file paths listed in the manpage (`man alacritty`), and you can start filling them out.

- Very fast

	While not as critical to me, the incredible snappiness and speed of the terminal is very nice. It doesn't feel bloated, doesn't hang up, and altogether feels transparent when working, which is exactly what I expect out of a good terminal.


Cons

- macOS support

	Alacritty has middling suport on macOS.

	There is support for borderless windows, transparency, blur, and a number of keyboard actions.

	However, drop shadow rendering is flaky at best, occasionally disappearing if a minimized window is reopened or when changing desktops. Drop shadows are completely disabled if you enable terminal transparency. The top of a borderless window can sometimes render with a white line that obviously isn't part of the theme. Every new window gets its own app icon in the dock (I don't often run new windows so this hasn't affected me enough to find a workaround, but I couldn't find an option in the settings.) And while this is super nitpicky, the icon is abnormally shaped as a rectangle instead of providing a square one to match the icon format of every other modern mac application.

- No ligatures

	Another small issue, but ligatures aren't supported and reading between the lines, the maintainers are adamant that they never will be. They pretty clearly don't think any user-submitted changes are up to their standards, or integration. Again, not critical to me, but interesting how they handled the request.

- No image printing

	Even less important to me, but this seems to be a more commonly accepted feature of modern terminals. Same response/behavior as above with regards to ligatures.

- Maintainer behavior

	All of this would be fine and could be considered teething problems of an program pushing the boundaries of a crystallized application category, but the maintainers' abrasive behavior is offputting. They seem to have an active hostile reaction to anything mac-related, which they struggle to keep thinly veiled.

	I don't hold any animosity towards them, but it doesn't inspire confidence in the future of this app. Nevertheless, let's move onto some configurations.
