#!/usr/bin/env bash

#
# Author: Ken Youens-Clark <kyclark@c-path.org>
# Purpose: Download ClinicalTrials.gov data and load into Postgres
#

#
# Make working directory, remove old data
#
DATA_DIR="/usr/local/cpath/clinicaltrials.gov/data"
[[ ! -d "$DATA_DIR" ]] && mkdir "$DATA_DIR"
rm -rf "$DATA_DIR/*"

#
# Download the latest XML
#
XML_DIR="$DATA_DIR/$(date +"%F")"
[[ ! -d "$XML_DIR" ]] && mkdir -p "$XML_DIR"
echo "Working in \"$XML_DIR\""

cd "$XML_DIR"
XML_FILE="AllPublicXML.zip"
[[ ! -f "$XML_FILE" ]] && wget https://clinicaltrials.gov/AllPublicXML.zip
[[ ! -f "Contents.txt" ]] && unzip "$XML_FILE" # Don't unzip twice

#
# Load Pg
#
LOADER_DIR="/usr/local/cpath/clinicaltrials.gov/ctloader"
LOADER="$LOADER_DIR/target/release/ctloader"
if [[ ! -f "$LOADER" ]]; then
    echo "Missing LOADER \"$LOADER\""
    exit 1
fi

cd "$LOADER_DIR" # Need .env file there
$LOADER --force "$XML_DIR"

echo "Updating tsvec field"
SQL="/usr/local/cpath/clinicaltrials.gov/lib/scripts/tsvec.sql"
HOST="postgres-prod.cnw0jywsbq0l.us-west-2.rds.amazonaws.com"
psql -h "$HOST" -U kyclark clinical_trial < "$SQL"
