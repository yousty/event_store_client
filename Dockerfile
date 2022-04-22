FROM ruby:3.2-rc-alpine

ENV BUNDLER_VERSION '2.1.4'

RUN apk add curl wget build-base tzdata bash shared-mime-info gcompat && \
  gem install grpc --platform ruby && \
  apk del build-base && \
  find /usr/local/bundle -name "*.o" -delete && \
  find /usr/local/bundle -name "*.c" -delete  && \
  rm -rf /usr/local/bundle/cache/*.gem

RUN gem update --system && \
  gem install bundler

WORKDIR /usr/src/app

COPY lib/event_store_client/version.rb lib/event_store_client/version.rb
COPY event_store_client.gemspec Gemfile ./

RUN apk add build-base git && \
  bundle install && \
  gem uninstall grpc --platform x86_64-linux -x -a -I && \
  gem uninstall google-protobuf --platform x86_64-linux -x -a -I && \
  apk del build-base postgresql-dev && \
  apk add postgresql

COPY . .

# Copy and install generated CA certificate
COPY ./certs/ca/ca.crt /usr/local/share/ca-certificates/eventstoredb_ca.crt
RUN chmod 644 /usr/local/share/ca-certificates/eventstoredb_ca.crt && update-ca-certificates
