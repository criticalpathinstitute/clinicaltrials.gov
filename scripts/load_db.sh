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
OUT_DIR="$DATA_DIR/$(date +"%F")"
[[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"

#
# Download data
#
cd "$OUT_DIR"
XML_FILE="AllPublicXML.zip"
[[ ! -f "$XML_FILE" ]] && wget https://clinicaltrials.gov/AllPublicXML.zip
[[ ! -f "Contents.txt" ]] && unzip "$XML_FILE" # Don't unzip twice

#
# Load Pg
#
LOADER="/usr/local/cpath/clinicaltrials.gov/ctloader/target/release/ctloader"
if [[ ! -f "$LOADER" ]]; then
    echo "Missing LOADER \"$LOADER\""
    exit 1
fi
$LOADER $(pwd)
