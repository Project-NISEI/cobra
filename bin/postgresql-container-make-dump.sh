#!/bin/sh

# Run as postgres user since it has permissions in the DB
chown postgres /var/backups/postgres
su - postgres

echo "Deleting old dump if present"
rm -f /var/backups/postgres/dump
echo "Creating dump"
pg_dumpall > /var/backups/postgres/dump
echo "Created"
