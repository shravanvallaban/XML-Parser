#!/bin/sh
set -e

# Wait for PostgreSQL to start
while ! pg_isready -q -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME
do
  echo "Waiting for database connection..."
  sleep 2
done

# Create, migrate, and seed database if it doesn't exist.
if [[ -z `psql -Atqc "\\list $POSTGRES_DB"` ]]; then
  echo "Database $POSTGRES_DB does not exist. Creating..."
  mix ecto.create
  mix ecto.migrate
  mix run priv/repo/seeds.exs
  echo "Database $POSTGRES_DB created."
fi

exec "$@"