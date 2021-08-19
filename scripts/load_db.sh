#!/usr/bin/env bash

#
# Author: Ken Youens-Clark <kyclark@c-path.org>
# Purpose: Download ClinicalTrials.gov data and load into Postgres
#

#
# Make working directory
#
DATA_DIR="/usr/local/cpath/clinicaltrials.gov/data"
if [[ ! -d "$DATA_DIR" ]]; then
    echo "Missing DATA DIR \"$DATA_DIR\""
    exit 1
fi
XML_DIR="$DATA_DIR/$(date +"%F")"
[[ ! -d "$XML_DIR" ]] && mkdir -p "$XML_DIR"


#
# Remove old data and download the latest
#
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
$LOADER "$XML_DIR"
