locals {
  required_apis = toset([
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com"
  ])

  effective_project_id = var.create_project ? google_project.demo[0].project_id : data.google_project.existing[0].project_id
}

resource "google_project" "demo" {
  count = var.create_project ? 1 : 0

  project_id      = var.project_id
  name            = var.project_name
  billing_account = var.billing_account

  org_id    = var.org_id
  folder_id = var.folder_id
}

data "google_project" "existing" {
  count = var.create_project ? 0 : 1

  project_id = var.project_id
}

resource "google_project_service" "required" {
  for_each = local.required_apis

  project            = local.effective_project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "demo" {
  name                    = var.network_name
  project                 = local.effective_project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "demo" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  project       = local.effective_project_id
  network       = google_compute_network.demo.id

  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_cidr
  }
}

resource "google_container_cluster" "demo" {
  name       = var.cluster_name
  location   = var.region
  project    = local.effective_project_id
  network    = google_compute_network.demo.name
  subnetwork = google_compute_subnetwork.demo.name

  deletion_protection = false

  networking_mode = "VPC_NATIVE"

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  workload_identity_config {
    workload_pool = "${local.effective_project_id}.svc.id.goog"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [google_project_service.required]
}

resource "google_container_node_pool" "primary" {
  name       = "primary-pool"
  project    = local.effective_project_id
  cluster    = google_container_cluster.demo.name
  location   = var.region
  node_count = var.node_count_min

  autoscaling {
    min_node_count = var.node_count_min
    max_node_count = var.node_count_max
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "demo"
      workload    = "gitops-promoter"
    }
  }
}
