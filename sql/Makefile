DB = ct

db:
	dropdb $(DB) && createdb $(DB) && psql $(DB) < create.psql

er:
	sqlt-graph -f PostgreSQL -o schema.png create.psql

dump:
	pg_dump nord | gzip > nord.pg.gz
