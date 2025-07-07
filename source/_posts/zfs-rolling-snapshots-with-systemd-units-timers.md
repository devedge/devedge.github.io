---
title: zfs rolling snapshots with systemd units + timers
tags:
  - zfs
  - systemd
date: 2025-07-06 19:49:33
---


As a copy-on-write filesystem, ZFS provides the capability to take snapshots. However, taking and managing them is completely manual, so maintaining a rolling list of snapshots requires either custom bash scripts + cron, installing external tools such as sanoid, or using an entire OS in the case of TrueNAS.

However, this functionality can be easily achieved by utilizing systemd units and timers.

## unit file

The goal of this unit file is to keep a week's worth of daily snapshots. Each snapshot is named in a way that is easily referenced:

```
autosnapshot-7-days-ago
autosnapshot-6-days-ago
autosnapshot-5-days-ago
autosnapshot-4-days-ago
autosnapshot-3-days-ago
autosnapshot-2-days-ago
autosnapshot-1-day-ago
```

Since ZFS snapshots can be renamed, the strategy for rolling them is to delete the oldest one, rename all the subsequent ones, and take a new one.

```bash
zfs destroy %I@autosnapshot-7-days-ago
zfs rename %I@autosnapshot-6-days-ago %I@autosnapshot-7-days-ago
...
zfs snapshot %I@autosnapshot-1-day-ago
```

Conveniently, systemd units have the `ExecStartPre` directive in the `[Service]` section, allowing for commands to be run before the actual target command., eg., the latest snapshot. 

Additionally, it is possible to prepend the entire command with a `-`, which prevents the unit from failing if the command fails. This is great for a first-time run where none of the previous snapshots exist, causing the ZFS command to fail.

Finally, this unit file has the ability to pause snapshots instantly. This is done by requiring a specific path _not_ exist with a negated `ConditionPathExists`:

```
ConditionPathExists=!/home/gadget/pause-snapshots
```

Pausing is as simple as a `touch ~/pause-snapshots`, and once the file is deleted, snapshots resume whenever the timer triggers the unit file again. This could even be used to pause multiple (or all) autosnapshots on a system if they are all pointed to the same file.

### zfs-7-daily-autosnapshots@.service

```ini
[Unit]
Description=Keep 7 rotating snapshots of %I daily
Requires=zfs.target
After=zfs.target
ConditionACPower=true
ConditionPathIsDirectory=/sys/module/zfs
ConditionPathExists=!/home/gadget/pause-snapshots

[Service]
EnvironmentFile=-/etc/sysconfig/zfs
Type=exec
Restart=no
ExecStartPre=-/sbin/zfs destroy %I@autosnapshot-7-days-ago
ExecStartPre=-/sbin/zfs rename %I@autosnapshot-6-days-ago %I@autosnapshot-7-days-ago
ExecStartPre=-/sbin/zfs rename %I@autosnapshot-5-days-ago %I@autosnapshot-6-days-ago
ExecStartPre=-/sbin/zfs rename %I@autosnapshot-4-days-ago %I@autosnapshot-5-days-ago
ExecStartPre=-/sbin/zfs rename %I@autosnapshot-3-days-ago %I@autosnapshot-4-days-ago
ExecStartPre=-/sbin/zfs rename %I@autosnapshot-2-days-ago %I@autosnapshot-3-days-ago
ExecStartPre=-/sbin/zfs rename %I@autosnapshot-1-day-ago %I@autosnapshot-2-days-ago
ExecStart=/sbin/zfs snapshot %I@autosnapshot-1-day-ago
```

The remainder of the directives were taken from the `zfs-scrub@.service` bundled along with the ZFS installation on Fedora 41. No `[Install]` section is required since this unit file will be triggered by a timer.

## timer file

The timer is even simpler. The `OnCalendar` directive is set to `daily`, and the variable window of time when it runs is reduced to 10 seconds from the default of 1 minutes using `AccuracySec`:

### zfs-7-daily-autosnapshots@.timer

```ini
[Unit]
Description=Keep 7 rotating snapshots of %I daily

[Timer]
OnCalendar=daily
AccuracySec=10seconds
Unit=zfs-7-daily-autosnapshots@%i.service

[Install]
WantedBy=timers.target
```

## enabling the service

There's a gotcha when trying to pass the full ZFS pool+dataset(s) path to the timer as an instance variable: a ZFS path contains invalid characters that can't be passed on the command line - namely, forward slashes and dashes (`/`, `-`).

Luckily, systemd has a way to handle this: `systemd-escape`, and the variables `%i` and `%I`.

First, pass the full ZFS path to `systemd-escape`:

```bash
$ systemd-escape "pool-1/dataset-2"
pool\x2d1-dataset\x2d2
```

This is the safely escaped ZFS path, and the timer can be enabled by using it:

```bash
sudo systemctl enable --now 'zfs-7-daily-autosnapshots@pool\x2d1-dataset\x2d2.timer'
```

Or in one command:

```bash
sudo systemctl enable --now "zfs-7-daily-autosnapshots@$(systemd-escape 'pool-1/dataset-2').timer"
``

The timer unit file will use `%i` to enable the respective unit service file with the escaped string. However, the service will use the unescaped string with `%I` to run the ZFS snapshot commands.

The systemd timers can be listed with:

```bash
systemctl list-timers
```

And the snapshots, their creation dates, and the amount of space they use can be listed with:

```bash
zfs list -t snapshot -o name,creation,used
```
