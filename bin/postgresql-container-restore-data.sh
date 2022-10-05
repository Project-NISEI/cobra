#!/bin/sh

DATA_DIR=/var/lib/postgresql/data
BACKUP_DIR=/var/backups/postgres/data

# Run as postgres user to ensure restored data files get correct permissions
chown postgres /var/backups/postgres
su - postgres

echo "Clearing data directory"
rm -rf $DATA_DIR/*
echo "Copying PostgreSQL data from backup"
cp -r $BACKUP_DIR/* $DATA_DIR/
echo "Restored"
