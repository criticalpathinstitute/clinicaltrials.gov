#!/usr/bin/env bash

set -u

DB="ct"
COLL="ct"

echo "Dropping collection \"${COLL}\""
TMP=$(mktemp)
echo "db.${COLL}.drop()" > "$TMP"
mongo "$DB" --quiet < "$TMP"

echo "Creating jobs"
JOBS=$(mktemp)
i=0
for FILE in json/*; do
    # i=$((i+1))
    # printf "%6d: %s\r" $i $FILE
    echo "mongoimport --quiet -d $DB -c $COLL $FILE" >> "$JOBS"
done

echo ""
echo "Importing \"$JOBS\"..."
parallel -j 8 --halt soon,fail=1 < "$JOBS"
rm "$JOBS"

echo "Creating index..."
# echo "db.${COLL}.createIndex({text: 'text', detailed_description: 'text'})" > "$TMP"
echo "db.${COLL}.createIndex({text: 'text'})" > "$TMP"
mongo "$DB" --quiet < "$TMP"
rm "$TMP"

echo "Done!"
