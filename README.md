# hello-world-service

This service greets the entire world with hellos.

## Table of Contents

- [Requirements](#requirements)
- [Local Development](#local-development)
    - [Build](#build)
    - [Run](#run)
    - [Test](#test)
- [Deployment](#deployment)
    - [Infrastructure](#infrastructure)
    - [CI/CD](#cicd)
- [Monitoring and Alerts](#monitoring-and-alerts)

## Requirements

- Docker Runtime
- AWS CLI (with appropriate permissions)
- Terraform (latest version)
- Bash

## Local Development

### Build

To build the Docker image:

```bash
docker build . -t hello-world-service
```

### Run

* Execute `docker run -it --rm -d -p 18080:80 --name hello-world-service hello-world-service`
* Open your browser and navigate to `localhost:18080` and be greeted with a hello

### Test

* Execute `./tests.sh localhost:18080`

## Deployment

### Infrastructure
Infrastructure setup using Terraform

* Initialize terraform

```bash
    terraform init
```
* Review planned infrastructure changes

```bash
    terraform plan
```

* Apply infrastructure changes

```bash
    terraform apply
```

### CI/CD
The CI/CD pipeline is managed via GitHub Actions. For every push or pull request to master branch, it:

- Builds the Docker image
- Executes tests
- Provisions the infrastructure using Terraform
- Deploys the application to AWS
- Validates the deployment

## Monitoring and Alerts
Monitoring is implemented using Amazon CloudWatch:

- EC2 Metrics: Monitor instance CPU.
- ALB Metrics: Observe request latencies.
- Alerts: CloudWatch Alarms notify through Amazon SNS for events like high - CPU usage or abnormal latencies.