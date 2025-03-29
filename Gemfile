# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 3.3.6'

# Gems that have trouble with native packages on alpine.
gem 'nokogiri', force_ruby_platform: true

gem 'bootstrap', '~> 4.6'
gem 'bootstrap-datepicker-rails'
gem 'coffee-rails'
gem 'execjs'
gem 'faraday', '~> 1.0'
gem 'flipper'
gem 'flipper-active_record'
gem 'font-awesome-rails'
gem 'graph_matching'
gem 'jbuilder'
gem 'jquery-rails'
gem 'js-routes'
gem 'net-http'
gem 'pg', '~> 1.3'
gem 'puma'
gem 'pundit'
gem 'rails', '~> 7'
gem 'redcarpet'
gem 'rqrcode'
gem 'sassc-rails'
gem 'scenic'
gem 'simple_form'
gem 'slim-rails'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'vite_rails'

group :development, :test do
  gem 'brakeman'
  gem 'bullet'
  gem 'pry'
  gem 'simplecov'
  gem 'simplecov-cobertura'
  gem 'simplecov-html'
end

group :test do
  gem 'bundler-audit'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'launchy'
  gem 'rspec-rails'
  gem 'vcr'
end

group :development do
  gem 'listen'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'spring'
  gem 'stackprof'
end
