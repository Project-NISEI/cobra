#!/bin/sh

RESTORE_FILE=$1

# Make a database backup created by backup.sh

gunzip "$RESTORE_FILE" -c | docker exec -i cobra-db-1 psql -U postgres
