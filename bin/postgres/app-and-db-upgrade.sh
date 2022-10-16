#!/bin/sh

source "$(dirname "$0")/postgresql-upgrade-fns.sh"
app_and_postgresql_upgrade
