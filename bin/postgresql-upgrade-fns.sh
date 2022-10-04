SCRIPTS_DIR="$(dirname "$0")"

compose_db_upgrade() {
  docker-compose -f docker-compose.yml -f docker-compose.db-upgrade.yml $@
}

postgresql_upgrade() {
  compose_db_upgrade rm -s -f db db-old
  compose_db_upgrade up -d db-old
  compose_db_upgrade exec -T db-old bash < ${SCRIPTS_DIR}/postgresql-container-make-dump.sh
  compose_db_upgrade rm -s -f db-old
  compose_db_upgrade run --rm -T db-old bash < ${SCRIPTS_DIR}/postgresql-container-move-data.sh
  compose_db_upgrade up -d db
  compose_db_upgrade exec -T db bash < ${SCRIPTS_DIR}/postgresql-container-restore-dump.sh
}

postgresql_upgrade_do() {
  compose_db_upgrade $@
}
