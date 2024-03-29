SCHEMA = ./scripts/public.xsd
DB = clinical_trial
DBUSER = kyclark
DBPASS = mHo%90^NOMgT
DBHOST = postgres-prod.cnw0jywsbq0l.us-west-2.rds.amazonaws.com
DBPORT = 5432

reqs:
	python3 -m pip install -r scripts/requirements.txt

orm:
	pwiz.py --host $(DBHOST) --port $(DBPORT) --user $(DBUSER) --password $(DB) > scripts/ct.py

dump:
	pg_dump $(DB) > dumps/$(DB).sql
	mongoexport --out dumps/ct_mongo.json --db $(DB) --collection ct
	zip -r ~/Downloads/ct.zip dumps

# 1. Download all the data
data:
	wget https://clinicaltrials.gov/AllPublicXML.zip

# 2. Convert original XML to JSON for Mongo, add search text
one:
	./scripts/xml2json.py -s $(SCHEMA) -f xml/NCT0145xxxx/NCT01452867.xml -o json

some:
	./scripts/xml2json.py -s $(SCHEMA) -d xml/NCT014* -o json

alljson:
	./scripts/xml2json.py -s $(SCHEMA) -d xml -o json

# 3. Import JSON into Mongo
mongo:
	./scripts/mongoimport.sh

pgload:
	./scripts/load_pg.py -d json -p loaded.txt
