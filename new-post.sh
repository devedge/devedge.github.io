#!/bin/bash
# Fail on any non-zero exit status, uninitialized variables, or errors in pipelines
set -euo pipefail

# Create a new post and automatically slugify the Markdown file
POST_TITLE="$1"

# Create the URL slug:
# - convert to lowercase
# - turn all non-alphanumerics to dashes
# - convert sequential dashes to a single one
# - strip dashes from the start and end
POST_FILENAME="$(
    echo "${POST_TITLE}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed --regexp-extended 's/-[-]+/-/g' \
    | sed --regexp-extended 's/^-|-$//g'
)"

POST_PATH="content/posts/${POST_FILENAME}.md"

echo "Slug: $POST_FILENAME"
echo "Path: $POST_PATH"

echo "
+++
title = \"$POST_TITLE\"
date = \"2999-99-99 00:00:00\"

[taxonomies]
tags = [\"DRAFT\"]
+++

" >> $POST_PATH
