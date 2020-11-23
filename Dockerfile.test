FROM ruby:2.7.2-alpine

RUN gem update --system && \
  gem install bundler

RUN gem list

WORKDIR /usr/src/app

COPY lib/event_store_client/version.rb lib/event_store_client/version.rb
COPY event_store_client.gemspec Gemfile Gemfile.lock ./

ARG GEM_FURY_TOKEN
RUN bundle config gem.fury.io $GEM_FURY_TOKEN

RUN bundle install

EXPOSE 3000

COPY . .
