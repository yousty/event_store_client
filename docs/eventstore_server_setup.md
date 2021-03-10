## Setting up the environment on the local machine

Due to the issues with installing GRPC on some machines, we came with a dockerized environment for
anyone wanting to quickly run the working setup.

### Pre-requirements

- Docker
- ruby version 2.7.2

### Running the environment

```shell
# first time
bin/setup
```

This will:

- install the `docker-sync` and `docker-compose` gems
- run the eventstore server being accessible at localhost:2113
- run the container for the client's ruby environment

### Working with the configured project

```shell
# start network
docker-sync start && docker-compose up -d

# Login to the image shell
docker-compose exec dev bash

# play around with the testing scripts:
bin/grpc
bin/http
```
