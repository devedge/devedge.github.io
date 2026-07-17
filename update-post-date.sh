#!/bin/bash
set -euo pipefail

# Replace draft date with the current one
sed -i "s/9999-01-01 00:00:00/$(date '+%F %H:%M:%S')/" $1
