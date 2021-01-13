# Critical Path Search Interface for ClinicalTrials.gov Data

This is a mirror of the ClinicalTrials.gov database running at http://ct.c-path.org.

## Code

All the code for this project can be found at:

https://github.com/criticalpathinstitute/clinicaltrials.gov

## Database

I have not yet settled on a single database as I've been using both MongoDB and Postgres.
Here is the state of the relational schema in Postgres:

![schema](/sql/schema.png)

## Data

All the data was obtained from https://clinicaltrials.gov/ct2/resources/download.
Specifically, I downloaded 359,682 XML documents in https://clinicaltrials.gov/AllPublicXML.zip.
I verified each document using https://clinicaltrials.gov/ct2/html/images/info/public.xsd and found XXX were invalid.

As my first instinct was to load this data as-is into Mongo, I first wrote [scripts/xml2json.py] to convert the XML to JSON.
Later I decided to load this data into Postgres, and so [scripts/load_pg.py] uses the JSON files.
If I decide to remove Mongo completely, I'll likely streamline this process.

## Web Interface

The web interface at http://ct.c-path.org/ is comprised of two parts:

1. A back-end API written with Python's [web/fastapi](FastAPI)
2. A front-end UI written in [web/elm](Elm)

## Author

Ken Youens-Clark <kyclark@c-path.org>
