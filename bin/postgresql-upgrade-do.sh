#!/bin/sh

source "$(dirname "$0")/postgresql-upgrade-fns.sh"
compose_db_upgrade_do $@
