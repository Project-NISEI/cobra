#!/bin/sh

source "$(dirname "$0")/postgresql-upgrade-fns.sh"
postgresql_upgrade_do $@
