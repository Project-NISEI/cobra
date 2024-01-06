# Base our image on an official, minimal image of our preferred Ruby
FROM ruby:3.2.2-alpine3.19 AS build

# Install essential Linux packages and nodejs
RUN apk -U upgrade && apk add --no-cache \
  bash build-base libpq-dev postgresql-client ca-certificates tzdata nodejs npm \
  && rm -rf /var/cache/apk/*

# Define where our application will live inside the image
ENV RAILS_ROOT /var/www/cobra

# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids

# Set our working directory inside the image
WORKDIR $RAILS_ROOT

# Use the Gemfiles as Docker cache markers. Always bundle before copying app src.
# (the src likely changed and we don't want to invalidate Docker's cache too early)
# http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/
COPY Gemfile Gemfile.lock package.json package-lock.json ./

# Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
RUN gem install bundler

# Finish establishing our Ruby enviornment
RUN bundle install
RUN npm install

# Define the script we want run once the container boots
# Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
CMD [ "config/containers/app_cmd.sh" ]
