# Cobra
- [Requirements](#requirements)
- [Development Setup](#development-setup)
  - [Devcontainer with VS Code](#devcontainer-with-vs-code)
  - [Local dev with Docker Compose](#local-dev-with-docker-compose)
  - [Local Ruby installation](#local-ruby-installation)
  - [Important Commands](#important-commands)
  - [Feature flags](#feature-flags)
- [Deploy in Production](#deploy-in-production)
  - [Docker Compose](#docker-compose)
  - [Pulumi](#pulumi)

## Requirements
To deploy Cobra, you only need Docker Compose and a way of getting the repository onto your server (such as git).

For local development, you can either use Docker, and potentially Devcontainers, or you can use your own installation of
Ruby and/or PostgreSQL. The included setup can deploy these in Docker containers rather than needing to install them.
Depending on your IDE or code editor, you may prefer to install Ruby locally.

Either installed or in Docker, you will need:
- Ruby (or a Ruby version manager - e.g. rvm or rbenv), matching the version declared in [.ruby-version](.ruby-version).
- Bundler:
  ```sh
  $ gem install bundler
  ```
- PostgreSQL
- Git

## Development Setup
### Devcontainer with VS Code
The application has a Docker
[DevContainer](https://code.visualstudio.com/docs/devcontainers/containers)
setup. If you use VS Code, this is the easiest way to develop for Cobra.

To use it, first create the database.yml file:
```sh
$ cat config/database.example.app-in-docker.yml | sed s/localhost/db/ > config/database.yml
```

If you open this folder in VS Code it will prompt you to re-open in the
devcontainer. From there, your terminal will be in the container and you will have a
self-contained, full-featured development environment.

### Local dev with Docker Compose
If you want to develop with docker outside of VS Code, these instructions are
for you. This set up is preferred over local environment dev to keep
development and deployed versions consistent.

Local changes are live refreshed for both ruby and svelte aside from server-startup configuration.

1. Set up config files
   ```sh
   $ cat config/database.example.app-in-docker.yml | sed s/localhost/db/ > config/database.yml
   $ echo "POSTGRES_PASSWORD=cobra" > .env
   $ echo "RAILS_ENV=development" >> .env
   ```
2. Start the application
   ```sh
   $ docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

To interact with the application, enter the `app` shell and run your commands in there.
```sh
$ docker compose -f docker-compose.yml -f docker-compose.dev.yml exec app /bin/sh
```

### Local Ruby installation
1. Get the project
   ```sh
   $ git clone https://github.com/Project-NISEI/cobra.git
   $ cd cobra
   ```
2. Install dependencies
   ```sh
   $ bundle
   ```
3. Set up config files
   ```sh
   $ cp config/database.example.app-in-host.yml config/database.yml
   ```
4. Set up database in Docker
   ```sh
   $ echo "POSTGRES_PASSWORD=cobra" > .env
   $ echo "RAILS_ENV=development" >> .env
   $ bin/init-db-from-host
   ```

This will create a Docker container running PostgreSQL and set up the database there.
If you prefer to install PostgreSQL locally instead, you can set up the database like this:
```sh
$ psql postgres
    # create user cobra with password 'cobra' CREATEDB;
    # \q
$ rake db:create db:migrate
```

Start local server in your IDE, or with the Rails CLI (this was installed when you ran `bundle`):
```sh
$ rails server
```

### Important commands
#### Update IDs from the NRDB API
```sh
$ bundle exec rake ids:update
```
This rake task queries the NRDB API and creates/updates identities as appropriate.
Identities not in the database are stripped out of ABR uploads to avoid errors.
This is run automatically by `bin/deploy` and `bin/init-db-*`.

#### Update Card Sets from the NRDB API
```sh
$ bundle exec rake card_sets:update
```

#### Seed Tournament Metadata
Formats, tournament types, and prize kits are seeded by this task.
```sh
$ bundle exec rake tournament_metadata:seed
```

#### Run tests
```sh
$ bundle exec rspec
```

Note that you will need to override the environment if you are running this in a Docker container:
```sh
$ RAILS_ENV=test bundle exec rspec
```

### Feature flags
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

## Deploy in Production
### Docker Compose
1. Deploy NGINX
   ```sh
   $ git clone https://github.com/Project-NISEI/nginx-proxy.git nginx
   $ cd nginx
   $ docker network create --driver bridge null_signal
   $ docker compose up -d
   ```
2. Get the project
   ```sh
   $ git clone https://github.com/Project-NISEI/cobra.git
   $ cd cobra
   ```
3. Set up config files
   ```sh
   $ cp config/database.example.app-in-docker.yml config/database.yml
   $ echo "RAILS_ENV=production" > .env
   $ echo "COMPOSE_FILE_TYPE=prod" >> .env
   $ echo "POSTGRES_PASSWORD=some-good-password" >> .env
   $ echo "SECRET_KEY_BASE=random-64-bit-hex-key" >> .env
   $ echo "COBRA_DOMAIN=yourdomainhere.com" >> .env
   ```
4. Deploy
   ```sh
   $ bin/deploy
   ```

### Pulumi
The deploy directory contains scripts for deploying to DigitalOcean using Pulumi for infrastructure as code. Here are
some steps for setting that up.

1. In the deploy directory, log into Pulumi CLI and create a new stack.
2. Choose the region you'll deploy to, and size of droplet you want to deploy here: https://slugs.do-api.dev/.
3. Set these for Pulumi like `pulumi config set cobra:region lon1` and `pulumi config set cobra:size s-1vcpu-1gb`.

You can deploy a droplet directly with `pulumi up` if you're logged into Pulumi and DigitalOcean, but this will not
deploy Cobra. You can follow the instructions above for manual deployment on the droplet, or use the automated
deployment below.

You can SSH to the resulting droplet with `deploy/bin/ssh-to-droplet`. If you have an SSH key you'd like to use to log
in, you can create a non-root user on the droplet with `deploy/bin/create-user-with-key`.

If you'd prefer to manage the resulting droplet manually and just use this as a way to create a droplet, you can discard
the resulting Pulumi stack. It may be easier to hold state locally for this, rather than creating a stack in Pulumi
cloud. Refer to Pulumi documentation to log into the CLI in local-only mode.

#### GitHub Actions deployment
There's a GitHub Actions workflow that handles deployment with Pulumi, and also deployment of Cobra inside the droplet.
This needs the configuration for Cobra stored in Pulumi, alongside details of the droplet. You'll also need to connect
your GitHub to Pulumi and DigitalOcean. With a Pulumi stack set up as above, follow the following steps:

1. Tell Pulumi we want it to configure Cobra with `pulumi config set cobra:configure_cobra true`.
2. Set the domain you want to use in Pulumi, with `pulumi config set cobra:cobra_domain your_domain.com`.
   Ensure you own the domain you want to use.
3. If you have NetrunnerDB client credentials, encrypt them with these commands:
   ```sh
   $ pulumi config set cobra:nrdb_client --secret
   $ pulumi config set cobra:nrdb_secret --secret
   ```
   If you don't have client credentials, you can still deploy but you won't be able to log into Cobra.
4. Set a Pulumi access token and a DigitalOcean token in GitHub repository secrets, PULUMI_ACCESS_TOKEN and
   DIGITALOCEAN_TOKEN. You can get these from the Pulumi and DigitalOcean websites, see their documentation.
5. On your own fork of the GitHub repository, create a branch  named `deploy/stackname` matching the name of your stack.
6. Commit the resulting `Pulumi.stackname.yaml` file to the branch. Push this to your fork on GitHub and watch the
   output in the Actions tab.

The whole deployment job should take about 10 minutes starting with an empty Pulumi stack. If the Actions deploy job was
successful, you can point your DNS to the new droplet, or assign it a reserved IP that your domain already points to.
You can SSH to the resulting droplet with `deploy/bin/ssh-to-droplet`.
