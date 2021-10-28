DB = clinical_trial
HOST = postgres-prod.cnw0jywsbq0l.us-west-2.rds.amazonaws.com

dump:
	pg_dump --schema-only -f pg_schema.sql -h $(HOST) -U kyclark $(DB)

er:
	# sqlt-graph -f PostgreSQL -o schema.png create.psql
	eralchemy -i 'postgresql+psycopg2://kyclark:g0p3rl!@localhost:5432/ct' -o schema.png
