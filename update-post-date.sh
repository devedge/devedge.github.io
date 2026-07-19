#!/bin/bash
set -euo pipefail

# Replace draft date with the current one
sed --in-place "s/^\(date = \"\)9999-01-01 00:00:00/\1$(date '+%F %H:%M:%S')/" $1
