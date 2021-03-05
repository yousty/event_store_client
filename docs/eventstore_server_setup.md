## Setting up the environment on the local machine

Due to the issues with installing GRPC on some machines, we came with a dockerized environment for
anyone wanting to quickly run the working setup.

### Pre-requirements

- Docker
- ruby version 2.7.2

# Docker


```shell
bin/setup
```

This will:

- install the `docker-sync` and `docker-compose` gems
- run the eventstore server being accessible at localhost:2113
- run the container for the client's ruby environment
