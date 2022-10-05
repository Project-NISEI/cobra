#!/bin/sh

DATA_DIR=/var/lib/postgresql/data
BACKUP_DIR=/var/backups/postgres/data

echo "Deleting old data backup if present"
rm -rf $BACKUP_DIR
mkdir $BACKUP_DIR
echo "Moving PostgreSQL data directory to backups"
mv $DATA_DIR/* $BACKUP_DIR/
echo "Cleared & backed up"
