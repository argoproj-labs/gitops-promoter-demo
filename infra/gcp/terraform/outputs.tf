output "project_id" {
  description = "Target GCP project ID"
  value       = local.effective_project_id
}

output "cluster_name" {
  description = "Regional GKE cluster name"
  value       = google_container_cluster.demo.name
}

output "cluster_region" {
  description = "GKE cluster region"
  value       = google_container_cluster.demo.location
}

output "vpc_network" {
  description = "VPC network name"
  value       = google_compute_network.demo.name
}

output "gke_workload_identity_pool" {
  description = "Workload Identity pool for this cluster"
  value       = "${local.effective_project_id}.svc.id.goog"
}
