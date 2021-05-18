locals {
  project_id = var.packet_net_project_id
}

data "packet_device" "builder" {
  project_id = local.project_id
  hostname   = "builder.fluentbit.io"
}

data "packet_device" "dev-arm" {
  project_id = local.project_id
  hostname   = "dev-arm.fluentbit.io"
}

data "packet_device" "www" {
  project_id = local.project_id
  hostname   = "fluentbit.io"
}

data "packet_device" "perf-test" {
  project_id = local.project_id
  hostname   = "perf-test.fluentbit.io"
}

provider "google" {
  project     = var.gcp-project-id
  region      = var.gcp-default-region
  credentials = var.gcp-sa-key
}

resource "google_compute_network" "default-services" {
  name                    = "default-public-svc-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default-services-subnet" {
  name          = "default-public-svc-subnet"
  ip_cidr_range = "192.168.1.0/24"
  network       = google_compute_network.default-services.self_link
  region        = var.gcp-default-region
}

resource "google_compute_firewall" "ssh_default" {
  name    = "default-public-svc-ssh"
  network = google_compute_network.default-services.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["public-ssh"]
}

resource "google_compute_instance" "long-running-test" {
  name         = "long-running-test"
  machine_type = var.gcp-default-machine-type
  zone         = var.gcp-default-zone

  tags = ["public-ssh"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size = 500
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default-services-subnet.name
    access_config {
    }
  }

  metadata = {
    ssh-keys = join("\n", [for user, key in var.gcp-ssh-keys : "${user}:${key}"])
  }
}