# Cobra

## Requirements
To deploy Cobra, you only need Docker Compose and a way of getting the repository onto your server (such as git).

For local development, you will need:
- Ruby 2.4.2 (or a Ruby version manager - e.g. rvm or rbenv - with access to 2.4.2)
- Bundler
```
$ gem install bundler
```
- Postgres (installed or in Docker)
- Git

## Set up for local development
- Get the project
```
$ git clone https://github.com/Project-NISEI/cobra.git
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

## Feature flags

[Flipper](https://github.com/jnunemaker/flipper) is included to give the option to hide or disable features which are
incomplete. This lets you make changes in smaller increments, while still being able to deploy to a production
environment with your feature hidden.

You can enable or disable a feature for all development environments by editing
[development.rb](config/environments/development.rb).

That file can include code similar to the following, which will enable the feature when the app starts up. The rescue
block handles cases where the database is not fully initialized, eg. in a rake task.

```ruby
Rails.application.configure do

   # There should be other configuration here...

   config.after_initialize do
      begin
         Flipper.enable :nrdb_deck_registration
      rescue => e
         Rails.logger.warn "Failed setting Flipper features: #{e.class}"
      end
   end
end
```

## For local dev with Docker

- Set up config files
```shell
cat config/database.example.yml | sed s/localhost/db/ > config/database.yml
cp config/secrets.example.yml config/secrets.yml
echo "POSTGRES_PASSWORD=cobra" > .env
echo "RAILS_ENV=development" >> .env
```

- Deploy the app

```shell
bin/deploy
```

This will build the Docker image, run rake tasks to initialise or migrate the database, update Netrunner identities,
precompile assets, and bring up the app in Docker.

To run tests in your docker container, you will need to override the environment, like so:
```shell
docker compose exec -e RAILS_ENV=test app rspec
```

## Deploy in production with Docker Compose
- Deploy NGINX
```shell
git clone https://github.com/Project-NISEI/nginx-proxy.git nginx
cd nginx
docker network create --driver bridge null_signal
docker compose up -d
```
- Get the project
```shell
git clone https://github.com/Project-NISEI/cobra.git
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
echo "COBRA_DOMAIN=yourdomainhere.com" >> .env
```
- Deploy
```shell
bin/deploy
```

## Deploy with Pulumi

The deploy directory contains scripts for deploying to DigitalOcean using Pulumi for infrastructure as code. Here are
some steps for setting that up.

1. Fork the GitHub repository.
2. In the deploy directory, log into Pulumi CLI and create a new stack.
3. Choose the region you'll deploy to, and size of droplet you want to deploy.
4. Find the slug values for these here: https://slugs.do-api.dev/.
5. Set these for Pulumi like `pulumi config set cobra:region lon1` and `pulumi config set cobra:size s-1vcpu-1gb`.

You can deploy a droplet directly with `pulumi up` if you're logged into Pulumi and DigitalOcean, but this will not
deploy Cobra. There's a GitHub Actions workflow that handles deployment with Pulumi, and also deployment of Cobra inside
the droplet. This needs the configuration for Cobra stored in Pulumi, alongside details of the droplet. You'll also need
to connect your GitHub repository to Pulumi and DigitalOcean. Follow the following steps:

1. Tell Pulumi we want it to configure Cobra with `pulumi config set cobra:configure_cobra true`.
2. Set the domain you want to use in Pulumi, with `pulumi config set cobra:cobra_domain your_domain.com`.
   Ensure you own the domain you want to use.
3. If you have NetrunnerDB client credentials, encrypt them with these commands:
   ```shell
   pulumi config set cobra:nrdb_client --secret
   pulumi config set cobra:nrdb_secret --secret
   ```
   If you don't have client credentials, you can still deploy but you won't be able to log into Cobra.
4. Set a Pulumi access token and a DigitalOcean token in GitHub repository secrets, PULUMI_ACCESS_TOKEN and 
   DIGITALOCEAN_TOKEN. You can get these from the Pulumi and DigitalOcean websites, see their documentation.
5. Check in the resulting Pulumi.stackname.yaml file to Git, on a branch named `deploy/stackname` matching the name of
   your Pulumi stack.
6. Push your branch to your fork on GitHub and watch the output in the Actions tab.

You can SSH to the resulting droplet with `deploy/bin/ssh-to-droplet`. If the Actions deploy job was successful, you can
point your DNS to the new droplet, or assign it a reserved IP that your domain already points to. The whole deployment
job should take about 10 minutes starting with an empty Pulumi stack.

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
