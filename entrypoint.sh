#!/bin/sh
set -e

# Wait for database to be ready
while ! pg_isready -q -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME
do
  echo "Waiting for database connection..."
  sleep 2
done

# Run migrations
mix ecto.migrate

# Start the Phoenix app in the background
mix phx.server &

# Change to the assets directory
cd assets

# Start the React development server
npm start