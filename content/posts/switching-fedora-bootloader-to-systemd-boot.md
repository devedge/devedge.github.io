+++
title = "Switching Fedora bootloader to systemd-boot"
date = "2026-02-22 12:30:03"

[taxonomies]
tags = ["fedora", "systemd"]
+++


The current default bootloader for Fedora 43 is still `GRUB`, and I wanted to switch over to the native systemd bootloader `systemd-boot`. However, it was somewhat of a challenge to find clear instructions for this process, so I'll step through them here.

This guide only shows how to set up `systemd-boot` on a fresh Fedora 43 install, since I had challenges trying to switch from `GRUB` post-installation.

_Note_: Ironically, this method is [broken specifically for Fedora 43](https://bugzilla.redhat.com/show_bug.cgi?id=2402975). A fix [has been merged](https://bodhi.fedoraproject.org/updates/FEDORA-2025-3190649b5c) into the upcoming Fedora 44 release.

Before you even boot into the Fedora ISO of your choosing, the `GRUB` bootloader will flash:

![bootloader-picker](/assets/switching-fedora-bootloader-to-systemd-boot/bootloader-picker.png)

Before the 60s timer runs out, use the arrow keys to select the installation and press `e` to enter an Emacs-like editor:

![bootloader-editor](/assets/switching-fedora-bootloader-to-systemd-boot/bootloader-editor.png)

The editor will show the current boot parameters that are being used to boot into the specified ISO.

Now, enter the text `inst.sdboot` after the second line, `linuxefi /images/pxeboot/vmlinuz `:

![bootloader-sdboot](/assets/switching-fedora-bootloader-to-systemd-boot/bootloader-sdboot.png)

Type `Ctrl+x` to save & boot with the modified boot parameters, and you'll be good to start your OS installation!

![fedora43-installation](/assets/switching-fedora-bootloader-to-systemd-boot/fedora43-installation.png)

---

## Resources

- [Fedora instructions for testing `systemd-boot`](https://fedoraproject.org/wiki/Changes/cleanup_systemd_install)
- [Arch Wiki entry for further information on `systemd-boot`](https://wiki.archlinux.org/title/Systemd-boot)
