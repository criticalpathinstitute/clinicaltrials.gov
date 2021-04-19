DB = ct

db:
	dropdb $(DB) && createdb $(DB) && psql $(DB) < create.psql
	# dropdb $(DB) && createdb $(DB) && psql $(DB) < little.psql

er:
	# sqlt-graph -f PostgreSQL -o schema.png create.psql
	eralchemy -i 'postgresql+psycopg2://kyclark:g0p3rl!@localhost:5432/ct' -o schema.png

dump:
	pg_dump ct | gzip > ct.pg.gz
