set -e
CONTAINER_SCRIPTS_DIR=$(cd $(dirname $0) && cd "in-container" && pwd)
BASE_DIR=$(cd $(dirname $0) && cd "../../" && pwd)
pushd ${BASE_DIR}

compose_db_upgrade_do() {
  docker-compose -f docker-compose.yml -f docker-compose.db-upgrade.yml $@
}

compose_db_upgrade_exec() {
  SERVICE=$1
  SCRIPT_NAME=$2
  compose_db_upgrade_do exec -T ${SERVICE} bash < ${CONTAINER_SCRIPTS_DIR}/${SCRIPT_NAME}
}

compose_db_upgrade_run() {
  SERVICE=$1
  SCRIPT_NAME=$2
  compose_db_upgrade_do run --rm -T ${SERVICE} bash < ${CONTAINER_SCRIPTS_DIR}/${SCRIPT_NAME}
}

compose_db_upgrade_exec_with_wait() {
  DB_SERVICE=$1
  DB_SCRIPT_NAME=$2
  compose_db_upgrade_do up -d ${DB_SERVICE}
  # Need to wait because docker-compose up returns before the database finishes starting
  compose_db_upgrade_exec ${DB_SERVICE} wait-for-postgres.sh
  compose_db_upgrade_exec ${DB_SERVICE} ${DB_SCRIPT_NAME}
  compose_db_upgrade_do rm -s -f ${DB_SERVICE}
}

postgresql_upgrade() {
  compose_db_upgrade_do rm -s -f db db-old app
  compose_db_upgrade_exec_with_wait db-old make-dump.sh
  compose_db_upgrade_run db-old move-data.sh
  compose_db_upgrade_exec_with_wait db restore-dump.sh
}

app_upgrade() {
  docker-compose build app
  docker-compose run --rm app rake db:migrate
  docker-compose run --rm app rake ids:update
  docker-compose run --rm app bundle exec rake assets:precompile
  docker-compose up -d
}

postgresql_upgrade_restore_backup() {
  compose_db_upgrade_do rm -s -f db db-old app
  compose_db_upgrade_run db-old restore-data.sh
}

app_and_postgresql_upgrade() {
  postgresql_upgrade
  app_upgrade
}
