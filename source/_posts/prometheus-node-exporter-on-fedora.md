---
title: prometheus node_exporter on fedora
tags:
  - prometheus
  - fedora
  - selinux
date: 2025-05-12 23:08:58
---

Prometheus provides a server-level metrics exporter [called `node_exporter`](https://prometheus.io/docs/guides/node-exporter/) that reports hardware & kernel-level metrics. However, I found the container deployment method in Docker to be too extreme, and there was no clear documentation for setting it up manually or any officially supported package on Fedora.

Other unofficial online resources didn't mention working with SELinux or firewalld, so this guide outlines how to set up a basic `node_exporter` daemon on a Fedora 41 server.

## download and extraction

Fairly straightforward, find your appropriate version [on the downloads page](https://prometheus.io/download/#node_exporter) and download it:

```bash
curl -JLO https://github.com/prometheus/node_exporter/releases/...
```

and extract it:

```bash
tar -xvf node_exporter-1.9.1.linux-amd64.tar.gz
```

## user creation and manual installation

Manual installation involves moving the executable to the `/usr/local/bin/` directory, which [is specifically for programs](https://en.wikipedia.org/wiki/Unix_filesystem#Conventional_directory_layout) that normal users can run.

```bash
sudo mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/
```

Create the `node_exporter` user & group for the service account that runs the binary, and apply them to the binary. It does not need to run with any special privileges to gather metrics, and the login shell is disabled for security:

```bash
sudo useradd -rs /sbin/nologin node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

## systemd unit file

Create the systemd unit file at `/etc/systemd/system/node_exporter.service`:

```ini
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=exec
Restart=always
ExecStart=/usr/local/bin/node_exporter --web.listen-address="0.0.0.0:9100"

[Install]
WantedBy=multi-user.target
```

This is a very simple configuration that gets `node_exporter` listening on all interfaces on the default port `9100`.

##  SELinux relabelling

Depending on where/how you downloaded it, the binary will likely have an incorrect SELinux label:

```
[gadget@trinity ~]# ls -Z /usr/local/bin/
unconfined_u:object_r:user_home_t:s0 node_exporter
```

This means that attempting to start it will fail. This is the `journalctl` log, and you can see SELinux kicking in with the `AVC` line:

```
...
May 12 17:11:45 trinity audit[569311]: AVC avc:  denied  { execute } for  pid=569311 comm="(exporter)" name="node_exporter" dev="dm-0" ino=180936 scontext=system_u:system_r:init_t:s0 tcontext=unconfined_u:object_r:user_home_t:s0 tclass=file permissive=0
May 12 17:11:45 trinity (exporter)[569311]: node_exporter.service: Unable to locate executable '/usr/local/bin/node_exporter': Permission denied
May 12 17:11:45 trinity (exporter)[569311]: node_exporter.service: Failed at step EXEC spawning /usr/local/bin/node_exporter: Permission denied
May 12 17:11:45 trinity systemd[1]: node_exporter.service: Main process exited, code=exited, status=203/EXEC
May 12 17:11:45 trinity systemd[1]: node_exporter.service: Failed with result 'exit-code'.
...
```

Fixing this is easy since the binary is located in the correct directory. The `restorecon` command with the recursive flag (`-R`) will apply the parent folder's label to its children, and `/usr/local/bin` is already defined with a specific label:

```bash
sudo restorecon -R -v /usr/local/bin/
```

In this case, SELinux is in `targeted` mode rather than `MLS` mode, so `unconfined_u` is still allowed to run:

```
[gadget@trinity ~]# ls -Z /usr/local/bin/
unconfined_u:object_r:bin_t:s0 node_exporter
```

## open firewall port

If `firewalld` is enabled and running (the default), you will need to open its port to query the metrics from another host.

You can check the active `firewalld` zone with:

```
[gadget@trinity ~]$ firewall-cmd --get-active-zones
public (default)
```

Then, add the port as an exception to the zone:

```bash
sudo firewall-cmd --zone=public --add-port=9100/tcp --permanent
sudo firewall-cmd --reload
```

## start `node_exporter` and test

Enable and start `node_exporter` in one line:

```bash
sudo systemctl enable --now node_exporter
```

and from another host, query the endpoint:

```bash
curl trinity.local:9100/metrics
```

You will be greeted by a wall of metrics:

```
# HELP go_gc_duration_seconds A summary of the wall-time pause (stop-the-world) duration in garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 3.7163e-05
go_gc_duration_seconds{quantile="0.25"} 8.5233e-05
go_gc_duration_seconds{quantile="0.5"} 9.2137e-05
go_gc_duration_seconds{quantile="0.75"} 0.000103134
go_gc_duration_seconds{quantile="1"} 0.000114001
go_gc_duration_seconds_sum 0.001062938
go_gc_duration_seconds_count 12
# HELP go_gc_gogc_percent Heap size target percentage configured by the user, otherwise 100. This value is set by the GOGC environment variable, and the runtime/debug.SetGCPercent function. Sourced from /gc/gogc:percent
# TYPE go_gc_gogc_percent gauge
go_gc_gogc_percent 100
# HELP go_gc_gomemlimit_bytes Go runtime memory limit configured by the user, otherwise math.MaxInt64. This value is set by the GOMEMLIMIT environment variable, and the runtime/debug.SetMemoryLimit function. Sourced from /gc/gomemlimit:bytes
# TYPE go_gc_gomemlimit_bytes gauge
go_gc_gomemlimit_bytes 9.223372036854776e+18
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 7
...
```

---

## resources

- Prometheus Node Exporter home page:
    https://prometheus.io/docs/guides/node-exporter/
