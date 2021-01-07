# KeyRing for cluster
resource "google_kms_key_ring" "gke" {
  location = var.region
  name     = var.name
  project  = var.project_id

  lifecycle {
    # KeyRings cannot be destroyed in Google Cloud
    prevent_destroy = true
  }
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

resource "google_kms_crypto_key_iam_binding" "crypto_key_db" {
  crypto_key_id = google_kms_crypto_key.db.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

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

resource "google_kms_crypto_key_iam_binding" "crypto_key_root_disk" {
  crypto_key_id = google_kms_crypto_key.root_disk.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.gke_project.number}@compute-system.iam.gserviceaccount.com",
  ]
}

# Disk encryption key for PVCs in storageClass "standard-cmek"
resource "google_kms_crypto_key" "sc_standard_cmek_disk" {
  name     = "k8s-sc-standard-cmek-disk"
  key_ring = google_kms_key_ring.gke.self_link
  # 30 days
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "crypto_key_sc_standard_cmek_disk" {
  crypto_key_id = google_kms_crypto_key.sc_standard_cmek_disk.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.gke_project.number}@compute-system.iam.gserviceaccount.com",
  ]
}
