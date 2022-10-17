#!/bin/sh
set -e

DATA_DIR=/var/lib/postgresql/data
BACKUP_DIR=/var/backups/postgres/data

echo "Clearing data directory"
su - postgres -c "rm -rf $DATA_DIR/*"
echo "Copying PostgreSQL data from backup"
su - postgres -c "cp -r $BACKUP_DIR/* $DATA_DIR/"
echo "Restored"
