#!/bin/bash
# Fail on any non-zero exit status, uninitialized variables, or errors in pipelines
set -euo pipefail

# Create a new post and automatically slugify the Markdown file

# The post title is passed as the first argument, in quotes
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

# Print the generated slug and its path
# TODO: Some way to create an assets directory with the same name
echo "Slug: $POST_FILENAME"
echo "Path: $POST_PATH"


# Create the post and insert the header. The date can be updated using "update-post-date.sh"
echo "+++
title = \"$POST_TITLE\"
date = \"9999-01-01 00:00:00\"

[taxonomies]
tags = [\"DRAFT\"]
+++

" >> $POST_PATH
