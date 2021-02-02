#!/usr/bin/env bash

JOBS=$(mktemp)
PRG="./scripts/load_pg_one.py"

for FILE in json/*; do
    echo "$PRG $FILE" >> "$JOBS"
done

NUM=$(wc -l $JOBS | awk '{print $1}')
echo "Launching $NUM jobs"
parallel -j 8 --halt soon,fail=1 < "$JOBS"
echo "Done"
