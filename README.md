# Micro-serv - mock of microservice

A tiny golang application simulating a microservice. It

- listens for inbound connections
- connects to other named microservices specified on the command line
- sends messages containing a sequence number
- logs sent and received messages
- attempts to reconnect on failure

## Build

### Using Go natively

```bash
make micro-serv
```

## Usage

```bash
Usage of ./micro-serv:
  -a string
        listening address
  -i duration
        message sending interval (default 2s)
  -l    listen
  -r duration
        connection retry interval (default 1s)
  -t duration
        connect/send/recv timeout (default 5s)
```

## Example

The following example will start micro-serv in listen mode, and attempt to connect to a different instance of micro-serv, on host "test-host".

```bash
./micro-serv -l test-host
```

## Micro Sock on Docker Compose and Weave Cloud

Micro Sock is a small application that simulates a microservice. It listens for connections and initiates connection to other services specified as a parameter on the command line, and exchanges messages with those services. It is ideal for building a quick topology of services that talk to each other. 

The instructions on this page will allow you to get started with a Docker Compose setup that uses multiple micro-serv containers to build a topology that resembles the other Sock Shop deployments. The advantage is that that the required download is only 5 MB and the whole setup starts very fast.

### Pre-requisites

- Install [Docker](https://www.docker.com/products/overview)
- Install [Docker Compose](https://docs.docker.com/compose/install/)
- Install [Weave Scope](https://www.weave.works/install-weave-scope/)

```
git clone https://github.com/microservices-demo/microservices-demo
cd microservices-demo
```
<!-- deploy-doc-hidden pre-install

    curl -sSL https://get.docker.com/ | sh
    apt-get install -yq python-pip build-essential python-dev
    pip install docker-compose

-->

### Launch Weave Scope

Get a token by [registering on Weave Cloud](http://cloud.weave.works/). Once you have the token you can download and start the Scope instance.

    sudo curl -L git.io/scope -o /usr/local/bin/scope
    sudo chmod a+x /usr/local/bin/scope
    scope launch --service-token=<token>

### Prepare docker-compose.yaml configuration file
minimal compose for a simulation of https://github.com/weaveworks/weaveDemo: 
```bash
version: '2'

services:
  load_balancer:
    image: euknyaz/micro-serv
    container_name: load_balancer
    command: frontend
    ports:
      - '80:80'
      - '8080:8080'
    networks:
      - frontend
  frontend:
    image: euknyaz/micro-serv
    command: -l backend
    networks:
      - frontend
      - backend
  backend:
    image: euknyaz/micro-serv
    command: -l mongo_db redis_cache rabbitmq_queue
    networks:
      - backend
      - storage
  mongo_db:
    image: euknyaz/micro-serv
    container_name: mongo_db 
    command: -l
    networks:
      - storage
  redis_cache:
    image: euknyaz/micro-serv
    container_name: redis_cache
    command: -l
    networks:
      - storage
  rabbitmq_queue:
    image: euknyaz/micro-serv
    container_name: rabbitmq_queue
    command: -l processor_worker
    networks:
      - storage
      - processor
  processor_worker:
    image: euknyaz/micro-serv
    command: -l data-db
    networks:
      - processor
      - storage
networks:
  frontend:
  backend:
  processor:
  storage:
```

### Provision infrastructure

<!-- deploy-doc-start create-infrastructure -->

    docker-compose -f docker-compose.yaml up -d

<!-- deploy-doc-end -->

### Scale infrastructure
<!-- deploy-doc-start scale-infrastructure -->

    docker-compose -f docker-compose.yaml scale frontend=2 backend=2 processor_worker=3

<!-- deploy-doc-end -->

### Check Weave Cloud

Once you started the application using Docker Compose, you can visit [Weave Cloud](http://cloud.weave.works/) to see how the containers are connected to each other. You should be seeing something like this:

![Micro Sock in Scope](https://github.com/euknyaz/micro-serv/blob/master/assets/micro-serv-scope.png?raw=true)

### Cleaning up

<!-- deploy-doc-start destroy-infrastructure -->

    docker-compose -f docker-compose.yaml down

<!-- deploy-doc-end -->
