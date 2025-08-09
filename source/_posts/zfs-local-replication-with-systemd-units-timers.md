---
title: zfs local replication with systemd units + timers
tags:
  - zfs
  - systemd
date: 2025-07-09 19:39:21
---


Following up the previous post on {% post_link zfs-rolling-snapshots-with-systemd-units-timers creating rolling ZFS snapshots with systemd units & timers %}, this entry will cover continuous replication of these snapshots to another pool on the same host, using the same strategy.


## unit file

The unit file relies on snapshots having a consistent naming scheme. The names here are the ones defined in the the previous post:

```
autosnapshot-7-days-ago
autosnapshot-6-days-ago
...
autosnapshot-1-day-ago
```

Unlike the autosnapshot unit file however, this is not initialized with the pool name as an instance variable. This is because there are 2 variables: the source pool and the target pool, which would necessitate some implicit functionality - they are both defined as environment variables in the unit file instead:

```ini
[Service]
...
Environment="REPLICATION_SOURCE=pool-1/dataset2"
Environment="REPLICATION_TARGET=pool-2/backups/pool-1/dataset2"
...
```

This unit file handles rotating the snapshots on the replication target. This could be adjusted to save a different number of snapshots, but for consistency, it will match the strategy used in the autosnapshot unit file.

Lastly, the replication command needs to be wrapped in a `/usr/bin/sh -c "..."` statement since the ZFS CLI requires a unix pipe to send/receive and has no alternative. The systemd Exec* directives do not support pipes, so running it in a subshell is hacky but officially recommended (`COMMAND LINES` section in the `systemd.service(5)` manpage).

```ini
[Service]
...
ExecStart=/usr/bin/sh -c "zfs send --raw --props -i @autosnapshot-2-days-ago ${REPLICATION_SOURCE}@autosnapshot-1-day-ago | zfs receive -Fv ${REPLICATION_TARGET}"
```

The filename format of the unit file is:

```
zfs-autoreplication-<dataset name>-<number of retained snapshots>-<frequency>.service
```

### zfs-autoreplication-dataset2-7-daily.service

```ini
[Unit]
Description=Keep 7 rotating daily snapshots of pool-1/dataset2 replicated to pool-2
Requires=zfs.target
After=zfs.target
ConditionACPower=true
ConditionPathIsDirectory=/sys/module/zfs
ConditionPathExists=!/home/gadget/pause-replications

[Service]
EnvironmentFile=-/etc/sysconfig/zfs
Type=exec
Environment="REPLICATION_SOURCE=pool-1/dataset2"
Environment="REPLICATION_TARGET=pool-2/backups/pool-1/dataset2"
ExecStartPre=-/sbin/zfs destroy ${REPLICATION_TARGET}@autosnapshot-7-days-ago
ExecStartPre=-/sbin/zfs rename ${REPLICATION_TARGET}@autosnapshot-6-days-ago ${REPLICATION_TARGET}@autosnapshot-7-days-ago
ExecStartPre=-/sbin/zfs rename ${REPLICATION_TARGET}@autosnapshot-5-days-ago ${REPLICATION_TARGET}@autosnapshot-6-days-ago
ExecStartPre=-/sbin/zfs rename ${REPLICATION_TARGET}@autosnapshot-4-days-ago ${REPLICATION_TARGET}@autosnapshot-5-days-ago
ExecStartPre=-/sbin/zfs rename ${REPLICATION_TARGET}@autosnapshot-3-days-ago ${REPLICATION_TARGET}@autosnapshot-4-days-ago
ExecStartPre=-/sbin/zfs rename ${REPLICATION_TARGET}@autosnapshot-2-days-ago ${REPLICATION_TARGET}@autosnapshot-3-days-ago
ExecStartPre=-/sbin/zfs rename ${REPLICATION_TARGET}@autosnapshot-1-day-ago ${REPLICATION_TARGET}@autosnapshot-2-days-ago
ExecStart=/usr/bin/sh -c "zfs send --raw --props -i @autosnapshot-2-days-ago ${REPLICATION_SOURCE}@autosnapshot-1-day-ago | zfs receive -Fv ${REPLICATION_TARGET}"
```


## timer file

The timer is very simple. The `OnCalendar` directive is set to 5 minutes after midnight, allowing the autosnapshot service plenty of time to complete first.

### zfs-autoreplication-dataset2-7-daily.timer

```ini
[Unit]
Description=Keep 7 rotating daily snapshots of pool-1/dataset2 replicated to pool-2

[Timer]
OnCalendar=*-*-* 00:05:00
Unit=zfs-autoreplication-dataset2-7-daily.service

[Install]
WantedBy=timers.target
```


## enabling the service

Unlike the autosnapshot service, the autoreplication service requires some manual preliminary setup. 

First, the entire ZFS pool+dataset hierarchy needs to be created beforehand, _except_ for the actual dataset to be replicated. In this example, `pool-1/dataset2` is being replicated to `pool-2/backups/pool-1/dataset2`, so the path to create is `pool-2/backups/pool-1`:

```bash
sudo zfs create -p pool-2/backups/pool-1
```

Next, send over the very first snapshot. In this case the dataset is encrypted, so the `--raw` and `--props` flags are used to send over the dataset exactly as it exists on disk with all of its custom properties:

```bash
sudo zfs send --raw --props pool-1/dataset2@autosnapshot-1-day-ago | zfs receive -Fv pool-2/backups/pool-1/dataset2@autosnapshot-1-day-ago
```

The reason for manually running this command is because it does not include the previous snapshot as an option (`-i`) - something the unit file relies on.

Finally, the autoreplication service + timer can be started:

```bash
sudo systemctl enable --now zfs-autoreplication-dataset2-7-daily.timer
```
