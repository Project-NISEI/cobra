#!/bin/sh
set -e

# Run as postgres user since it has permissions in the DB
chown postgres /var/backups/postgres
su - postgres

echo "Restoring dump"
psql -d postgres -f /var/backups/postgres/dump
echo "Restored"
psql --username=postgres -c "alter role cobra with password '${POSTGRES_PASSWORD}';"
echo "Restored password"
