#!/bin/sh

RETRIES=10

# Run as postgres user since it has permissions in the DB
chown postgres /var/backups/postgres
su - postgres

# Need to wait because docker-compose up returns before the database finishes starting
until psql -c "select 1" > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  sleep 5
done
echo "Found postgres server"

psql -d postgres -f /var/backups/postgres/dump
