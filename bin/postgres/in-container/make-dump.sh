#!/bin/sh
set -e

# Run as postgres user since it has permissions in the DB
chown postgres /var/backups/postgres

echo "Deleting old dump if present"
su - postgres -c "rm -f /var/backups/postgres/dump"
echo "Creating dump"
su - postgres -c "pg_dumpall > /var/backups/postgres/dump"
echo "Created"
