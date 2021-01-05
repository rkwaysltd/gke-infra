# KeyRing for cluster
resource "google_kms_key_ring" "gke" {
  location = var.region
  name     = var.name
  project  = var.project_id
}

# Database (Secrets) encryption key
resource "google_kms_crypto_key" "db" {
  name     = "k8s-db"
  key_ring = google_kms_key_ring.gke.self_link
  # 30 days
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_key_ring_iam_binding" "key_ring_db" {
  key_ring_id = google_kms_key_ring.gke.id
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.gke_project.number}@container-engine-robot.iam.gserviceaccount.com",
  ]
}

# Root disk (for nodes) encryption key
resource "google_kms_crypto_key" "root_disk" {
  name     = "k8s-root-disk"
  key_ring = google_kms_key_ring.gke.self_link
  # 30 days
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_key_ring_iam_binding" "key_ring_root_disk" {
  key_ring_id = google_kms_key_ring.gke.id
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.gke_project.number}@container-engine-robot.iam.gserviceaccount.com",
  ]
}
