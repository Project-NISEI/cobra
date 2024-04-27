#####################################################################
FROM ruby:3.2.3-alpine3.19 AS base

# Install essential Linux packages and nodejs
RUN apk -U upgrade && apk add --no-cache \
  postgresql-client tzdata nodejs gcompat \
  && rm -rf /var/cache/apk/*

# Define where our application will live inside the image
ENV RAILS_ROOT /var/www/cobra
ENV BUNDLE_ROOT /var/www/bundle


#####################################################################
FROM base as build

# Install build packages
RUN apk -U upgrade && apk add --no-cache \
  bash build-base libpq-dev ca-certificates npm \
  && rm -rf /var/cache/apk/*

# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids

# Set our working directory inside the image
WORKDIR $RAILS_ROOT

# Throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock package.json package-lock.json ./

# Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
RUN gem install bundler

# Finish establishing our Ruby environment
RUN bundle config set --local path $BUNDLE_ROOT && \
  bundle config set force_ruby_platform true && \
  bundle install --verbose
RUN npm install

COPY . $RAILS_ROOT/


#####################################################################
FROM base AS final

WORKDIR $RAILS_ROOT
RUN bundle config set --local path $BUNDLE_ROOT
COPY --from=build $RAILS_ROOT $RAILS_ROOT/
COPY --from=build $BUNDLE_ROOT $BUNDLE_ROOT/

EXPOSE 3000
RUN chmod +x ./entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

# Start the main process.
CMD ["/bin/sh", "-c", "bundle exec puma"]
