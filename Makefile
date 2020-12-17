# 1. Download all the data
data:
	wget https://clinicaltrials.gov/AllPublicXML.zip

# 2. Convert original XML to JSON for Mongo, add search text
json:
	./scripts/xml2json.py -d xml -o json

# 3. Import JSON into Mongo
mongo:
	./scripts/mongoimport.sh
