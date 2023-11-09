variable "availability_zones" {
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "route53_zone_id" {
  type        = string
  description = "The ID of the Route53 zone to create records in"
  default     = "Z079980139JAGEVY4FHE7"
}

variable "cluster_control_join_token" {
  type        = string
  description = "The token to join a control node to the cluster"
  default     = ""
}

variable "cluster_worker_join_token" {
  type        = string
  description = "The token to join a worker node to the cluster"
  default     = ""
}
