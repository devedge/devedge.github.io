# Create a new post, automatically slugify the title and insert the current date

set -euo pipefail

POST_TITLE="$1"

# Create the URL slug
# Convert to lowercase, turn all non-alphanumerics to dashes, and 
# convert sequential dashes to a single one.
POST_FILENAME="$(
    echo $POST_TITLE \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed --regexp-extended 's/-[-]+/-/g'
)"

POST_PATH="content/posts/${POST_FILENAME}.md"

echo "Slug: $POST_FILENAME"
echo "Path: $POST_PATH"

touch $POST_PATH
echo "+++" >> $POST_PATH
echo "title = \"$POST_TITLE\"" >> $POST_PATH
echo "date = \"$(date '+%F %H:%M:%S')\"" >> $POST_PATH
echo >> $POST_PATH
echo "[taxonomies]" >> $POST_PATH
echo "tags = [\"\"]" >> $POST_PATH
echo "+++" >> $POST_PATH
echo >> $POST_PATH
