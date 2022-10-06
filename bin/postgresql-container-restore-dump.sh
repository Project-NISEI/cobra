#!/bin/sh
set -e

echo "Restoring dump"
psql --username=postgres -d postgres -f /var/backups/postgres/dump
echo "Restored"
psql --username=postgres -c "alter role cobra with password '${POSTGRES_PASSWORD}';"
echo "Restored password"
