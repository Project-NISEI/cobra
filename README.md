# Cobra

## For local dev with docker

- Set up config files
```shell
cat config/database.example.yml | sed s/localhost/db/ > config/database.yml
cp config/secrets.example.yml config/secrets.yml
echo "POSTGRES_PASSWORD=cobra" > .env
echo "RAILS_ENV=development" >> .env
```

Then initialize everything and bring up the server.

```shell
bin/deploy
```

To run tests in your docker container, you will need to override the environment, like so:
```shell
docker compose exec -e RAILS_ENV=test app rspec
```

## Requirements
To deploy Cobra, you only need Docker Compose and a way of getting the repository onto your server (such as git).

For local development, you will need:
- Ruby 2.4.2 (or a Ruby version manager - e.g. rvm or rbenv - with access to 2.4.2)
- Bundler
```
$ gem install bundler
```
- Postgres
- Git

## Set up for local development
- Get the project
```
$ git clone https://github.com/muyjohno/cobra.git
$ cd cobra
```
- Install dependencies
```
$ bundle
```
- Set up config files
```
$ cp config/database.example.yml config/database.yml
$ cp config/secrets.example.yml config/secrets.yml
```
- Set up database
```
$ psql postgres
    # create user cobra with password 'cobra' CREATEDB;
    # \q
$ rake db:create db:migrate
```

If you prefer to use PostgreSQL in Docker instead of a local installation,
you can set that up like this:

```
$ echo "POSTGRES_PASSWORD=cobra" > .env
$ echo "RAILS_ENV=development" >> .env
$ bin/init-db
```

- Start local server
```
$ rails server
```

## Run tests
```
$ rspec
```

## Identities
Identities are stored in the database and can be seeded/updated by running a rake task:
```
$ rake ids:update
```
This rake task queries the NRDB API and creates/updates identities as appropriate.
Identities not in the database are stripped out of ABR uploads to avoid errors.

## Deploy as a web server
- Get the project
```shell
git clone https://github.com/muyjohno/cobra.git
cd cobra
```
- Set up config files
```shell
cp config/database.example.yml config/database.yml
cp config/secrets.example.yml config/secrets.yml
echo "RAILS_ENV=production" > .env
echo "COMPOSE_FILE=prod" >> .env
echo "POSTGRES_PASSWORD=some-good-password" >> .env
echo "SECRET_KEY_BASE=random-64-bit-hex-key" >> .env
echo "COBRA_DOMAIN=cobr.ai" >> .env
echo "NISEI_DOMAIN=tournaments.nisei.net" >> .env
```
- Deploy
```shell
bin/deploy
```

## :bug: Troubleshooting

### Rails doesn't start
The rails app may not start after running `docker compose up`. You might see logs like:

```
Starting cobra_db_1 ... done
Starting cobra_app_1 ... done
Attaching to cobra_db_1, cobra_app_1
db_1   | LOG:  database system was interrupted; last known up at 2022-01-30 22:12:19 UTC
db_1   | LOG:  database system was not properly shut down; automatic recovery in progress
db_1   | LOG:  record with zero length at 0/19D93F8
db_1   | LOG:  redo is not required
db_1   | LOG:  MultiXact member wraparound protections are now enabled
db_1   | LOG:  database system is ready to accept connections
db_1   | LOG:  autovacuum launcher started
cobra_app_1 exited with code 1
```

In this case, one of your rails dependencies, `unicorn`, is corrupted from an ungraceful shutdown.
To remedy this you'll need to delete the unicorn `pid` file. Simply run this command:

```
docker run -v cobra_cobra-tmp:/cobra/tmp ubuntu rm /cobra/tmp/pids/unicorn.pid
```

Then you should be able to start up the app again with `docker compose up` as normal.
