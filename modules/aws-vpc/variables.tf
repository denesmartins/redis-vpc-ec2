// VPC config

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

//REDIS config

variable "replication_group_id" {
}

variable "replication_group_description" {
  default = "Managed by terraform"
}

variable "port" {
  default = 6379
}

variable "node_type" {
  default = "cache.t2.micro"
}

variable "num_node_groups" {
  default = 1
}

variable "replicas_per_node_group" {
  default = 1
}

# variable "subnet_ids" {
#   type = list(string)
# }

# variable "vpc_id" {
# }

variable "snapshot_retention_limit" {
  default = 0
}

variable "parameter_group_name" {
}

variable "cidr_blocks" {
  type = list(string)
}

variable "engine_version" {
}

variable "app_name" {
}

variable "environment" {
}

variable "maintenance_window" {
}

variable "transit_encryption_enabled" {
  type        = bool
  description = "Enable use of TLS connection in redis-cluster"
  default     = false
}

variable "at_rest_encryption_enabled" {
  type        = bool
  description = "Whether to enable encryption at rest"
  default     = false
}

#Tags
variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "cluster_mode_enabled" {
  type    = bool
  default = true
}

variable "automatic_failover_enabled" {
  default = true
  type    = bool
}