#!/bin/sh

set -e
CONTAINER_SCRIPTS_DIR=$(cd $(dirname $0) && cd "postgres/in-container" && pwd)
BASE_DIR=$(cd $(dirname $0) && cd "../" && pwd)
pushd ${BASE_DIR}

docker-compose up -d db

docker-compose exec -T db bash < ${CONTAINER_SCRIPTS_DIR}/wait-for-postgres.sh
docker-compose exec db psql --username=postgres -c "create user cobra with password 'cobra' CREATEDB;"
docker-compose build app
docker-compose run --rm app rake db:create db:migrate
docker-compose run --rm app rake ids:update
echo "Updated IDs"
docker-compose run --rm app bundle exec rake assets:precompile
echo "Precompiled assets"
docker-compose up -d
