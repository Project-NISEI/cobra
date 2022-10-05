set -e
SCRIPTS_DIR="$(dirname "$0")"

compose_db_upgrade_do() {
  docker-compose -f docker-compose.yml -f docker-compose.db-upgrade.yml $@
}

compose_db_upgrade_exec() {
  SERVICE=$1
  SCRIPT_NAME=$2
  compose_db_upgrade_do exec -T ${SERVICE} bash < ${SCRIPTS_DIR}/${SCRIPT_NAME}
}

compose_db_upgrade_exec_with_wait() {
  DB_SERVICE=$1
  SCRIPT_NAME=$2
  compose_db_upgrade_do up -d ${DB_SERVICE}
  # Need to wait because docker-compose up returns before the database finishes starting
  compose_db_upgrade_exec ${DB_SERVICE} postgresql-container-wait-for-postgres.sh
  compose_db_upgrade_exec ${DB_SERVICE} ${SCRIPT_NAME}
  compose_db_upgrade_do rm -s -f ${DB_SERVICE}
}

postgresql_upgrade() {
  compose_db_upgrade_do rm -s -f db db-old app
  compose_db_upgrade_exec_with_wait db-old postgresql-container-make-dump.sh
  compose_db_upgrade_do run --rm -T db-old bash < ${SCRIPTS_DIR}/postgresql-container-move-data.sh
  compose_db_upgrade_exec_with_wait db postgresql-container-restore-dump.sh
}

postgresql_upgrade_restore_backup() {
  compose_db_upgrade_do rm -s -f db db-old
  compose_db_upgrade_do run -T db-old bash < ${SCRIPTS_DIR}/postgresql-container-restore-backup.sh
}
