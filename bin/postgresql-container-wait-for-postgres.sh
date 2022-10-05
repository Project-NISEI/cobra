#!/bin/sh

RETRIES=10

# Need to wait because docker-compose up returns before the database finishes starting
psql -c "select 1"
until psql -c "select 1" > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  sleep 5
done
echo "Found postgres server"
