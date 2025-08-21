variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
  default     = "chipsterz"
}

variable "ssh_key_name" {
  description = "The name of the AWS EC2 key pair to use for SSH"
  type        = string
}

variable "docker_image" {
  description = "Docker image to run on the instance"
  type        = string
  default     = "chipsterz/simple-web-demo:latest"
}
