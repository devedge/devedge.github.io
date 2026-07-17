#!/bin/bash
set -euo pipefail

# Replace draft date with the current one
sed -i "s/2999-99-99 00:00:00/$(date '+%F %H:%M:%S')/" $1
