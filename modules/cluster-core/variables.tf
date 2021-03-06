variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in."
}

variable "region" {
  type        = string
  description = "The region to host the cluster in."
}

variable "zones" {
  type        = list(string)
  description = "The zones to host the cluster in. Single entry means it's zonal cluster. Multiple entries for regional clusters."
}

variable "name" {
  type        = string
  description = "The name of the cluster."

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*$", var.name))
    error_message = "The cluster name should only contain A-Z, a-z, 0-9 and '-' character. Cannot start with '-'."
  }
}

variable "machine_type" {
  type        = string
  description = "Type of the node compute engines."
}

variable "min_count" {
  type        = number
  description = "Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count."
}

variable "max_count" {
  type        = number
  description = "Maximum number of nodes in the NodePool. Must be >= min_node_count."
}

variable "disk_size_gb" {
  type        = number
  description = "Size of the node's disk."
}

variable "initial_node_count" {
  type        = number
  description = "The number of nodes to create in this cluster's default node pool."
}
