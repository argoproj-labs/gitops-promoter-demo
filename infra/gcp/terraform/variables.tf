variable "create_project" {
  description = "Whether Terraform should create the GCP project. Set false to use an existing project_id."
  type        = bool
  default     = true
}

variable "project_id" {
  description = "Unique GCP project ID"
  type        = string
}

variable "project_name" {
  description = "GCP project display name"
  type        = string
}

variable "billing_account" {
  description = "Billing account ID in the form 000000-000000-000000"
  type        = string
}

variable "org_id" {
  description = "Optional organization ID if you want to place the project under an org"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Optional folder ID if you want to place the project under a folder"
  type        = string
  default     = null
}

variable "region" {
  description = "Regional location for GKE"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "gitops-promoter-demo"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "gitops-promoter-vpc"
}

variable "subnet_cidr" {
  description = "Subnet CIDR for GKE nodes"
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_secondary_range_name" {
  description = "Secondary range name for pod CIDRs"
  type        = string
  default     = "pods"
}

variable "pods_secondary_cidr" {
  description = "Secondary CIDR range for pods"
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_secondary_range_name" {
  description = "Secondary range name for service CIDRs"
  type        = string
  default     = "services"
}

variable "services_secondary_cidr" {
  description = "Secondary CIDR range for services"
  type        = string
  default     = "10.30.0.0/20"
}

variable "node_machine_type" {
  description = "Machine type for demo node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "node_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "node_count_min" {
  description = "Autoscaling minimum node count"
  type        = number
  default     = 3
}

variable "node_count_max" {
  description = "Autoscaling maximum node count"
  type        = number
  default     = 6
}
