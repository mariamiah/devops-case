# hello-world-service

This service greets the entire world with hellos.

## Requirements

* Docker Runtime
* Bash

## Local development

### Build

* Execute `docker build . -t hello-world-service`

### Run

* Execute `docker run -it --rm -d -p 18080:80 --name hello-world-service hello-world-service`
* Open your browser and navigate to `localhost:18080` and be greeted with a hello

### Test

* Execute `./tests.sh localhost:18080`
