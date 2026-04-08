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

  region       = "us-central1"
  cluster_name = "gitops-promoter-demo"

  network_name = "gitops-promoter-vpc"
  subnet_cidr  = "10.10.0.0/20"

  pods_range_name    = "pods"
  pods_cidr          = "10.20.0.0/16"
  services_range_name = "services"
  services_cidr      = "10.30.0.0/20"

  # Sized for typical new-project quotas (CPUS_ALL_REGIONS / SSD); edit here if you raise quotas.
  node_machine_type = "e2-standard-2"
  node_disk_size_gb   = 100
  node_disk_type      = "pd-standard"
  # Regional cluster: min/max apply **per zone** (us-central1 → 3 zones). min=2 ⇒ 6 VMs minimum; min=1 ⇒ 3 VMs.
  node_count_min = 1
  # Cap scale-out cost (per zone); 2 ⇒ at most 6 nodes regional.
  node_count_max = 2
  # Spot VMs: large discount; nodes may be preempted (workloads reschedule). No cluster recreate—pool update only.
  node_spot = true
}

resource "google_project" "demo" {
  project_id      = var.project_id
  name            = var.project_name
  billing_account = var.billing_account
}

resource "google_project_service" "required" {
  for_each = local.required_apis

  project            = google_project.demo.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "demo" {
  name                    = local.network_name
  project                 = google_project.demo.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "demo" {
  name          = "${local.cluster_name}-subnet"
  ip_cidr_range = local.subnet_cidr
  region        = local.region
  project       = google_project.demo.project_id
  network       = google_compute_network.demo.id

  secondary_ip_range {
    range_name    = local.pods_range_name
    ip_cidr_range = local.pods_cidr
  }

  secondary_ip_range {
    range_name    = local.services_range_name
    ip_cidr_range = local.services_cidr
  }
}

resource "google_container_cluster" "demo" {
  name       = local.cluster_name
  location   = local.region
  project    = google_project.demo.project_id
  # self_link matches API state; short names often drift to full URLs in refresh and can show huge diffs.
  network    = google_compute_network.demo.self_link
  subnetwork = google_compute_subnetwork.demo.self_link

  deletion_protection = false

  networking_mode = "VPC_NATIVE"

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
  }

  workload_identity_config {
    workload_pool = "${google_project.demo.project_id}.svc.id.goog"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    # Required at create; after remove_default_node_pool the API/provider often diverge on this block.
    # Spot belongs on google_container_node_pool only (cluster-level spot forces replacement).
    machine_type = local.node_machine_type
    disk_size_gb = local.node_disk_size_gb
    disk_type    = local.node_disk_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [node_config]
  }

  depends_on = [google_project_service.required]
}

resource "google_container_node_pool" "primary" {
  name       = "primary-pool"
  project    = google_project.demo.project_id
  cluster    = google_container_cluster.demo.name
  location   = local.region
  node_count = local.node_count_min

  autoscaling {
    min_node_count = local.node_count_min
    max_node_count = local.node_count_max
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = local.node_machine_type
    disk_size_gb = local.node_disk_size_gb
    disk_type    = local.node_disk_type
    spot         = local.node_spot

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "demo"
      workload    = "gitops-promoter"
    }
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "60m"
  }
}
