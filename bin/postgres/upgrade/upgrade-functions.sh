set -e
BASE_DIR_IN_CONTAINER="/var/www/cobra"
CONTAINER_SCRIPTS_DIR="$BASE_DIR_IN_CONTAINER/bin/postgres/in-container"
BASE_DIR=$(cd "$(dirname "$0")" && cd "../../../" && pwd)
pushd "${BASE_DIR}"

compose_for_upgrade() {
  docker compose -f docker-compose.yml -f docker-compose.db-upgrade.yml "$@"
}

compose_for_upgrade_exec() {
  SERVICE=$1
  SCRIPT_NAME=$2
  compose_for_upgrade exec -it "${SERVICE}" "bash ${CONTAINER_SCRIPTS_DIR}/${SCRIPT_NAME}"
}

compose_for_upgrade_run() {
  SERVICE=$1
  SCRIPT_NAME=$2
  compose_for_upgrade run --rm "${SERVICE}" "bash ${CONTAINER_SCRIPTS_DIR}/${SCRIPT_NAME}"
}

compose_for_upgrade_exec_with_wait_for_db() {
  DB_SERVICE=$1
  DB_SCRIPT_NAME=$2
  compose_for_upgrade up -d "${DB_SERVICE}"
  # Need to wait because docker-compose up returns before the database finishes starting
  compose_for_upgrade_exec "${DB_SERVICE}" wait-for-postgres.sh
  compose_for_upgrade_exec "${DB_SERVICE}" "${DB_SCRIPT_NAME}"
  compose_for_upgrade rm -s -f "${DB_SERVICE}"
}

upgrade_db() {
  compose_for_upgrade rm -s -f db db-old app
  compose_for_upgrade_exec_with_wait_for_db db-old make-dump.sh
  compose_for_upgrade_run db-old move-data.sh
  compose_for_upgrade_exec_with_wait_for_db db restore-dump.sh
}

upgrade_app() {
  docker-compose build app
  docker-compose run --rm app rake db:migrate
  docker-compose run --rm app rake ids:update
  docker-compose run --rm app bundle exec rake assets:precompile
  docker-compose up -d
}

restore_db_backup() {
  compose_for_upgrade rm -s -f db db-old app
  compose_for_upgrade_run db-old restore-data.sh
}

upgrade_db_and_app() {
  upgrade_db
  upgrade_app
}
