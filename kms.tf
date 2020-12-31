resource "google_kms_key_ring" "db" {
  location = var.region
  name     = "k8s-db"
  project  = var.project_id
}

resource "google_kms_crypto_key" "db" {
  name     = "k8s-db"
  key_ring = google_kms_key_ring.db.self_link
  # 30 days
  rotation_period = "2592000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_key_ring_iam_binding" "key_ring_db" {
  key_ring_id = google_kms_key_ring.db.id
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.gke_project.number}@container-engine-robot.iam.gserviceaccount.com",
  ]
}
