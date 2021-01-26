FROM ruby:2.7.2-slim

ENV BUNDLER_VERSION '2.1.4'

RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y --force-yes \
  apt-transport-https \
  build-essential \
  curl \
  g++ \
  gcc \
  git \
  libfontconfig \
  # libgconf2-4 \
  libgtk-3-dev \
  libpq-dev \
  libxt6 \
  qt5-default \
  unzip \
  wget \
  xvfb \
  && apt-get clean autoclean \
  && apt-get autoremove -y \
  && rm -rf \
    /var/lib/apt \
    /var/lib/dpkg/* \
    /var/lib/cache \
    /var/lib/log \
  && gem update --system \
  && gem install bundler -v 2.1.4

WORKDIR /usr/src/app

COPY lib/event_store_client/version.rb lib/event_store_client/version.rb
COPY event_store_client.gemspec Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

# Copy and install generated CA certificate
COPY ./certs/ca/ca.crt /usr/local/share/ca-certificates/eventstoredb_ca.crt
RUN chmod 644 /usr/local/share/ca-certificates/eventstoredb_ca.crt && update-ca-certificates
