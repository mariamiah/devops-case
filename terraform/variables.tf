# variables.tf
variable "region" {
  description = "AWS region for the deployment."
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2."
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance."
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in ASG."
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in ASG."
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG."
  type        = number
}

variable "subnets" {
  description = "List of subnets for the ASG and ALB."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed."
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy"
  type        = string
}