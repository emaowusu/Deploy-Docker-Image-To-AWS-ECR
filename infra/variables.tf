variable "region" {
  default = "us-east-1"
}

variable "ecr_repo_name" {
  default = "secret-gen-repo"
}

variable "cluster_name" {
  default = "secret-gen-cluster"
}

variable "service_name" {
  default = "secret-gen-service"
}

variable "container_port" {
  default = 3000
}
