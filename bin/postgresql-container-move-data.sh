#!/bin/sh

DATA_DIR=/var/lib/postgresql/data
BACKUP_DIR=/var/backups/postgres/data

rm -rf $BACKUP_DIR
mkdir $BACKUP_DIR
mv $DATA_DIR/* $BACKUP_DIR/
