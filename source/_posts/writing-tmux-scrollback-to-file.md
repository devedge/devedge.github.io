---
title: writing tmux scrollback to file
tags: tmux
date: 2025-05-03 22:55:37
---

Occasionally, I'll be running a command in tmux that prints a lot of output - then realize midway that I'd like to save it for further inspection (eg., bootloader recompilation errors on system upgrade). 

After digging around for a while, I found an excellent starting point [on StackOverflow](https://unix.stackexchange.com/a/26568) and modified it:

```bash
bind-key -T copy-mode-vi S command-prompt \
    -p 'Save scrollback (start at cursor):' \
    -I './tmuxscrollback-history-#{t|f|%%Y%%m%%d%%H%%M%%S:client_activity}.txt' \
    -F 'capture-pane -S #{e|*:-1,#{e|-:#{scroll_position},#{copy_cursor_y}}} ; save-buffer %1 ; delete-buffer'

```

To use this:

- jump into copy mode (Vi) with `<TMUX PREFIX> [`
- scroll up however far as needed
- leave the cursor at the line where the scrollback should start
- type `SHIFT s`, and either use the default timestamped filename or overwrite it with a custom one
- hit `<ENTER>` to save to the file

The command automatically calculates the scrollback position and the cursor offset to pick the starting line, and writes everything from that point on downwards to the target file. 

## command breakdown

Bind `S` (capital s) in Vi copy mode & prompt for a filename:

```
bind-key -T copy-mode-vi S command-prompt -p 'Save scrollback (start at cursor):'
```

Autogenerate a default filename with an instant timestamp. The `client_activity` event was picked because it continues to update as the user interacts with tmux, rather than something like `buffer_created` which would not update when taking multiple scrollback saves. Use tmux string formatting (can be found under `FORMATS` section in the manpage, or on [the official Wiki](https://github.com/tmux/tmux/wiki/Formats)) to generate a `YearMonthDayHourMinuteSecond` timestamp.

```
-I './tmuxscrollback-history-#{t|f|%%Y%%m%%d%%H%%M%%S:client_activity}.txt'
```

The command that the `command-prompt` directive will execute. The `-F` flag is required for the calculation of the scrollback offset defined in the next section, and the `-S` flag sets the starting line number.

```
-F 'capture-pane -S
```

Calculate the offset. First, the entire calculation is multplied by `-1` to provide a negative offset into the scroll buffer. `#{e` marks this as an execution block, and the `*` (after the `|` delineator) marks the mathematical operation that will happen between the next 2 values, which are specified after the `:` (`-1` and the offset).

```
#{e|*:-1, ... }
```

The offset is calculated by subtracting the scrollback position into the pane history from the cursor offset in the currently visible pane. These two variables are defined as:

- `#{scroll_position}` the scrollback position during copy mode. This is anchored against the top of the tmux pane, and is zero-indexed when copy mode is initialized at the very bottom of the scrollback history.
- `#{copy_cursor_y}` the cursor offset, which is zero-indexed against the top of the currently visible tmux pane.

The `scroll_position` is the larger value unless the user does not scroll up. This makes the multiplication by `-1` a much better choice than prepending the equation with a minus sign: the cursor offset `copy_cursor_y` reduces the starting line position _except_ when the pane has not been scrolled up, which instead results in a positive value.

```
... #{e|-:#{scroll_position},#{copy_cursor_y}} ...
```

Save the buffer that was just calculated into the filename, using the variable `%1`. Then, clear it so it doesn't linger in the user's copy buffer.

```
 ; save-buffer %1 ; delete-buffer'
```

## references

- tmux official Wiki
    https://github.com/tmux/tmux/wiki
- tmux Wiki FORMATS
    https://github.com/tmux/tmux/wiki/Formats
