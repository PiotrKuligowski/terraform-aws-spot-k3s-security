variable "component" {
  description = "Component name, will be used to generate names for created resources"
  type        = string
  default     = ""
}

variable "project" {
  description = "Project name, will be used to generate names for created resources"
  type        = string
  default     = "k3s"
}

variable "tags" {
  description = "Tags to attach to resources"
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where security groups should be created"
  type        = string
}

variable "whitelisted_ips" {
  description = "IPs to whitelist to NLB instance"
  type        = list(string)
  default     = []
}