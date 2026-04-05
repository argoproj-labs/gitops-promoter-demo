variable "project_id" {
  description = "Globally unique id for the GCP project this stack creates"
  type        = string
}

variable "project_name" {
  description = "Human-readable GCP project name"
  type        = string
}

variable "billing_account" {
  description = "OPEN billing account id (gcloud billing accounts list)"
  type        = string
}
