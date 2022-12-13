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

## Deploy with Pulumi

The deploy directory contains scripts for deploying to DigitalOcean using Pulumi for infrastructure as code. Here are
some steps for setting that up.

1. Fork the GitHub repository.
2. Set a Pulumi access token and a DigitalOcean token in GitHub secrets, PULUMI_ACCESS_TOKEN and DIGITALOCEAN_TOKEN.
   You can get these from the Pulumi and DigitalOcean websites, see their documentation.
3. In the deploy directory, log into Pulumi CLI and create a new stack.
4. Run this in the deploy directory: `pulumi config set cobra:cobra_domain your_domain.com`. 
   Ensure you own the domain you want to use.
5. Do the same for cobra:nisei_domain. If you don't like the defaults for cobra:region and cobra:size, you can set them
   to slug values shown here: https://slugs.do-api.dev/.
6. Check in the resulting Pulumi.stackname.yaml file to Git. If you prefer not to put the domain names in that file,
   they can be encrypted by adding `--secret` to the `pulumi config set` command. If you do that, note that the domain
   names will be displayed in GitHub Actions output when the HTTPS certificate is created. You may want to delete the
   workflow runs where that happens.
7. Add an entry to trigger deploying your stack in `deploy/bin/github-actions-plan-deployment`. There's an example there
   that deploys on all pushes to a certain branch. You can make a branch for your deployed environment so you can deploy
   by pushing to that branch.
8. Add your branch to the on.push.branches in `.github/workflows/ci.yaml`. If you also put the branch in
   on.pull_request.branches, you may need to adapt `github-actions-plan-deployment` to avoid a deployment when a pull
   request is created.
9. Push to your branch in GitHub and watch the output in the Actions tab. This will fail to get an HTTPS certificate
   for the domain as there's no DNS record pointing to the droplet yet. You might avoid that if you do the next step
   before it gets to it. If not, you may want to temporarily set the staging flag in `bin/init-certbot` to avoid hitting
   the rate limit for certificate requests to production Let's Encrypt.
10. Configure your domain to point to the public IP listed in the Actions output, or configure your domain in
    DigitalOcean. The generated public IP is a DigitalOcean reserved static IP. This is free while assigned to a droplet
    but costs money if it's left unassigned. After the DNS change has propagated, you'll need to re-run the Actions job.
    If you used the staging flag then you'll need to SSH to the droplet and delete the `data/certbot directory` in the
    cobra repository, then set the flag back to use production Let's Encrypt.

You can SSH to the resulting droplet with `deploy/bin/ssh-to-droplet`. The app should already be accessible at your
domain if the Actions deploy job was successful. If you manage to configure DNS before it requests a certificate, the
whole deployment job should take about 10 minutes starting with an empty Pulumi stack.

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
